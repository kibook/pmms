local mediaPlayers = {}
local localMediaPlayers = {}

local usableModels = {}
local usableObjects = {}
local personalMediaPlayers = {}

local baseVolume = 50
local statusIsShown = false
local uiIsOpen = false
local syncIsEnabled = true

local permissions = {}
permissions.interact = false
permissions.anyModel = false
permissions.anyObject = false
permissions.anyUrl = false
permissions.manage = false

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
RegisterNetEvent("pmms:loadPermissions")
RegisterNetEvent("pmms:loadSettings")
RegisterNetEvent("pmms:notify")
RegisterNetEvent("pmms:enableModel")
RegisterNetEvent("pmms:disableModel")
RegisterNetEvent("pmms:enableObject")
RegisterNetEvent("pmms:disableObject")
RegisterNetEvent("pmms:refreshPermissions")

local function notify(args)
	if type(args) ~= "table" then
		args = {}
	end

	if not args.title then
		args.title = GetCurrentResourceName()
	end

	if not args.duration then
		args.duration = Config.notificationDuration;
	end

	SendNUIMessage({
		type = "showNotification",
		args = args
	})
end

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
	local model = GetEntityModel(object)

	if not (permissions.anyModel or usableModels[model]) then
		return false
	end

	if not (permissions.anyObject or usableObjects[object]) then
		return false
	end

	return Config.models[model] ~= nil
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

local function getObjectLabel(handle, object)
	local defaultMediaPlayer = GetDefaultMediaPlayer(Config.defaultMediaPlayers, GetEntityCoords(object))

	if defaultMediaPlayer and defaultMediaPlayer.label then
		return defaultMediaPlayer.label
	else
		local model = GetEntityModel(object)

		if model and Config.models[model] then
			return Config.models[model].label
		else
			return tostring(handle)
		end
	end
end

local function getCoordsLabel(handle, coords)
	local defaultMediaPlayer = GetDefaultMediaPlayer(Config.defaultMediaPlayers, coords)

	if defaultMediaPlayer and defaultMediaPlayer.label then
		return defaultMediaPlayer.label
	else
		return tostring(handle)
	end
end

local function startMediaPlayer(handle, options)
	if not options.offset then
		options.offset = "0"
	end

	if NetworkDoesNetworkIdExist(handle) then
		local object = NetToObj(handle)

		options.model = GetEntityModel(object)
		options.renderTarget = Config.models[options.model].renderTarget
		options.label = getObjectLabel(handle, object)
	elseif DoesEntityExist(handle) then
		if not options.coords then
			options.coords = GetEntityCoords(handle)
		end

		options.model = GetEntityModel(handle)
		options.renderTarget = Config.models[options.model].renderTarget
		options.label = getObjectLabel(handle, handle)

		handle = false
	elseif options.coords then
		options.label = getCoordsLabel(handle, options.coords)

		handle = false
	end

	TriggerServerEvent("pmms:start", handle, options)
end

local function startClosestMediaPlayer(options)
	local mediaPlayer = getClosestMediaPlayer()

	if not mediaPlayer then
		if Config.showNotifications then
			notify{text = "No media player nearby"}
		end

		return
	end

	startMediaPlayer(getHandle(mediaPlayer), options)
end

local function pauseMediaPlayer(handle)
	TriggerServerEvent("pmms:pause", handle)
end

local function pauseClosestMediaPlayer()
	local mediaPlayer = getClosestMediaPlayer()

	if not mediaPlayer then
		if Config.showNotifications then
			notify{text = "No media player nearby"}
		end

		return
	end

	pauseMediaPlayer(findHandle(mediaPlayer))
end

local function stopMediaPlayer(handle)
	TriggerServerEvent("pmms:stop", handle)
end

local function stopClosestMediaPlayer()
	local mediaPlayer = getClosestMediaPlayer()

	if not mediaPlayer then
		if Config.showNotifications then
			notify{text = "No media player nearby"}
		end

		return
	end

	stopMediaPlayer(findHandle(mediaPlayer))
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
		notify{text = "No presets available"}
	else
		table.sort(presets)

		for _, preset in ipairs(presets) do
			TriggerEvent("chat:addMessage", {
				args = {preset, Config.presets[preset].title}
			})
		end
	end
end

