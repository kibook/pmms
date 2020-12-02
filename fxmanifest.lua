fx_version 'adamant'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

files {
	'ui/index.html',
	'ui/style.css',
	'ui/script.js',
	'ui/chineserocks.ttf'
}

ui_page 'ui/index.html'

server_script 'server.lua'

client_script 'config.lua'
client_script 'client.lua'
