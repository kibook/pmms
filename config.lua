Config = {}

-- Whether the game is RDR2 or GTA V
Config.isRDR = not TerraingridActivate

-- Max distance at which to interact with phonographs with the /phono command.
Config.MaxDistance = 30.0

-- Object models that music can be played on, with a label for the type of object it is.
Config.models = {
	[`p_phonograph01x`]  = "Phonograph",
	[`prop_radio_01`] = "Radio",
	[`prop_boombox_01`] = "Boombox",
	[`bkr_prop_clubhouse_jukebox_01a`] = "Jukebox",
	[`bkr_prop_clubhouse_jukebox_01b`] = "Jukebox",
	[`bkr_prop_clubhouse_jukebox_02a`] = "Jukebox",
	[`ch_prop_arcade_jukebox_01a`] = "Jukebox",
	[`prop_50s_jukebox`] = "Jukebox",
	[`prop_jukebox_01`] = "Jukebox",
	[`prop_jukebox_01`] = "Jukebox",
	[`v_res_j_radio`] = "Radio",
	[`v_res_fa_radioalrm`] = "Alarm Clock",
	[`sm_prop_smug_radio_01`] = "Radio",
}

-- The default model to use for default phonographs if none is specified.
Config.defaultModel = Config.isRDR and `p_phonograph01x` or `prop_boombox_01`

-- Pre-defined music URLs.
--
-- Mandatory properties:
--
-- url
-- 	The URL of the music.
--
-- Optional properties:
--
-- title
-- 	The title displayed for the music.
--
-- filter
-- 	Whether to apply the phonograph filter.
--
-- video
-- 	If true and the media specified is a video, the video will be displayed
-- 	above the phonograph.
--
Config.Presets = {
	--['1'] = {url = 'https://example.com/example.ogg', title = 'Example Preset', filter = true, video = false}
}

-- These phonographs will be automatically spawned and start playing when the
-- resource starts.
--
-- Mandatory properties:
--
-- position
-- 	A vector3 giving the position of the phonograph.
--
-- Optional properties:
--
-- label
-- 	A name to use for the phonograph in the UI instead of the handle.
--
-- spawn
-- 	If true, a new phonograph will be spawned. The model, pitch, roll and yaw
-- 	properties must be given.
--
-- 	If false or omitted, an existing phonograph is expected to exist at the
-- 	x, y and z specified.
--
-- model
--  The object model to use for the phonograph, if one is to be spawned.
--
-- rotation
--  A vector3 giving the rotation of the phonograph, if one is to be spawned.
--
-- invisible
-- 	If true, the phonograph will be made invisible.
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
-- loop
-- 	Whether or not to loop playback of the music.
--
-- filter
-- 	Whether to apply the phonograph filter to the music when using a URL.
-- 	If a preset is specified, the filter setting of the preset will be used
-- 	instead.
--
-- locked
-- 	If true, the phonograph can only be controlled by players with the
-- 	phonograph.manage ace.
--
-- video
-- 	If true and the media specified is a video, the video will be displayed
-- 	above the phonograph. If a preset is specified, the video setting of
-- 	the preset will be used instead.
--
-- videoSize
-- 	The default size of the video screen above the phonograph.
--
Config.DefaultPhonographs = {
	--[[
	{
		position = vector3(2071.527, -850.825, 43.399),
		label = "Example Phonograph",
		spawn = true,
		model = `p_phonograph01x`,
		rotation = vector3(0.0, 0.0, -76.858),
		invisible = false,
		url = 'https://example.com/example.ogg',
		title = 'Example Song',
		volume = 100,
		offset = 0,
		loop = false,
		filter = true,
		locked = false,
		video = false,
		videoSize = 50
	}
	]]
}

-- Distance at which default phonographs spawn/despawn
Config.DefaultPhonographSpawnDistance = 100.0
