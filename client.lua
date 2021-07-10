local mediaPlayers = {}
local localMediaPlayers = {}

local baseVolume = 50
local statusIsShown = false
local uiIsOpen = false
local syncIsEnabled = true

RegisterNetEvent("pmms:sync")
RegisterNetEvent("pmms:start")
RegisterNetEvent("pmms:play")
RegisterNetEvent("pmms:stop")
RegisterNetEvent("pmms:showControls")
RegisterNetEvent("pmms:toggleStatus")
RegisterNetEvent("pmms:error")
RegisterNetEvent("pmms:init")
RegisterNetEvent("pmms:reset")
RegisterNetEvent("pmms:startClosestMediaPlayer")
RegisterNetEvent("pmms:pauseClosestMediaPlayer")
RegisterNetEvent("pmms:stopClosestMediaPlayer")
RegisterNetEvent("pmms:listPresets")
RegisterNetEvent("pmms:setBaseVolume")
RegisterNetEvent("pmms:showBaseVolume")
RegisterNetEvent("pmms:loadSettings")

local entityEnumerator = {
	__gc = function(enum)
		if enum.destructor and enum.handle then
			enum.destructor(enum.handle)
		end
		enum.destructor = nil
		enum.handle = nil
	end
}

local function enumerateEntities(firstFunc, nextFunc, endFunc)
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

local function enumerateObjects()
	return enumerateEntities(FindFirstObject, FindNextObject, EndFindObject)
end

local function isMediaPlayer(object)
	return Config.models[GetEntityModel(object)] ~= nil
end

local function getHandle(object)
	return NetworkGetEntityIsNetworked(object) and ObjToNet(object) or object
end

local function findHandle(object)
	if NetworkGetEntityIsNetworked(object) then
		local netId = ObjToNet(object)

		if mediaPlayers[netId] then
			return netId
		end
	end

	local handle = GetHandleFromCoords(GetEntityCoords(object))

	if mediaPlayers[handle] then
		return handle
	end

	return nil
end

local function forEachMediaPlayer(func)
	for object in enumerateObjects() do
		if isMediaPlayer(object) then
			func(object)
		end
	end
end

local function getClosestMediaPlayerObject(centre, radius, listenerPos, range)
	if listenerPos and range and #(centre - listenerPos) > range then
		return nil
	end

	local min
	local closest

	forEachMediaPlayer(function(object)
		local coords = GetEntityCoords(object)
		local distance = #(centre - coords)

		if distance <= radius and (not min or distance < min) then
			min = distance
			closest = object
		end
	end)

	return closest
end

local function getClosestMediaPlayer()
	return getClosestMediaPlayerObject(GetEntityCoords(PlayerPedId()), Config.maxDiscoveryDistance)
end

local function startMediaPlayer(handle, url, volume, offset, loop, filter, locked, video, videoSize, muted, attenuation, range, visualization, queue, coords)
	volume = Clamp(volume, 0, 100, 100)

	if not offset then
		offset = "0"
	end

	if NetworkDoesNetworkIdExist(handle) then
		TriggerServerEvent("pmms:start", handle, url, volume, offset, loop, filter, locked, video, videoSize, muted, attenuation, range, visualization, queue, false)
	else
		if not coords then
			coords = GetEntityCoords(handle)
		end

		TriggerServerEvent("pmms:start", nil, url, volume, offset, loop, filter, locked, video, videoSize, muted, attenuation, range, visualization, queue, coords)
	end
end

local function startClosestMediaPlayer(url, volume, offset, loop, filter, locked, video, videoSize, muted, attenuation, range, visualization)
	startMediaPlayer(getHandle(getClosestMediaPlayer()), url, volume, offset, loop, filter, locked, video, videoSize, muted, attenuation, range, visualization, false, false)
end

local function pauseMediaPlayer(handle)
	TriggerServerEvent("pmms:pause", handle)
end

local function pauseClosestMediaPlayer()
	pauseMediaPlayer(findHandle(getClosestMediaPlayer()))
end

local function stopMediaPlayer(handle)
	TriggerServerEvent("pmms:stop", handle)
end

