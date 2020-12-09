local Phonographs = {}
local SyncQueue = {}

RegisterNetEvent('phonograph:start')
RegisterNetEvent('phonograph:init')
RegisterNetEvent('phonograph:pause')
RegisterNetEvent('phonograph:stop')
RegisterNetEvent('phonograph:showControls')
RegisterNetEvent('phonograph:toggleStatus')
RegisterNetEvent('phonograph:setVolume')
RegisterNetEvent('phonograph:setStartTime')
RegisterNetEvent('phonograph:lock')
RegisterNetEvent('phonograph:unlock')

function Enqueue(queue, cb)
	table.insert(queue, 1, cb)
end

function Dequeue(queue)
	local cb = table.remove(queue)

	if cb then
		cb()
	end
end

function AddPhonograph(handle, url, title, volume, offset, startTime, filter, locked, coords)
	if not Phonographs[handle] then
		Phonographs[handle] = {
			url = url,
			title = title,
			volume = volume,
			offset = offset,
			startTime = startTime,
			filter = filter,
			locked = locked,
			coords = coords,
			paused = nil
		}

		Enqueue(SyncQueue, function()
			TriggerClientEvent('phonograph:play', -1, handle)
		end)
	end
end

function RemovePhonograph(handle)
	Phonographs[handle] = nil

	Enqueue(SyncQueue, function()
		TriggerClientEvent('phonograph:stop', -1, handle)
	end)
end

function PausePhonograph(handle, paused)
	if not Phonographs[handle] then
		return
	end

	if Phonographs[handle].paused then
		Phonographs[handle].startTime = Phonographs[handle].startTime + (paused - Phonographs[handle].paused)
		Phonographs[handle].paused = nil
	else
		Phonographs[handle].paused = paused
	end
end

function StartPhonographByNetworkId(netId, url, title, volume, offset, filter, locked)
	title = title or url
	volume = volume or 100
	offset = offset or 0

	if url == 'random' then
		url = GetRandomPreset()
	end

	local startTime = os.time() - offset

	if Config.Presets[url] then
		AddPhonograph(netId,
			Config.Presets[url].url,
			Config.Presets[url].title,
			volume,
			offset,
			startTime,
			Config.Presets[url].filter,
			locked,
			nil)
	else
		AddPhonograph(netId,
			url,
			title,
			volume,
			offset,
			startTime,
			filter,
			locked,
			nil)
	end

	return netId
end

function StartPhonographByCoords(x, y, z, url, title, volume, offset, filter, locked)
	local coords = vector3(x, y, z)
	local handle = GetHandleFromCoords(coords)

	title = title or url
	volume = volume or 100
	offset = offset or 0

	if url == 'random' then
		url = GetRandomPreset()
	end

	local startTime = os.time() - offset

	if Config.Presets[url] then
		AddPhonograph(handle,
			Config.Presets[url].url,
			Config.Presets[url].title,
			volume,
			offset,
			startTime,
			Config.Presets[url].filter,
			locked,
			coords)
	else
		AddPhonograph(handle,
			url,
			title,
			volume,
			offset,
			startTime,
			filter,
			locked,
			coords)
	end

	return handle
end

function ErrorMessage(player, message)
	TriggerClientEvent('phonograph:error', player, message)
end

function StartDefaultPhonographs()
	for _, phonograph in ipairs(Config.DefaultPhonographs) do
		if phonograph.url then
			StartPhonographByCoords(phonograph.x, phonograph.y, phonograph.z, phonograph.url, phonograph.title, phonograph.volume, phonograph.offset, phonograph.filter, phonograph.locked)
		end
	end
end

function SyncPhonographs()
	for _, playerId in ipairs(GetPlayers()) do
		TriggerClientEvent('phonograph:sync', playerId,
			Phonographs,
			IsPlayerAceAllowed(playerId, 'phonograph.manage'),
			IsPlayerAceAllowed(playerId, 'phonograph.anyUrl'))
	end

	Dequeue(SyncQueue)
end

function IsLockedDefaultPhonograph(handle)
	for _, phonograph in ipairs(Config.DefaultPhonographs) do
		local coords = vector3(phonograph.x, phonograph.y, phonograph.z)

		print(handle, GetHandleFromCoords(coords))

		if handle == GetHandleFromCoords(coords) then
			return true
		end
	end

	return false
end

exports('startByNetworkId', StartPhonographByNetworkId)
exports('startByCoords', StartPhonographByCoords)
exports('stop', RemovePhonograph)

