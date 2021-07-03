Config = {}

-- Whether the game is RDR2 or GTA V
Config.isRDR = not TerraingridActivate

-- Max distance at which to interact with phonographs with the /phono command.
Config.maxDistance = 40.0

-- Object models that media can be played on.
--
-- Optional properties:
--
--	label
--		The label to use for this object in the UI.
--
--	renderTarget
--		If specified, video will be displayed on the render target with DUI,
--		rather than in a floating screen above the object.
--
Config.models = {
	[`p_phonograph01x`]  = {
		label = "Phonograph"
	},
	[`prop_radio_01`] = {
		label = "Radio"
	},
	[`prop_boombox_01`] = {
		label = "Boombox"
	},
	[`bkr_prop_clubhouse_jukebox_01a`] = {
		label = "Jukebox"
	},
	[`bkr_prop_clubhouse_jukebox_01b`] = {
		label = "Jukebox"
	},
	[`bkr_prop_clubhouse_jukebox_02a`] = {
		label = "Jukebox"
	},
	[`ch_prop_arcade_jukebox_01a`] = {
		label = "Jukebox"
	},
	[`prop_50s_jukebox`] = {
		label = "Jukebox"
	},
	[`prop_jukebox_01`] = {
		label = "Jukebox"
	},
	[`prop_jukebox_01`] = {
		label = "Jukebox"
	},
	[`v_res_j_radio`] = {
		label = "Radio"
	},
	[`v_res_fa_radioalrm`] = {
		label = "Alarm Clock"
	},
	[`sm_prop_smug_radio_01`] = {
		label = "Radio"
	},
	[`ex_prop_ex_tv_flat_01`] = {
		label = "TV",
		renderTarget = "ex_tvscreen"
	},
	[`prop_tv_flat_01`] = {
		label = "TV",
		renderTarget = "tvscreen"
	},
	[`prop_tv_flat_02`] = {
		label = "TV",
		renderTarget = "tvscreen"
	},
	[`prop_tv_flat_02b`] = {
		label = "TV",
		renderTarget = "tvscreen"
	},
	[`prop_tv_flat_03`] = {
		label = "TV",
		renderTarget = "tvscreen"
	},
	[`prop_tv_flat_03b`] = {
		label = "TV",
		renderTarget = "tvscreen"
	},
	[`prop_tv_flat_michael`] = {
		label = "TV",
		renderTarget = "tvscreen"
	},
	[`prop_monitor_w_large`] = {
		label = "Monitor",
		renderTarget = "tvscreen"
	},
	[`hei_prop_dlc_tablet`] = {
		label = "Tablet",
		renderTarget = "tablet"
	},
	[`prop_trev_tv_01`] = {
		label = "TV",
		renderTarget = "tvscreen"
	},
	[`prop_tv_02`] = {
		label = "TV",
		renderTarget = "tvscreen"
	},
	[`prop_tv_03`] = {
		label = "TV",
		renderTarget = "tvscreen"
	},
	[`prop_tv_03_overlay`] = {
		label = "TV",
		renderTarget = "tvscreen"
	},
	[`prop_laptop_lester2`] = {
		label = "Laptop",
		renderTarget = "tvscreen"
	},
	[`des_tvsmash_start`] = {
		label = "TV",
		renderTarget = "tvscreen"
	},
	[`prop_flatscreen_overlay`] = {
		label = "TV",
		renderTarget = "tvscreen"
	},
	[`prop_monitor_02`] = {
		label = "Monitor",
		renderTarget = "tvscreen"
	},
	[`prop_big_cin_screen`] = {
		label = "Cinema",
		renderTarget = "cinscreen"
	},
	[`v_ilev_cin_screen`] = {
		label = "Cinema",
		renderTarget = "cinscreen"
	},
	[`ba_prop_battle_club_computer_01`] = {
		label = "Computer",
		renderTarget = "club_computer"
	},
	[`ba_prop_club_laptop_dj`] = {
		label = "Laptop",
		renderTarget = "laptop_dj"
	},
	[`ba_prop_club_laptop_dj_02`] = {
		label = "Laptop",
		renderTarget = "laptop_dj_02"
	},
	[`sm_prop_smug_monitor_01`] = {
		label = "Computer",
		renderTarget = "smug_monitor_01"
	},
	[`xm_prop_x17_tv_flat_01`] = {
		label = "TV",
		renderTarget = "tv_flat_01"
	},
	[`sm_prop_smug_tv_flat_01`] = {
		label = "TV",
		renderTarget = "tv_flat_01"
	},
	[`xm_prop_x17_computer_02`] = {
		label = "Monitor",
		renderTarget = "monitor_02"
	},
	[`xm_prop_x17_screens_02a_01`] = {
		label = "Screen",
		renderTarget = "prop_x17_8scrn_01"
	},
	[`xm_prop_x17_screens_02a_02`] = {
		label = "Screen",
		renderTarget = "prop_x17_8scrn_02"
	},
	[`xm_prop_x17_screens_02a_03`] = {
		label = "Screen",
		renderTarget = "prop_x17_8scrn_03"
	},
	[`xm_prop_x17_screens_02a_04`] = {
		label = "Screen",
		renderTarget = "prop_x17_8scrn_04"
	},
	[`xm_prop_x17_screens_02a_05`] = {
		label = "Screen",
		renderTarget = "prop_x17_8scrn_05"
	},
	[`xm_prop_x17_screens_02a_06`] = {
		label = "Screen",
		renderTarget = "prop_x17_8scrn_06"
	},
	[`xm_prop_x17_screens_02a_07`] = {
		label = "Screen",
		renderTarget = "prop_x17_8scrn_07"
	},
	[`xm_prop_x17_screens_02a_08`] = {
		label = "Screen",
		renderTarget = "prop_x17_8scrn_08"
	},
	[`xm_prop_x17_tv_ceiling_scn_01`] = {
		label = "TV",
		renderTarget = "prop_x17_tv_ceil_scn_01"
	},
	[`xm_prop_x17_tv_ceiling_scn_02`] = {
		label = "TV",
		renderTarget = "prop_x17_tv_ceil_scn_02"
	},
	[`xm_prop_x17_tv_scrn_01`] = {
		label = "TV",
		renderTarget = "prop_x17_tv_scrn_01"
	},
	[`xm_prop_x17_tv_scrn_02`] = {
		label = "TV",
		renderTarget = "prop_x17_tv_scrn_02"
	},
	[`xm_prop_x17_tv_scrn_03`] = {
		label = "TV",
		renderTarget = "prop_x17_tv_scrn_03"
	},
	[`xm_prop_x17_tv_scrn_04`] = {
		label = "TV",
		renderTarget = "prop_x17_tv_scrn_04"
	},
	[`xm_prop_x17_tv_scrn_05`] = {
		label = "TV",
		renderTarget = "prop_x17_tv_scrn_05"
	},
	[`xm_prop_x17_tv_scrn_06`] = {
		label = "TV",
		renderTarget = "prop_x17_tv_scrn_06"
	},
	[`xm_prop_x17_tv_scrn_07`] = {
		label = "TV",
		renderTarget = "prop_x17_tv_scrn_07"
	},
	[`xm_prop_x17_tv_scrn_08`] = {
		label = "TV",
		renderTarget = "prop_x17_tv_scrn_08"
	},
	[`xm_prop_x17_tv_scrn_09`] = {
		label = "TV",
		renderTarget = "prop_x17_tv_scrn_09"
	},
	[`xm_prop_x17_tv_scrn_10`] = {
		label = "TV",
		renderTarget = "prop_x17_tv_scrn_10"
	},
	[`xm_prop_x17_tv_scrn_11`] = {
		label = "TV",
		renderTarget = "prop_x17_tv_scrn_11"
	},
	[`xm_prop_x17_tv_scrn_12`] = {
		label = "TV",
		renderTarget = "prop_x17_tv_scrn_12"
	},
	[`xm_prop_x17_tv_scrn_13`] = {
		label = "TV",
		renderTarget = "prop_x17_tv_scrn_13"
	},
	[`xm_prop_x17_tv_scrn_14`] = {
		label = "TV",
		renderTarget = "prop_x17_tv_scrn_14"
	},
	[`xm_prop_x17_tv_scrn_15`] = {
		label = "TV",
		renderTarget = "prop_x17_tv_scrn_15"
	},
	[`xm_prop_x17_tv_scrn_16`] = {
		label = "TV",
		renderTarget = "prop_x17_tv_scrn_16"
	},
	[`xm_prop_x17_tv_scrn_17`] = {
		label = "TV",
		renderTarget = "prop_x17_tv_scrn_17"
	},
	[`xm_prop_x17_tv_scrn_18`] = {
		label = "TV",
		renderTarget = "prop_x17_tv_scrn_18"
	},
	[`xm_prop_x17_tv_scrn_19`] = {
		label = "TV",
		renderTarget = "prop_x17_tv_scrn_18"
	},
	[`xm_screen_1`] = {
		label = "Screen",
		renderTarget = "prop_x17_tv_ceiling_01"
	},
	[`ex_prop_monitor_01_ex`] = {
		label = "Computer",
		renderTarget = "prop_ex_computer_screen"
	},
	[`gr_prop_gr_laptop_01a`] = {
		label = "Laptop",
		renderTarget = "gr_bunker_laptop_01a"
	},
	[`gr_prop_gr_laptop_01b`] = {
		label = "Laptop",
		renderTarget = "gr_bunker_laptop_sq_01a"
	},
	[`gr_prop_gr_trailer_monitor_01`] = {
		label = "Monitor",
		renderTarget = "gr_trailer_monitor_01"
	},
	[`gr_prop_gr_trailer_monitor_02`] = {
		label = "Monitor",
		renderTarget = "gr_trailer_monitor_02"
	},
	[`gr_prop_gr_trailer_monitor_03`] = {
		label = "Monitor",
		renderTarget = "gr_trailer_monitor_03"
	},
	[`gr_prop_gr_trailer_tv`] = {
		label = "TV",
		renderTarget = "gr_trailertv_01"
	},
	[`gr_prop_gr_trailer_tv_02`] = {
		label = "TV",
		renderTarget = "gr_trailertv_02"
	},
	[`hei_prop_dlc_heist_board`] = {
		label = "Projector",
		renderTarget = "heist_brd"
	},
	[`hei_prop_hei_monitor_overlay`] = {
		label = "Monitor",
		renderTarget = "hei_mon"
	},
	[`sr_mp_spec_races_blimp_sign`] = {
		label = "Blimp",
		renderTarget = "blimp_text"
	},
	[`xm_prop_orbital_cannon_table`] = {
		label = "Orbital Cannon",
		renderTarget = "orbital_table"
	},
	[`imp_prop_impexp_lappy_01a`] = {
		label = "Laptop",
		renderTarget = "prop_impexp_lappy_01a"
	},
	[`w_am_digiscanner`] = {
		label = "Digiscanner",
		renderTarget = "digiscanner"
	},
	[`prop_phone_cs_frank`] = {
		label = "Phone",
		renderTarget = "npcphone"
	},
	[`prop_phone_proto`] = {
		label = "Phone",
		renderTarget = "npcphone"
	},
	[`prop_huge_display_01`] = {
		label = "Screen",
		renderTarget = "big_disp"
	},
	[`prop_huge_display_02`] = {
		label = "Screen",
		renderTarget = "big_disp"
	},
	[`hei_prop_hei_muster_01`] = {
		label = "Whiteboard",
		renderTarget = "planning"
	},
	[`ba_prop_battle_hacker_screen`] = {
		label = "Tablet",
		renderTarget = "prop_battle_touchscreen_rt"
	},
	[`xm_prop_x17_sec_panel_01`] = {
		label = "Panel",
		renderTarget = "prop_x17_p_01"
	},
	[`bkr_prop_clubhouse_laptop_01a`] = {
		label = "Laptop",
		renderTarget = "prop_clubhouse_laptop_01a"
	},
	[`bkr_prop_clubhouse_laptop_01b`] = {
		label = "Laptop",
		renderTarget = "prop_clubhouse_laptop_square_01a"
	},
	[`prop_tv_flat_01_screen`] = {
		label = "TV",
		renderTarget = "tvscreen"
	},
	[`hei_prop_hst_laptop`] = {
		label = "Laptop",
		renderTarget = "tvscreen"
	},
	[`hei_bank_heist_laptop`] = {
		label = "Laptop",
		renderTarget = "tvscreen"
	},
	[`hei_heist_str_avunitl_03`] = {
		label = "TV",
		renderTarget = "tvscreen"
	},
	[`xm_prop_x17dlc_monitor_wall_01a`] = {
		label = "Screen",
		renderTarget = "prop_x17dlc_monitor_wall_01a"
	},
	[`ch_prop_ch_tv_rt_01a`] = {
		label = "TV",
		renderTarget = "ch_tv_rt_01a"
	},
	[`apa_mp_h_str_avunits_04`] = {
		label = "TV",
		renderTarget = "tvscreen"
	},
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

-- DUI configuration
Config.dui = {}

-- The URL for the DUI server.
--
-- To host your own server:
-- 	git clone --branch gh-pages https://github.com/kibook/phonograph
Config.dui.url = "https://kibook.github.io/phonograph"

-- The screen width of the DUI browser
Config.dui.screenWidth = 1280

-- The screen height of the DUI browser.
Config.dui.screenHeight = 720

-- Prefix for commands
Config.commandPrefix = "phono"

-- Separator between prefix and command name
Config.commandSeparator = "_"