local function stopClosestMediaPlayer()
	stopMediaPlayer(findHandle(getClosestMediaPlayer()))
end

local function getListenerAndViewerInfo()
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

local function sortByDistance(a, b)
	if a.distance < 0 then
		return false
	elseif b.distance < 0 then
		return true
	else
		return a.distance < b.distance
	end
end

local function isInSameRoom(entity1, entity2)
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

local function listPresets()
	local presets = {}

	for preset, info in pairs(Config.presets) do
		table.insert(presets, preset)
	end

	if #presets == 0 then
		TriggerEvent("chat:addMessage", {
			color = {255, 255, 128},
			args = {"No presets available"}
		})
	else
		table.sort(presets)

		for _, preset in ipairs(presets) do
			TriggerEvent("chat:addMessage", {
				args = {preset, Config.presets[preset].title}
			})
		end
	end
end

local function getLocalMediaPlayer(coords, listenerPos, range)
	local handle = GetHandleFromCoords(coords)

	if not (localMediaPlayers[handle] and DoesEntityExist(localMediaPlayers[handle])) then
		localMediaPlayers[handle] = getClosestMediaPlayerObject(coords, 1.0, listenerPos, range)
	end

	return localMediaPlayers[handle]
end

local function getObjectLabel(handle, object)
	local defaultMediaPlayer = GetDefaultMediaPlayer(Config.defaultMediaPlayers, GetEntityCoords(object))

	if defaultMediaPlayer and defaultMediaPlayer.label then
		return defaultMediaPlayer.label
	else
		local model = GetEntityModel(object)

		if model and Config.models[model] then
			return Config.models[model].label
		else
			return string.format("%x", handle)
		end
	end
end

local function updateUi(fullControls, anyUrl)
	local pos = GetEntityCoords(PlayerPedId())

	local activeMediaPlayers = {}

	for handle, info in pairs(mediaPlayers) do
		local object

		if info.coords then
			object = getLocalMediaPlayer(info.coords, pos, info.range)
		elseif NetworkDoesNetworkIdExist(handle) then
			object = NetToObj(handle)
		end

		if object and object > 0 then
			local mediaPos = GetEntityCoords(object)
			local distance = #(pos - mediaPos)

			if fullControls or distance <= info.range then
				table.insert(activeMediaPlayers, {
					handle = handle,
					info = info,
					distance = distance,
					label = getObjectLabel(handle, object)
				})
			end
		else
			if fullControls then
				table.insert(activeMediaPlayers, {
					handle = handle,
					info = info,
					distance = -1
				})
			end
		end
	end

	table.sort(activeMediaPlayers, sortByDistance)

	local usableMediaPlayers = {}

	if uiIsOpen then
		forEachMediaPlayer(function(object)
			local mediaPos = GetEntityCoords(object)
			local clHandle = getHandle(object)

			if clHandle then
				local svHandle = NetworkGetEntityIsNetworked(object) and ObjToNet(object) or GetHandleFromCoords(mediaPos)
				local distance = #(pos - mediaPos)

				if fullControls or distance <= Config.maxDiscoveryDistance then
					table.insert(usableMediaPlayers, {
						handle = clHandle,
						distance = distance,
						label = getObjectLabel(clHandle, object),
						active = mediaPlayers[svHandle] ~= nil
					})
				end
			end
		end)

		table.sort(usableMediaPlayers, sortByDistance)
	end

	SendNUIMessage({
		type = "updateUi",
		uiIsOpen = uiIsOpen,
		activeMediaPlayers = json.encode(activeMediaPlayers),
		usableMediaPlayers = json.encode(usableMediaPlayers),
		presets = json.encode(Config.presets),
		anyUrl = anyUrl,
		maxDiscoveryDistance = Config.maxDiscoveryDistance,
		fullControls = fullControls,
		baseVolume = baseVolume
	})
end

local function createMediaPlayer(mediaPlayer)
	local model = mediaPlayer.model or Config.defaultModel

	RequestModel(model)

	while not HasModelLoaded(model) do
		Citizen.Wait(0)
	end

	mediaPlayer.handle = CreateObjectNoOffset(model, mediaPlayer.position, false, false, false, false)

	SetModelAsNoLongerNeeded(model)

	SetEntityRotation(mediaPlayer.handle, mediaPlayer.rotation, 2)

	if mediaPlayer.invisible then
		SetEntityVisible(mediaPlayer.handle, false)
		SetEntityCollision(mediaPlayer.handle, false, false)
	end
