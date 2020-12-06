local Phonographs = {}
local SyncQueue = {}

RegisterNetEvent('phonograph:start')
RegisterNetEvent('phonograph:init')
RegisterNetEvent('phonograph:pause')
RegisterNetEvent('phonograph:stop')
RegisterNetEvent('phonograph:showControls')
RegisterNetEvent('phonograph:setVolume')
RegisterNetEvent('phonograph:setStartTime')

function Enqueue(queue, cb)
	table.insert(queue, 1, cb)
end

function Dequeue(queue)
	local cb = table.remove(queue)

	if cb then
		cb()
	end
end

function AddPhonograph(handle, url, title, volume, offset, startTime, filter, coords)
	if not Phonographs[handle] then
		Phonographs[handle] = {
			url = url,
			title = title,
			volume = volume,
			offset = offset,
			startTime = startTime,
			filter = filter,
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

function ErrorMessage(player, message)
	TriggerClientEvent('phonograph:error', player, message)
end

function StartDefaultPhonographs()
	for _, phonograph in ipairs(Config.DefaultPhonographs) do
		if phonograph.url then
			local coords = vector3(phonograph.x, phonograph.y, phonograph.z)
			local handle = GetHandleFromCoords(coords)
			local url = phonograph.url
			local title = phonograph.title or url
			local volume = phonograph.volume or 100
			local offset = phonograph.offset or 0
			local filter = phonograph.filter

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
					coords)
			else
				AddPhonograph(handle,
					url,
					title,
					volume,
					offset,
					startTime,
					filter,
					coords)
			end
		end
	end
end

function SyncPhonographs()
	for _, playerId in ipairs(GetPlayers()) do
		TriggerClientEvent('phonograph:sync', playerId,
			Phonographs,
			IsPlayerAceAllowed(playerId, 'phonograph.fullControls'),
			IsPlayerAceAllowed(playerId, 'phonograph.anyUrl'))
	end

	Dequeue(SyncQueue)
end

AddEventHandler('phonograph:start', function(handle, url, volume, offset, filter, coords)
	if coords then
		handle = GetHandleFromCoords(coords)
	end

	if Phonographs[handle] then
		return
	end

	if IsPlayerAceAllowed(source, 'phonograph.interact') then
		if Config.Presets[url] then
			TriggerClientEvent('phonograph:start', source,
				handle,
				Config.Presets[url].url,
				Config.Presets[url].title,
				volume,
				offset,
				Config.Presets[url].filter,
				coords)
		elseif IsPlayerAceAllowed(source, 'phonograph.anyUrl') then
			TriggerClientEvent('phonograph:start', source,
				handle,
				url,
				nil,
				volume,
				offset,
				filter,
				coords)
		else
			ErrorMessage(source, 'You must select from one of the pre-defined songs (/phono songs)')
		end
	else
		ErrorMessage(source, 'You do not have permission to play a song on a phonograph')
	end
end)

AddEventHandler('phonograph:init', function(handle, url, title, volume, offset, startTime, filter, coords)
	AddPhonograph(handle, url, title, volume, offset, startTime, filter, coords)
end)

AddEventHandler('phonograph:pause', function(handle, paused)
	if IsPlayerAceAllowed(source, 'phonograph.interact') then
		PausePhonograph(handle, paused)
	else
		ErrorMessage(source, 'You do not have permission to pause/resume phonographs')
	end
end)

AddEventHandler('phonograph:stop', function(handle)
	if IsPlayerAceAllowed(source, 'phonograph.interact') then
		RemovePhonograph(handle)
	else
		ErrorMessage(source, 'You do not have permission to stop phonographs')
	end
end)

AddEventHandler('phonograph:showControls', function()
	TriggerClientEvent('phonograph:showControls', source)
end)

AddEventHandler('phonograph:setVolume', function(handle, volume)
	if not Phonographs[handle] then
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

	Phonographs[handle].startTime = time
end)

CreateThread(function()
	StartDefaultPhonographs()

	while true do
		Wait(500)
		SyncPhonographs()
	end
end)

RegisterCommand('sv_dumpphonos', function(source, args, raw)
	print(json.encode(Phonographs))
end, true)
