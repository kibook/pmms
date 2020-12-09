fx_version 'adamant'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

shared_scripts {
	'config.lua',
	'common.lua'
}

server_script 'server.lua'

files {
	'ui/index.html',
	'ui/style.css',
	'ui/script.js',
	'ui/jsmediatags.min.js',
	'ui/chineserocks.ttf',
	'ui/loading.svg'
}

ui_page 'ui/index.html'

client_script 'client.lua'
