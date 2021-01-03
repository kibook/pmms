local Phonographs = {}
local LocalPhonographs = {}

local BaseVolume = 100
local StatusIsShown = false
local UiIsOpen = false

RegisterNetEvent('phonograph:sync')
RegisterNetEvent('phonograph:start')
RegisterNetEvent('phonograph:play')
RegisterNetEvent('phonograph:stop')
RegisterNetEvent('phonograph:showControls')
RegisterNetEvent('phonograph:toggleStatus')
RegisterNetEvent('phonograph:error')

local entityEnumerator = {
	__gc = function(enum)
		if enum.destructor and enum.handle then
			enum.destructor(enum.handle)
		end
		enum.destructor = nil
		enum.handle = nil
	end
}

function EnumerateEntities(firstFunc, nextFunc, endFunc)
	return coroutine.wrap(function()
		local iter, id = firstFunc()

		if not id or id == 0 then
			endFunc(iter)
			return
		end

		local enum = {handle = iter, destructor = endFunc}
		setmetatable(enum, entityEnumerator)

		local next = true
		repeat
			coroutine.yield(id)
			next, id = nextFunc(iter)
		until not next

		enum.destructor, enum.handle = nil, nil
		endFunc(iter)
	end)
end

function EnumerateObjects()
	return EnumerateEntities(FindFirstObject, FindNextObject, EndFindObject)
end

function IsPhonograph(object)
	return GetEntityModel(object) == GetHashKey('p_phonograph01x')
end

function GetHandle(object)
	return NetworkGetEntityIsNetworked(object) and ObjToNet(object) or object
end

function FindHandle(object)
	if NetworkGetEntityIsNetworked(object) then
		local netId = ObjToNet(object)

		if Phonographs[netId] then
			return netId
		end
	end

	local handle = GetHandleFromCoords(GetEntityCoords(object))

	if Phonographs[handle] then
		return handle
	end

	return nil
end

function ForEachPhonograph(func)
	for object in EnumerateObjects() do
		if IsPhonograph(object) then
			func(object)
		end
	end
end

function GetClosestPhonographObject(centre, radius, listenerPos)
	if listenerPos and #(centre - listenerPos) > Config.MaxDistance then
		return nil
	end

	local min
	local closest

	ForEachPhonograph(function(object)
		local coords = GetEntityCoords(object)
		local distance = #(centre - coords)

		if distance <= radius and (not min or distance < min) then
			min = distance
			closest = object
		end
	end)

	return closest
end

function GetClosestPhonograph()
	return GetClosestPhonographObject(GetEntityCoords(PlayerPedId()), Config.MaxDistance)
end

function StartPhonograph(handle, url, volume, offset, filter, locked, video, videoSize, muted)
	if url == 'random' then
		url = GetRandomPreset()
	end

	volume = Clamp(volume, 0, 100)

	if not offset then
		offset = '0'
	end

	if NetworkDoesNetworkIdExist(handle) then
		TriggerServerEvent('phonograph:start', handle, url, volume, offset, filter, locked, video, videoSize, muted, nil)
	else
		local coords = GetEntityCoords(handle)
		TriggerServerEvent('phonograph:start', nil, url, volume, offset, filter, locked, video, videoSize, muted, coords)
	end
end

function StartClosestPhonograph(url, volume, offset, filter, locked, video, videoSize, muted)
	StartPhonograph(GetHandle(GetClosestPhonograph()), url, volume, offset, filter, locked, video, videoSize, muted)
end

function PausePhonograph(handle)
	TriggerServerEvent('phonograph:pause', handle)
end

function PauseClosestPhonograph()
end

function StopPhonograph(handle)
	TriggerServerEvent('phonograph:stop', handle)
end

function StopClosestPhonograph()
	StopPhonograph(FindHandle(GetClosestPhonograph()))
end

