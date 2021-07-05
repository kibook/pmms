const minVolumeFactor = 1.0;
const maxVolumeFactor = 4.0;

const maxTimeDifference = 2;

var isRDR = true;

function sendMessage(name, params) {
	return fetch('https://pmms/' + name, {
		method: 'POST',
		headers: {
			'Content-Type': 'application/json'
		},
		body: JSON.stringify(params)
	});
}

function applyPhonographFilter(player) {
	var context = new (window.AudioContext || window.webkitAudioContext)();

	var source;

	if (player.youTubeApi) {
		var html5Player = player.youTubeApi.getIframe().contentWindow.document.querySelector('.html5-main-video');

		source = context.createMediaElementSource(html5Player);
	} else if (player.hlsPlayer) {
		source = context.createMediaElementSource(player.hlsPlayer.media);
	} else if (player.originalNode) {
		source = context.createMediaElementSource(player.originalNode);
	} else {
		source = context.createMediaElementSource(player);
	}

	if (source) {
		var splitter = context.createChannelSplitter(2);
		var merger = context.createChannelMerger(2);

		var gainNode = context.createGain();
		gainNode.gain.value = 0.5;

		var lowpass = context.createBiquadFilter();
		lowpass.type = 'lowpass';
		lowpass.frequency.value = 3000;
		lowpass.gain.value = -1;

		var highpass = context.createBiquadFilter();
		highpass.type = 'highpass';
		highpass.frequency.value = 300;
		highpass.gain.value = -1;

		source.connect(splitter);
		splitter.connect(merger, 0, 0);
		splitter.connect(merger, 1, 0);
		splitter.connect(merger, 0, 1);
		splitter.connect(merger, 1, 1);
		merger.connect(gainNode);
		gainNode.connect(lowpass);
		lowpass.connect(highpass);
		highpass.connect(context.destination);
	}

	var noise = document.createElement('audio');
	noise.id = player.id + '_noise';
	noise.src = 'https://redm.khzae.net/phonograph/noise.webm';
	noise.volume = 0;
	document.body.appendChild(noise);
	noise.play();

	player.style.filter = 'sepia()';

	player.addEventListener('play', event => {
		noise.play();
	});
	player.addEventListener('pause', event => {
		noise.pause();
	});
	player.addEventListener('volumechange', event => {
		noise.volume = player.volume;
	});
	player.addEventListener('seeked', event => {
		noise.currentTime = player.currentTime;
	});
}

function applyRadioFilter(player) {
	var context = new (window.AudioContext || window.webkitAudioContext)();

	var source;

	if (player.youTubeApi) {
		var html5Player = player.youTubeApi.getIframe().contentWindow.document.querySelector('.html5-main-video');

		source = context.createMediaElementSource(html5Player);
	} else if (player.hlsPlayer) {
		source = context.createMediaElementSource(player.hlsPlayer.media);
	} else if (player.originalNode) {
		source = context.createMediaElementSource(player.originalNode);
	} else {
		source = context.createMediaElementSource(player);
	}

	if (source) {
		var splitter = context.createChannelSplitter(2);
		var merger = context.createChannelMerger(2);

		var gainNode = context.createGain();
		gainNode.gain.value = 0.5;

		var lowpass = context.createBiquadFilter();
		lowpass.type = 'lowpass';
		lowpass.frequency.value = 5000;
		lowpass.gain.value = -1;

		var highpass = context.createBiquadFilter();
		highpass.type = 'highpass';
		highpass.frequency.value = 200;
		highpass.gain.value = -1;

		source.connect(splitter);
		splitter.connect(merger, 0, 0);
		splitter.connect(merger, 1, 0);
		splitter.connect(merger, 0, 1);
		splitter.connect(merger, 1, 1);
		merger.connect(gainNode);
		gainNode.connect(lowpass);
		lowpass.connect(highpass);
		highpass.connect(context.destination);
	}
}

function showLoadingIcon() {
	document.getElementById('loading').style.display = 'block';
}

function hideLoadingIcon() {
	document.getElementById('loading').style.display = 'none';
}

