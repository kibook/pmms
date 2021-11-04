local mediaPlayers = {}
local restrictedHandles = {}
local syncQueue = {}

RegisterNetEvent("pmms:start")
RegisterNetEvent("pmms:init")
RegisterNetEvent("pmms:pause")
RegisterNetEvent("pmms:stop")
RegisterNetEvent("pmms:showControls")
RegisterNetEvent("pmms:toggleStatus")
RegisterNetEvent("pmms:setVolume")
RegisterNetEvent("pmms:setAttenuation")
RegisterNetEvent("pmms:setDiffRoomVolume")
RegisterNetEvent("pmms:setRange")
RegisterNetEvent("pmms:setIsVehicle")
RegisterNetEvent("pmms:setScaleform")
RegisterNetEvent("pmms:setStartTime")
RegisterNetEvent("pmms:lock")
RegisterNetEvent("pmms:unlock")
RegisterNetEvent("pmms:enableVideo")
RegisterNetEvent("pmms:disableVideo")
RegisterNetEvent("pmms:setVideoSize")
RegisterNetEvent("pmms:mute")
RegisterNetEvent("pmms:unmute")
RegisterNetEvent("pmms:copy")
RegisterNetEvent("pmms:setLoop")
RegisterNetEvent("pmms:next")
RegisterNetEvent("pmms:removeFromQueue")
RegisterNetEvent("pmms:saveModel")
RegisterNetEvent("pmms:saveEntity")
RegisterNetEvent("pmms:deleteModel")
RegisterNetEvent("pmms:deleteEntity")
RegisterNetEvent("pmms:loadPermissions")
RegisterNetEvent("pmms:loadSettings")

local function enqueue(queue, cb)
	table.insert(queue, 1, cb)
end

local function dequeue(queue)
	local cb = table.remove(queue)

	if cb then
		cb()
	end
end

local function addToQueue(handle, source, options)
	table.insert(mediaPlayers[handle].queue, {
		source = source,
		name = GetPlayerName(source),
		options = options
	})
end

local function removeFromQueue(handle, index)
	table.remove(mediaPlayers[handle].queue, index)
end

local function isUrlAllowed(url)
	for _, pattern in ipairs(Config.allowedUrls) do
		if url:match(pattern) then
			return true
		end
	end

	return false
end

local function addMediaPlayer(handle, options)
	if mediaPlayers[handle] then
		return
	end

	if not options.title then
		options.title = options.url
	end

	options.volume = Clamp(options.volume, 0, 100, 100)
	options.startTime = os.time() - (options.offset or 0)
	options.offset = 0
	options.videoSize = Clamp(options.videoSize, 10, 100, Config.defaultVideoSize)
	options.paused = false

	if options.filter == nil then
		options.filter = Config.enableFilterByDefault
	end

	if options.attenuation then
		options.attenuation.sameRoom = Clamp(options.attenuation.sameRoom, 0.0, 10.0, Config.defaultSameRoomAttenuation)
		options.attenuation.diffRoom = Clamp(options.attenuation.diffRoom, 0.0, 10.0, Config.defaultDiffRoomAttenuation)
	else
		options.attenuation = {
			sameRoom = Config.defaultSameRoomAttenuation,
			diffRoom = Config.defaultDiffRoomAttenuation
		}
	end

	options.diffRoomVolume = Clamp(options.diffRoomVolume, 0.0, 1.0, Config.defaultDiffRoomVolume)

	options.range = Clamp(options.range, 0, Config.maxRange, Config.defaultRange)

	if options.scaleform then
		options.scaleform.position = ToVector3(options.scaleform.position)
		options.scaleform.rotation = ToVector3(options.scaleform.rotation)
		options.scaleform.scale = ToVector3(options.scaleform.scale)

		if not options.label then
			options.label = "Scaleform"
		end
	end

	if not options.queue then
		options.queue = {}
	end

	mediaPlayers[handle] = options

	enqueue(syncQueue, function()
		TriggerClientEvent("pmms:play", -1, handle)
	end)
end

local function removeMediaPlayer(handle)
	mediaPlayers[handle] = nil

	enqueue(syncQueue, function()
		TriggerClientEvent("pmms:stop", -1, handle)
	end)
end

local function playNextInQueue(handle)
	local mediaPlayer = mediaPlayers[handle]

	removeMediaPlayer(handle)

	while #mediaPlayer.queue > 0 do
		local next = table.remove(mediaPlayer.queue, 1)

		local client

		if GetPlayerName(next.source) == next.name then
			client = next.source
		else
			client = GetPlayers()[1]
		end

		if client then
			restrictedHandles[handle] = client

			local options = {}

			-- Copy properties of the current media player
			for k, v in pairs(mediaPlayer) do
				options[k] = v
			end

			-- Override these options with what the user specified
			options.url = next.options.url
			options.volume = next.options.volume
			options.offset = next.options.offset
			options.filter = next.options.filter
			options.video = next.options.video
			options.visualization = next.options.visualization

			enqueue(syncQueue, function()
				TriggerClientEvent("pmms:init", client, handle, options)
			end)

			break
		end
	end
end

