Config = {}

-- Max distance at which to interact with phonographs with the /phono command
Config.MaxDistance = 30

-- Pre-defined music URLs
Config.Presets = {
	--['1'] = {title = 'Example Preset', url = 'https://example.com/example.ogg', filter = true}
}

-- These phonographs will be automatically spawned and start playing when the
-- resource starts
--
-- Mandatory properties:
--
-- x, y, z
-- 	The position of the phonograph.
--
-- Optional properties:
--
-- spawn
-- 	If true, a new phonograph will be spawned. The pitch, roll and yaw
-- 	properties must be given.
--
-- 	If false or omitted, an existing phonograph is expected to exist at the
-- 	x, y and z specified.
--
-- pitch, roll, yaw
-- 	The rotation of the phonograph, if one is to be spawned.
--
-- url
-- 	The URL or preset name of music to start playing on this phonograph
-- 	when the resource starts. 'random' can be used to select a random
-- 	preset. If this is omitted, nothing will be played on the phonograph
-- 	automatically.
--
-- title
-- 	The title displayed for the music when using a URL. If a preset is
-- 	specified, the title of the preset will be used instead.
--
-- volume
-- 	The default volume to play the music at.
--
-- offset
-- 	The time in seconds to start playing the music from.
--
-- filter
-- 	Whether to apply the phonograph filter to the music when using a URL.
-- 	If a preset is specified, the filter setting of the preset will be used
-- 	instead.
--
Config.DefaultPhonographs = {
	--[[{
		x = 2071.527,
		y = -850.825,
		z = 43.399,
		spawn = true,
		pitch = 0.0,
		roll = 0.0,
		yaw = -76.858,
		url = 'https://example.com/example.ogg',
		title = 'Example Song',
		volume = 100,
		offset = 0,
		filter = true
	}]]
}