local function updateUi()
	local pos = GetEntityCoords(PlayerPedId())

	local activeMediaPlayers = {}

	for handle, info in pairs(mediaPlayers) do
		local object
		local objectExists

		if info.coords then
			object = localMediaPlayers[handle]
		elseif NetworkDoesNetworkIdExist(handle) then
			object = NetToObj(handle)
		end

		local objectExists = object and DoesEntityExist(object)

		local mediaPos

		if objectExists then
			mediaPos = GetEntityCoords(object)
		elseif info.coords then
			mediaPos = info.coords
		end

		if mediaPos then
			local distance = #(pos - mediaPos)

			if permissions.manage or distance <= info.range then
				local label

				if info.label then
					label = info.label
				elseif objectExists then
					label = getObjectLabel(handle, object)
				else
					label = getCoordsLabel(handle, mediaPos)
				end

				local model

				if info.model then
					model = info.model
				elseif objectExists then
					model = GetEntityModel(object)
				end

				-- Can the user interact with this particular media player?
				local canInteract = permissions.manage or
					(permissions.interact and
						(permissions.anyModel or usableModels[model] ~= nil) and
						(not objectExists or (permissions.anyObject or usableObjects[object] ~= nil)))

				table.insert(activeMediaPlayers, {
					handle = handle,
					info = info,
					distance = distance,
					label = label,
					canInteract = canInteract
				})
			end
		else
			if permissions.manage then
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

				if permissions.manage or distance <= Config.maxDiscoveryDistance then
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
		maxDiscoveryDistance = Config.maxDiscoveryDistance,
		permissions = permissions,
		baseVolume = baseVolume
	})
end

local function createMediaPlayerObject(options, networked)
	local model = options.model or Config.defaultModel

	if not IsModelInCdimage(model) then
		print("Invalid model: " .. tostring(model))
		return
	end

	RequestModel(model)

	while not HasModelLoaded(model) do
		Citizen.Wait(0)
	end

	local object = CreateObjectNoOffset(model, options.position, networked, networked, false, false)

	SetModelAsNoLongerNeeded(model)

	if options.rotation then
		SetEntityRotation(object, options.rotation, 2)
	end

	if options.invisible then
		SetEntityVisible(object, false)
		SetEntityCollision(object, false, false)
	end

	return object
end

local function createDefaultMediaPlayer(mediaPlayer)
	mediaPlayer.handle = createMediaPlayerObject(mediaPlayer, false)
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

local function toggleStatus()
	SendNUIMessage({
		type = "toggleStatus"
	})
	statusIsShown = not statusIsShown
	SetResourceKvpInt("showStatus", statusIsShown and 1 or 0)
end

local function loadSettings()
	local volume = GetResourceKvpString("baseVolume")

	if volume then
		baseVolume = tonumber(volume)
	end

	local showStatus = GetResourceKvpInt("showStatus")

	if showStatus == 1 then
		toggleStatus()
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

local function getLocalMediaPlayer(coords, listenerPos, range)
	local handle = GetHandleFromCoords(coords)

	if not (localMediaPlayers[handle] and DoesEntityExist(localMediaPlayers[handle])) then
		localMediaPlayers[handle] = getClosestMediaPlayerObject(coords, 1.0, listenerPos, range)
	end

	return localMediaPlayers[handle]
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

			local mediaPos

			if object then
				mediaPos = GetEntityCoords(object)
			elseif mediaPlayers[handle] then
				mediaPos = mediaPlayers[handle].coords
				model = mediaPlayers[handle].model
				renderTarget = mediaPlayers[handle].renderTarget
			end

			if mediaPos and model then
				local ped, listenPos, viewerPos, viewerFov = getListenerAndViewerInfo()

				if #(viewerPos - mediaPos) < (data.range or Config.maxRange) then
					duiBrowser = DuiBrowser:new(handle, model, renderTarget)
				end
			end
		end

		if duiBrowser then
			duiBrowser:sendMessage(data)
		end
	end
end

local function getSvHandle(handle)
	if NetworkDoesNetworkIdExist(handle) then
		return handle
	elseif DoesEntityExist(handle) then
		return GetHandleFromCoords(GetEntityCoords(handle))
	end
end

local function enableModel(model)
	usableModels[model] = true
end

local function disableModel(model)
	usableModels[model] = nil
end

local function enableObject(object)
	usableObjects[object] = true
end

local function disableObject(object)
	usableObjects[object] = nil

	stopMediaPlayer(findHandle(object))
end

local function createMediaPlayer(options)
	local object = createMediaPlayerObject(options, true)

	personalMediaPlayers[object] = true
	enableObject(object)

	return object
