const maxTimeDifference = 2;
const tooltipDelay = 750;

var isRDR = true;
var defaultSameRoomAttenuation = 4.0;
var defaultDiffRoomAttenuation = 6.0;
var defaultDiffRoomVolume = 4.0;
var defaultRange = 50;
var defaultScaleformName = 'pmms_texture_renderer';
var defaultVideoSize = 30;
var audioVisualizations = {};
var currentServerEndpoint = '127.0.0.1:30120';

var tooltipsEnabled = true;

function sendMessage(name, params) {
	return fetch('https://' + GetParentResourceName() + '/' + name, {
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

function createAudioVisualization(player, visualization) {
        var waveCanvas = document.createElement('canvas');
        waveCanvas.id = player.id + '_visualization';
        waveCanvas.style.position = 'absolute';
        waveCanvas.style.top = '0';
        waveCanvas.style.left = '0';
        waveCanvas.style.width = '100%';
        waveCanvas.style.height = '100%';

        player.appendChild(waveCanvas);

        var html5Player;

        if (player.youTubeApi) {
                html5Player = player.youTubeApi.getIframe().contentWindow.document.querySelector('.html5-main-video');
        } else if (player.hlsPlayer) {
                html5Player = player.hlsPlayer.media;
        } else if (player.originalNode) {
                html5Player = player.originalNode;
        } else {
                html5Player = player;
        }

        if (!html5Player.id) {
                html5Player.id = player.id + '_html5Player';
        }

        html5Player.style.visibility = 'hidden';

		var doc = player.youTubeApi ? player.youTubeApi.getIframe().contentWindow.document : document;

		if (player.youTubeApi) {
			player.youTubeApi.getIframe().style.visibility = 'hidden';
		}

        var wave = new Wave();

	var options;

	if (visualization) {
		options = audioVisualizations[visualization] || {};

		if (options.type == undefined) {
			options.type = visualization;
		}
	} else {
		options = {type: 'cubes'}
	}

	options.skipUserEventsWatcher = true;
	options.elementDoc = doc;

        wave.fromElement(html5Player.id, waveCanvas.id, options);
}

function showLoadingIcon() {
	document.getElementById('loading').style.display = 'block';
}

function hideLoadingIcon() {
	document.getElementById('loading').style.display = 'none';
}

function resolveUrl(url) {
	if (url.startsWith('http://') || url.startsWith('https://')) {
		return url;
	} else {
		return 'http://' + currentServerEndpoint + '/pmms/media/' + url;
	}
}

function initPlayer(id, handle, options) {
	var player = document.createElement('video');
	player.id = id;
	player.src = resolveUrl(options.url);
	document.body.appendChild(player);

	new MediaElement(id, {
		error: function(media) {
			hideLoadingIcon();

			sendMessage('initError', {
				url: options.url,
				message: media.error.message
			});

			media.remove();
		},
		success: function(media, domNode) {
			media.className = 'player';

			media.pmms = {};
			media.pmms.initialized = false;
			media.pmms.attenuationFactor = options.attenuation.diffRoom;
			media.pmms.volumeFactor = options.diffRoomVolume;

			media.volume = 0;

			if (options.video) {
				media.style.display = 'block';
			} else {
				media.style.display = 'none';
			}

			media.addEventListener('error', event => {
				hideLoadingIcon();

				sendMessage('playError', {
					url: options.url,
					message: media.error.message
				});

				if (!media.pmms.initialized) {
					media.remove();
				}
			});

			media.addEventListener('canplay', () => {
				if (media.pmms.initialized) {
					return;
				}

				hideLoadingIcon();

				var duration;

				if (media.duration == NaN || media.duration == Infinity || media.duration == 0 || media.hlsPlayer) {
					options.offset = 0;
					options.duration = false;
					options.loop = false;
				} else {
					options.duration = media.duration;
				}

				if (media.youTubeApi) {
					options.title = media.youTubeApi.getVideoData().title;

					media.videoTracks = {length: 1};
				} else if (media.hlsPlayer) {
					media.videoTracks = media.hlsPlayer.videoTracks;
				} else {
					media.videoTracks = media.originalNode.videoTracks;
				}

				sendMessage('init', {
					handle: handle,
					options: options,
				});

				media.pmms.initialized = true;

				media.play();
			});

			media.addEventListener('playing', () => {
				if (options.filter && !media.pmms.filterAdded) {
					if (isRDR) {
						applyPhonographFilter(media);
					} else {
						applyRadioFilter(media);
					}
					media.pmms.filterAdded = true;
				}

				if (options.visualization && !media.pmms.visualizationAdded) {
					createAudioVisualization(media, options.visualization);
					media.pmms.visualizationAdded = true;
				}
			});

			media.play();
		}
	});
}

function getPlayer(handle, options) {
	if (handle == undefined) {
		return;
	}

	var id = 'player_' + handle.toString();

	var player = document.getElementById(id);

	if (!player && options && options.url) {
		player = initPlayer(id, handle, options);
	}

	return player;
}

function parseTimecode(timecode) {
	if (typeof timecode != "string") {
		return timecode;
	} else if (timecode.includes(':')) {
		var a = timecode.split(':');
		return parseInt(a[0]) * 3600 + parseInt(a[1]) * 60 + parseInt(a[2]);
	} else {
		return parseInt(timecode);
	}
}

function init(data) {
	if (data.options.url == '') {
		return;
	}

	showLoadingIcon();

	data.options.offset = parseTimecode(data.options.offset);

	if (!data.options.title) {
		data.options.title = data.options.url;
	}

	getPlayer(data.handle, data.options);
}

function play(handle) {
	var player = getPlayer(handle);
}

function pause(handle) {
	sendMessage('pause', {
		handle: handle
	});
}

function removePlayer(player) {
		let noise = document.getElementById(player.id + '_noise');

		if (noise) {
			noise.remove();
		}

		player.remove();
}

function stop(handle) {
	var player = getPlayer(handle);

	if (player) {
		removePlayer(player);
	}
}

function setAttenuationFactor(player, target) {
	if (player.pmms.attenuationFactor > target) {
		player.pmms.attenuationFactor -= 0.1;
	} else {
		player.pmms.attenuationFactor += 0.1;
	}
}

function setVolumeFactor(player, target) {
	if (player.pmms.volumeFactor > target) {
		player.pmms.volumeFactor -= 0.01;
	} else {
		player.pmms.volumeFactor += 0.01;
	}
}

function setVolume(player, target) {
	if (Math.abs(player.volume - target) > 0.1) {
		if (player.volume > target) {
			player.volume -= 0.05;
		} else {
			player.volume += 0.05;
		}
	}
}

function calculateFocalLength(fov) {
	const x = 43.266615300557;
	var f = x / 2 * Math.tan(Math.PI * fov / 360);
	return 1 / f * 50;
}

function update(data) {
	var player = getPlayer(data.handle, data.options);

	if (player) {
		if (data.options.paused || data.distance < 0 || data.distance > data.options.range) {
			if (!player.paused) {
				player.pause();
			}
		} else {
			if (data.sameRoom) {
				setAttenuationFactor(player, data.options.attenuation.sameRoom);
				setVolumeFactor(player, 1.0);
			} else {
				setAttenuationFactor(player, data.options.attenuation.diffRoom);
				setVolumeFactor(player, data.options.diffRoomVolume);
			}

			if (player.readyState > 0) {
				var volume;

				if (data.options.muted || data.volume == 0) {
					volume = 0;
				} else {
					volume = (((100 - data.distance * player.pmms.attenuationFactor) / 100) * player.pmms.volumeFactor) * (data.volume / 100);
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

				if (data.options.duration) {
					var currentTime = data.options.offset % player.duration;

					if (Math.abs(currentTime - player.currentTime) > maxTimeDifference) {
						player.currentTime = currentTime;
					}
				}

				if (player.paused) {
					player.play();
				}
			}
		}

		if (data.options.video && data.sameRoom && data.camDistance >= 0 && data.distance <= data.options.range) {
			var scale = calculateFocalLength(data.fov) / data.camDistance;
			var width = data.options.videoSize * scale;

			player.style.left = data.screenX * 100 + '%';
			player.style.top  = data.screenY * 100 + '%';
			player.style.width = width + 'vw';
			if (player.youTubeApi) {
				player.style.height = width * (9 / 16) + 'vw';
			}
			player.style.zIndex = Math.floor(data.camDistance * -1).toString();

			if (player.style.display == 'none') {
				player.style.display = 'block';
			}
		} else {
			if (player.style.display == 'block') {
				player.style.display = 'none';
			}
		}
	}
}

function lock(handle) {
	sendMessage('lock', {
		handle: handle
	});
}

function unlock(handle) {
	sendMessage('unlock', {
		handle: handle
	});
}

function enableVideo(handle) {
	sendMessage('enableVideo', {
		handle: handle
	});
}

function disableVideo(handle) {
	sendMessage('disableVideo', {
		handle: handle
	});
}

function mute(handle) {
	sendMessage('mute', {
		handle: handle
	});
}

function unmute(handle) {
	sendMessage('unmute', {
		handle: handle
	});
}

function copy(oldHandle) {
	var handleInput = document.getElementById('usable-media-players');

	var newHandle = parseInt(handleInput.value);

	sendMessage('copy', {
		oldHandle: oldHandle,
		newHandle: newHandle
	});
}

function setLoop(handle, loop) {
	sendMessage('setLoop', {
		handle: handle,
		loop: loop
	});
}

function timeToString(time) {
	var h = Math.floor(time / 60 / 60);
	var m = Math.floor(time / 60) % 60;
	var s = Math.floor(time) % 60;

	return String(h).padStart(2, '0') + ':' + String(m).padStart(2, '0') + ':' + String(s).padStart(2, '0');
}

function copyToClipboard(text) {
	var e = document.createElement('textarea');
	e.textContent = text;
	document.body.appendChild(e);

	var selection = document.getSelection();
	selection.removeAllRanges();

	e.select();
	document.execCommand('copy');

	selection.removeAllRanges();
	e.remove();
}

function createActiveMediaPlayerDiv(mediaPlayer, permissions, includeQueue) {
	var player = getPlayer(mediaPlayer.handle);

	var div = document.createElement('div');
	div.className = 'active-media-player';

	var mainDiv = document.createElement('div');
	mainDiv.className = 'active-media-player-main';

	var handleDiv = document.createElement('div');
	handleDiv.className = 'active-media-player-handle';

	if (mediaPlayer.label) {
		handleDiv.innerHTML = mediaPlayer.label;
	} else {
		handleDiv.innerHTML = mediaPlayer.handle.toString();
	}

	var distanceDiv = document.createElement('div');
	distanceDiv.className = 'active-media-player-distance';

	if (mediaPlayer.distance >= 0) {
		distanceDiv.innerHTML = Math.floor(mediaPlayer.distance) + 'm';
	} else {
		distanceDiv.innerHTML = '-';
	}

	var titleDiv = document.createElement('div');
	titleDiv.className = 'active-media-player-title';

	var titleSpan = document.createElement('span');
	titleSpan.innerHTML = mediaPlayer.info.title.substring(0, 47);

	var urlCopyButton = document.createElement('button');
	urlCopyButton.className = 'control-button';
	urlCopyButton.innerHTML = '<i class="fas fa-link"></i>';
	urlCopyButton.addEventListener('click', event => {
		copyToClipboard(mediaPlayer.info.url);
		sendMessage('notify', {
			text: 'URL copied to clipboard!'
		});
	});

	titleDiv.appendChild(titleSpan);
	titleDiv.appendChild(urlCopyButton);

	var timeDiv = document.createElement('div');
	timeDiv.className = 'active-media-player-time';

	var timeDisplayDiv = document.createElement('div');
	timeDisplayDiv.className = 'active-media-player-time-display';

	var timeInput = document.createElement('input');
	timeInput.type = 'range';

	if (mediaPlayer.info.duration) {
		timeInput.className = 'active-media-player-time-slider';

		timeInput.min = 0;
		timeInput.max = mediaPlayer.info.duration;
		timeInput.step = 1;
		timeInput.value = mediaPlayer.info.offset;
	} else {
		timeInput.className = 'active-media-player-time-slider disabled-range';
	}

	if (!mediaPlayer.canInteract || (mediaPlayer.info.locked && !permissions.manage) || !mediaPlayer.info.duration) {
		timeInput.disabled = true;
	} else {
		timeInput.addEventListener('input', event => {
			sendMessage('seekToTime', {
				handle: mediaPlayer.handle,
				offset: timeInput.value
			});
		});
	}

	timeDisplayDiv.appendChild(timeInput);

	var timeSpan = document.createElement('span');
	timeSpan.className = 'active-media-player-time-counter';
	if (mediaPlayer.info.duration) {
		timeSpan.innerHTML = timeToString(mediaPlayer.info.offset) + '/' + timeToString(mediaPlayer.info.duration);
	} else {
		timeSpan.innerHTML = timeToString(mediaPlayer.info.offset);
	}

	timeDisplayDiv.appendChild(timeSpan);

	var seekBackwardButton = document.createElement('button');
	seekBackwardButton.className = 'control-button';
	seekBackwardButton.innerHTML = '<i class="fas fa-backward"></i>';
	seekBackwardButton.addEventListener('click', event => {
		sendMessage('seekBackward', {
			handle: mediaPlayer.handle
		});
	});

	var seekForwardButton = document.createElement('button');
	seekForwardButton.className = 'control-button';
	seekForwardButton.innerHTML = '<i class="fas fa-forward"></i>';
	seekForwardButton.addEventListener('click', event => {
		sendMessage('seekForward', {
			handle: mediaPlayer.handle
		});
	});

	var nextButton = document.createElement('button');
	nextButton.className = 'control-button';
	nextButton.innerHTML = '<i class="fas fa-step-forward"></i>';
	if (mediaPlayer.info.queue.length < 1) {
		nextButton.disabled = true;
	} else {
		nextButton.addEventListener('click', event => {
			sendMessage('next', {
				handle: mediaPlayer.handle
			});
		});
	}

	if (!mediaPlayer.canInteract || (mediaPlayer.info.locked && !permissions.manage) || !mediaPlayer.info.duration) {
		seekBackwardButton.disabled = true;
		seekForwardButton.disabled = true;
	}

	timeDiv.appendChild(seekBackwardButton);
	timeDiv.appendChild(timeDisplayDiv);
	timeDiv.appendChild(seekForwardButton);
	timeDiv.appendChild(nextButton);

	var videoSizeDiv = document.createElement('div');
	videoSizeDiv.className = 'active-media-player-video-size';
	if (mediaPlayer.info.video && player && player.videoTracks && player.videoTracks.length > 0) {
		var videoSizeDecreaseButton = document.createElement('button');
		videoSizeDecreaseButton.className = 'control-button';
		videoSizeDecreaseButton.innerHTML = '<i class="fas fa-minus"></i>';
		videoSizeDecreaseButton.addEventListener('click', event => {
			sendMessage('decreaseVideoSize', {
				handle: mediaPlayer.handle
			});
		});

		var videoSizeSpan = document.createElement('span');
		videoSizeSpan.innerHTML = mediaPlayer.info.videoSize;

		var videoSizeIncreaseButton = document.createElement('button');
		videoSizeIncreaseButton.className = 'control-button';
		videoSizeIncreaseButton.innerHTML = '<i class="fas fa-plus"></i>';
		videoSizeIncreaseButton.addEventListener('click', event => {
			sendMessage('increaseVideoSize', {
				handle: mediaPlayer.handle
			});
		});

		videoSizeDiv.appendChild(videoSizeDecreaseButton);
		videoSizeDiv.appendChild(videoSizeSpan);
		videoSizeDiv.appendChild(videoSizeIncreaseButton);
	}

	var controlsDiv = document.createElement('div');
	controlsDiv.className = 'active-media-player-controls';

	var lockedButton = document.createElement('button');
	lockedButton.className = 'control-button';
	if (mediaPlayer.info.locked) {
		lockedButton.innerHTML = '<i class="fas fa-lock"></i>';
		lockedButton.addEventListener('click', event => {
			unlock(mediaPlayer.handle);
		});
	} else {
		lockedButton.innerHTML = '<i class="fas fa-unlock"></i>';
		lockedButton.addEventListener('click', event => {
			lock(mediaPlayer.handle);
		});
	}
	if (!permissions.manage) {
		lockedButton.disabled = true;
	}

	var copyButton = document.createElement('button');
	copyButton.className = 'control-button';
	copyButton.innerHTML = '<i class="fas fa-clone"></i>';
	copyButton.addEventListener('click', event => {
		copy(mediaPlayer.handle);
	});
	if (!mediaPlayer.canInteract || (mediaPlayer.info.locked && !permissions.manage)) {
		copyButton.disabled = true;
	}

	var loopButton = document.createElement('button');
	loopButton.className = 'control-button';
	if (mediaPlayer.info.loop) {
		loopButton.innerHTML = '<i class="fas fa-retweet"></i>';
	} else {
		loopButton.innerHTML = '<i class="fas fa-arrow-right"></i>';
	}
	loopButton.addEventListener('click', event => {
		setLoop(mediaPlayer.handle, !mediaPlayer.info.loop);
	});
	if (!mediaPlayer.canInteract || (mediaPlayer.info.locked && !permissions.manage) || !mediaPlayer.info.duration) {
		loopButton.disabled = true;
	}

	var videoButton = document.createElement('button');
	videoButton.className = 'control-button';
	if (player && player.videoTracks && player.videoTracks.length > 0) {
		if (mediaPlayer.info.video) {
			videoButton.innerHTML = '<i class="fas fa-video"></i>';
			videoButton.addEventListener('click', event => {
				disableVideo(mediaPlayer.handle);
			});
		} else {
			videoButton.innerHTML = '<i class="fas fa-video-slash"></i>';
			videoButton.addEventListener('click', event => {
				enableVideo(mediaPlayer.handle);
			});
		}
	} else {
		videoButton.innerHTML = '<i class="fas fa-video-slash"></i>';
		videoButton.disabled = true;
	}
	if (!mediaPlayer.canInteract || (mediaPlayer.info.locked && !permissions.manage)) {
		videoButton.disabled = true;
	}

	var muteButton = document.createElement('button');
	muteButton.className = 'control-button';
	if (mediaPlayer.info.muted) {
		muteButton.innerHTML = '<i class="fas fa-volume-mute"></i>';
		muteButton.addEventListener('click', event => {
			unmute(mediaPlayer.handle);
		});
	} else {
		muteButton.innerHTML = '<i class="fas fa-volume-up"></i>';
		muteButton.addEventListener('click', event => {
			mute(mediaPlayer.handle);
		});
	}
	if (!mediaPlayer.canInteract || (mediaPlayer.info.locked && !permissions.manage)) {
		muteButton.disabled = true;
	}

	var pauseResumeButton = document.createElement('button');
	pauseResumeButton.className = 'control-button';
	if (mediaPlayer.info.paused) {
		pauseResumeButton.innerHTML = '<i class="fas fa-play"></i>';
	} else {
		pauseResumeButton.innerHTML = '<i class="fas fa-pause"></i>';
	}
	pauseResumeButton.addEventListener('click', event => {
		pause(mediaPlayer.handle);
	});
	if (!mediaPlayer.canInteract || (mediaPlayer.info.locked && !permissions.manage) || !mediaPlayer.info.duration) {
		pauseResumeButton.disabled = true;
	}

	var stopButton = document.createElement('button');
	stopButton.className = 'control-button';
	stopButton.innerHTML = '<i class="fas fa-stop"></i>';
	stopButton.addEventListener('click', event => {
		sendMessage('stop', {
			handle: mediaPlayer.handle
		});
	});
	if (!mediaPlayer.canInteract || (mediaPlayer.info.locked && !permissions.manage)) {
		stopButton.disabled = true;
	}

	controlsDiv.appendChild(lockedButton);
	controlsDiv.appendChild(copyButton);
	controlsDiv.appendChild(loopButton);
	controlsDiv.appendChild(videoButton);
	controlsDiv.appendChild(muteButton);
	controlsDiv.appendChild(pauseResumeButton);
	controlsDiv.appendChild(stopButton);

	mainDiv.appendChild(handleDiv);
	mainDiv.appendChild(distanceDiv);
	mainDiv.appendChild(titleDiv);
	mainDiv.appendChild(timeDiv);
	mainDiv.appendChild(videoSizeDiv);
	mainDiv.appendChild(controlsDiv);

	div.appendChild(mainDiv);

	if (includeQueue && mediaPlayer.info.queue.length > 0) {
		var queueDiv = document.createElement('div');
		queueDiv.className = 'active-media-player-queue';

		var queueHeadDiv = document.createElement('div');
		queueHeadDiv.className = 'queue-head';
		queueHeadDiv.innerHTML = '<div>Queue</div><div><i class="fas fa-clock"></i></div><div><i class="fas fa-filter"></i></div><div><i class="fas fa-video"></i></div><div><i class="fas fa-signal"></i></div><div><i class="fas fa-user"></i></div><div></div>';

		var queueBodyDiv = document.createElement('div');
		queueBodyDiv.className = 'queue-body';

		for (let i = 0; i < mediaPlayer.info.queue.length; ++i) {
			var entry = mediaPlayer.info.queue[i];

			var urlDiv = document.createElement('div');
			urlDiv.innerHTML = entry.options.url.substring(0, 40);

			var offsetDiv = document.createElement('div');
			offsetDiv.innerHTML = entry.options.offset;

			var filterDiv = document.createElement('div');
			filterDiv.innerHTML = entry.options.filter ? '<i class="fas fa-check"></i>' : '<i class="fas fa-times"></i>';

			var videoDiv = document.createElement('div');
			videoDiv.innerHTML = entry.options.video ? '<i class="fas fa-check"></i>' : '<i class="fas fa-times"></i>';

			var visualizationDiv = document.createElement('div');
			if (entry.options.visualization) {
				var v = entry.options.visualization;
				if (audioVisualizations[v] && audioVisualizations[v].name) {
					visualizationDiv.innerHTML = audioVisualizations[v].name;
				} else {
					visualizationDiv.innerHTML = v;
				}
			} else {
				visualizationDiv.innerHTML = '<i class="fas fa-times"></i>';
			}

			var nameDiv = document.createElement('div');
			nameDiv.innerHTML = entry.name;

			var deleteButton = document.createElement('button');
			deleteButton.className = 'control-button';
			deleteButton.innerHTML = '<i class="fas fa-trash"></i>';
			deleteButton.addEventListener('click', event => {
				sendMessage('removeFromQueue', {
					handle: mediaPlayer.handle,
					index: i + 1
				});
			});

			queueBodyDiv.appendChild(urlDiv);
			queueBodyDiv.appendChild(offsetDiv);
			queueBodyDiv.appendChild(filterDiv);
			queueBodyDiv.appendChild(videoDiv);
			queueBodyDiv.appendChild(visualizationDiv);
			queueBodyDiv.appendChild(nameDiv);
			queueBodyDiv.appendChild(deleteButton);
		}

		queueDiv.appendChild(queueHeadDiv);
		queueDiv.appendChild(queueBodyDiv);

		div.appendChild(queueDiv);
	}

	return div;
}

function updateUi(data) {
	var activeMediaPlayers = JSON.parse(data.activeMediaPlayers);

	if (data.uiIsOpen) {
		var activeMediaPlayersDiv = document.getElementById('active-media-players');
		var queuesDiv = document.getElementById('queues');
		activeMediaPlayersDiv.innerHTML = '';
		activeMediaPlayers.forEach(mediaPlayer => {
			var div = createActiveMediaPlayerDiv(mediaPlayer, data.permissions, true);

			if (div) {
				activeMediaPlayersDiv.appendChild(div);
			}
		});

		var usableMediaPlayers = JSON.parse(data.usableMediaPlayers);
		var presets = JSON.parse(data.presets);

		var usableMediaPlayersSelect = document.getElementById('usable-media-players');
		var presetSelect = document.getElementById('preset');
		var urlInput = document.getElementById('url');
		var volumeInput = document.getElementById('volume');
		var offsetInput = document.getElementById('offset');
		var loopCheckbox = document.getElementById('loop');
		var filterCheckbox = document.getElementById('filter');
		var lockedCheckbox = document.getElementById('locked');
		var videoCheckbox = document.getElementById('video');
		var videoSizeInput = document.getElementById('video-size');
		var mutedInput = document.getElementById('muted');
		var playButton = document.getElementById('play-button');
		var visualizationSelect = document.getElementById('visualization');
		var sameRoomAttenuationInput = document.getElementById('same-room-attenuation');
		var diffRoomAttenuationInput = document.getElementById('diff-room-attenuation');
		var diffRoomVolumeInput = document.getElementById('diff-room-volume');
		var rangeInput = document.getElementById('range');
		var isVehicleCheckbox = document.getElementById('is-vehicle');
		var scaleformCheckbox = document.getElementById('scaleform');
		var saveButton = document.getElementById('save');
		var deleteButton = document.getElementById('delete');
		var revertButton = document.getElementById('revert-settings');

		var usableMediaPlayersValue = usableMediaPlayersSelect.value;
		var presetValue = presetSelect.value;

		var presetKeys = Object.keys(presets).sort();

		if (presetKeys.length > 0) {
			if (data.permissions.customUrl) {
				presetSelect.innerHTML = '<option value="">&#xf0c1; Custom URL</option>';
			} else {
				presetSelect.innerHTML = '';
			}

			if (presetValue == 'random') {
				presetSelect.innerHTML += '<option value="random" selected>&#xf522; Random</option>';
			} else {
				presetSelect.innerHTML += '<option value="random">&#xf522; Random</option>';
			}

			presetKeys.forEach(key => {
				var preset = presets[key];
				var option = document.createElement('option');

				option.value = key;

				if (preset.video) {
					option.innerHTML = '&#xf008; ' + preset.title;
				} else {
					option.innerHTML = '&#xf001; ' + preset.title;
				}

				if (key == presetValue) {
					option.selected = true;
				}

				presetSelect.appendChild(option);
			});

			presetSelect.style.visibility = 'visibile';
		} else {
			presetSelect.style.visibility = 'hidden';
			presetSelect.style.width = 0;
		}

		usableMediaPlayersSelect.innerHTML = '<option></option>';

		if ((!data.permissions.interact || usableMediaPlayers.length == 0) && !scaleformCheckbox.checked) {
			usableMediaPlayersSelect.disabled = true;
			presetSelect.disabled = true;
			urlInput.disabled = true;
			volumeInput.disabled = true;
			offsetInput.disabled = true;
			loopCheckbox.disabled = true;
			filterCheckbox.disabled = true;
			lockedCheckbox.disabled = true;
			visualizationSelect.disabled = true;
			sameRoomAttenuationInput.disabled = true;
			diffRoomAttenuationInput.disabled = true;
			diffRoomVolumeInput.disabled = true;
			rangeInput.disabled = true;
			isVehicleCheckbox.disabled = true;
			deleteButton.disabled = true;
			revertButton.disabled = true;

			if (isRDR) {
				videoCheckbox.disabled = true;
				videoSizeInput.disabled = true;
			}

			mutedInput.disabled = true;
			playButton.disabled = true;
		} else {
			usableMediaPlayers.forEach(mediaPlayer => {
				var option = document.createElement('option');

				option.value = mediaPlayer.handle;

				if (mediaPlayer.active) {
					option.innerHTML = '&#xf144; ';
				} else {
					option.innerHTML = '';
				}

				if (mediaPlayer.label) {
					option.innerHTML += mediaPlayer.label + ' (' + Math.floor(mediaPlayer.distance) + 'm)';
				} else {
					option.innerHTML += mediaPlayer.handle.toString() + ' (' + Math.floor(mediaPlayer.distance) + 'm)';
				}

				if (mediaPlayer.handle == usableMediaPlayersValue) {
					option.selected = true;
				}

				if (mediaPlayer.standaloneScaleform) {
					option.setAttribute("data-standalone-scaleform", "true");
				}

				if (mediaPlayer.coords) {
					option.setAttribute("data-coords-x", mediaPlayer.coords.x);
					option.setAttribute("data-coords-y", mediaPlayer.coords.y);
					option.setAttribute("data-coords-z", mediaPlayer.coords.z);
				}

				usableMediaPlayersSelect.appendChild(option);
			});

			if (presetSelect.value == '') {
				urlInput.disabled = false;
				filterCheckbox.disabled = false;

				if (isRDR) {
					videoCheckbox.disabled = false;
					videoSizeInput.disabled = false;
				}
			} else {
				urlInput.disabled = true;
				filterCheckbox.disabled = true;

				if (isRDR) {
					if (visualizationSelect.value == '') {
						videoCheckbox.disabled = true;

						if (presets[presetSelect.value] && presets[presetSelect.value].video) {
							videoSizeInput.disabled = false;
							videoCheckbox.checked = true;
						} else {
							videoSizeInput.disabled = true;
							videoCheckbox.checked = false;
						}
					} else {
						videoCheckbox.disabled = false;
						videoSizeInput.disabled = false;
					}
				}
			}

			if (data.permissions.manage) {
				lockedCheckbox.disabled = false;

				saveButton.disabled = false;
			} else {
				lockedCheckbox.checked = false;
				lockedCheckbox.disabled = true;

				saveButton.disabled = true;
			}

			if (data.permissions.manage && usableMediaPlayersSelect.value != '') {
				deleteButton.disabled = false;
			} else {
				deleteButton.disabled = true;
			}

			if (usableMediaPlayers.length > 0) {
				usableMediaPlayersSelect.disabled = false;
			}
			presetSelect.disabled = false;
			volumeInput.disabled = false;
			offsetInput.disabled = false;
			loopCheckbox.disabled = false;
			mutedInput.disabled = false;
			visualizationSelect.disabled = false;
			sameRoomAttenuationInput.disabled = false;
			diffRoomAttenuationInput.disabled = false;
			diffRoomVolumeInput.disabled = false;
			rangeInput.disabled = false;
			isVehicleCheckbox.disabled = false;
			revertButton.disabled = false;

			if ((usableMediaPlayersSelect.value == '' && !scaleformCheckbox.checked) || (presetSelect.value == '' && urlInput.value == '')) {
				playButton.disabled = true;
			} else {
				playButton.disabled = false;
			}

			if (isRDR) {
				if (videoCheckbox.checked) {
					videoSizeInput.style.display = 'inline-block';
				} else {
					videoSizeInput.style.display = 'none';
				}
			}
		}

		if (data.permissions.customUrl) {
			urlInput.style.display = 'inline-block';
			urlInput.parentNode.style.pointerEvents = null;
			document.getElementById('filter-container').style.display = 'inline-block';
		} else {
			urlInput.style.display = 'none';
			urlInput.parentNode.style.pointerEvents = 'none';
			document.getElementById('filter-container').style.display = 'none';
		}

		document.getElementById('base-volume').innerHTML = data.baseVolume;
		document.getElementById('set-base-volume').value = data.baseVolume;
	}

	var statusDiv = document.getElementById('status');
	statusDiv.innerHTML = '';
	for (i = 0; i < activeMediaPlayers.length; ++i) {
		if (activeMediaPlayers[i].distance >= 0 && activeMediaPlayers[i].distance <= activeMediaPlayers[i].info.range) {
			var div = createActiveMediaPlayerDiv(activeMediaPlayers[i], data.permissions, false);

			if (div) {
				statusDiv.appendChild(div);
				break;
			}
		}
	}
}

function showUi() {
	document.getElementById('ui').style.display = 'flex';

	document.getElementById('tooltips').style.display = 'block';
}

function hideUi() {
	document.getElementById('ui').style.display = 'none';

	document.getElementById('tooltips').style.display = 'none';
	document.querySelectorAll('.tooltip').forEach(hideTooltip);
}

function toggleStatus() {
	var statusDiv = document.getElementById('status');

	if (statusDiv.style.display == 'grid') {
		statusDiv.style.display = 'none';
	} else {
		statusDiv.style.display = 'grid';
	}
}

function getScaleformSettings(standalone) {
	var nameInput = document.getElementById('scaleform-name');
	var posXInput = document.getElementById('scaleform-position-x');
	var posYInput = document.getElementById('scaleform-position-y');
	var posZInput = document.getElementById('scaleform-position-z');
	var rotXInput = document.getElementById('scaleform-rotation-x');
	var rotYInput = document.getElementById('scaleform-rotation-y');
	var rotZInput = document.getElementById('scaleform-rotation-z');
	var scaleXInput = document.getElementById('scaleform-scale-x');
	var scaleYInput = document.getElementById('scaleform-scale-y');
	var scaleZInput = document.getElementById('scaleform-scale-z');
	var attachedInput = document.getElementById('scaleform-attached');

	var name = nameInput.value;
	var posX = parseFloat(posXInput.value);
	var posY = parseFloat(posYInput.value);
	var posZ = parseFloat(posZInput.value);
	var rotX = parseFloat(rotXInput.value);
	var rotY = parseFloat(rotYInput.value);
	var rotZ = parseFloat(rotZInput.value);
	var scaleX = parseFloat(scaleXInput.value);
	var scaleY = parseFloat(scaleYInput.value);
	var scaleZ = parseFloat(scaleZInput.value);
	var attached = attachedInput.checked;

	if (name == '') {
		name = null;
	}

	if (isNaN(posX)) {
		posX = 0;
	}

	if (isNaN(posY)) {
		posY = 0;
	}

	if (isNaN(posZ)) {
		posZ = 0;
	}

	if (isNaN(rotX)) {
		rotX = 0;
	}

	if (isNaN(rotY)) {
		rotY = 0;
	}

	if (isNaN(rotZ)) {
		rotZ = 0;
	}

	if (isNaN(scaleX)) {
		scaleX = 0;
	}

	if (isNaN(scaleY)) {
		scaleY = 0;
	}

	if (isNaN(scaleZ)) {
		scaleZ = 0;
	}

	return {
		name: name,
		position: {
			x: posX,
			y: posY,
			z: posZ
		},
		rotation: {
			x: rotX,
			y: rotY,
			z: rotZ
		},
		scale: {
			x: scaleX,
			y: scaleY,
			z: scaleZ
		},
		standalone: standalone,
		attached: attached
	};
}

function startMediaPlayer() {
	var handleInput = document.getElementById('usable-media-players');
	var presetSelect = document.getElementById('preset');
	var urlInput = document.getElementById('url');
	var volumeInput = document.getElementById('volume');
	var offsetInput = document.getElementById('offset');
	var loopCheckbox = document.getElementById('loop');
	var filterCheckbox = document.getElementById('filter');
	var lockedCheckbox = document.getElementById('locked');
	var videoCheckbox = document.getElementById('video');
	var videoSizeInput = document.getElementById('video-size');
	var mutedInput = document.getElementById('muted');
	var sameRoomAttenuationInput = document.getElementById('same-room-attenuation');
	var diffRoomAttenuationInput = document.getElementById('diff-room-attenuation');
	var diffRoomVolumeInput = document.getElementById('diff-room-volume');
	var rangeInput = document.getElementById('range');
	var visualizationSelect = document.getElementById('visualization');
	var isVehicleCheckbox = document.getElementById('is-vehicle');
	var scaleformCheckbox = document.getElementById('scaleform');

	var handle = parseInt(handleInput.value);

	var url;
	if (presetSelect.value == '') {
		url = urlInput.value;
	} else {
		url = presetSelect.value;
	}

	var volume = parseInt(volumeInput.value);
	var offset = offsetInput.value;
	var loop = loopCheckbox.checked;
	var filter = filterCheckbox.checked;
	var locked = lockedCheckbox.checked;
	var video = videoCheckbox.checked;
	var videoSize = parseInt(videoSizeInput.value);
	var muted = mutedInput.checked;
	var sameRoomAttenuation = parseFloat(sameRoomAttenuationInput.value);
	var diffRoomAttenuation = parseFloat(diffRoomAttenuationInput.value);
	var diffRoomVolume = parseFloat(diffRoomVolumeInput.value);
	var range = parseFloat(rangeInput.value);
	var visualization = visualizationSelect.value;
	var isVehicle = isVehicleCheckbox.checked;

	var scaleform;

	var standaloneScaleform = handleInput.options[handleInput.selectedIndex].getAttribute("data-standalone-scaleform") == "true";

	if (scaleformCheckbox.checked || standaloneScaleform) {
		scaleform = getScaleformSettings(standaloneScaleform);
	}

	if (isNaN(volume)) {
		volume = 100;
	}

	if (isNaN(videoSize)) {
		videoSize = defaultVideoSize;
	}

	if (isNaN(sameRoomAttenuation)) {
		sameRoomAttenuation = defaultSameRoomAttenuation;
	}

	if (isNaN(diffRoomAttenuation)) {
		diffRoomAttenuation = defaultDiffRoomAttenuation;
	}

	if (isNaN(diffRoomVolume)) {
		diffRoomVolume = defaultDiffRoomVolume;
	}

	if (isNaN(range)) {
		range = defaultRange;
	}

	if (visualization == '') {
		visualization = null
	} else {
		video = true;
		filter = false;
	}

	if (standaloneScaleform) {
		handle = null;
	}

	sendMessage('play', {
		handle: handle,
		options: {
			url: url,
			volume: volume,
			offset: offset,
			loop: loop,
			filter: filter,
			locked: locked,
			video: video,
			videoSize: videoSize,
			muted: muted,
			attenuation: {
				sameRoom: sameRoomAttenuation,
				diffRoom: diffRoomAttenuation
			},
			diffRoomVolume: diffRoomVolume,
			range: range,
			visualization: visualization,
			isVehicle: isVehicle,
			scaleform: scaleform
		}
	});
}

function makeElementDraggable(element, dragPoint) {
	var pos1 = 0;
	var pos2 = 0;
	var pos3 = 0;
	var pos4 = 0;

	dragPoint.onmousedown = startDraggingElement;

	function startDraggingElement(e) {
		e.preventDefault();
		pos3 = e.clientX;
		pos4 = e.clientY;
		document.onmouseup = stopDraggingElement;
		document.onmousemove = dragElement;
	}

	function dragElement(e) {
		e.preventDefault();
		pos1 = pos3 - e.clientX;
		pos2 = pos4 - e.clientY;
		pos3 = e.clientX;
		pos4 = e.clientY;
		element.style.top  = (element.offsetTop  - pos2) + "px";
		element.style.left = (element.offsetLeft - pos1) + "px";
	}

	function stopDraggingElement() {
		document.onmouseup = null;
		document.onmousemove = null;
	}
}

function setMediaPlayerDefaults(handle) {
	sendMessage('setMediaPlayerDefaults', {
		handle: handle
	}).then(resp => resp.json()).then(resp => {
		document.getElementById('save-label').value = resp.label || '';

		if (resp.filter != undefined) {
			document.getElementById('filter').checked = resp.filter;
		}

		if (resp.volume) {
			document.getElementById('volume').value = resp.volume;
		} else {
			document.getElementById('volume').value = 100;
		}

		if (resp.attenuation) {
			document.getElementById('same-room-attenuation').value = resp.attenuation.sameRoom;
			document.getElementById('diff-room-attenuation').value = resp.attenuation.diffRoom;
		} else {
			document.getElementById('same-room-attenuation').value = defaultSameRoomAttenuation;
			document.getElementById('diff-room-attenuation').value = defaultDiffRoomAttenuation;
		}

		if (resp.diffRoomVolume) {
			document.getElementById('diff-room-volume').value = resp.diffRoomVolume;
		} else {
			document.getElementById('diff-room-volume').value = defaultDiffRoomVolume;
		}

		if (resp.range) {
			document.getElementById('range').value = resp.range;
		} else {
			document.getElementById('range').value = defaultRange;
		}

		document.getElementById('is-vehicle').checked = resp.isVehicle;

		if (resp.scaleform) {
			var scaleform = JSON.parse(resp.scaleform);
			document.getElementById('scaleform-name').value = scaleform.name;
			document.getElementById('scaleform-position-x').value = scaleform.position.x;
			document.getElementById('scaleform-position-y').value = scaleform.position.y;
			document.getElementById('scaleform-position-z').value = scaleform.position.z;
			document.getElementById('scaleform-rotation-x').value = scaleform.rotation.x;
			document.getElementById('scaleform-rotation-y').value = scaleform.rotation.y;
			document.getElementById('scaleform-rotation-z').value = scaleform.rotation.z;
			document.getElementById('scaleform-scale-x').value = scaleform.scale.x;
			document.getElementById('scaleform-scale-y').value = scaleform.scale.y;
			document.getElementById('scaleform-scale-z').value = scaleform.scale.z;
			document.getElementById('scaleform-attached').checked = scaleform.attached;

			document.getElementById('scaleform').checked = true;
			document.getElementById('scaleform-settings').style.display = 'grid';
		} else {
			document.getElementById('scaleform').checked = false;
			document.getElementById('scaleform-settings').style.display = 'none';
		}
	});
}

function saveSettings(method) {
	var usableMediaPlayers = document.getElementById('usable-media-players');

	var handle = parseInt(usableMediaPlayers.value);
	var model = document.getElementById('save-model').value;
	var renderTarget = document.getElementById('save-render-target').value;
	var label = document.getElementById('save-label').value;
	var filter = document.getElementById('filter').checked;
	var volume = parseInt(document.getElementById('volume').value);
	var sameRoomAttenuation = parseFloat(document.getElementById('same-room-attenuation').value);
	var diffRoomAttenuation = parseFloat(document.getElementById('diff-room-attenuation').value);
	var diffRoomVolume = parseFloat(document.getElementById('diff-room-volume').value);
	var range = parseFloat(document.getElementById('range').value);
	var isVehicle = document.getElementById('is-vehicle').checked;
	var scaleformEnabled = document.getElementById('scaleform').checked;

	var scaleform;

	var standaloneScaleform = usableMediaPlayers.options[usableMediaPlayers.selectedIndex].getAttribute("data-standalone-scaleform") == "true";

	if (scaleformEnabled || standaloneScaleform) {
		scaleform = getScaleformSettings(standaloneScaleform || isNaN(handle));
	}

	if (model == '') {
		model = null;
	}

	if (renderTarget == '') {
		renderTarget = null;
	}

	sendMessage('save', {
		handle: handle,
		method: method,
		model: model,
		renderTarget: renderTarget,
		label: label,
		filter: filter,
		volume: volume,
		attenuation: {
			sameRoom: sameRoomAttenuation,
			diffRoom: diffRoomAttenuation
		},
		diffRoomVolume: diffRoomVolume,
		range: range,
		isVehicle: isVehicle,
		scaleform: scaleform
	});
}

function updateSaveSettings(newModelMode) {
	if (newModelMode) {
		document.getElementById('save-model-container').style.display = 'block';
		document.getElementById('save-render-target-container').style.display = 'block';
		document.getElementById('save-server-model').style.display = 'none';
		document.getElementById('save-server-entity').style.display = 'none';
		document.getElementById('save-new-model').style.display = 'inline-block';
	} else {
		document.getElementById('save-model-container').style.display = 'none';
		document.getElementById('save-render-target-container').style.display = 'none';
		document.getElementById('save-server-model').style.display = 'inline-block';
		document.getElementById('save-server-entity').style.display = 'inline-block';
		document.getElementById('save-new-model').style.display = 'none';
	}
}

function showNotification(data) {
	let notification = document.createElement("div")
	notification.className = "notification";

	if (data.args.title) {
		let title = document.createElement("div");
		title.className = "title";
		title.innerHTML = data.args.title;
		notification.appendChild(title);
	}

	if (data.args.text) {
		let text = document.createElement("div");
		text.className = "text";

		text.innerHTML = data.args.text;

		if (data.args.color) {
			text.style.color = data.args.color;
		}

		notification.appendChild(text);
	}

	let notifications = document.querySelector(".notifications")
	notifications.appendChild(notification)

	setTimeout(() => notifications.removeChild(notification), data.args.duration);
}

function deleteSettings(method) {
	var usableMediaPlayers = document.getElementById('usable-media-players');

	var handle = parseInt(usableMediaPlayers.value);

	var coords;

	var selected = usableMediaPlayers.options[usableMediaPlayers.selectedIndex];

	if (selected) {
		var x = parseFloat(selected.getAttribute("data-coords-x"));
		var y = parseFloat(selected.getAttribute("data-coords-y"));
		var z = parseFloat(selected.getAttribute("data-coords-z"));

		if (!(isNaN(x) || isNaN(y) || isNaN(z))) {
			coords = {
				x: x,
				y: y,
				z: z
			}
		}
	}

	sendMessage('delete', {
		handle: handle,
		method: method,
		coords: coords
	});
}

function resetPlayers() {
	document.querySelectorAll('.player').forEach(player => removePlayer(player));
}

function showTooltip(tooltip, event) {
	document.querySelectorAll('.tooltip').forEach(hideTooltip);

	tooltip.style.top = event.pageY + 'px';
	tooltip.style.left = event.pageX + 'px';

	tooltip.style.display = 'block';
}

function hideTooltip(tooltip) {
	tooltip.style.display = 'none';
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
		case 'showUi':
			showUi();
			break;
		case 'hideUi':
			hideUi();
			break;
		case 'toggleStatus':
			toggleStatus();
			break;
		case 'updateUi':
			updateUi(event.data);
			break;
		case 'showNotification':
			showNotification(event.data);
			break;
		case 'reset':
			resetPlayers();
			break;
	}
});

window.addEventListener('load', () => {
	sendMessage('startup', {}).then(resp => resp.json()).then(resp => {
		isRDR = resp.isRDR;
		defaultSameRoomAttenuation = resp.defaultSameRoomAttenuation;
		defaultDiffRoomAttenuation = resp.defaultDiffRoomAttenuation;
		defaultDiffRoomVolume = resp.defaultDiffRoomVolume;
		defaultRange = resp.defaultRange;

		if (resp.currentServerEndpoint != undefined) {
			currentServerEndpoint = resp.currentServerEndpoint;
		}

		document.getElementById('filter').checked = resp.enableFilterByDefault;

		document.getElementById('same-room-attenuation').value = defaultSameRoomAttenuation;
		document.getElementById('diff-room-attenuation').value = defaultDiffRoomAttenuation;
		document.getElementById('diff-room-volume').value = defaultDiffRoomVolume;
		document.getElementById('video-size').value = defaultVideoSize;

		var rangeInput = document.getElementById('range');
		rangeInput.value = defaultRange;
		rangeInput.max = resp.maxRange;

		var visualizationSelect = document.getElementById('visualization');
		audioVisualizations = resp.audioVisualizations;
		var keys = Object.keys(audioVisualizations);
		keys.sort((a, b) => {
			return audioVisualizations[a].name < audioVisualizations[b].name;
		});
		keys.forEach(key => {
			var option = document.createElement('option');
			option.value = key;
			option.innerHTML = audioVisualizations[key].name;
			visualizationSelect.appendChild(option);
		});

		document.getElementById('scaleform-name').value = resp.defaultScaleformName;

		tooltipsEnabled = resp.tooltipsEnabled;
		document.getElementById('toggle-tips').checked = tooltipsEnabled;
	});

	var ui = document.getElementById('ui');
	makeElementDraggable(ui, document.getElementById('drag-top'));
	makeElementDraggable(ui, document.getElementById('drag-bottom'));

	document.getElementById('close-ui').addEventListener('click', function(event) {
		hideUi();
		sendMessage('closeUi', {});
	});

	document.getElementById('play-button').addEventListener('click', function(event) {
		startMediaPlayer();
	});

	document.querySelectorAll('.start-on-enter').forEach(e => e.addEventListener('keyup', function(event) {
		if (event.keyCode == 13) {
			event.preventDefault();
			startMediaPlayer();
		}
	}));

	document.getElementById('set-base-volume').addEventListener('input', function(event) {
		sendMessage('setBaseVolume', {
			volume: parseInt(this.value)
		});
	});

	document.getElementById('advanced-settings-button').addEventListener('click', function(event) {
		var advancedSettings = document.getElementById('advanced-settings');

		if (advancedSettings.style.display == 'grid') {
			advancedSettings.style.display = 'none';
		} else {
			advancedSettings.style.display = 'grid';
		}
	});

	document.getElementById('revert-settings').addEventListener('click', event => {
		document.getElementById('offset').value = '00:00:00';
		document.getElementById('visualization').value = null;

		var usableMediaPlayersSelect = document.getElementById('usable-media-players');
		if (usableMediaPlayersSelect.value != '') {
			setMediaPlayerDefaults(parseInt(usableMediaPlayersSelect.value));
		} else {
			document.getElementById('same-room-attenuation').value = defaultSameRoomAttenuation;
			document.getElementById('diff-room-attenuation').value = defaultDiffRoomAttenuation;
			document.getElementById('diff-room-volume').value = defaultDiffRoomVolume;
			document.getElementById('range').value = defaultRange;
			document.getElementById('volume').value = 100;
			document.getElementById('is-vehicle').checked = false;
		}
	});

	document.getElementById('restore-ui-position').addEventListener('click', event => {
		ui.style.top = '50vh';
		ui.style.left = '50vw';
	});

	document.getElementById('toggle-status').addEventListener('click', event => {
		sendMessage('toggleStatus');
	});

	document.getElementById('visualization').addEventListener('input', function(event) {
		if (this.value != '') {
			document.getElementById('filter').checked = false;

			if (isRDR) {
				document.getElementById('video').checked = true;
			}
		}
	});

	document.getElementById('usable-media-players').addEventListener('input', function(event) {
		if (this.value == '') {
			updateSaveSettings(!document.getElementById('scaleform').checked);
		} else {
			updateSaveSettings(false);
			setMediaPlayerDefaults(parseInt(this.value));
		}
	});

	document.getElementById('save').addEventListener('click', function(event) {
		updateSaveSettings(document.getElementById('usable-media-players').value == '' && !document.getElementById('scaleform').checked);
		document.getElementById('save-settings').style.display = 'grid';
	});

	document.querySelectorAll('.save-method').forEach(e => e.addEventListener('click', function(event) {
		saveSettings(this.getAttribute('data-save-method'));
		document.getElementById('save-settings').style.display = 'none';
	}));

	document.getElementById('save-cancel').addEventListener('click', function(event) {
		document.getElementById('save-settings').style.display = 'none';
	});

	document.getElementById('delete').addEventListener('click', function(event) {
		document.getElementById('delete-settings').style.display = 'grid';
	});

	document.querySelectorAll('.delete-method').forEach(e => e.addEventListener('click', function(event) {
		deleteSettings(this.getAttribute('data-delete-method'));
		document.getElementById('delete-settings').style.display = 'none';
	}));

	document.getElementById('delete-cancel').addEventListener('click', function(event) {
		document.getElementById('delete-settings').style.display = 'none';
	});

	document.getElementById('range').addEventListener('input', function(event) {
		var handle = parseInt(document.getElementById('usable-media-players').value);

		if (!isNaN(handle)) {
			sendMessage('setRange', {
				handle: handle,
				range: parseFloat(this.value)
			});
		}
	});

	document.querySelectorAll('.set-attenuation').forEach(e => e.addEventListener('input', function(event) {
		var handle = parseInt(document.getElementById('usable-media-players').value);

		if (!isNaN(handle)) {
			sendMessage('setAttenuation', {
				handle: handle,
				sameRoom: parseFloat(document.getElementById('same-room-attenuation').value),
				diffRoom: parseFloat(document.getElementById('diff-room-attenuation').value)
			});
		}
	}));

	document.getElementById('diff-room-volume').addEventListener('input', function(event) {
		var handle = parseInt(document.getElementById('usable-media-players').value);

		if (!isNaN(handle)) {
			sendMessage('setDiffRoomVolume', {
				handle: handle,
				diffRoomVolume: parseFloat(this.value)
			});
		}
	});

	document.getElementById('volume').addEventListener('input', function(event) {
		var handle = parseInt(document.getElementById('usable-media-players').value);

		if (!isNaN(handle)) {
			sendMessage('setVolume', {
				handle: handle,
				volume: parseInt(this.value)
			});
		}
	});

	document.getElementById('is-vehicle').addEventListener('input', function(event) {
		var handle = parseInt(document.getElementById('usable-media-players').value);

		if (!isNaN(handle)) {
			sendMessage('setIsVehicle', {
				handle: handle,
				isVehicle: this.checked
			});
		}
	});

	document.getElementById('scaleform').addEventListener('input', function(event) {
		document.getElementById('scaleform-settings').style.display = this.checked ? 'grid' : 'none';
	});

	document.getElementById('scaleform-auto-my-position').addEventListener('click', function(event) {
		sendMessage('getScaleformSettingsFromMyPosition').then(resp => resp.json()).then(resp => {
			var data = JSON.parse(resp);
			document.getElementById('scaleform-position-x').value = data.position.x;
			document.getElementById('scaleform-position-y').value = data.position.y;
			document.getElementById('scaleform-position-z').value = data.position.z;
			document.getElementById('scaleform-rotation-x').value = data.rotation.x;
			document.getElementById('scaleform-rotation-y').value = data.rotation.y;
			document.getElementById('scaleform-rotation-z').value = data.rotation.z;
			document.getElementById('scaleform-attached').checked = false;
		});
	});

	document.getElementById('scaleform-auto-entity').addEventListener('click', function(event) {
		var handle = parseInt(document.getElementById('usable-media-players').value);

		if (isNaN(handle)) {
			return;
		}

		sendMessage('getScaleformSettingsFromEntity', {
			handle: handle
		}).then(resp => resp.json()).then(resp => {
			var data = JSON.parse(resp);
			document.getElementById('scaleform-position-x').value = data.position.x;
			document.getElementById('scaleform-position-y').value = data.position.y;
			document.getElementById('scaleform-position-z').value = data.position.z;
			document.getElementById('scaleform-rotation-x').value = data.rotation.x;
			document.getElementById('scaleform-rotation-y').value = data.rotation.y;
			document.getElementById('scaleform-rotation-z').value = data.rotation.z;
			document.getElementById('scaleform-attached').checked = false;
		});
	});

	document.querySelectorAll('.scaleform-setting').forEach(e => e.addEventListener('input', function(event) {
		var handle = parseInt(document.getElementById('usable-media-players').value);

		if (isNaN(handle)) {
			return;
		}

		var scaleform = getScaleformSettings();

		sendMessage('setScaleform', {
			handle: handle,
			scaleform: scaleform
		}).then(resp => resp.json()).then(resp => {
			if (resp.scaleform) {
				document.getElementById('scaleform-position-x').value = resp.scaleform.position.x;
				document.getElementById('scaleform-position-y').value = resp.scaleform.position.y;
				document.getElementById('scaleform-position-z').value = resp.scaleform.position.z;
				document.getElementById('scaleform-rotation-x').value = resp.scaleform.rotation.x;
				document.getElementById('scaleform-rotation-y').value = resp.scaleform.rotation.y;
				document.getElementById('scaleform-rotation-z').value = resp.scaleform.rotation.z;
			}
		});
	}));

	document.getElementById('fix').addEventListener('click', function(event) {
		sendMessage('fix');
	});

	let tooltips = document.createElement('div');
	tooltips.id = 'tooltips';

	document.querySelectorAll(".tooltip").forEach(tooltip => {
		tooltip.parentNode.addEventListener('mouseover', function(event) {
			if (tooltipsEnabled) {
				let delay = setTimeout(() => {
					showTooltip(tooltip, event);
					this.onmouseout = () => hideTooltip(tooltip);
				}, tooltipDelay);

				this.onmouseout = () => clearTimeout(delay);
			}
		});

		tooltip.onmouseover = () => hideTooltip(tooltip);

		tooltips.appendChild(tooltip);
	});

	document.body.appendChild(tooltips);

	document.getElementById('toggle-tips').addEventListener('input', function(event) {
		tooltipsEnabled = this.checked;

		sendMessage('toggleTips', {
			enabled: this.checked
		});
	});
});
