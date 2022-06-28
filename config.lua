Config = {}

-- Whether the game is RDR2 or GTA V
Config.isRDR = IsDuplicityVersion() and GetConvar("gamename", "gta5") == "rdr3" or not TerraingridActivate

-- Max distance at which inactive media player entities appear
Config.maxDiscoveryDistance = 30.0

-- Default sound attenuation multiplier when in the same room
Config.defaultSameRoomAttenuation = 4.0

-- Default sound attenuation multiplier when in a different room
Config.defaultDiffRoomAttenuation = 6.0

-- Default range where active media players are visible/audible
Config.defaultRange = 30.0

-- Maximum range that players can set
Config.maxRange = 200.0

-- Difference between the base volume in the same room and a different room
Config.defaultDiffRoomVolume = 0.25

-- Whether the filter options is enabled by default
Config.enableFilterByDefault = Config.isRDR

-- Default size for the NUI video screen
Config.defaultVideoSize = 30

-- Entity models that media can be played on.
--
-- Optional properties:
--
--	label
--		The label to use for this entity in the UI.
--
--	renderTarget
--		If specified, video will be displayed on the render target with DUI,
--		rather than in a floating screen above the entity.
--
--	filter
--		The default state of the filter for this type of entity.
--
--	attenuation
--		The default sound attenuation multipliers for this type of entity.
--
--	range
--		The default range for this type of entity
--
--	isVehicle
--		Whether to treat this type of entity as a vehicle, where being
--		outside the vehicle counts as a "different room". You may want
--		to set this for some vehicles with external speakers, so they
--		are treated like objects instead.
--
--		If not specified, this will be determined automatically based
--		on whether the entity is a vehicle or not.
--
-- Example:
--
-- 	[`p_phonograph01x`] = {
-- 		label = "Phonograph",
-- 		filter = true,
-- 		attenuation = {sameRoom = 4, diffRoom = 6},
-- 		range = 30
-- 	}
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
	[`prop_portable_hifi_01`] = {
		label = "Boombox"
	},
	[`prop_ghettoblast_01`] = {
		label = "Boombox"
	},
	[`prop_ghettoblast_02`] = {
		label = "Boombox"
	},
	[`prop_tapeplayer_01`] = {
		label = "Tape Player"
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
	[`v_res_j_radio`] = {
		label = "Radio"
	},
	[`v_res_fa_radioalrm`] = {
		label = "Alarm Clock"
	},
	[`prop_mp3_dock`] = {
		label = "MP3 Dock"
	},
	[`v_res_mm_audio`] = {
		label = "MP3 Dock"
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
	[`v_ilev_lest_bigscreen`] = {
		label = "Projector",
		renderTarget = "tvscreen"
	},
	[`v_ilev_mm_screen`] = {
		label = "Projector",
		renderTarget = "big_disp"
	},
	[`v_ilev_mm_screen2`] = {
		label = "Projector",
		renderTarget = "tvscreen"
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
	[`xm_prop_x17dlc_monitor_wall_01a`] = {
		label = "Screen",
		renderTarget = "prop_x17dlc_monitor_wall_01a"
	},
	[`ch_prop_ch_tv_rt_01a`] = {
		label = "TV",
		renderTarget = "ch_tv_rt_01a"
	},
	[`apa_mp_h_str_avunitl_01_b`] = {
		label = "TV",
		renderTarget = "tvscreen"
	},
	[`apa_mp_h_str_avunitl_04`] = {
		label = "TV",
		renderTarget = "tvscreen"
	},
	[`apa_mp_h_str_avunitm_01`] = {
		label = "TV",
		renderTarget = "tvscreen"
	},
	[`apa_mp_h_str_avunitm_03`] = {
		label = "TV",
		renderTarget = "tvscreen"
	},
	[`apa_mp_h_str_avunits_01`] = {
		label = "TV",
		renderTarget = "tvscreen"
	},
	[`apa_mp_h_str_avunits_04`] = {
		label = "TV",
		renderTarget = "tvscreen"
	},
	[`hei_heist_str_avunitl_03`] = {
		label = "TV",
		renderTarget = "tvscreen"
	},
	[`xs_prop_arena_screen_tv_01`] = {
		label = "TV",
		renderTarget = "screen_tv_01"
	},
	[`xs_prop_arena_bigscreen_01`] = {
		label = "Jumbotron",
		renderTarget = "bigscreen_01"
	},
	[`vw_prop_vw_arcade_01_screen`] = {
		label = "Arcade Machine",
		renderTarget = "arcade_01a_screen"
	},
	[`vw_prop_vw_arcade_02_screen`] = {
		label = "Arcade Machine",
		renderTarget = "arcade_02a_screen"
	},
	[`vw_prop_vw_arcade_02b_screen`] = {
		label = "Arcade Machine",
		renderTarget = "arcade_02b_screen"
	},
	[`vw_prop_vw_arcade_02c_screen`] = {
		label = "Arcade Machine",
		renderTarget = "arcade_02c_screen"
	},
	[`vw_prop_vw_arcade_02d_screen`] = {
		label = "Arcade Machine",
		renderTarget = "arcade_02d_screen"
	},
	[`vw_prop_vw_cinema_tv_01`] = {
		label = "TV",
		renderTarget = "tvscreen"
	},
	[`pbus2`] = {
		attenuation = {sameRoom = 1.5, diffRoom = 6},
		range = 100,
		isVehicle = false
	},
	[`blimp3`] = {
		attenuation = {sameRoom = 0.6, diffRoom = 6},
		range = 150,
		isVehicle = false
	},
}

-- The default model to use for default media players if none is specified.
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
-- 	Whether to apply the immersive filter.
--
-- video
-- 	If true and the media specified is a video, the video will be displayed
-- 	above the entity.
--
Config.presets = {
	--['1'] = {url = 'https://example.com/example.ogg', title = 'Example Preset', filter = true, video = false}
}

-- These media player entities will be automatically spawned (if they do not
-- exist) and can start playing something automatically when the resource
-- starts. When selecting one of these entities in the UI, certain settings,
-- such as attenuation and range, will be applied automatically.
--
-- Mandatory properties:
--
-- position
-- 	A vector3 giving the position of the entity.
--
-- Optional properties:
--
-- label
-- 	A name to use for the media player in the UI instead of the handle.
--
-- spawn
-- 	If true, a new entity will be spawned.
--
-- 	If false or omitted, an existing entity is expected to exist at the
-- 	x, y and z specified.
--
-- model
-- 	The entity model to use for the media player, if one is to be spawned.
--
-- rotation
-- 	A vector3 giving the rotation of the entity, if one is to be spawned.
--
-- invisible
-- 	If true, the entity will be made invisible.
--
-- url
-- 	The URL or preset name of music to start playing on this media player
-- 	when the resource starts. 'random' can be used to select a random
-- 	preset. If this is omitted, nothing will be played on the media player
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
-- 	Whether to apply the immersive filter to the music when using a URL.
-- 	If a preset is specified, the filter setting of the preset will be used
-- 	instead.
--
-- locked
-- 	If true, the media player can only be controlled by players with the
-- 	pmms.manage ace.
--
-- video
-- 	If true and the media specified is a video, the video will be displayed
-- 	above the entity. If a preset is specified, the video setting of the
-- 	preset will be used instead.
--
-- videoSize
-- 	The default size of the video screen above the entity.
--
-- muted
-- 	Whether or not the default media player is muted.
--
-- attenuation
-- 	The default sound attenuation multipliers used for this media player.
--
-- range
-- 	The default range used for this media player.
--
-- scaleform
-- 	If specified, video will be displayed on a separate 3D scaleform
-- 	screen. Scaleforms have the following properties:
--
--	name
--		The name of the scaleform (.gfx filename minus extension).
--
-- 	position
-- 		A vector3 for the coordinates of the top-left edge of the
-- 		scaleform.
--
-- 	rotation
-- 		A vector3 for the orientation of the scaleform.
--
-- 	scale
-- 		A vector3 for the size of the scaleform.
--
-- 	standalone
-- 		If true, then this scaleform is not associated with an object,
-- 		and can be used by itself.
--
-- 	attached
-- 		If true, the scaleform's position and rotation are relative
-- 		to the entity it is associated with (when not standalone).
--
Config.defaultMediaPlayers = {
	--[[
	{
		position = vector3(2071.527, -850.825, 43.399),
		label = "Example Media Player",
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
		videoSize = 30,
		muted = false,
		attenuation = {
			sameRoom = 4,
			diffRoom = 6
		},
		range = 30,
		scaleform = {
			position = vector3(153.9, -988.7, 36.9),
			rotation = vector3(0, 0, 20),
			scale = vector3(0.6, 0.344, 0),
			standalone = false,
			attached = false
		}
	}
	]]
}

-- Distance at which default media player entities spawn/despawn
Config.defaultMediaPlayerSpawnDistance = Config.maxRange + 10.0

-- DUI configuration
Config.dui = {}

-- DUI page URL configuration
Config.dui.urls = {}

-- The URL of the DUI page used for HTTPS links.
--
-- Most people can just use the default URL. If you do want to host your own
-- page, there are two options:
--
-- 	a. Using GitHub pages:
-- 		Fork https://github.com/kibook/pmms-dui on GitHub. You will
-- 		then have a page at https://<your username>.github.io/pmms-dui.
--
-- 	b. Using your own web server:
-- 		Clone https://github.com/kibook/pmms-dui and install on your
-- 		web server.
--
Config.dui.urls.https = "https://kibook.github.io/pmms-dui"

-- The URL of the DUI page used for HTTP links. If left unset, the internal DUI page is used.
--Config.dui.urls.http = ""

-- The screen width of the DUI browser
Config.dui.screenWidth = 1280

-- The screen height of the DUI browser.
Config.dui.screenHeight = 720

-- Time to wait on a connection to the DUI page.
Config.dui.timeout = 30000

-- Prefix for commands
Config.commandPrefix = "pmms"

-- Separator between prefix and command name
Config.commandSeparator = "_"

-- Audio visualizations users can select from.
--
-- Mandatory properties:
--
--	name
--		Name to display in the UI.
--
-- Optional properties:
--
-- 	type
-- 		If the key is not the type, this must be given.
--
-- 	stroke
--		The thickness of the lines that are drawn. Default is 2.
--
--	colors
--		A list of colours used in the visual. Any valid CSS colour is legal.
--
-- For more details: https://foobar404.github.io/Wave.js/#/
Config.audioVisualizations = {
	["bars"] = {
		name = "Bars"
	},
	["bars blocks"] = {
		name = "Blocky Bars"
	},
	["cubes"] = {
		name = "Cubes"
	},
	["dualbars"] = {
		name = "Dual Bars"
	},
	["dualbars blocks"] = {
		name = "Blocky Dual Bars"
	},
	["fireworks"] = {
		name = "Fireworks"
	},
	["flower"] = {
		name = "Flower"
	},
	["flower blocks"] = {
		name = "Blocky Flower"
	},
	["orbs"] = {
		name = "Orbs"
	},
	["ring"] = {
		name = "Ring"
	},
	["rings"] = {
		name = "Rings"
	},
	["round wave"] = {
		name = "Round Wave"
	},
	["shine"] = {
		name = "Shine"
	},
	["shine rings"] = {
		name = "Shine Rings"
	},
	["shockwave"] = {
		name = "Shockwave"
	},
	["star"] = {
		name = "Star"
	},
	["static"] = {
		name = "Static"
	},
	["stitches"] = {
		name = "Stitches"
	},
	["web"] = {
		name = "Web"
	},
	["wave"] = {
		name = "Wave"
	}
}

-- Whether to show errors and other notifications on-screen, or only in the console.
Config.showNotifications = true

-- How long on-screen notifications appear for, if enabled.
Config.notificationDuration = 5000

-- Allow using vehicles as media players. Enabled by default for GTA V, disabled for RDR2.
Config.allowPlayingFromVehicles = not Config.isRDR

-- Default gfx used for scaleforms
Config.defaultScaleformName = "pmms_texture_renderer"

-- Automatically disable static emitters when media is playing
Config.autoDisableStaticEmitters = true

-- Automatically disable the idle cam when media is playing
Config.autoDisableIdleCam = true

-- Automatically disable a vehicle's radio when media is playing on it
Config.autoDisableVehicleRadio = true

-- Allowed URL patterns for players without pmms.anyUrl
Config.allowedUrls = {
	"^https?://w?w?w?%.?youtube.com/.*$",
	"^https?://w?w?w?%.?youtu.be/.*$",
	"^https?://w?w?w?%.?twitch.tv/.*$"
}