end

local function setMediaPlayerVolume(handle, volume)
	TriggerServerEvent("pmms:setVolume", handle, volume)
end

local function setMediaPlayerStartTime(handle, time)
	TriggerServerEvent("pmms:setStartTime", handle, time)
end

local function lockMediaPlayer(handle)
	TriggerServerEvent("pmms:lock", handle)
end

local function unlockMediaPlayer(handle)
	TriggerServerEvent("pmms:unlock", handle)
end

local function setBaseVolume(volume)
	baseVolume = Clamp(volume, 0, 100, 100)
	SetResourceKvp("baseVolume", tostring(baseVolume))
end

local function loadSettings()
	local volume = GetResourceKvpString("baseVolume")

	if volume then
		baseVolume = tonumber(volume)
	end

	local showStatus = GetResourceKvpInt("showStatus")

	if showStatus == 1 then
		TriggerEvent("pmms:toggleStatus")
	end
end

local function enableVideo(handle)
	TriggerServerEvent("pmms:enableVideo", handle)
end

local function disableVideo(handle)
	TriggerServerEvent("pmms:disableVideo", handle)
end

local function isPauseMenuOrMapActive()
	if Config.isRDR then
		return IsPauseMenuActive() or IsAppActive(`MAP`) ~= 0
	else
		return IsPauseMenuActive()
	end
end

local function copyMediaPlayer(oldHandle, newHandle)
	if NetworkDoesNetworkIdExist(newHandle) then
		TriggerServerEvent("pmms:copy", oldHandle, newHandle)
	else
		local coords = GetEntityCoords(newHandle)
		TriggerServerEvent("pmms:copy", oldHandle, false, coords)
	end
end

local function getObjectModelAndRenderTarget(handle)
	local object

	if type(handle) == "vector3" then
		object = getLocalMediaPlayer(handle, GetEntityCoords(PlayerPedId()), Config.maxRange)
	elseif NetworkDoesNetworkIdExist(handle) then
		object = NetToObj(handle)
	else
		return
	end

	local model = GetEntityModel(object)

	if not model then
		return
	end

	if Config.models[model] then
		return object, model, Config.models[model].renderTarget
	end
end

local function sendMediaMessage(handle, coords, data)
	if Config.isRDR then
		SendNUIMessage(data)
	else
		local duiBrowser = DuiBrowser:getBrowserForHandle(handle)

		if not duiBrowser then
			local object, model, renderTarget = getObjectModelAndRenderTarget(coords or handle)

			if object and model then
				local ped, listenPos, viewerPos, viewerFov = getListenerAndViewerInfo()

				if #(viewerPos - GetEntityCoords(object)) < (data.range or Config.maxRange) then
					duiBrowser = DuiBrowser:new(handle, model, renderTarget)
				end
			end
		end

		if duiBrowser then
			duiBrowser:sendMessage(data)
		end
	end
end

RegisterNUICallback("startup", function(data, cb)
	loadSettings()

	TriggerServerEvent("pmms:loadSettings")

	cb {
		isRDR = Config.isRDR,
		defaultSameRoomAttenuation = Config.defaultSameRoomAttenuation,
		defaultDiffRoomAttenuation = Config.defaultDiffRoomAttenuation,
		defaultRange = Config.defaultRange,
		maxRange = Config.maxRange,
		defaultVideoSize = Config.defaultVideoSize,
		audioVisualizations = Config.audioVisualizations
	}
end)

RegisterNUICallback("duiStartup", function(data, cb)
	cb {
		isRDR = Config.isRDR,
		audioVisualizations = Config.audioVisualizations
	}
end)