function GetListenerAndViewerInfo()
	local cam = GetRenderingCam()
	local ped = PlayerPedId()

	local listenerCoords, viewerCoords, viewerFov

	if cam == -1 then
		if IsPedDeadOrDying(ped) then
			listenerCoords = GetGameplayCamCoord()
			viewerCoords = listenerCoords
		else
			listenerCoords = GetEntityCoords(ped)
			viewerCoords = GetGameplayCamCoord()
		end

		viewerFov = GetGameplayCamFov()
	else
		listenerCoords = GetCamCoord(cam)
		viewerCoords = listenerCoords
		viewerFov = GetCamFov(cam)
	end

	return ped, listenerCoords, viewerCoords, viewerFov
end

function SortByDistance(a, b)
	if a.distance < 0 then
		return false
	elseif b.distance < 0 then
		return true
	else
		return a.distance < b.distance
	end
end

function IsInSameRoom(entity1, entity2)
	local interior1 = GetInteriorFromEntity(entity1)
	local interior2 = GetInteriorFromEntity(entity2)

	if interior1 ~= interior2 then
		return false
	end

	local roomHash1 = GetRoomKeyFromEntity(entity1)
	local roomHash2 = GetRoomKeyFromEntity(entity2)

	if roomHash1 ~= roomHash2 then
		return false
	end

	return true
end

function ListPresets()
	local presets = {}

	for preset, info in pairs(Config.Presets) do
		table.insert(presets, preset)
	end

	if #presets == 0 then
		TriggerEvent('chat:addMessage', {
			color = {255, 255, 128},
			args = {'No presets available'}
		})
	else
		table.sort(presets)

		for _, preset in ipairs(presets) do
			TriggerEvent('chat:addMessage', {
				args = {preset, Config.Presets[preset].title}
			})
		end
	end
end

function GetLocalPhonograph(coords, listenerPos)
	local handle = GetHandleFromCoords(coords)

	if LocalPhonographs[handle] and DoesEntityExist(LocalPhonographs[handle]) then
		return LocalPhonographs[handle]
	else
		LocalPhonographs[handle] = GetClosestPhonographObject(coords, 1.0, listenerPos)
	end
end

function UpdateUi(fullControls, anyUrl)
	local pos = GetEntityCoords(PlayerPedId())

	local activePhonographs = {}

	for handle, info in pairs(Phonographs) do
		local object

		if info.coords then
			object = GetLocalPhonograph(info.coords, pos)
		elseif NetworkDoesNetworkIdExist(handle) then
			object = NetToObj(handle)
		end

		if object and object > 0 then
			local phonoPos = GetEntityCoords(object)
			local distance = #(pos - phonoPos)

			if fullControls or distance <= Config.MaxDistance then
				table.insert(activePhonographs, {
					handle = handle,
					info = info,
					distance = distance
				})
			end
		else
			if fullControls then
				table.insert(activePhonographs, {
					handle = handle,
					info = info,
					distance = -1
				})
			end
		end
	end

	table.sort(activePhonographs, SortByDistance)

	local inactivePhonographs = {}

	if UiIsOpen then
		ForEachPhonograph(function(object)
			local phonoPos = GetEntityCoords(object)
			local clHandle = GetHandle(object)
			local svHandle = NetworkGetEntityIsNetworked(object) and ObjToNet(object) or GetHandleFromCoords(phonoPos)

			if clHandle and not Phonographs[svHandle] then
				local distance = #(pos - phonoPos)

				if fullControls or distance <= Config.MaxDistance then
					table.insert(inactivePhonographs, {
						handle = clHandle,
						distance = distance
					})
				end
			end
		end)

		table.sort(inactivePhonographs, SortByDistance)
	end

	SendNUIMessage({
		type = 'updateUi',
		activePhonographs = json.encode(activePhonographs),
		inactivePhonographs = json.encode(inactivePhonographs),
		presets = json.encode(Config.Presets),
		anyUrl = anyUrl,
		maxDistance = Config.MaxDistance,
		fullControls = fullControls,
		baseVolume = BaseVolume
	})
end