local function pauseMediaPlayer(handle)
	if not mediaPlayers[handle] then
		return
	end

	if mediaPlayers[handle].paused then
		mediaPlayers[handle].startTime = mediaPlayers[handle].startTime + (os.time() - mediaPlayers[handle].paused)
		mediaPlayers[handle].paused = false
	else
		mediaPlayers[handle].paused = os.time()
	end
end

local function getRandomPreset()
	local presets = {}

	for preset, info in pairs(Config.presets) do
		table.insert(presets, preset)
	end

	return #presets > 0 and presets[math.random(#presets)] or ""
end

local function resolvePreset(url, title, filter, video)
	if url == "random" then
		url = getRandomPreset()
	end

	if Config.presets[url] then
		return Config.presets[url]
	else
		return {
			url = url,
			title = title,
			filter = filter,
			video = video
		}
	end
end

local function startMediaPlayerByNetworkId(netId, options)
	local resolved = resolvePreset(options.url, options.title, options.filter, options.video)

	options.url = resolved.url
	options.title = resolved.title
	options.filter = resolved.filter
	options.video = resolved.video
	options.queue = nil
	options.coords = nil

	addMediaPlayer(netId, options)

	return netId
end

local function startMediaPlayerByCoords(x, y, z, options)
	local coords = vector3(x, y, z)
	local handle = GetHandleFromCoords(coords)

	local resolved = resolvePreset(options.url, options.title, options.filter, options.video)

	options.url = resolved.url
	options.title = resolved.title
	options.filter = resolved.filter
	options.video = resolved.video
	options.queue = nil
	options.coords = coords

	addMediaPlayer(handle, options)

	return handle
end

local function startMediaPlayerScaleform(scaleform, options)
	options.scaleform = scaleform
	options.scaleform.standalone = true
	return startMediaPlayerByCoords(scaleform.position.x, scaleform.position.y, scaleform.position.z, options)
end

local function errorMessage(player, message)
	TriggerClientEvent("pmms:error", player, message)
end

local function startDefaultMediaPlayers()
	for _, mediaPlayer in ipairs(Config.defaultMediaPlayers) do
		if mediaPlayer.url then
			startMediaPlayerByCoords(
				mediaPlayer.position.x,
				mediaPlayer.position.y,
				mediaPlayer.position.z,
				mediaPlayer)
		end
	end
end

local function resetPlaytime(handle)
	mediaPlayers[handle].offset = 0
	mediaPlayers[handle].startTime = os.time()
end

local function syncMediaPlayers()
	for handle, info in pairs(mediaPlayers) do
		if not info.paused then
			info.offset = os.time() - info.startTime

			if info.duration and info.offset >= info.duration then
				if info.loop then
					resetPlaytime(handle)
				elseif #info.queue > 0 then
					playNextInQueue(handle)
				else
					removeMediaPlayer(handle)
				end
			end
		end
	end

	TriggerClientEvent("pmms:sync", -1, mediaPlayers)

	dequeue(syncQueue)
end

local function isLockedDefaultMediaPlayer(handle)
	for _, mediaPlayer in ipairs(Config.defaultMediaPlayers) do
		if handle == GetHandleFromCoords(mediaPlayer.position) and mediaPlayer.locked then
			return true
		end
	end

	return false
end

local function lockMediaPlayer(handle)
	mediaPlayers[handle].locked = true
end

local function unlockMediaPlayer(handle)
	mediaPlayers[handle].locked = false
end

local function muteMediaPlayer(handle)
	mediaPlayers[handle].muted = true
end

local function unmuteMediaPlayer(handle)
	mediaPlayers[handle].muted = false
end

local function copyMediaPlayer(oldHandle, newHandle, newCoords)
	local options = {}

	for k, v in pairs(mediaPlayers[oldHandle]) do
		options[k] = v
	end

	options.label = nil
	options.model = nil
	options.renderTarget = nil

	if newHandle then
		startMediaPlayerByNetworkId(newHandle, options)
	elseif newCoords then
		startMediaPlayerByCoords(newCoords.x, newCoords.y, newCoords.z, options)
	end
end

local function setMediaPlayerLoop(handle, loop)
	mediaPlayers[handle].loop = loop
end

local function syncSettings()
	TriggerClientEvent("pmms:loadSettings", -1, Config.models, Config.defaultMediaPlayers)
end

