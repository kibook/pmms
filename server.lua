local Phonographs = {}
local RestrictedHandles = {}
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
RegisterNetEvent('phonograph:setLoop')
RegisterNetEvent('phonograph:next')
RegisterNetEvent('phonograph:removeFromQueue')

function Enqueue(queue, cb)
	table.insert(queue, 1, cb)
end

function Dequeue(queue)
	local cb = table.remove(queue)

	if cb then
		cb()
	end
end

function AddToQueue(handle, source, url, volume, offset, filter, video)
	table.insert(Phonographs[handle].queue, {
		source = source,
		name = GetPlayerName(source),
		url = url,
		volume = volume,
		offset = offset,
		filter = filter,
		video = video
	})
end

function RemoveFromQueue(handle, index)
	table.remove(Phonographs[handle].queue, index)
end

function AddPhonograph(handle, url, title, volume, offset, duration, loop, filter, locked, video, videoSize, muted, queue, coords)
	if Phonographs[handle] then
		return
	end

	Phonographs[handle] = {
		url = url,
		title = title or url,
		volume = Clamp(volume, 0, 100, 50),
		startTime = os.time() - (offset or 0),
		offset = 0,
		duration = duration,
		loop = loop,
		filter = filter,
		locked = locked,
		video = video,
		videoSize = Clamp(videoSize, 10, 100, 50),
		coords = coords,
		paused = false,
		muted = muted,
		queue = queue or {}
	}

	Enqueue(SyncQueue, function()
		TriggerClientEvent('phonograph:play', -1, handle)
	end)
end

function PlayNextInQueue(handle)
	local phono = Phonographs[handle]

	RemovePhonograph(handle)

	while #phono.queue > 0 do
		local next = table.remove(phono.queue, 1)

		local client

		if GetPlayerName(next.source) == next.name then
			client = next.source
		else
			client = GetPlayers()[1]
		end

		if client then
			RestrictedHandles[handle] = client

			Enqueue(SyncQueue, function()
				TriggerClientEvent('phonograph:init',
					client,
					handle,
					next.url,
					next.volume,
					next.offset,
					phono.loop,
					next.filter,
					phono.locked,
					next.video,
					phono.videoSize,
					phono.muted,
					phono.queue,
					phono.coords)
			end)

			break
		end
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
		Phonographs[handle].paused = false
	else
		Phonographs[handle].paused = os.time()
	end
end

function GetRandomPreset()
	local presets = {}

	for preset, info in pairs(Config.Presets) do
		table.insert(presets, preset)
	end

	return #presets > 0 and presets[math.random(#presets)] or ''
end

function ResolvePreset(url, title, filter, video)
	if url == 'random' then
		url = GetRandomPreset()
	end

	if Config.Presets[url] then
		return Config.Presets[url]
	else
		return {
			url = url,
			title = title,
			filter = filter,
			video = video
		}
	end
end

function StartPhonographByNetworkId(netId, url, title, volume, offset, duration, loop, filter, locked, video, videoSize, muted)
	local resolved = ResolvePreset(url, title, filter, video)

	AddPhonograph(netId,
		resolved.url,
		resolved.title,
		volume,
		offset,
		duration,
		loop,
		resolved.filter,
		locked,
		resolved.video,
		videoSize,
		muted,
		false,
		false)

	return netId
end

function StartPhonographByCoords(x, y, z, url, title, volume, offset, duration, loop, filter, locked, video, videoSize, muted)
	local coords = vector3(x, y, z)
	local handle = GetHandleFromCoords(coords)

	local resolved = ResolvePreset(url, title, filter, video)

	AddPhonograph(handle,
		resolved.url,
		resolved.title,
		volume,
		offset,
		duration,
		loop,
		resolved.filter,
		locked,
		resolved.video,
		videoSize,
		muted,
		false,
		coords)

	return handle
end

function ErrorMessage(player, message)
	TriggerClientEvent('phonograph:error', player, message)
end

function StartDefaultPhonographs()
	for _, phonograph in ipairs(Config.DefaultPhonographs) do
		if phonograph.url then
			StartPhonographByCoords(
				phonograph.x,
				phonograph.y,
				phonograph.z,
				phonograph.url,
				phonograph.title,
				phonograph.volume,
				phonograph.offset,
				phonograph.duration,
				phonograph.loop,
				phonograph.filter,
				phonograph.locked,
				phonograph.video,
				phonograph.videoSize,
				phonograph.muted)
		end
	end
end

function ResetPlaytime(handle)
	Phonographs[handle].offset = 0
	Phonographs[handle].startTime = os.time()
end

function SyncPhonographs()
	for handle, phono in pairs(Phonographs) do
		if not phono.paused then
			phono.offset = os.time() - phono.startTime

			if phono.duration and phono.offset >= phono.duration then
				if phono.loop then
					ResetPlaytime(handle)
				elseif #phono.queue > 0 then
					PlayNextInQueue(handle)
				else
					RemovePhonograph(handle)
				end
			end
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

		if handle == GetHandleFromCoords(coords) and phonograph.locked then
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
			Phonographs[oldHandle].duration,
			Phonographs[oldHandle].loop,
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
			Phonographs[oldHandle].duration,
			Phonographs[oldHandle].loop,
			Phonographs[oldHandle].filter,
			Phonographs[oldHandle].locked,
			Phonographs[oldHandle].video,
			Phonographs[oldHandle].videoSize,
			Phonographs[oldHandle].muted)
	end
end

function SetPhonographLoop(handle, loop)
	Phonographs[handle].loop = loop
end