RegisterNUICallback("init", function(data, cb)
	if NetworkDoesNetworkIdExist(data.handle) or data.coords then
		local coords = json.decode(data.coords)

		TriggerServerEvent("pmms:init",
			data.handle,
			data.url,
			data.title,
			data.volume,
			data.offset,
			data.duration,
			data.loop,
			data.filter,
			data.locked,
			data.video,
			data.videoSize,
			data.muted,
			data.attenuation,
			data.range,
			data.visualization,
			data.queue,
			coords and ToVector3(coords))
	end
	cb({})
end)

RegisterNUICallback("initError", function(data, cb)
	TriggerEvent("pmms:error", "Error loading " .. data.url)
	cb({})
end)

RegisterNUICallback("playError", function(data, cb)
	TriggerEvent("pmms:error", "Error playing " .. data.url)
	cb({})
end)

RegisterNUICallback("play", function(data, cb)
	startMediaPlayer(data.handle, data.url, data.volume, data.offset, data.loop, data.filter, data.locked, data.video, data.videoSize, data.muted, data.attenuation, data.range, data.visualization, false, false)
	cb({})
end)

RegisterNUICallback("pause", function(data, cb)
	TriggerServerEvent("pmms:pause", data.handle)
	cb({})
end)

RegisterNUICallback("stop", function(data, cb)
	stopMediaPlayer(data.handle, true)
	cb({})
end)

RegisterNUICallback("closeUi", function(data, cb)
	SetNuiFocus(false, false)
	uiIsOpen = false
	cb({})
end)

RegisterNUICallback("volumeDown", function(data, cb)
	setMediaPlayerVolume(data.handle, mediaPlayers[data.handle].volume - 5)
	cb({})
end)

RegisterNUICallback("volumeUp", function(data, cb)
	setMediaPlayerVolume(data.handle, mediaPlayers[data.handle].volume + 5)
	cb({})
end)

RegisterNUICallback("seekBackward", function(data, cb)
	setMediaPlayerStartTime(data.handle, mediaPlayers[data.handle].startTime + 10)
	cb({})
end)

RegisterNUICallback("seekForward", function(data, cb)
	setMediaPlayerStartTime(data.handle, mediaPlayers[data.handle].startTime - 10)
	cb({})
end)

RegisterNUICallback("seekToTime", function(data, cb)
	local p = mediaPlayers[data.handle]
	setMediaPlayerStartTime(data.handle, p.startTime + (p.offset - data.offset))
	cb({})
end)

RegisterNUICallback("lock", function(data, cb)
	lockMediaPlayer(data.handle)
	cb({})
end)

RegisterNUICallback("unlock", function(data, cb)
	unlockMediaPlayer(data.handle)
	cb({})
end)

RegisterNUICallback("setBaseVolume", function(data, cb)
	setBaseVolume(data.volume)
	cb({})
end)

RegisterNUICallback("enableVideo", function(data, cb)
	enableVideo(data.handle)
	cb({})
end)

RegisterNUICallback("disableVideo", function(data, cb)
	disableVideo(data.handle)
	cb({})
end)

RegisterNUICallback("decreaseVideoSize", function(data, cb)
	TriggerServerEvent("pmms:setVideoSize", data.handle, mediaPlayers[data.handle].videoSize - 10)
	cb({})
end)

RegisterNUICallback("increaseVideoSize", function(data, cb)
	TriggerServerEvent("pmms:setVideoSize", data.handle, mediaPlayers[data.handle].videoSize + 10)
	cb({})
end)

RegisterNUICallback("mute", function(data, cb)
	TriggerServerEvent("pmms:mute", data.handle)
	cb({})
end)

RegisterNUICallback("unmute", function(data, cb)
	TriggerServerEvent("pmms:unmute", data.handle)
	cb({})
end)

RegisterNUICallback("copy", function(data, cb)
	copyMediaPlayer(data.oldHandle, data.newHandle)
	cb({})
end)

RegisterNUICallback("setLoop", function(data, cb)
	TriggerServerEvent("pmms:setLoop", data.handle, data.loop)
	cb({})
end)

RegisterNUICallback("next", function(data, cb)
	TriggerServerEvent("pmms:next", data.handle)
	cb({})
end)

RegisterNUICallback("removeFromQueue", function(data, cb)
	TriggerServerEvent("pmms:removeFromQueue", data.handle, data.index)
	cb({})
end)

