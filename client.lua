local Phonographs = {}

RegisterNetEvent('phonograph:sync')
RegisterNetEvent('phonograph:play')
RegisterNetEvent('phonograph:stop')
RegisterNetEvent('phonograph:showControls')

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

function GetClosestPhonograph()
	local pos = GetEntityCoords(PlayerPedId())

	local closestPhonograph = nil
	local closestDistance = nil

	for object in EnumerateObjects() do
		if IsPhonograph(object) then
			local phonoPos = GetEntityCoords(object)
			local distance = GetDistanceBetweenCoords(pos.x, pos.y, pos.z, phonoPos.x, phonoPos.y, phonoPos.z, true)

			if distance <= Config.MaxDistance and (not closestDistance or distance < closestDistance) then
				closestPhonograph = object
				closestDistance = distance
			end
		end
	end
	
	return ObjToNet(closestPhonograph)
end

function StartPhonograph(handle, url, volume, offset)
	if not volume then
		volume = 100
	end

	if not offset then
		offset = 0
	end

	SendNUIMessage({
		type = 'init',
		handle = handle,
		url = url,
		volume = volume,
		offset = offset
	})
end

function StartClosestPhonograph(url, volume, offset)
	StartPhonograph(GetClosestPhonograph(), url, volume, offset)
end

function PausePhonograph(handle)
	SendNUIMessage({
		type = 'pause',
		handle = handle
	})
end

function PauseClosestPhonograph()
	PausePhonograph(GetClosestPhonograph())
end

function StopPhonograph(handle)
	TriggerServerEvent('phonograph:stop', handle)
end

function StopClosestPhonograph()
	StopPhonograph(GetClosestPhonograph())
end

function StatusPhonograph(handle)
	SendNUIMessage({
		type = 'status',
		handle = handle
	})
end

function StatusClosestPhonograph()
	StatusPhonograph(GetClosestPhonograph())
end

function GetActiveCamCoord()
	local cam = GetRenderingCam()
	return cam == -1 and GetGameplayCamCoord() or GetCamCoord(cam)
end

function SortByDistance(a, b)
	return a.distance < b.distance
end

function IsInSameRoom(entity1, entity2)
	local interior1 = GetInteriorFromEntity(entity2)
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

RegisterCommand('phono', function(source, args, raw)
	if #args > 0 then
		local command = args[1]

		if command == 'play' then
			if #args > 1 then
				local url = args[2]
				local volume = tonumber(args[3])
				local offset = tonumber(args[4])
				StartClosestPhonograph(url, volume, offset)
			else
				PauseClosestPhonograph()
			end
		elseif command == 'pause' then
			PauseClosestPhonograph()
		elseif command == 'stop' then
			StopClosestPhonograph()
		elseif command == 'status' then
			StatusClosestPhonograph()
		end
	end
end)

RegisterCommand('phonoctl', function(source, args, raw)
	TriggerServerEvent('phonograph:showControls')
end)

RegisterNUICallback('init', function(data, cb)
	TriggerServerEvent('phonograph:init', data.handle, data.url, data.volume, data.startTime)
	cb({})
end)

RegisterNUICallback('play', function(data, cb)
	StartPhonograph(data.handle, data.url, data.volume, data.offset)
	cb({})
end)

RegisterNUICallback('pause', function(data, cb)
	TriggerServerEvent('phonograph:pause', data.handle, data.paused)
	cb({})
end)

RegisterNUICallback('stop', function(data, cb)
	StopPhonograph(data.handle)
	cb({})
end)

RegisterNUICallback('status', function(data, cb)
	local phonograph = Phonographs[data.handle]

	if phonograph then
		TriggerEvent('chat:addMessage', {
			args = {string.format('[%x] %s 🔊%d 🕒%d %s', data.handle, phonograph.url, phonograph.volume, data.now - phonograph.startTime, phonograph.paused and '⏸' or '▶️')}
		})
	else
		TriggerEvent('chat:addMessage', {
			args = {string.format('[%x] Not playing', data.handle)}
		})
	end

	cb({})
end)

RegisterNUICallback('closeUi', function(data, cb)
	SetNuiFocus(false, false)
	cb({})
end)

AddEventHandler('phonograph:sync', function(phonographs)
	Phonographs = phonographs
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
end)

CreateThread(function()
	TriggerEvent('chat:addSuggestion', '/phono', 'Play music on the nearest phonograph (no arguments to stop)', {
		{name = 'command', help = 'play|pause|stop|status'},
		{name = 'url', help = 'URL of the music to play'},
		{name = 'volume', help = 'Volume to play the music at (0-100)'},
		{name = 'time', help = 'Time in seconds to start playing at'}
	})

	TriggerEvent('chat:addSuggestion', '/phonoctl', 'Open phonograph control panel')
end)

CreateThread(function()
	while true do
		Wait(0)

		local pos = GetActiveCamCoord()

		for handle, info in pairs(Phonographs) do
			if NetworkDoesNetworkIdExist(handle) then
				local object = NetToObj(handle)
				local phonoPos = GetEntityCoords(object)
				local distance = GetDistanceBetweenCoords(pos.x, pos.y, pos.z, phonoPos.x, phonoPos.y, phonoPos.z, true)

				SendNUIMessage({
					type = 'update',
					handle = handle,
					url = info.url,
					volume = info.volume,
					startTime = info.startTime,
					paused = info.paused,
					distance = distance,
					sameRoom = IsInSameRoom(PlayerPedId(), object)
				})
			else
				SendNUIMessage({
					type = 'update',
					handle = handle,
					url = info.url,
					volume = 0,
					startTime = info.startTime,
					paused = info.paused,
					distance = 0,
					sameRoom = false
				})
			end
		end
	end
end)

CreateThread(function()
	while true do
		Wait(500)

		local inactivePhonographs = {}

		local pos = GetEntityCoords(PlayerPedId())

		for object in EnumerateObjects() do
			if NetworkGetEntityIsNetworked(object) then
				local handle = ObjToNet(object)

				if IsPhonograph(object) and not Phonographs[handle] then
					local phonoPos = GetEntityCoords(object)
					local distance = GetDistanceBetweenCoords(pos.x, pos.y, pos.z, phonoPos.x, phonoPos.y, phonoPos.z, true)

					table.insert(inactivePhonographs, {
						handle = handle,
						distance = distance
					})
				end
			end
		end

		table.sort(inactivePhonographs, SortByDistance)

		SendNUIMessage({
			type = 'updateUi',
			activePhonographs = json.encode(Phonographs),
			inactivePhonographs = json.encode(inactivePhonographs)
		})
	end
end)