local function loadSettings()
	local models = json.decode(LoadResourceFile(GetCurrentResourceName(), "models.json"))

	if models then
		for key, info in pairs(models) do
			local model = tonumber(key)
			if Config.models[model] then
				Config.models[model].renderTarget = info.renderTarget
				Config.models[model].label = info.label
				Config.models[model].filter = info.filter
				Config.models[model].volume = info.volume
				Config.models[model].attenuation = info.attenuation
				Config.models[model].diffRoomVolume = info.diffRoomVolume
				Config.models[model].range = info.range
				Config.models[model].isVehicle = info.isVehicle
				Config.models[model].scaleform = info.scaleform
			else
				Config.models[model] = info
			end
		end
	end

	local defaultMediaPlayers = json.decode(LoadResourceFile(GetCurrentResourceName(), "defaultMediaPlayers.json"))

	if defaultMediaPlayers then
		for _, defaultMediaPlayer in ipairs(defaultMediaPlayers) do
			defaultMediaPlayer.position = ToVector3(defaultMediaPlayer.position)

			if defaultMediaPlayer.scaleform then
				defaultMediaPlayer.scaleform.position = ToVector3(defaultMediaPlayer.scaleform.position)
				defaultMediaPlayer.scaleform.rotation = ToVector3(defaultMediaPlayer.scaleform.rotation)
				defaultMediaPlayer.scaleform.scale = ToVector3(defaultMediaPlayer.scaleform.scale)
			end

			local dmp = GetDefaultMediaPlayer(Config.defaultMediaPlayers, defaultMediaPlayer.position)

			if dmp then
				dmp.label = defaultMediaPlayer.label
				dmp.filter = defaultMediaPlayer.filter
				dmp.volume = defaultMediaPlayer.volume
				dmp.attenuation = defaultMediaPlayer.attenuation
				dmp.diffRoomVolume = defaultMediaPlayer.diffRoomVolume
				dmp.range = defaultMediaPlayer.range
				dmp.isVehicle = defaultMediaPlayer.isVehicle
				dmp.scaleform = defaultMediaPlayer.scaleform
			else
				table.insert(Config.defaultMediaPlayers, defaultMediaPlayer)
			end
		end
	end

	syncSettings()
end

local function addModel(model, data)
	if Config.models[model] then
		if not data.renderTarget then
			data.renderTarget = Config.models[model].renderTarget
		else
			Config.models[model].renderTarget = data.renderTarget
		end
		if not data.label then
			data.label = Config.models[model].label
		else
			Config.models[model].label = data.label
		end
		Config.models[model].filter = data.filter
		Config.models[model].volume = data.volume
		Config.models[model].attenuation = data.attenuation
		Config.models[model].diffRoomVolume = data.diffRoomVolume
		Config.models[model].range = data.range
		Config.models[model].isVehicle = data.isVehicle
		Config.models[model].scaleform = data.scaleform
	else
		Config.models[model] = data
	end

	syncSettings()
end

local function addModelPermanently(model, data)
	data.handle = nil
	data.method = nil
	data.model = nil

	if data.renderTarget == "" then
		data.renderTarget = nil
	end

	if data.label == "" then
		data.label = nil
	end

	addModel(model, data)

	local models = json.decode(LoadResourceFile(GetCurrentResourceName(), "models.json"))

	if not models then
		models = {}
	end

	models[tostring(model)] = data

	SaveResourceFile(GetCurrentResourceName(), "models.json", json.encode(models), -1)
end

local function addEntity(coords, data)
	local defaultMediaPlayer = GetDefaultMediaPlayer(Config.defaultMediaPlayers, coords)

	if defaultMediaPlayer then
		if data.label == "" then
			data.label = defaultMediaPlayer.label
		else
			defaultMediaPlayer.label = data.label
		end
		defaultMediaPlayer.filter = data.filter
		defaultMediaPlayer.volume = data.volume
		defaultMediaPlayer.attenuation = data.attenuation
		defaultMediaPlayer.diffRoomVolume = data.diffRoomVolume
		defaultMediaPlayer.range = data.range
		defaultMediaPlayer.isVehicle = data.isVehicle
		defaultMediaPlayer.scaleform = data.scaleform
	else
		table.insert(Config.defaultMediaPlayers, data)
	end

	syncSettings()
end

local function addEntityPermanently(coords, data)
	data.handle = nil
	data.method = nil
	data.position = coords

	addEntity(coords, data)

	local defaultMediaPlayers = json.decode(LoadResourceFile(GetCurrentResourceName(), "defaultMediaPlayers.json"))

	if not defaultMediaPlayers then
		defaultMediaPlayers = {}
	end

	for _, defaultMediaPlayer in ipairs(defaultMediaPlayers) do
		defaultMediaPlayer.position = ToVector3(defaultMediaPlayer.position)

		if defaultMediaPlayer.scaleform then
			defaultMediaPlayer.scaleform.position = ToVector3(defaultMediaPlayer.scaleform.position)
			defaultMediaPlayer.scaleform.rotation = ToVector3(defaultMediaPlayer.scaleform.rotation)
			defaultMediaPlayer.scaleform.scale = ToVector3(defaultMediaPlayer.scaleform.scale)
		end
	end

	defaultMediaPlayer = GetDefaultMediaPlayer(defaultMediaPlayers, coords)

	if defaultMediaPlayer then
		defaultMediaPlayer.label = data.label
		defaultMediaPlayer.filter = data.filter
		defaultMediaPlayer.volume = data.volume
		defaultMediaPlayer.attenuation = data.attenuation
		defaultMediaPlayer.diffRoomVolume = data.diffRoomVolume
		defaultMediaPlayer.range = data.range
		defaultMediaPlayer.isVehicle = data.isVehicle
		defaultMediaPlayer.scaleform = data.scaleform
	else
		table.insert(defaultMediaPlayers, data)
	end

	SaveResourceFile(GetCurrentResourceName(), "defaultMediaPlayers.json", json.encode(defaultMediaPlayers), -1)
