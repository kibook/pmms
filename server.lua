local Phonographs = {}

RegisterNetEvent('phonograph:start')
RegisterNetEvent('phonograph:init')
RegisterNetEvent('phonograph:pause')
RegisterNetEvent('phonograph:stop')
RegisterNetEvent('phonograph:showControls')

function AddPhonograph(handle, url, title, volume, startTime, coords)
	if not Phonographs[handle] then
		Phonographs[handle] = {
			url = url,
			title = title,
			volume = volume,
			startTime = startTime,
			paused = nil,
			coords = coords
		}

		TriggerClientEvent('phonograph:play', -1, handle)
	end
end

function RemovePhonograph(handle)
	Phonographs[handle] = nil
	TriggerClientEvent('phonograph:stop', -1, handle)
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

AddEventHandler('phonograph:start', function(handle, url, volume, offset, filter, coords)
	if coords then
		print(coords)
		handle = GetHashKey(string.format('%f_%f_%f', coords.x, coords.y, coords.z))
	end

	if Phonographs[handle] then
		ErrorMessage(source, 'This phonograph is already active, stop it first before playing a new song')
		return
	end

	if IsPlayerAceAllowed(source, 'phonograph.interact') then
		if Config.Presets[url] then
			TriggerClientEvent('phonograph:start', source, handle, Config.Presets[url].url, Config.Presets[url].title, volume, offset, filter, coords)
		elseif IsPlayerAceAllowed(source, 'phonograph.anyUrl') then
			TriggerClientEvent('phonograph:start', source, handle, url, nil, volume, offset, filter, coords)
		else
			ErrorMessage(source, 'You must select from one of the pre-defined songs (/phono songs)')
		end
	else
		ErrorMessage(source, 'You do not have permission to play a song on a phonograph')
	end
end)

AddEventHandler('phonograph:init', function(handle, url, title, volume, startTime, coords)
	AddPhonograph(handle, url, title, volume, startTime, coords)
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

CreateThread(function()
	while true do
		Wait(500)

		for _, playerId in ipairs(GetPlayers()) do
			TriggerClientEvent('phonograph:sync', playerId, Phonographs, IsPlayerAceAllowed(playerId, 'phonograph.fullControls'), IsPlayerAceAllowed(playerId, 'phonograph.anyUrl'))
		end
	end
end)