exports('startByNetworkId', StartPhonographByNetworkId)
exports('startByCoords', StartPhonographByCoords)
exports('stop', RemovePhonograph)
exports('pause', PausePhonograph)
exports('lock', LockPhonograph)
exports('unlock', UnlockPhonograph)
exports('mute', MutePhonograph)
exports('unmute', UnmutePhonograph)

AddEventHandler('phonograph:start', function(handle, url, volume, offset, loop, filter, locked, video, videoSize, muted, queue, coords)
	if coords then
		handle = GetHandleFromCoords(coords)
	end

	if RestrictedHandles[handle] then
		if RestrictedHandles[handle] ~= source then
			ErrorMessage(source, 'This player is busy')
			return
		end

		RestrictedHandles[handle] = nil
	end

	if Phonographs[handle] then
		AddToQueue(handle, source, url, volume, offset, filter, video)
	else
		if not IsPlayerAceAllowed(source, 'phonograph.interact') then
			ErrorMessage(source, 'You do not have permission to play a song on a phonograph')
			return
		end

		if (locked or IsLockedDefaultPhonograph(handle)) and not IsPlayerAceAllowed(source, 'phonograph.manage') then
			ErrorMessage(source, 'You do not have permission to play a song on a locked phonograph')
			return
		end

		if url == 'random' then
			url = GetRandomPreset()
		end

		if Config.Presets[url] then
			TriggerClientEvent('phonograph:start', source,
				handle,
				Config.Presets[url].url,
				Config.Presets[url].title,
				volume,
				offset,
				loop,
				Config.Presets[url].filter or false,
				locked,
				Config.Presets[url].video or false,
				videoSize,
				muted,
				queue,
				coords)
		elseif IsPlayerAceAllowed(source, 'phonograph.anyUrl') then
			TriggerClientEvent('phonograph:start', source,
				handle,
				url,
				false,
				volume,
				offset,
				loop,
				filter,
				locked,
				video,
				videoSize,
				muted,
				queue,
				coords)
		else
			ErrorMessage(source, 'You must select from one of the pre-defined songs (/phono songs)')
		end
	end
end)

AddEventHandler('phonograph:init', function(handle, url, title, volume, offset, duration, loop, filter, locked, video, videoSize, muted, queue, coords)
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

	AddPhonograph(handle, url, title, volume, offset, duration, loop, filter, locked, video, videoSize, muted, queue, coords)
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

	Phonographs[handle].volume = Clamp(volume, 0, 100, 50)
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

	Phonographs[handle].videoSize = Clamp(size, 10, 100, 50)
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
		ErrorMessage(source, 'You do not have permission to copy locked phonographs')
		return
	end

	CopyPhonograph(oldHandle, newHandle, newCoords)
end)

AddEventHandler('phonograph:setLoop', function(handle, loop)
	if not Phonographs[handle] then
		return
	end

	if not IsPlayerAceAllowed(source, 'phonograph.interact') then
		ErrorMessage(source, 'You do not have permission to change loop settings on phonographs')
		return
	end

	if Phonographs[handle].locked and not IsPlayerAceAllowed(source, 'phonograph.manage') then
		ErrorMessage(source, 'You do not have permission to change loop settings on locked phonographs')
		return
	end

	SetPhonographLoop(handle, loop)
end)

AddEventHandler('phonograph:next', function(handle)
	if not Phonographs[handle] then
		return
	end

	if not IsPlayerAceAllowed(source, 'phonograph.interact') then
		ErrorMessage(source, 'You do not have permission to skip forward on phonographs')
		return
	end

	if Phonographs[handle].locked and not IsPlayerAceAllowed(source, 'phonograph.manage') then
		ErrorMessage(source, 'You do not have permission to skip forward on locked phonographs')
		return
	end

	PlayNextInQueue(handle)
end)

AddEventHandler('phonograph:removeFromQueue', function(handle, id)
	if not Phonographs[handle] then
		return
	end

	if not IsPlayerAceAllowed(source, 'phonograph.interact') then
		ErrorMessage(source, 'You do not have permission to remove an item from the queue of phonographs')
		return
	end

	if Phonographs[handle].locked and not IsPlayerAceAllowed(source, 'phonograph.manage') then
		ErrorMessage(source, 'You do not have permission to remove an item from the queue of locked phonographs')
		return
	end

	RemoveFromQueue(handle, id)
end)

RegisterCommand('phonoctl', function(source, args, raw)
	if #args < 1 then
		print('Usage:')
		print('  phonoctl list')
		print('  phonoctl lock <handle>')
		print('  phonoctl unlock <handle>')
		print('  phonoctl mute <handle>')
		print('  phonoctl unmute <handle>')
		print('  phonoctl loop <handle> <on|off>')
		print('  phonoctl next <handle>')
		print('  phonoctl pause <handle>')
		print('  phonoctl stop <handle>')
	elseif args[1] == 'list' then
		for handle, info in pairs(Phonographs) do
			print(string.format('[%x] %s %d %d/%s %s %s %s %s',
				handle,
				info.title,
				info.volume,
				info.offset,
				info.duration or 'inf',
				info.loop and 'loop' or 'noloop',
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
	elseif args[1] == 'next' then
		PlayNextInQueue(tonumber(args[2], 16))
	elseif args[1] == 'pause' then
		PausePhonograph(tonumber(args[2], 16))
	elseif args[1] == 'stop' then
		RemovePhonograph(tonumber(args[2], 16))
	elseif args[1] == 'loop' then
		SetPhonographLoop(tonumber(args[2], 16), args[3] == 'on')
	end
end, true)

Citizen.CreateThread(function()
	StartDefaultPhonographs()

	while true do
		Citizen.Wait(500)
		SyncPhonographs()
	end
end)