end

local function deleteMediaPlayer(object)
	personalMediaPlayers[object] = nil

	disableObject(object)

	DeleteObject(object)
end

exports("enableModel", enableModel)
exports("disableModel", disableModel)
exports("enableObject", enableObject)
exports("disableObject", disableObject)
exports("createMediaPlayer", createMediaPlayer)
exports("deleteMediaPlayer", deleteMediaPlayer)

RegisterNUICallback("startup", function(data, cb)
	loadSettings()

	TriggerServerEvent("pmms:loadPermissions")
	TriggerServerEvent("pmms:loadSettings")

	cb {
		isRDR = Config.isRDR,
		defaultSameRoomAttenuation = Config.defaultSameRoomAttenuation,
		defaultDiffRoomAttenuation = Config.defaultDiffRoomAttenuation,
		defaultDiffRoomVolume = Config.defaultDiffRoomVolume,
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
	if NetworkDoesNetworkIdExist(data.handle) or data.options.coords then
		if data.options.coords then
			data.options.coords = ToVector3(data.options.coords)
		end

		TriggerServerEvent("pmms:init", data.handle, data.options)
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
	startMediaPlayer(data.handle, data.options)
	cb({})
end)

RegisterNUICallback("pause", function(data, cb)
	TriggerServerEvent("pmms:pause", data.handle)
	cb({})
end)

RegisterNUICallback("stop", function(data, cb)
	stopMediaPlayer(data.handle)
	cb({})
end)

RegisterNUICallback("closeUi", function(data, cb)
	SetNuiFocus(false, false)
	uiIsOpen = false
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
	local handle
	local object
	local coords

	if NetworkDoesNetworkIdExist(data.handle) then
		handle = data.handle
		object = NetToObj(data.handle)
		coords = GetEntityCoords(object)
	elseif DoesEntityExist(data.handle) then
		object = data.handle
		coords = GetEntityCoords(object)
		handle = GetHandleFromCoords(coords)
	end

	local defaults = GetDefaultMediaPlayer(Config.defaultMediaPlayers, coords) or Config.models[GetEntityModel(object)]

	local defaultsData = {}

	if defaults then
		for k, v in pairs(defaults) do
			defaultsData[k] = v
		end
	end

	local handle = getSvHandle(data.handle)

	if handle and mediaPlayers[handle] then
		defaultsData.volume = mediaPlayers[handle].volume
		defaultsData.attenuation = mediaPlayers[handle].attenuation
		defaultsData.diffRoomVolume = mediaPlayers[handle].diffRoomVolume
		defaultsData.range = mediaPlayers[handle].range
	end

	cb(defaultsData or {})
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

RegisterNUICallback("setVolume", function(data, cb)
	local handle = getSvHandle(data.handle)

	if handle and mediaPlayers[handle] then
		TriggerServerEvent("pmms:setVolume", handle, data.volume)
	end

	cb({})
end)

RegisterNUICallback("setAttenuation", function(data, cb)
	local handle = getSvHandle(data.handle)

	if handle and mediaPlayers[handle] then
		TriggerServerEvent("pmms:setAttenuation", handle, data.sameRoom, data.diffRoom)
	end

	cb({})
end)

RegisterNUICallback("setDiffRoomVolume", function(data, cb)
	local handle = getSvHandle(data.handle)

	if handle and mediaPlayers[handle] then
		TriggerServerEvent("pmms:setDiffRoomVolume", handle, data.diffRoomVolume)
	end

	cb({})
end)

RegisterNUICallback("setRange", function(data, cb)
	local handle = getSvHandle(data.handle)

	if handle and mediaPlayers[handle] then
		TriggerServerEvent("pmms:setRange", handle, data.range)
	end

	cb({})
end)

RegisterNUICallback("delete", function(data, cb)
	local object

	if NetworkDoesNetworkIdExist(data.handle) then
		object = NetToObj(data.handle)
	elseif DoesEntityExist(data.handle) then
		object = data.handle
	end

	if data.method == "server-model" then
		TriggerServerEvent("pmms:deleteModel", GetEntityModel(object))
	elseif data.method == "server-object" then
		TriggerServerEvent("pmms:deleteObject", GetEntityCoords(object))
	end

	cb({})
end)

AddEventHandler("pmms:sync", function(players)
	if syncIsEnabled then
		mediaPlayers = players

		if uiIsOpen or statusIsShown then
			updateUi()
		end
	end
end)

AddEventHandler("pmms:start", function(handle, options)
	sendMediaMessage(handle, options.coords, {
		type = "init",
		handle = handle,
		options = options
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
	toggleStatus()

	if Config.showNotifications then
		notify{text = "Status " .. (statusIsShown and "enabled" or "disabled"), duration = 1000}
	end
end)

AddEventHandler("pmms:error", function(message)
	print(message)

	if Config.showNotifications then
		notify{text = message}
	end
end)

AddEventHandler("pmms:init", function(handle, options)
	startMediaPlayer(handle, options)
end)

AddEventHandler("pmms:reset", function()
	print("Resetting...")

	if Config.showNotifications then
		notify{text = "Resetting..."}
	end

	syncIsEnabled = false

	SendNUIMessage({
		type = "reset"
	})

	mediaPlayers = {}
	localMediaPlayers = {}

	DuiBrowser:resetPool()

	syncIsEnabled = true
end)

AddEventHandler("pmms:startClosestMediaPlayer", function(options)
	startClosestMediaPlayer(options)
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
	notify{text = "Volume: " .. baseVolume}
end)

AddEventHandler("pmms:setBaseVolume", function(volume)
	setBaseVolume(volume)
end)

AddEventHandler("pmms:loadPermissions", function(perms)
	permissions = perms
end)

AddEventHandler("pmms:loadSettings", function(models, defaultMediaPlayers)
	Config.models = models

	-- Keep local object handles of default media players
	for _, dmp1 in ipairs(Config.defaultMediaPlayers) do
		if dmp1.handle then
			local dmp2 = GetDefaultMediaPlayer(defaultMediaPlayers, dmp1.position)

			if dmp2 then
				dmp2.handle = dmp1.handle
			end
		end
	end

	Config.defaultMediaPlayers = defaultMediaPlayers
end)

AddEventHandler("pmms:notify", function(data)
	notify(data)
end)

AddEventHandler("pmms:enableModel", enableModel)
AddEventHandler("pmms:disableModel", disableModel)
AddEventHandler("pmms:enableObject", enableObject)
AddEventHandler("pmms:disableObject", disableObject)

AddEventHandler("pmms:refreshPermissions", function()
	TriggerServerEvent("pmms:loadPermissions")
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

	for object, _ in pairs(personalMediaPlayers) do
		DeleteObject(object)
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
		{name = "volumeDiff", help = "Difference in volume between the same and different rooms. Default: " .. Config.defaultDiffRoomVolume},
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

	TriggerEvent("chat:addSuggestion", "/" .. Config.commandPrefix .. Config.commandSeparator .. "refresh_perms", "Refresh permissions for all clients.")
end)

Citizen.CreateThread(function()
	while true do
		local ped, listenPos, viewerPos, viewerFov = getListenerAndViewerInfo()

		local canWait = true
		local duiToDraw = {}

		for handle, info in pairs(mediaPlayers) do
			local object

			if info.coords then
				object = localMediaPlayers[handle]
			elseif NetworkDoesNetworkIdExist(handle) then
				object = NetToObj(handle)
			end

			local data

			local objectExists = object and DoesEntityExist(object)

			local mediaPos

			if objectExists then
				mediaPos = GetEntityCoords(object)
			elseif info.coords then
				mediaPos = info.coords
			end

			if mediaPos then
				local distance = #(listenPos - mediaPos)

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
					options = info,
					volume = math.floor(info.volume * (baseVolume / 100)),
					distance = distance,
					sameRoom = objectExists and isInSameRoom(ped, object),
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
				data = {
					type = "update",
					handle = handle,
					options = info,
					volume = 0,
					distance = -1,
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

		for handle, info in pairs(mediaPlayers) do
			if info.coords then
				getLocalMediaPlayer(info.coords, myPos, info.range)
			end
		end

		for _, mediaPlayer in ipairs(Config.defaultMediaPlayers) do
			if mediaPlayer.spawn then
				local nearby = #(myPos - mediaPlayer.position) <= Config.defaultMediaPlayerSpawnDistance

				if mediaPlayer.handle and not DoesEntityExist(mediaPlayer.handle) then
					mediaPlayer.handle = nil
				end

				if nearby and not mediaPlayer.handle then
					createDefaultMediaPlayer(mediaPlayer)
				elseif not nearby and mediaPlayer.handle then
					DeleteObject(mediaPlayer.handle)
				end
			end
		end

		Citizen.Wait(1000)
	end
end)