function CreatePhonograph(phonograph)
	local model = GetHashKey('p_phonograph01x')

	RequestModel(model)
	while not HasModelLoaded(model) do
		Wait(0)
	end

	phonograph.handle = CreateObjectNoOffset(GetHashKey('p_phonograph01x'), phonograph.x, phonograph.y, phonograph.z, false, false, false, false)

	SetModelAsNoLongerNeeded(model)

	SetEntityRotation(phonograph.handle, phonograph.pitch, phonograph.roll, phonograph.yaw, 2)

	if phonograph.invisible then
		SetEntityVisible(phonograph.handle, false)
	end
end

function SetPhonographVolume(handle, volume)
	TriggerServerEvent('phonograph:setVolume', handle, volume)
end

function SetPhonographStartTime(handle, time)
	TriggerServerEvent('phonograph:setStartTime', handle, time)
end

function LockPhonograph(handle)
	TriggerServerEvent('phonograph:lock', handle)
end

function UnlockPhonograph(handle)
	TriggerServerEvent('phonograph:unlock', handle)
end

function SetBaseVolume(volume)
	BaseVolume = Clamp(volume, 0, 100)
	SetResourceKvp('baseVolume', tostring(BaseVolume))
end

function LoadSettings()
	local volume = GetResourceKvpString('baseVolume')

	if volume then
		BaseVolume = tonumber(volume)
	end

	local showStatus = GetResourceKvpInt('showStatus')

	if showStatus == 1 then
		TriggerEvent('phonograph:toggleStatus')
	end
end

function EnableVideo(handle)
	TriggerServerEvent('phonograph:enableVideo', handle)
end

function DisableVideo(handle)
	TriggerServerEvent('phonograph:disableVideo', handle)
end

function IsPauseMenuOrMapActive()
	return IsPauseMenuActive() or IsAppActive(`MAP`) ~= 0
end

function CopyPhonograph(oldHandle, newHandle)
	if NetworkDoesNetworkIdExist(newHandle) then
		TriggerServerEvent('phonograph:copy', oldHandle, newHandle)
	else
		local coords = GetEntityCoords(newHandle)
		TriggerServerEvent('phonograph:copy', oldHandle, false, coords)
	end
end

function tovector3(t)
	return vector3(t.x, t.y, t.z)
end

RegisterCommand('phono', function(source, args, raw)
	if #args > 0 then
		local command = args[1]

		if command == 'play' then
			if #args > 1 then
				local url = args[2]
				local volume = tonumber(args[3]) or 100
				local offset = args[4]
				local filter = args[5] == '1'
				local locked = args[6] == '1'
				local video = args[7] == '1'
				local videoSize = tonumber(args[8]) or 50
				local muted = args[9] == '1'

				StartClosestPhonograph(url, volume, offset, filter, locked, video, videoSize, muted)
			else
				PauseClosestPhonograph()
			end
		elseif command == 'pause' then
			PauseClosestPhonograph()
		elseif command == 'stop' then
			StopClosestPhonograph()
		elseif command == 'status' then
			TriggerServerEvent('phonograph:toggleStatus')
		elseif command == 'songs' then
			ListPresets()
		end
	else
		TriggerServerEvent('phonograph:showControls')
	end
end)

RegisterCommand('phonovol', function(source, args, raw)
	if #args < 1 then
		TriggerEvent('chat:addMessage', {
			color = {255, 255, 128},
			args = {'Volume', BaseVolume}
		})
	else
		local volume = tonumber(args[1])

		if volume then
			SetBaseVolume(volume)
		end
	end
end)

RegisterNUICallback('startup', function(data, cb)
	LoadSettings()
	cb({})
end)

RegisterNUICallback('init', function(data, cb)
	if NetworkDoesNetworkIdExist(data.handle) or data.coords then
		TriggerServerEvent('phonograph:init',
			data.handle,
			data.url,
			data.title,
			data.volume,
			data.offset,
			data.filter,
			data.locked,
			data.video,
			data.videoSize,
			data.muted,
			data.coords and tovector3(json.decode(data.coords)))
	end
	cb({})
end)

