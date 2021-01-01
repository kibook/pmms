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
RegisterNetEvent('phonograph:enableVideo')
RegisterNetEvent('phonograph:disableVideo')
RegisterNetEvent('phonograph:setVideoSize')
RegisterNetEvent('phonograph:mute')
RegisterNetEvent('phonograph:unmute')
RegisterNetEvent('phonograph:copy')

function Enqueue(queue, cb)
	table.insert(queue, 1, cb)
end

function Dequeue(queue)
	local cb = table.remove(queue)

	if cb then
		cb()
	end
end

function AddPhonograph(handle, url, title, volume, offset, filter, locked, video, videoSize, muted, coords)
	if not Phonographs[handle] then
		title = title or url
		volume = Clamp(volume, 0, 100)
		offset = offset or 0
		videoSize = Clamp(videoSize, 10, 100)

		Phonographs[handle] = {
			url = url,
			title = title,
			volume = volume,
			startTime = os.time() - offset,
			offset = 0,
			filter = filter,
			locked = locked,
			video = video,
			videoSize = videoSize,
			coords = coords,
			paused = nil,
			muted = muted
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

function PausePhonograph(handle)
	if not Phonographs[handle] then
		return
	end

	if Phonographs[handle].paused then
		Phonographs[handle].startTime = Phonographs[handle].startTime + (os.time() - Phonographs[handle].paused)
		Phonographs[handle].paused = nil
	else
		Phonographs[handle].paused = os.time()
	end
end

function StartPhonographByNetworkId(netId, url, title, volume, offset, filter, locked, video, videoSize, muted)
	if url == 'random' then
		url = GetRandomPreset()
	end

	if Config.Presets[url] then
		AddPhonograph(netId,
			Config.Presets[url].url,
			Config.Presets[url].title,
			volume,
			offset,
			Config.Presets[url].filter or false,
			locked,
			Config.Presets[url].video or false,
			videoSize,
			muted,
			nil)
	else
		AddPhonograph(netId,
			url,
			title,
			volume,
			offset,
			filter,
			locked,
			video,
			videoSize,
			muted,
			nil)
	end

	return netId
end

function StartPhonographByCoords(x, y, z, url, title, volume, offset, filter, locked, video, videoSize, muted)
	local coords = vector3(x, y, z)
	local handle = GetHandleFromCoords(coords)

	if url == 'random' then
		url = GetRandomPreset()
	end

	if Config.Presets[url] then
		AddPhonograph(handle,
			Config.Presets[url].url,
			Config.Presets[url].title,
			volume,
			offset,
			Config.Presets[url].filter or false,
			locked,
			Config.Presets[url].video or false,
			videoSize,
			muted,
			coords)
	else
		AddPhonograph(handle,
			url,
			title,
			volume,
			offset,
			filter,
			locked,
			video,
			videoSize,
			muted,
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
			StartPhonographByCoords(phonograph.x, phonograph.y, phonograph.z, phonograph.url, phonograph.title, phonograph.volume, phonograph.offset, phonograph.filter, phonograph.locked, phonograph.video, phonograph.videoSize, phonograph.muted)
		end
	end
end

function SyncPhonographs()
	for handle, _ in pairs(Phonographs) do
		if not Phonographs[handle].paused then
			Phonographs[handle].offset = os.time() - Phonographs[handle].startTime
		end
	end

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

		if handle == GetHandleFromCoords(coords) then
			return true
		end
	end

	return false
end

function LockPhonograph(handle)
	Phonographs[handle].locked = true
end

function UnlockPhonograph(handle)
	Phonographs[handle].locked = false
end

function MutePhonograph(handle)
	Phonographs[handle].muted = true
end

function UnmutePhonograph(handle)
	Phonographs[handle].muted = false
end

function CopyPhonograph(oldHandle, newHandle, newCoords)
	if newHandle then
		StartPhonographByNetworkId(
			newHandle,
			Phonographs[oldHandle].url,
			Phonographs[oldHandle].title,
			Phonographs[oldHandle].volume,
			Phonographs[oldHandle].offset,
			Phonographs[oldHandle].filter,
			Phonographs[oldHandle].locked,
			Phonographs[oldHandle].video,
			Phonographs[oldHandle].videoSize,
			Phonographs[oldHandle].muted)
	elseif newCoords then
		StartPhonographByCoords(
			newCoords.x,
			newCoords.y,
			newCoords.z,
			Phonographs[oldHandle].url,
			Phonographs[oldHandle].title,
			Phonographs[oldHandle].volume,
			Phonographs[oldHandle].offset,
			Phonographs[oldHandle].filter,
			Phonographs[oldHandle].locked,
			Phonographs[oldHandle].video,
			Phonographs[oldHandle].videoSize,
			Phonographs[oldHandle].muted)
	end
end

exports('startByNetworkId', StartPhonographByNetworkId)
exports('startByCoords', StartPhonographByCoords)
exports('stop', RemovePhonograph)
exports('pause', PausePhonograph)
exports('lock', LockPhonograph)
exports('unlock', UnlockPhonograph)
exports('mute', MutePhonograph)
exports('unmute', UnmutePhonograph)

AddEventHandler('phonograph:start', function(handle, url, volume, offset, filter, locked, video, videoSize, muted, coords)
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
			Config.Presets[url].filter or false,
			locked,
			Config.Presets[url].video or false,
			videoSize,
			muted,
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
			video,
			videoSize,
			muted,
			coords)
	else
		ErrorMessage(source, 'You must select from one of the pre-defined songs (/phono songs)')
	end
end)

AddEventHandler('phonograph:init', function(handle, url, title, volume, offset, filter, locked, video, videoSize, muted, coords)
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

	AddPhonograph(handle, url, title, volume, offset, filter, locked, video, videoSize, muted, coords)
end)

AddEventHandler('phonograph:pause', function(handle)
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

	PausePhonograph(handle)
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

	Phonographs[handle].volume = Clamp(volume, 0, 100)
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

	LockPhonograph(handle)
end)

AddEventHandler('phonograph:unlock', function(handle)
	if not Phonographs[handle] then
		return
	end

	if not IsPlayerAceAllowed(source, 'phonograph.manage') then
		ErrorMessage(source, 'You do not have permission to unlock a phonograph')
		return
	end

	UnlockPhonograph(handle)
end)

AddEventHandler('phonograph:enableVideo', function(handle)
	if not Phonographs[handle] then
		return
	end

	if not IsPlayerAceAllowed(source, 'phonograph.interact') then
		ErrorMessage(source, 'You do not have permission to enable video on phonographs')
		return
	end

	if Phonographs[handle].locked and not IsPlayerAceAllowed(source, 'phonograph.manage') then
		ErrorMessage(source, 'You do not have permission to enable video on locked phonographs')
		return
	end

	Phonographs[handle].video = true
end)

AddEventHandler('phonograph:disableVideo', function(handle)
	if not Phonographs[handle] then
		return
	end

	if not IsPlayerAceAllowed(source, 'phonograph.interact') then
		ErrorMessage(source, 'You do not have permission to disable video on phonographs')
		return
	end

	if Phonographs[handle].locked and not IsPlayerAceAllowed(source, 'phonograph.manage') then
		ErrorMessage(source, 'You do not have permission to disable video on locked phonographs')
		return
	end

	Phonographs[handle].video = false
end)

AddEventHandler('phonograph:setVideoSize', function(handle, size)
	if not Phonographs[handle] then
		return
	end

	if not IsPlayerAceAllowed(source, 'phonograph.interact') then
		ErrorMessage(source, 'You do not have permission to change video size on phonographs')
		return
	end

	if Phonographs[handle].locked and not IsPlayerAceAllowed(source, 'phonograph.manage') then
		ErrorMessage(source, 'You do not have permission to change video size on locked phonographs')
		return
	end

	Phonographs[handle].videoSize = Clamp(size, 10, 100)
end)

AddEventHandler('phonograph:mute', function(handle)
	if not Phonographs[handle] then
		return
	end

	if not IsPlayerAceAllowed(source, 'phonograph.interact') then
		ErrorMessage(source, 'You do not have permission to mute phonographs')
		return
	end

	if Phonographs[handle].locked and not IsPlayerAceAllowed(source, 'phonograph.manage') then
		ErrorMessage(source, 'You do not have permission to mute locked phonographs')
		return
	end

	MutePhonograph(handle)
end)

AddEventHandler('phonograph:unmute', function(handle)
	if not Phonographs[handle] then
		return
	end

	if not IsPlayerAceAllowed(source, 'phonograph.interact') then
		ErrorMessage(source, 'You do not have permission to mute phonographs')
		return
	end

	if Phonographs[handle].locked and not IsPlayerAceAllowed(source, 'phonograph.manage') then
		ErrorMessage(source, 'You do not have permission to mute locked phonographs')
		return
	end

	UnmutePhonograph(handle)
end)

AddEventHandler('phonograph:copy', function(oldHandle, newHandle, newCoords)
	if not Phonographs[oldHandle] then
		return
	end

	if not IsPlayerAceAllowed(source, 'phonograph.interact') then
		ErrorMessage(source, 'You do not have permission to copy phonographs')
		return
	end

	if Phonographs[oldHandle].locked and not IsPlayerAceAllowed(source, 'phonograph.manage') then
		ErrorMessage(source, 'You do not have permission to mute locked phonographs')
		return
	end

	CopyPhonograph(oldHandle, newHandle, newCoords)
end)

RegisterCommand('phonoctl', function(source, args, raw)
	if #args < 1 then
		print('Usage:')
		print('  phonoctl list')
		print('  phonoctl lock <handle>')
		print('  phonoctl unlock <handle>')
		print('  phonoctl mute <handle>')
		print('  phonoctl unmute <handle>')
		print('  phonoctl pause <handle>')
		print('  phonoctl stop <handle>')
	elseif args[1] == 'list' then
		for handle, info in pairs(Phonographs) do
			print(string.format('[%x] %s %d %d %s %s %s %s',
				handle,
				info.title,
				info.volume,
				info.offset,
				info.locked and 'locked' or 'unlocked',
				info.video and 'video' or 'audio',
				info.muted and 'muted' or 'unmuted',
				info.paused and 'paused' or 'playing'))
		end
	elseif args[1] == 'lock' then
		LockPhonograph(tonumber(args[2], 16))
	elseif args[1] == 'unlock' then
		UnlockPhonograph(tonumber(args[2], 16))
	elseif args[1] == 'mute' then
		MutePhonograph(tonumber(args[2], 16))
	elseif args[1] == 'unmute' then
		UnmutePhonograph(tonumber(args[2], 16))
	elseif args[1] == 'pause' then
		PausePhonograph(tonumber(args[2], 16))
	elseif args[1] == 'stop' then
		RemovePhonograph(tonumber(args[2], 16))
	end
end, true)

CreateThread(function()
	StartDefaultPhonographs()

	while true do
		Wait(500)
		SyncPhonographs()
	end
end)
