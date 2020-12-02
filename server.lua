local Phonographs = {}

RegisterNetEvent('phonograph:init')
RegisterNetEvent('phonograph:pause')
RegisterNetEvent('phonograph:stop')
RegisterNetEvent('phonograph:showControls')

function AddPhonograph(handle, url, volume, startTime)
	Phonographs[handle] = {url = url, volume = volume, startTime = startTime, paused = nil}
	TriggerClientEvent('phonograph:play', -1, handle)
end

function RemovePhonograph(handle)
	Phonographs[handle] = nil
	TriggerClientEvent('phonograph:stop', -1, handle)
end

function PausePhonograph(handle, paused)
	if Phonographs[handle].paused then
		Phonographs[handle].startTime = Phonographs[handle].startTime + (paused - Phonographs[handle].paused)
		Phonographs[handle].paused = nil
	else
		Phonographs[handle].paused = paused
	end
end

AddEventHandler('phonograph:init', function(handle, url, volume, startTime)
	if IsPlayerAceAllowed(source, 'command.phono') then
		AddPhonograph(handle, url, volume, startTime)
	else
		TriggerClientEvent('chat:addMessage', source, {
			color = {255, 0, 0},
			args = {'Error', 'You do not have permission to use the /phono command'}
		})
	end
end)

AddEventHandler('phonograph:pause', function(handle, paused)
	if IsPlayerAceAllowed(source, 'command.phono') then
		PausePhonograph(handle, paused)
	else
		TriggerClientEvent('chat:addMessage', source, {
			color = {255, 0, 0},
			args = {'Error', 'You do not have permission to use the /phono command'}
		})
	end
end)

AddEventHandler('phonograph:stop', function(handle)
	if IsPlayerAceAllowed(source, 'command.phono') then
		RemovePhonograph(handle)
	else
		TriggerClientEvent('chat:addMessage', source, {
			color = {255, 0, 0},
			args = {'Error', 'You do not have permission to use the /phono command'}
		})
	end
end)

AddEventHandler('phonograph:showControls', function()
	if IsPlayerAceAllowed(source, 'command.phonoctl') then
		TriggerClientEvent('phonograph:showControls', source)
	else
		TriggerClientEvent('chat:addMessage', source, {
			color = {255, 0, 0},
			args = {'Error', 'You do not have permission to use the /phonoctl command'}
		})
	end
end)

CreateThread(function()
	while true do
		Wait(500)
		TriggerClientEvent('phonograph:sync', -1, Phonographs)
	end
end)