RegisterNUICallback("toggleStatus", function(data, cb)
	TriggerEvent("pmms:toggleStatus")
	cb({})
end)

RegisterNUICallback("setMediaPlayerDefaults", function(data, cb)
	local object

	if NetworkDoesNetworkIdExist(data.handle) then
		object = NetToObj(data.handle)
	else
		object = data.handle
	end

	local defaults = GetDefaultMediaPlayer(Config.defaultMediaPlayers, GetEntityCoords(object)) or Config.models[GetEntityModel(object)]

	cb(defaults or {})
end)

RegisterNUICallback("save", function(data, cb)
	if data.method == "new-model" then
		TriggerServerEvent("pmms:saveModel", GetHashKey(data.model), data)
	else
		local object

		if NetworkDoesNetworkIdExist(data.handle) then
			object = NetToObj(data.handle)
		elseif DoesEntityExist(data.handle) then
			object = data.handle
		end

		if not object then
			return
		end

		if data.method == "client-model" or data.method == "server-model" then
			local model = GetEntityModel(object)

			if data.method == "client-model" then
				print("Client-side model saving is not implemented yet")
			elseif data.method == "server-model" then
				TriggerServerEvent("pmms:saveModel", model, data)
			end
		elseif data.method == "client-object" or data.method == "server-object" then
			local coords = GetEntityCoords(object)

			if data.method == "client-object" then
				print("Client-side object saving is not implemented yet")
			elseif data.method == "server-object" then
				TriggerServerEvent("pmms:saveObject", coords, data)
			end
		end
	end

	cb({})
end)

AddEventHandler("pmms:sync", function(players, fullControls, anyUrl)
	if syncIsEnabled then
		mediaPlayers = players

		if uiIsOpen or statusIsShown then
			updateUi(fullControls, anyUrl)
		end
	end
end)

AddEventHandler("pmms:start", function(handle, url, title, volume, offset, loop, filter, locked, video, videoSize, muted, attenuation, range, visualization, queue, coords)
	sendMediaMessage(handle, coords, {
		type = "init",
		handle = handle,
		url = url,
		title = title,
		volume = volume,
		offset = offset,
		loop = loop,
		filter = filter,
		locked = locked,
		video = video,
		videoSize = videoSize,
		muted = muted,
		attenuation = attenuation,
		range = range,
		visualization = visualization,
		queue = queue,
		coords = json.encode(coords)
	})
end)

AddEventHandler("pmms:play", function(handle)
	sendMediaMessage(handle, nil, {
		type = "play",
		handle = handle
	})
end)

AddEventHandler("pmms:stop", function(handle)
	local duiBrowser = DuiBrowser:getBrowserForHandle(handle)

	if duiBrowser then
		duiBrowser:delete()
	else
		SendNUIMessage({
			type = "stop",
			handle = handle
		})
	end
end)

AddEventHandler("pmms:showControls", function()
	SendNUIMessage({
		type = "showUi"
	})
	SetNuiFocus(true, true)
	uiIsOpen = true
end)

AddEventHandler("pmms:toggleStatus", function()
	SendNUIMessage({
		type = "toggleStatus"
	})
	statusIsShown = not statusIsShown
	SetResourceKvpInt("showStatus", statusIsShown and 1 or 0)
end)

AddEventHandler("pmms:error", function(message)
	print(message)
end)

AddEventHandler("pmms:init", function(handle, url, volume, offset, loop, filter, locked, video, videoSize, muted, attenuation, range, visualization, queue, coords)
	startMediaPlayer(handle, url, volume, offset, loop, filter, locked, video, videoSize, muted, attenuation, range, visualization, queue, coords)
end)

AddEventHandler("pmms:reset", function()
	print("Resetting...")

	syncIsEnabled = false

	mediaPlayers = {}
	localMediaPlayers = {}

	DuiBrowser:resetPool()

	syncIsEnabled = true
end)

AddEventHandler("pmms:startClosestMediaPlayer", function(url, offset, loop, filter, locked, video, videoSize, muted, attenuation, range, visualization)
	startClosestMediaPlayer(url, 100, offset, loop, filter, locked, video, videoSize, muted, attenuation, range, visualization)
end)