AddEventHandler('phonograph:start', function(handle, url, volume, offset, filter, locked, coords)
	if coords then
		handle = GetHandleFromCoords(coords)
	end

	if Phonographs[handle] then
		return
	end

	if not IsPlayerAceAllowed(source, 'phonograph.interact') then
		ErrorMessage(source, 'You do not have permission to play a song on a phonograph')
		return
	end

	if (locked or IsLockedDefaultPhonograph(handle)) and not IsPlayerAceAllowed(source, 'phonograph.manage') then
		ErrorMessage(source, 'You do not have permission to play a song on a locked phonograph')
		return
	end

	if Config.Presets[url] then
		TriggerClientEvent('phonograph:start', source,
			handle,
			Config.Presets[url].url,
			Config.Presets[url].title,
			volume,
			offset,
			Config.Presets[url].filter,
			locked,
			coords)
	elseif IsPlayerAceAllowed(source, 'phonograph.anyUrl') then
		TriggerClientEvent('phonograph:start', source,
			handle,
			url,
			nil,
			volume,
			offset,
			filter,
			locked,
			coords)
	else
		ErrorMessage(source, 'You must select from one of the pre-defined songs (/phono songs)')
	end
end)

AddEventHandler('phonograph:init', function(handle, url, title, volume, offset, startTime, filter, locked, coords)
	if Phonographs[handle] then
		return
	end

	if not IsPlayerAceAllowed(source, 'phonograph.interact') then
		ErrorMessage(source, 'You do not have permission to play a song on a phonograph')
		return
	end

	if (locked or IsLockedDefaultPhonograph(handle)) and not IsPlayerAceAllowed(source, 'phonograph.manage') then
		ErrorMessage(source, 'You do not have permission to play a song on a locked phonographs')
		return
	end

	AddPhonograph(handle, url, title, volume, offset, startTime, filter, locked, coords)
end)

AddEventHandler('phonograph:pause', function(handle, paused)
	if not Phonographs[handle] then
		return
	end

	if not IsPlayerAceAllowed(source, 'phonograph.interact') then
		ErrorMessage(source, 'You do not have permission to pause or resume phonographs')
		return
	end

	if Phonographs[handle].locked and not IsPlayerAceAllowed(source, 'phonograph.manage') then
		ErrorMessage(source, 'You do not have permission to pause or resume locked phonographs')
		return
	end

	PausePhonograph(handle, paused)
end)

AddEventHandler('phonograph:stop', function(handle)
	if not Phonographs[handle] then
		return
	end

	if not IsPlayerAceAllowed(source, 'phonograph.interact') then
		ErrorMessage(source, 'You do not have permission to stop phonographs')
		return
	end

	if Phonographs[handle].locked and not IsPlayerAceAllowed(source, 'phonograph.manage') then
		ErrorMessage(source, 'You do not have permission to stop locked phonographs')
		return
	end

	RemovePhonograph(handle)
end)

AddEventHandler('phonograph:showControls', function()
	TriggerClientEvent('phonograph:showControls', source)
end)

AddEventHandler('phonograph:toggleStatus', function()
	TriggerClientEvent('phonograph:toggleStatus', source)
end)

AddEventHandler('phonograph:setVolume', function(handle, volume)
	if not Phonographs[handle] then
		return
	end

	if not IsPlayerAceAllowed(source, 'phonograph.interact') then
		ErrorMessage(source, 'You do not have permission to change the volume of phonographs')
		return
	end

	if Phonographs[handle].locked and not IsPlayerAceAllowed(source, 'phonograph.manage') then
		ErrorMessage(source, 'You do not have permission to change the volume of locked phonographs')
		return
	end

	if not volume then
		volume = 100
	elseif volume < 0 then
		volume = 0
	elseif volume > 100 then
		volume = 100
	end

	Phonographs[handle].volume = volume
end)

AddEventHandler('phonograph:setStartTime', function(handle, time)
	if not Phonographs[handle] then
		return
	end

	if not IsPlayerAceAllowed(source, 'phonograph.interact') then
		ErrorMessage(source, 'You do not have permission to seek on phonographs')
		return
	end

	if Phonographs[handle].locked and not IsPlayerAceAllowed(source, 'phonograph.manage') then
		ErrorMessage(source, 'You do not have permission to seek on locked phonographs')
		return
	end

	Phonographs[handle].startTime = time
end)

AddEventHandler('phonograph:lock', function(handle)
	if not Phonographs[handle] then
		return
	end

	if not IsPlayerAceAllowed(source, 'phonograph.manage') then
		ErrorMessage(source, 'You do not have permission to lock a phonograph')
		return
	end

	Phonographs[handle].locked = true
end)

AddEventHandler('phonograph:unlock', function(handle)
	if not Phonographs[handle] then
		return
	end

	if not IsPlayerAceAllowed(source, 'phonograph.manage') then
		ErrorMessage(source, 'You do not have permission to unlock a phonograph')
		return
	end

	Phonographs[handle].locked = false
end)

CreateThread(function()
	StartDefaultPhonographs()

	while true do
		Wait(500)
		SyncPhonographs()
	end
end)