function initPlayer(id, handle, url, title, volume, offset, loop, filter, locked, muted, attenuation, range, queue, coords) {
	var player = document.createElement('video');
	player.id = id;
	player.src = url;
	document.body.appendChild(player);

	new MediaElement(id, {
		error: function(media) {
			hideLoadingIcon();

			sendMessage('initError', {
				url: url
			});

			media.remove();
		},
		success: function(media, domNode) {
			media.className = 'player';

			media.phono = {};
			media.phono.initialized = false;
			media.phono.attenuationFactor = attenuation.max;
			media.phono.volumeFactor = maxVolumeFactor;

			media.volume = 0;

			media.addEventListener('error', event => {
				hideLoadingIcon();

				sendMessage('playError', {
					url: url
				});

				if (!media.phono.initialized) {
					media.remove();
				}
			});

			media.addEventListener('canplay', () => {
				if (media.phono.initialized) {
					return;
				}

				hideLoadingIcon();

				var duration;
				
				if (media.duration == NaN || media.duration == Infinity || media.duration == 0 || media.hlsPlayer) {
					offset = 0;
					duration = false;
					loop = false;
				} else {
					duration = media.duration;
				}

				if (media.youTubeApi) {
					title = media.youTubeApi.getVideoData().title;

					media.videoTracks = {length: 1};
				} else if (media.hlsPlayer) {
					media.videoTracks = media.hlsPlayer.videoTracks;
				} else {
					media.videoTracks = media.originalNode.videoTracks;
				}

				sendMessage('init', {
					handle: handle,
					url: url,
					title: title,
					volume: volume,
					offset: offset,
					duration: duration,
					loop: loop,
					filter: filter,
					locked: locked,
					video: true,
					videoSize: 50,
					muted: muted,
					attenuation: attenuation,
					range: range,
					queue: queue,
					coords: coords,
				});

				media.phono.initialized = true;

				media.play();
			});

			media.addEventListener('playing', () => {
				if (filter && !media.phono.filterAdded) {
					if (isRDR) {
						applyPhonographFilter(media);
					} else {
						applyRadioFilter(media);
					}
					media.phono.filterAdded = true;
				}
			});

			media.play();
		}
	});
}

function getPlayer(handle, url, title, volume, offset, loop, filter, locked, muted, attenuation, range, queue, coords) {
	var id = 'player_' + handle.toString(16);

	var player = document.getElementById(id);

	if (!player && url) {
		player = initPlayer(id, handle, url, title, volume, offset, loop, filter, locked, muted, attenuation, range, queue, coords);
	}

	return player;
}

function parseTimecode(timecode) {
	if (timecode.includes(':')) {
		var a = timecode.split(':');
		return parseInt(a[0]) * 3600 + parseInt(a[1]) * 60 + parseInt(a[2]);
	} else {
		return parseInt(timecode);
	}
}

function init(data) {
	if (data.url == '') {
		return;
	}

	showLoadingIcon();

	var offset = parseTimecode(data.offset);

	if (data.title) {
		getPlayer(data.handle, data.url, data.title, data.volume, offset, data.loop, data.filter, data.locked, data.muted, data.attenuation, data.range, data.queue, data.coords);
	} else{
		getPlayer(data.handle, data.url, data.url, data.volume, offset, data.loop, data.filter, data.locked, data.muted, data.attenuation, data.range, data.queue, data.coords);
	}
}

function play(handle) {
	var player = getPlayer(handle);
}

function stop(handle) {
	var player = getPlayer(handle);

	if (player) {
		var noise = document.getElementById(player.id + '_noise');
		if (noise) {
			noise.remove();
		}

		player.remove();
	}
}

function setAttenuationFactor(player, target) {
	if (player.phono.attenuationFactor > target) {
		player.phono.attenuationFactor -= 0.1;
	} else {
		player.phono.attenuationFactor += 0.1;
	}
}

function setVolumeFactor(player, target) {
	if (player.phono.volumeFactor > target) {
		player.phono.volumeFactor -= 0.1;
	} else {
		player.phono.volumeFactor += 0.1;
	}
}

function setVolume(player, target) {
	if (Math.abs(player.volume - target) > 0.1) {
		if (player.volume > target) {
			player.volume -= 0.05;
		} else{
			player.volume += 0.05;
		}
	}
}

function update(data) {
	var player = getPlayer(data.handle, data.url, data.title, data.volume, data.offset, data.loop, data.filter, data.locked, data.muted, data.attenuation, data.range, data.queue, data.coords);

	if (player) {
		if (data.paused || data.distance < 0 || data.distance > data.range) {
			if (!player.paused) {
				player.pause();
			}
		} else {
			if (data.sameRoom) {
				setAttenuationFactor(player, data.attenuation.min);
				setVolumeFactor(player, minVolumeFactor);
			} else {
				setAttenuationFactor(player, data.attenuation.max);
				setVolumeFactor(player, maxVolumeFactor);
			}

			if (player.readyState > 0) {
				var volume;

				if (data.muted) {
					volume = 0;
				} else {
					volume = (((100 - data.distance * player.phono.attenuationFactor) / 100) / player.phono.volumeFactor) * (data.volume / 100);
				}

				if (volume > 0) {
					if (data.distance > 100) {
						setVolume(player, volume);
					} else {
						player.volume = volume;
					}
				} else {
					player.volume = 0;
				}

				if (data.duration) {
					var currentTime = data.offset % player.duration;

					if (Math.abs(currentTime - player.currentTime) > maxTimeDifference) {
						player.currentTime = currentTime;
					}
				}

				if (player.paused) {
					player.play();
				}
			}
		}
	}
}

window.addEventListener('message', event => {
	switch (event.data.type) {
		case 'init':
			init(event.data);
			break;
		case 'play':
			play(event.data.handle);
			break;
		case 'stop':
			stop(event.data.handle);
			break;
		case 'update':
			update(event.data);
			break;
		case 'DuiBrowser:init':
			sendMessage('DuiBrowser:initDone', {handle: event.data.handle});
			break;
	}
});

window.addEventListener('load', () => {
	sendMessage('duiStartup', {}).then(resp => resp.json()).then(resp => {
		isRDR = resp.isRDR;
	});
});