RegisterNUICallback('initError', function(data, cb)
	TriggerEvent('phonograph:error', 'Error loading ' .. data.url)
	cb({})
end)

RegisterNUICallback('play', function(data, cb)
	StartPhonograph(data.handle, data.url, data.volume, data.offset, data.filter, data.locked, data.video, data.videoSize, data.muted)
	cb({})
end)

RegisterNUICallback('pause', function(data, cb)
	TriggerServerEvent('phonograph:pause', data.handle)
	cb({})
end)

RegisterNUICallback('stop', function(data, cb)
	StopPhonograph(data.handle, true)
	cb({})
end)

RegisterNUICallback('closeUi', function(data, cb)
	SetNuiFocus(false, false)
	UiIsOpen = false
	cb({})
end)

RegisterNUICallback('volumeDown', function(data, cb)
	SetPhonographVolume(data.handle, Phonographs[data.handle].volume - 5)
	cb({})
end)

RegisterNUICallback('volumeUp', function(data, cb)
	SetPhonographVolume(data.handle, Phonographs[data.handle].volume + 5)
	cb({})
end)

RegisterNUICallback('seekBackward', function(data, cb)
	SetPhonographStartTime(data.handle, Phonographs[data.handle].startTime + 10)
	cb({})
end)

RegisterNUICallback('seekForward', function(data, cb)
	SetPhonographStartTime(data.handle, Phonographs[data.handle].startTime - 10)
	cb({})
end)

RegisterNUICallback('lock', function(data, cb)
	LockPhonograph(data.handle)
	cb({})
end)

RegisterNUICallback('unlock', function(data, cb)
	UnlockPhonograph(data.handle)
	cb({})
end)

RegisterNUICallback('setBaseVolume', function(data, cb)
	SetBaseVolume(data.volume)
	cb({})
end)

RegisterNUICallback('enableVideo', function(data, cb)
	EnableVideo(data.handle)
	cb({})
end)

RegisterNUICallback('disableVideo', function(data, cb)
	DisableVideo(data.handle)
	cb({})
end)

RegisterNUICallback('decreaseVideoSize', function(data, cb)
	TriggerServerEvent('phonograph:setVideoSize', data.handle, Phonographs[data.handle].videoSize - 10)
	cb({})
end)

RegisterNUICallback('increaseVideoSize', function(data, cb)
	TriggerServerEvent('phonograph:setVideoSize', data.handle, Phonographs[data.handle].videoSize + 10)
	cb({})
end)

RegisterNUICallback('mute', function(data, cb)
	TriggerServerEvent('phonograph:mute', data.handle)
	cb({})
end)

RegisterNUICallback('unmute', function(data, cb)
	TriggerServerEvent('phonograph:unmute', data.handle)
	cb({})
end)

RegisterNUICallback('copy', function(data, cb)
	CopyPhonograph(data.oldHandle, data.newHandle)
	cb({})
end)

AddEventHandler('phonograph:sync', function(phonographs, fullControls, anyUrl)
	Phonographs = phonographs

	if UiIsOpen or StatusIsShown then
		UpdateUi(fullControls, anyUrl)
	end
end)

AddEventHandler('phonograph:start', function(handle, url, title, volume, offset, filter, locked, video, videoSize, muted, coords)
	SendNUIMessage({
		type = 'init',
		handle = handle,
		url = url,
		title = title,
		volume = volume,
		offset = offset,
		filter = filter,
		locked = locked,
		video = video,
		videoSize = videoSize,
		muted = muted,
		coords = json.encode(coords)
	})
end)

AddEventHandler('phonograph:play', function(handle)
	SendNUIMessage({
		type = 'play',
		handle = handle
	})
end)

AddEventHandler('phonograph:stop', function(handle)
	SendNUIMessage({
		type = 'stop',
		handle = handle
	})
end)

AddEventHandler('phonograph:showControls', function()
	SendNUIMessage({
		type = 'showUi'
	})
	SetNuiFocus(true, true)
	UiIsOpen = true
end)