end

local function removeModel(model)
	if not Config.models[model] then
		return
	end

	local data = Config.models[model]

	Config.models[model] = nil

	syncSettings()

	return data
end

local function removeModelPermanently(model)
	local data = removeModel(model)

	local models = json.decode(LoadResourceFile(GetCurrentResourceName(), "models.json"))

	if models then
		models[tostring(model)] = nil

		SaveResourceFile(GetCurrentResourceName(), "models.json", json.encode(models), -1)
	end

	return data
end

local function removeEntity(coords)
	local data

	for i = 1, #Config.defaultMediaPlayers do
		if IsSameEntity(coords, Config.defaultMediaPlayers[i].position) then
			data = table.remove(Config.defaultMediaPlayers, i)
			break
		end
	end

	syncSettings()

	return data
end

local function removeEntityPermanently(coords)
	local data = removeEntity(coords)

	local defaultMediaPlayers = json.decode(LoadResourceFile(GetCurrentResourceName(), "defaultMediaPlayers.json"))

	if defaultMediaPlayers then
		for i = 1, #defaultMediaPlayers do
			local position = ToVector3(defaultMediaPlayers[i].position)
			if IsSameEntity(coords, position) then
				table.remove(defaultMediaPlayers, i)
				break
			end
		end

		SaveResourceFile(GetCurrentResourceName(), "defaultMediaPlayers.json", json.encode(defaultMediaPlayers), -1)
	end

	return data
end

local function getMediaPlayerInfo(handle)
	return mediaPlayers[handle]
end

local function getAllMediaPlayers()
	return mediaPlayers
end

exports("startByNetworkId", startMediaPlayerByNetworkId)
exports("startByCoords", startMediaPlayerByCoords)
exports("startScaleform", startMediaPlayerScaleform)
exports("stop", removeMediaPlayer)
exports("pause", pauseMediaPlayer)
exports("lock", lockMediaPlayer)
exports("unlock", unlockMediaPlayer)
exports("mute", muteMediaPlayer)
exports("unmute", unmuteMediaPlayer)
exports("addModel", addModel)
exports("addModelPermanently", addModelPermanently)
exports("addEntity", addEntity)
exports("addEntityPermanently", addEntityPermanently)
exports("removeModel", removeModel)
exports("removeModelPermanently", removeModelPermanently)
exports("removeEntity", removeEntity)
exports("removeEntityPermanently", removeEntityPermanently)
exports("getMediaPlayerInfo", getMediaPlayerInfo)
exports("getAllMediaPlayers", getAllMediaPlayers)

AddEventHandler("pmms:start", function(handle, options)
	if not (options and options.url) then
		errorMessage(source, "You must specify a URL to play.")
		return
	end

	if options.coords then
		handle = GetHandleFromCoords(options.coords)
	end

	if restrictedHandles[handle] then
		if restrictedHandles[handle] ~= source then
			errorMessage(source, "This player is busy")
			return
		end

		restrictedHandles[handle] = nil
	end

	if mediaPlayers[handle] then
		addToQueue(handle, source, options)
	else
		if not IsPlayerAceAllowed(source, "pmms.interact") then
			errorMessage(source, "You do not have permission to play a song on a media player")
			return
		end

		if (locked or isLockedDefaultMediaPlayer(handle)) and not IsPlayerAceAllowed(source, "pmms.manage") then
			errorMessage(source, "You do not have permission to play a song on a locked media player")
			return
		end

		if options.url == "random" then
			options.url = getRandomPreset()
		end

		if Config.presets[options.url] then
			options.title  = Config.presets[options.url].title
			options.filter = Config.presets[options.url].filter or false
			options.video  = Config.presets[options.url].video or options.visualization ~= nil
			options.url    = Config.presets[options.url].url

			TriggerClientEvent("pmms:start", source, handle, options)
		elseif IsPlayerAceAllowed(source, "pmms.customUrl") then
			if IsPlayerAceAllowed(source, "pmms.anyUrl") or isUrlAllowed(options.url) then
				options.title = false

				TriggerClientEvent("pmms:start", source, handle, options)
			else
				errorMessage(source, "You do not have permission to play the specified URL")
			end
		else
			errorMessage(source, "You must select from one of the pre-defined songs (" .. Config.commandPrefix .. Config.commandSeparator .. "presets)")
		end
	end
end)

AddEventHandler("pmms:init", function(handle, options)
	if mediaPlayers[handle] then
		return
	end

	if not IsPlayerAceAllowed(source, "pmms.interact") then
		errorMessage(source, "You do not have permission to play a song on a media player")
		return
	end

	if (locked or isLockedDefaultMediaPlayer(handle)) and not IsPlayerAceAllowed(source, "pmms.manage") then
		errorMessage(source, "You do not have permission to play a song on a locked media players")
		return
	end

	addMediaPlayer(handle, options)
end)