AddEventHandler("pmms:pauseClosestMediaPlayer", function()
	pauseClosestMediaPlayer()
end)

AddEventHandler("pmms:stopClosestMediaPlayer", function()
	stopClosestMediaPlayer()
end)

AddEventHandler("pmms:listPresets", function()
	listPresets()
end)

AddEventHandler("pmms:showBaseVolume", function()
	TriggerEvent("chat:addMessage", {
		color = {255, 255, 128},
		args = {"Volume", baseVolume}
	})
end)

AddEventHandler("pmms:setBaseVolume", function(volume)
	setBaseVolume(volume)
end)

AddEventHandler("pmms:loadSettings", function(models, defaultMediaPlayers)
	Config.models = models or {}

	for _, defaultMediaPlayer in ipairs(defaultMediaPlayers) do
		local dmp = GetDefaultMediaPlayer(Config.defaultMediaPlayers, defaultMediaPlayer.position)

		if dmp then
			dmp.label = defaultMediaPlayer.label
			dmp.filter = defaultMediaPlayer.filter
			dmp.volume = defaultMediaPlayer.volume
			dmp.attenuation = defaultMediaPlayer.attenuation
			dmp.range = defaultMediaPlayer.range
		else
			table.insert(Config.defaultMediaPlayers, defaultMediaPlayer)
		end
	end
end)

AddEventHandler("onResourceStop", function(resource)
	if GetCurrentResourceName() ~= resource then
		return
	end

	for _, mediaPlayer in ipairs(Config.defaultMediaPlayers) do
		if mediaPlayer.handle then
			DeleteEntity(mediaPlayer.handle)
		end
	end

	if uiIsOpen then
		SetNuiFocus(false, false)
	end
end)

Citizen.CreateThread(function()
	TriggerEvent("chat:addSuggestion", "/" .. Config.commandPrefix, "Open the media player control panel.")

	TriggerEvent("chat:addSuggestion", "/" .. Config.commandPrefix .. Config.commandSeparator .. "play", "Play something on the closest media player.", {
		{name = "url", help = "URL or preset name of music to play. Use \"random\" to play a random preset."},
		{name = "filter", help = "0 = no filter, 1 = add immersive filter"},
		{name = "loop", help = "0 = play once, 1 = loop"},
		{name = "time", help = "Time to start playing at. Specify in seconds (e.g., 120) or hh:mm:ss (e.g., 00:02:00)."},
		{name = "lock", help = "0 = unlocked, 1 = locked"},
		{name = "video", help = "0 = hide video, 1 = show video"},
		{name = "size", help = "Video size"},
		{name = "mute", help = "0 = unmuted, 1 = muted"},
		{name = "sameRoom", help = "Sound attenuation multiplier when in the same room"},
		{name = "diffRoom", help = "Sound attenuation multiplier when in a different room"},
		{name = "range", help = "Maximum range of the media player"},
		{name = "visualization", help = "Audio visualization type"}
	})

	TriggerEvent("chat:addSuggestion", "/" .. Config.commandPrefix .. Config.commandSeparator .. "pause", "Pause the closest media player.")

	TriggerEvent("chat:addSuggestion", "/" .. Config.commandPrefix .. Config.commandSeparator .. "stop", "Stop the closest media player.")

	TriggerEvent("chat:addSuggestion", "/" .. Config.commandPrefix .. Config.commandSeparator .. "status", "Show/hide the status of the closest media player.")

	TriggerEvent("chat:addSuggestion", "/" .. Config.commandPrefix .. Config.commandSeparator .. "presets", "List available presets.")

	TriggerEvent("chat:addSuggestion", "/" .. Config.commandPrefix .. Config.commandSeparator .. "vol", "Adjust the base volume of all media players.", {
		{name = "volume", help = "0-100"}
	})

	TriggerEvent("chat:addSuggestion", "/" .. Config.commandPrefix .. Config.commandSeparator .. "add", "Add or modify a media player model preset.", {
		{name = "model", help = "The name of the object model"},
		{name = "label", help = "The label that appears for this model in the UI"},
		{name = "renderTarget", help = "An optional name of a render target for this model"}
	})

	TriggerEvent("chat:addSuggestion", "/" .. Config.commandPrefix .. Config.commandSeparator .. "fix", "Reset all media players to fix issues.")

	TriggerEvent("chat:addSuggestion", "/" .. Config.commandPrefix .. Config.commandSeparator .. "ctl", "Advanced media player control.")
end)