AddEventHandler('phonograph:toggleStatus', function()
	SendNUIMessage({
		type = 'toggleStatus'
	})
	StatusIsShown = not StatusIsShown
	SetResourceKvpInt('showStatus', StatusIsShown and 1 or 0)
end)

AddEventHandler('phonograph:error', function(message)
	print(message)
end)

AddEventHandler('onResourceStop', function(resource)
	if GetCurrentResourceName() ~= resource then
		return
	end

	for _, defaultPhonograph in ipairs(Config.DefaultPhonographs) do
		if defaultPhonograph.handle then
			DeleteEntity(defaultPhonograph.handle)
		end
	end

	if UiIsOpen then
		SetNuiFocus(false, false)
	end
end)

CreateThread(function()
	TriggerEvent('chat:addSuggestion', '/phono', 'Interact with phonographs. No arguments will open the phonograph control panel.', {
		{name = 'command', help = 'play|pause|stop|status|songs'},
		{name = 'url', help = 'URL or preset name of music to play. Use "random" to play a random preset.'},
		{name = 'volume', help = 'Volume to play the music at (0-100).'},
		{name = 'time', help = 'Time in seconds to start playing at.'},
		{name = 'filter', help = '0 = normal audio, 1 = add phonograph filter'},
		{name = 'lock', help = '0 = unlocked, 1 = locked'},
		{name = 'video', help = '0 = hide video, 1 = show video'},
		{name = 'size', help = 'Video size'},
		{name = 'mute', help = '0 = unmuted, 1 = muted'}
	})

	TriggerEvent('chat:addSuggestion', '/phonovol', 'Adjust the base volume of all phonographs', {
		{name = 'volume', help = '0-100'}
	})
end)

CreateThread(function()
	while true do
		Wait(0)

		local ped, listenPos, viewerPos, viewerFov = GetListenerAndViewerInfo()

		for handle, info in pairs(Phonographs) do
			local object

			if info.coords then
				object = GetLocalPhonograph(info.coords, listenPos)
			elseif NetworkDoesNetworkIdExist(handle) then
				object = NetToObj(handle)
			end

			if object and object > 0 then
				local phonoPos = GetEntityCoords(object)

				local distance = #(listenPos - phonoPos)

				local camDistance
				local onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(phonoPos.x, phonoPos.y, phonoPos.z + 0.8)

				if onScreen and not IsPauseMenuOrMapActive() then
					camDistance = #(viewerPos - phonoPos)
				else
					camDistance = -1
				end

				SendNUIMessage({
					type = 'update',
					handle = handle,
					url = info.url,
					title = info.title,
					volume = math.floor(info.volume * (BaseVolume / 100)),
					muted = info.muted,
					offset = info.offset,
					filter = info.filter,
					locked = info.locked,
					video = info.video,
					videoSize = info.videoSize,
					paused = info.paused,
					coords = json.encode(info.coords),
					distance = distance,
					sameRoom = IsInSameRoom(ped, object),
					camDistance = camDistance,
					fov = viewerFov,
					screenX = screenX,
					screenY = screenY,
					maxDistance = Config.MaxDistance
				})
			else
				SendNUIMessage({
					type = 'update',
					handle = handle,
					url = info.url,
					title = info.title,
					volume = 0,
					muted = true,
					offset = info.offset,
					filter = info.filter,
					locked = info.locked,
					video = info.video,
					videoSize = info.videoSize,
					paused = info.paused,
					coords = json.encode(info.coords),
					distance = -1,
					sameRoom = false,
					camDistance = -1,
					fov = viewerFov,
					screenX = 0,
					screenY = 0,
					maxDistance = Config.MaxDistance
				})
			end
		end
	end
end)

CreateThread(function()
	while true do
		Wait(0)

		for _, phonograph in ipairs(Config.DefaultPhonographs) do
			if (not phonograph.handle or not DoesEntityExist(phonograph.handle)) and phonograph.spawn then
				CreatePhonograph(phonograph)
			end
		end
	end
end)