AddEventHandler("pmms:pause", function(handle)
	if not mediaPlayers[handle] then
		return
	end

	if not mediaPlayers[handle].duration then
		errorMessage(source, "You cannot pause live streams.")
		return
	end

	if not IsPlayerAceAllowed(source, "pmms.interact") then
		errorMessage(source, "You do not have permission to pause or resume media players")
		return
	end

	if mediaPlayers[handle].locked and not IsPlayerAceAllowed(source, "pmms.manage") then
		errorMessage(source, "You do not have permission to pause or resume locked media players")
		return
	end

	pauseMediaPlayer(handle)
end)

AddEventHandler("pmms:stop", function(handle)
	if not mediaPlayers[handle] then
		return
	end

	if not IsPlayerAceAllowed(source, "pmms.interact") then
		errorMessage(source, "You do not have permission to stop media players")
		return
	end

	if mediaPlayers[handle].locked and not IsPlayerAceAllowed(source, "pmms.manage") then
		errorMessage(source, "You do not have permission to stop locked media players")
		return
	end

	removeMediaPlayer(handle)
end)

AddEventHandler("pmms:showControls", function()
	TriggerClientEvent("pmms:showControls", source)
end)

AddEventHandler("pmms:toggleStatus", function()
	TriggerClientEvent("pmms:toggleStatus", source)
end)

AddEventHandler("pmms:setVolume", function(handle, volume)
	if not mediaPlayers[handle] then
		return
	end

	if not IsPlayerAceAllowed(source, "pmms.interact") then
		errorMessage(source, "You do not have permission to change the volume of media players")
		return
	end

	if mediaPlayers[handle].locked and not IsPlayerAceAllowed(source, "pmms.manage") then
		errorMessage(source, "You do not have permission to change the volume of locked media players")
		return
	end

	mediaPlayers[handle].volume = Clamp(volume, 0, 100, 100)
end)

AddEventHandler("pmms:setAttenuation", function(handle, sameRoom, diffRoom)
	if not mediaPlayers[handle] then
		return
	end

	if not IsPlayerAceAllowed(source, "pmms.interact") then
		errorMessage(source, "You do not have permission to change the attenuation of media players")
		return
	end

	if mediaPlayers[handle].locked and not IsPlayerAceAllowed(source, "pmms.manage") then
		errorMessage(source, "You do not have permission to change the attenuation of locked media players")
		return
	end

	mediaPlayers[handle].attenuation = {
		sameRoom = Clamp(sameRoom, 0.0, 10.0, Config.defaultSameRoomAttenuation),
		diffRoom = Clamp(diffRoom, 0.0, 10.0, Config.defaultDiffRoomAttenuation)
	}
end)

AddEventHandler("pmms:setDiffRoomVolume", function(handle, diffRoomVolume)
	if not mediaPlayers[handle] then
		return
	end

	if not IsPlayerAceAllowed(source, "pmms.interact") then
		errorMessage(source, "You do not have permission to change the volume of media players")
		return
	end

	if mediaPlayers[handle].locked and not IsPlayerAceAllowed(source, "pmms.manage") then
		errorMessage(source, "You do not have permission to change the volume of locked media players")
		return
	end

	mediaPlayers[handle].diffRoomVolume = Clamp(diffRoomVolume, 0.0, 1.0, Config.defaultDiffRoomVolume)
end)

AddEventHandler("pmms:setRange", function(handle, range)
	if not mediaPlayers[handle] then
		return
	end

	if not IsPlayerAceAllowed(source, "pmms.interact") then
		errorMessage(source, "You do not have permission to change the range of media players")
		return
	end

	if mediaPlayers[handle].locked and not IsPlayerAceAllowed(source, "pmms.manage") then
		errorMessage(source, "You do not have permission to change the range of locked media players")
		return
	end

	mediaPlayers[handle].range = Clamp(range, 0.0, Config.maxRange, Config.defaultRange)
end)

AddEventHandler("pmms:setIsVehicle", function(handle, isVehicle)
	if not mediaPlayers[handle] then
		return
	end

	if not IsPlayerAceAllowed(source, "pmms.interact") then
		errorMessage(source, "You do not have permission to change the vehicle setting of media players")
		return
	end

	if mediaPlayers[handle].locked and not IsPlayerAceAllowed(source, "pmms.manage") then
		errorMessage(source, "You do not have permission to change the vehicle setting of locked media players")
		return
	end

	mediaPlayers[handle].isVehicle = isVehicle
end)

AddEventHandler("pmms:setScaleform", function(handle, scaleform)
	if not mediaPlayers[handle] then
		return
	end

	if not IsPlayerAceAllowed(source, "pmms.interact") then
		errorMessage(source, "You do not have permission to change scaleform settings of media players")
		return
	end

	if mediaPlayers[handle].locked and not IsPlayerAceAllowed(source, "pmms.manage") then
		errorMessage(source, "You do not have permission to change scaleform settings of locked media players")
		return
	end

	if mediaPlayers[handle].scaleform.standalone then
		scaleform.standalone = true
		mediaPlayers[handle].scaleform = scaleform
		mediaPlayers[handle].coords = scaleform.position
	else
		mediaPlayers[handle].scaleform = scaleform
	end
end)