Citizen.CreateThread(function()
	while true do
		local ped, listenPos, viewerPos, viewerFov = getListenerAndViewerInfo()

		local canWait = true
		local duiToDraw = {}

		for handle, info in pairs(mediaPlayers) do
			local object

			if info.coords then
				object = getLocalMediaPlayer(info.coords, listenPos, info.range)
			elseif NetworkDoesNetworkIdExist(handle) then
				object = NetToObj(handle)
			end

			local data
			local distance

			if object and object > 0 then
				local mediaPos = GetEntityCoords(object)

				distance = #(listenPos - mediaPos)

				local camDistance
				local onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(mediaPos.x, mediaPos.y, mediaPos.z + 0.8)

				if onScreen and not isPauseMenuOrMapActive() then
					camDistance = #(viewerPos - mediaPos)
				else
					camDistance = -1
				end

				data = {
					type = "update",
					handle = handle,
					url = info.url,
					title = info.title,
					volume = math.floor(info.volume * (baseVolume / 100)),
					muted = info.muted,
					attenuation = info.attenuation,
					range = info.range,
					visualization = info.visualization,
					offset = info.offset,
					duration = info.duration,
					loop = info.loop,
					filter = info.filter,
					locked = info.locked,
					video = info.video,
					videoSize = info.videoSize,
					paused = info.paused,
					coords = json.encode(info.coords),
					distance = distance,
					sameRoom = isInSameRoom(ped, object),
					camDistance = camDistance,
					fov = viewerFov,
					screenX = screenX,
					screenY = screenY
				}

				if distance < info.range then
					canWait = false
				end

				local duiBrowser = DuiBrowser:getBrowserForHandle(handle)

				if duiBrowser and duiBrowser.renderTarget then
					if distance < info.range then
						if not duiToDraw[duiBrowser.renderTarget] then
							duiToDraw[duiBrowser.renderTarget] = {}
						end
						table.insert(duiToDraw[duiBrowser.renderTarget], {
							duiBrowser = duiBrowser,
							distance = distance
						})
					end
				end
			else
				distance = -1

				data = {
					type = "update",
					handle = handle,
					url = info.url,
					title = info.title,
					volume = 0,
					muted = true,
					attenuation = info.attenuation,
					range = info.range,
					visualization = info.visualization,
					offset = info.offset,
					duration = info.duration,
					loop = info.loop,
					filter = info.filter,
					locked = info.locked,
					video = info.video,
					videoSize = info.videoSize,
					paused = info.paused,
					coords = json.encode(info.coords),
					distance = distance,
					sameRoom = false,
					camDistance = -1,
					fov = viewerFov,
					screenX = 0,
					screenY = 0
				}
			end

			sendMediaMessage(handle, info.coords, data)
		end

		for renderTarget, items in pairs(duiToDraw) do
			table.sort(items, function(a, b)
				return a.distance < b.distance
			end)

			for i = 2, #items do
				items[i].duiBrowser:disableRenderTarget()
			end

			items[1].duiBrowser:draw()
		end

		Citizen.Wait(canWait and 1000 or 0)
	end
end)

Citizen.CreateThread(function()
	while true do
		local myPos = GetEntityCoords(PlayerPedId())

		for _, mediaPlayer in ipairs(Config.defaultMediaPlayers) do
			if mediaPlayer.spawn then
				local nearby = #(myPos - mediaPlayer.position) <= Config.defaultMediaPlayerSpawnDistance

				if mediaPlayer.handle and not DoesEntityExist(mediaPlayer.handle) then
					mediaPlayer.handle = nil
				end

				if nearby and not mediaPlayer.handle then
					createMediaPlayer(mediaPlayer)
				elseif not nearby and mediaPlayer.handle then
					DeleteObject(mediaPlayer.handle)
				end
			end
		end

		Citizen.Wait(1000)
	end
end)