AddEventHandler("pmms:setStartTime", function(handle, time)
	if not mediaPlayers[handle] then
		return
	end

	if not mediaPlayers[handle].duration then
		errorMessage(source, "You cannot seek on live streams")
		return
	end

	if not IsPlayerAceAllowed(source, "pmms.interact") then
		errorMessage(source, "You do not have permission to seek on media players")
		return
	end

	if mediaPlayers[handle].locked and not IsPlayerAceAllowed(source, "pmms.manage") then
		errorMessage(source, "You do not have permission to seek on locked media players")
		return
	end

	mediaPlayers[handle].startTime = time
end)

AddEventHandler("pmms:lock", function(handle)
	if not mediaPlayers[handle] then
		return
	end

	if not IsPlayerAceAllowed(source, "pmms.manage") then
		errorMessage(source, "You do not have permission to lock a media player")
		return
	end

	lockMediaPlayer(handle)
end)

AddEventHandler("pmms:unlock", function(handle)
	if not mediaPlayers[handle] then
		return
	end

	if not IsPlayerAceAllowed(source, "pmms.manage") then
		errorMessage(source, "You do not have permission to unlock a media player")
		return
	end

	unlockMediaPlayer(handle)
end)

AddEventHandler("pmms:enableVideo", function(handle)
	if not mediaPlayers[handle] then
		return
	end

	if not IsPlayerAceAllowed(source, "pmms.interact") then
		errorMessage(source, "You do not have permission to enable video on media players")
		return
	end

	if mediaPlayers[handle].locked and not IsPlayerAceAllowed(source, "pmms.manage") then
		errorMessage(source, "You do not have permission to enable video on locked media players")
		return
	end

	mediaPlayers[handle].video = true
end)

AddEventHandler("pmms:disableVideo", function(handle)
	if not mediaPlayers[handle] then
		return
	end

	if not IsPlayerAceAllowed(source, "pmms.interact") then
		errorMessage(source, "You do not have permission to disable video on media players")
		return
	end

	if mediaPlayers[handle].locked and not IsPlayerAceAllowed(source, "pmms.manage") then
		errorMessage(source, "You do not have permission to disable video on locked media players")
		return
	end

	mediaPlayers[handle].video = false
end)

AddEventHandler("pmms:setVideoSize", function(handle, size)
	if not mediaPlayers[handle] then
		return
	end

	if not IsPlayerAceAllowed(source, "pmms.interact") then
		errorMessage(source, "You do not have permission to change video size on media players")
		return
	end

	if mediaPlayers[handle].locked and not IsPlayerAceAllowed(source, "pmms.manage") then
		errorMessage(source, "You do not have permission to change video size on locked media players")
		return
	end

	mediaPlayers[handle].videoSize = Clamp(size, 10, 100, Config.defaultVideoSize)
end)

AddEventHandler("pmms:mute", function(handle)
	if not mediaPlayers[handle] then
		return
	end

	if not IsPlayerAceAllowed(source, "pmms.interact") then
		errorMessage(source, "You do not have permission to mute media players")
		return
	end

	if mediaPlayers[handle].locked and not IsPlayerAceAllowed(source, "pmms.manage") then
		errorMessage(source, "You do not have permission to mute locked media players")
		return
	end

	muteMediaPlayer(handle)
end)

AddEventHandler("pmms:unmute", function(handle)
	if not mediaPlayers[handle] then
		return
	end

	if not IsPlayerAceAllowed(source, "pmms.interact") then
		errorMessage(source, "You do not have permission to mute media players")
		return
	end

	if mediaPlayers[handle].locked and not IsPlayerAceAllowed(source, "pmms.manage") then
		errorMessage(source, "You do not have permission to mute locked media players")
		return
	end

	unmuteMediaPlayer(handle)
end)

AddEventHandler("pmms:copy", function(oldHandle, newHandle, newCoords)
	if not mediaPlayers[oldHandle] then
		return
	end

	if not IsPlayerAceAllowed(source, "pmms.interact") then
		errorMessage(source, "You do not have permission to copy media players")
		return
	end

	if mediaPlayers[oldHandle].locked and not IsPlayerAceAllowed(source, "pmms.manage") then
		errorMessage(source, "You do not have permission to copy locked media players")
		return
	end

	copyMediaPlayer(oldHandle, newHandle, newCoords)
end)

AddEventHandler("pmms:setLoop", function(handle, loop)
	if not mediaPlayers[handle] then
		return
	end

	if not IsPlayerAceAllowed(source, "pmms.interact") then
		errorMessage(source, "You do not have permission to change loop settings on media players")
		return
	end

	if mediaPlayers[handle].locked and not IsPlayerAceAllowed(source, "pmms.manage") then
		errorMessage(source, "You do not have permission to change loop settings on locked media players")
		return
	end

	setMediaPlayerLoop(handle, loop)
end)

AddEventHandler("pmms:next", function(handle)
	if not mediaPlayers[handle] then
		return
	end

	if not IsPlayerAceAllowed(source, "pmms.interact") then
		errorMessage(source, "You do not have permission to skip forward on media players")
		return
	end

	if mediaPlayers[handle].locked and not IsPlayerAceAllowed(source, "pmms.manage") then
		errorMessage(source, "You do not have permission to skip forward on locked media players")
		return
	end

	playNextInQueue(handle)
end)

AddEventHandler("pmms:removeFromQueue", function(handle, id)
	if not mediaPlayers[handle] then
		return
	end

	if not IsPlayerAceAllowed(source, "pmms.interact") then
		errorMessage(source, "You do not have permission to remove an item from the queue of media players")
		return
	end

	if mediaPlayers[handle].locked and not IsPlayerAceAllowed(source, "pmms.manage") then
		errorMessage(source, "You do not have permission to remove an item from the queue of locked media players")
		return
	end

	removeFromQueue(handle, id)
end)

AddEventHandler("pmms:saveModel", function(model, data)
	if not IsPlayerAceAllowed(source, "pmms.manage") then
		errorMessage(source, "You do not have permission to save model defaults to the server")
		return
	end

	addModelPermanently(model, data)

	TriggerClientEvent("pmms:notify", source, {text = "Model \"" .. data.label .. "\" saved"})
end)

AddEventHandler("pmms:saveEntity", function(coords, data)
	if not IsPlayerAceAllowed(source, "pmms.manage") then
		errorMessage(source, "You do not have permission to save entity defaults to the server")
		return
	end

	addEntityPermanently(coords, data)

	TriggerClientEvent("pmms:notify", source, {text = "Entity \"" .. data.label .. "\" saved"})
end)

AddEventHandler("pmms:deleteModel", function(model)
	if not IsPlayerAceAllowed(source, "pmms.manage") then
		errorMessage(source, "You do not have permission to delete model defaults from the server")
		return
	end

	local data = removeModelPermanently(model)

	if data then
		if data.label then
			TriggerClientEvent("pmms:notify", source, {text = "Model \"" .. data.label .. "\" deleted"})
		else
			TriggerClientEvent("pmms:notify", source, {text = "Model deleted"})
		end
	end
end)

AddEventHandler("pmms:deleteEntity", function(coords)
	if not IsPlayerAceAllowed(source, "pmms.manage") then
		errorMessage(source, "You do not have permission to delete entity defaults from the server")
		return
	end

	local data = removeEntityPermanently(coords)

	if data then
		if data.label then
			TriggerClientEvent("pmms:notify", source, {text = "Entity \"" .. data.label .. "\" deleted"})
		else
			TriggerClientEvent("pmms:notify", source, {text = "Entity deleted"})
		end
	end
end)

AddEventHandler("pmms:loadSettings", function()
	TriggerClientEvent("pmms:loadSettings", source, Config.models, Config.defaultMediaPlayers)
end)

AddEventHandler("pmms:loadPermissions", function()
	local permissions = {}

	permissions.interact  = IsPlayerAceAllowed(source, "pmms.interact")
	permissions.anyEntity = IsPlayerAceAllowed(source, "pmms.anyEntity")
	permissions.customUrl = IsPlayerAceAllowed(source, "pmms.customUrl")
	permissions.anyUrl    = IsPlayerAceAllowed(source, "pmms.anyUrl")
	permissions.manage    = IsPlayerAceAllowed(source, "pmms.manage")

	TriggerClientEvent("pmms:loadPermissions", source, permissions)
end)

RegisterCommand(Config.commandPrefix, function(source, args, raw)
	TriggerClientEvent("pmms:showControls", source)
end, true)

local function parseOptions(args, requiredArguments, fn)
	local i = 1

	while i <= #args do
		local option
		local argument

		if args[i]:sub(1, 1) == "-" then
			option = args[i]:sub(2)

			if requiredArguments[option] then
				argument = args[i + 1]
				i = i + 1
			end
		else
			argument = args[i]
		end

		fn(option, argument)

		i = i + 1
	end
end

RegisterCommand(Config.commandPrefix .. Config.commandSeparator .. "play", function(source, args, raw)
	if #args > 0 then
		local options = {}

		local requiredArguments = {
			["offset"] = true,
			["size"] = true,
			["sra"] = true,
			["dra"] = true,
			["drv"] = true,
			["range"] = true,
			["visualization"] = true,
			["volume"] = true
		}

		parseOptions(args, requiredArguments, function(option, argument)
			if option == "filter" then
				options.filter = true
			elseif option == "nofilter" then
				options.filter = false
			elseif option == "loop" then
				options.loop = true
			elseif option == "offset" then
				options.offset = argument
			elseif option == "lock" then
				options.locked = true
			elseif option == "video" then
				options.video = true
			elseif option == "size" then
				options.videoSize = tonumber(argument)
			elseif option == "mute" then
				options.muted = true
			elseif option == "sra" then
				if not options.attenuation then
					options.attenuation = {}
				end
				options.attenuation.sameRoom = tonumber(argument)
			elseif option == "dra" then
				if not options.attenuation then
					options.attenuation = {}
				end
				options.attenuation.diffRoom = tonumber(argument)
			elseif option == "drv" then
				options.diffRoomVolume = tonumber(argument)
			elseif option == "range" then
				options.range = tonumber(argument)
			elseif option == "veh" then
				options.vehicle = true
			elseif option == "notveh" then
				options.vehicle = false
			elseif option == "visualization" then
				options.visualization = argument
			elseif option == "volume" then
				options.volume = tonumber(argument)
			elseif not option then
				options.url = argument
			end
		end)

		TriggerClientEvent("pmms:startClosestMediaPlayer", source, options)
	else
		TriggerClientEvent("pmms:pauseClosestMediaPlayer", source)
	end
end, true)

RegisterCommand(Config.commandPrefix .. Config.commandSeparator .. "pause", function(source, args, raw)
	TriggerClientEvent("pmms:pauseClosestMediaPlayer", source)
end, true)

RegisterCommand(Config.commandPrefix .. Config.commandSeparator .. "stop", function(source, args, raw)
	TriggerClientEvent("pmms:stopClosestMediaPlayer", source)
end, true)

RegisterCommand(Config.commandPrefix .. Config.commandSeparator .. "status", function(source, args, raw)
	TriggerClientEvent("pmms:toggleStatus", source)
end, true)

RegisterCommand(Config.commandPrefix .. Config.commandSeparator .. "presets", function(source, args, raw)
	TriggerClientEvent("pmms:listPresets", source)
end, true)

RegisterCommand(Config.commandPrefix .. Config.commandSeparator .. "vol", function(source, args, raw)
	if #args < 1 then
		TriggerClientEvent("pmms:showBaseVolume", source)
	else
		local volume = tonumber(args[1])

		if volume then
			TriggerClientEvent("pmms:setBaseVolume", source, volume)
		end
	end
end, true)

RegisterCommand(Config.commandPrefix .. Config.commandSeparator .. "ctl", function(source, args, raw)
	if #args < 1 then
		print("Usage:")
		print("  " .. Config.commandPrefix .. Config.commandSeparator .. "ctl list")
		print("  " .. Config.commandPrefix .. Config.commandSeparator .. "ctl lock <handle>")
		print("  " .. Config.commandPrefix .. Config.commandSeparator .. "ctl unlock <handle>")
		print("  " .. Config.commandPrefix .. Config.commandSeparator .. "ctl mute <handle>")
		print("  " .. Config.commandPrefix .. Config.commandSeparator .. "ctl unmute <handle>")
		print("  " .. Config.commandPrefix .. Config.commandSeparator .. "ctl loop <handle> <on|off>")
		print("  " .. Config.commandPrefix .. Config.commandSeparator .. "ctl next <handle>")
		print("  " .. Config.commandPrefix .. Config.commandSeparator .. "ctl pause <handle>")
		print("  " .. Config.commandPrefix .. Config.commandSeparator .. "ctl stop <handle>")
	elseif args[1] == "list" then
		for handle, info in pairs(mediaPlayers) do
			print(string.format("[%d] %s %s %d %d/%s %s %s %s %s %f %f %f %f %s %s %d %s %s %s",
				handle,
				info.title,
				info.filter and "filter" or "nofilter",
				info.volume,
				info.offset,
				info.duration or "inf",
				info.loop and "loop" or "noloop",
				info.locked and "locked" or "unlocked",
				info.video and "video" or "audio",
				info.muted and "muted" or "unmuted",
				info.attenuation.sameRoom,
				info.attenuation.diffRoom,
				info.diffRoomVolume,
				info.range,
				info.paused and "paused" or "playing",
				info.label or "nolabel",
				info.model or 0,
				info.renderTarget or "nort",
				info.isVehicle and "isveh" or "notveh",
				info.visualization or "novis"))
		end
	elseif args[1] == "lock" then
		lockMediaPlayer(tonumber(args[2]))
	elseif args[1] == "unlock" then
		unlockMediaPlayer(tonumber(args[2]))
	elseif args[1] == "mute" then
		muteMediaPlayer(tonumber(args[2]))
	elseif args[1] == "unmute" then
		unmuteMediaPlayer(tonumber(args[2]))
	elseif args[1] == "next" then
		playNextInQueue(tonumber(args[2]))
	elseif args[1] == "pause" then
		pauseMediaPlayer(tonumber(args[2]))
	elseif args[1] == "stop" then
		removeMediaPlayer(tonumber(args[2]))
	elseif args[1] == "loop" then
		setMediaPlayerLoop(tonumber(args[2]), args[3] == "on")
	end
end, true)

RegisterCommand(Config.commandPrefix .. Config.commandSeparator .. "add", function(source, args, raw)
	local model = args[1]
	local label = args[2]
	local renderTarget = args[3]

	addModelPermanently(GetHashKey(model), {
		label = label,
		renderTarget = renderTarget
	})
end, true)

RegisterCommand(Config.commandPrefix .. Config.commandSeparator .. "fix", function(source, args, raw)
	TriggerClientEvent("pmms:reset", source)
end, true)

RegisterCommand(Config.commandPrefix .. Config.commandSeparator .. "refresh_perms", function(source, args, raw)
	TriggerClientEvent("pmms:refreshPermissions", -1)
end, true)

SetHttpHandler(exports.httpmanager:createHttpHandler())

Citizen.CreateThread(function()
	loadSettings()

	startDefaultMediaPlayers()

	while true do
		Citizen.Wait(500)
		syncMediaPlayers()
	end
end)
