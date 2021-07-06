const minVolumeFactor = 1.0;
const maxVolumeFactor = 4.0;

const maxTimeDifference = 2;

var isRDR = true;
var defaultMinAttenuation = 4.0;
var defaultMaxAttenuation = 6.0;
var defaultRange = 50;
var defaultVideoSize = 30;
var audioVisualizations = {};

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

function initPlayer(id, handle, url, title, volume, offset, loop, filter, locked, video, videoSize, muted, attenuation, range, visualization, queue, coords) {
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

			media.pmms = {};
			media.pmms.initialized = false;
			media.pmms.attenuationFactor = attenuation.max;
			media.pmms.volumeFactor = maxVolumeFactor;

			media.volume = 0;

			if (video) {
				media.style.display = 'block';
			} else {
				media.style.display = 'none';
			}

			media.addEventListener('error', event => {
				hideLoadingIcon();

				sendMessage('playError', {
					url: url
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
					video: video,
					videoSize: videoSize,
					muted: muted,
					attenuation: attenuation,
					range: range,
					visualization: visualization,
					queue: queue,
					coords: coords,
				});

				media.pmms.initialized = true;

				media.play();
			});

			media.addEventListener('playing', () => {
				if (filter && !media.pmms.filterAdded) {
					if (isRDR) {
						applyPhonographFilter(media);
					} else {
						applyRadioFilter(media);
					}
					media.pmms.filterAdded = true;
				}

				if (visualization && !media.pmms.visualizationAdded) {
					createAudioVisualization(media, visualization);
					media.pmms.visualizationAdded = true;
				}
			});

			media.play();
		}
	});
}

function getPlayer(handle, url, title, volume, offset, loop, filter, locked, video, videoSize, muted, attenuation, range, visualization, queue, coords) {
	var id = 'player_' + handle.toString(16);

	var player = document.getElementById(id);

	if (!player && url) {
		player = initPlayer(id, handle, url, title, volume, offset, loop, filter, locked, video, videoSize, muted, attenuation, range, visualization, queue, coords);
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
		getPlayer(data.handle, data.url, data.title, data.volume, offset, data.loop, data.filter, data.locked, data.video, data.videoSize, data.muted, data.attenuation, data.range, data.visualization, data.queue, data.coords);
	} else{
		getPlayer(data.handle, data.url, data.url, data.volume, offset, data.loop, data.filter, data.locked, data.video, data.videoSize, data.muted, data.attenuation, data.range, data.visualization, data.queue, data.coords);
	}
}

function play(handle) {
	var player = getPlayer(handle);
}

function pause(handle) {
	sendMessage('pause', {
		handle: handle
	});
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
	if (player.pmms.attenuationFactor > target) {
		player.pmms.attenuationFactor -= 0.1;
	} else {
		player.pmms.attenuationFactor += 0.1;
	}
}

function setVolumeFactor(player, target) {
	if (player.pmms.volumeFactor > target) {
		player.pmms.volumeFactor -= 0.1;
	} else {
		player.pmms.volumeFactor += 0.1;
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
	var player = getPlayer(data.handle, data.url, data.title, data.volume, data.offset, data.loop, data.filter, data.locked, data.video, data.videoSize, data.muted, data.attenuation, data.range, data.visualization, data.queue, data.coords);

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
					volume = (((100 - data.distance * player.pmms.attenuationFactor) / 100) / player.pmms.volumeFactor) * (data.volume / 100);
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

		if (data.video && data.sameRoom && data.camDistance >= 0 && data.distance <= data.range) {
			var scale = calculateFocalLength(data.fov) / data.camDistance;
			var width = data.videoSize * scale;

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

function createActiveMediaPlayerDiv(mediaPlayer, fullControls, includeQueue) {
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
		handleDiv.innerHTML = mediaPlayer.handle.toString(16);
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

		timeInput.addEventListener('input', event => {
			sendMessage('seekToTime', {
				handle: mediaPlayer.handle,
				offset: timeInput.value
			});
		});
	} else {
		timeInput.className = 'active-media-player-time-slider disabled-range';
		timeInput.disabled = true;
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

	if ((mediaPlayer.info.locked && !fullControls) || !mediaPlayer.info.duration) {
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
	if (!fullControls) {
		lockedButton.disabled = true;
	}

	var copyButton = document.createElement('button');
	copyButton.className = 'control-button';
	copyButton.innerHTML = '<i class="fas fa-clone"></i>';
	copyButton.addEventListener('click', event => {
		copy(mediaPlayer.handle);
	});
	if (mediaPlayer.info.locked && !fullControls) {
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
	if ((mediaPlayer.info.locked && !fullControls) || !mediaPlayer.info.duration) {
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
	if (mediaPlayer.info.locked && !fullControls) {
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
		muteButton.innerHTML = '<i class="fas fa-volume-off"></i>';
		muteButton.addEventListener('click', event => {
			mute(mediaPlayer.handle);
		});
	}
	if (mediaPlayer.info.locked && !fullControls) {
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
	if ((mediaPlayer.info.locked && !fullControls) || !mediaPlayer.info.duration) {
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
	if (mediaPlayer.info.locked && !fullControls) {
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
		queueHeadDiv.innerHTML = '<div>Queue</div><div><i class="fas fa-clock"></i></div><div><i class="fas fa-filter"></i></div><div><i class="fas fa-video"></i></div><div><i class="fas fa-user"></i></div><div></div>';

		var queueBodyDiv = document.createElement('div');
		queueBodyDiv.className = 'queue-body';

		for (let i = 0; i < mediaPlayer.info.queue.length; ++i) {
			var entry = mediaPlayer.info.queue[i];

			var urlDiv = document.createElement('div');
			urlDiv.innerHTML = entry.url.substring(0, 40);

			var offsetDiv = document.createElement('div');
			offsetDiv.innerHTML = entry.offset;

			var filterDiv = document.createElement('div');
			filterDiv.innerHTML = entry.filter ? '<i class="fas fa-check"></i>' : '<i class="fas fa-times"></i>';

			var videoDiv = document.createElement('div');
			videoDiv.innerHTML = entry.video ? '<i class="fas fa-check"></i>' : '<i class="fas fa-times"></i>';

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

	var activeMediaPlayersDiv = document.getElementById('active-media-players');
	var queuesDiv = document.getElementById('queues');
	activeMediaPlayersDiv.innerHTML = '';
	activeMediaPlayers.forEach(mediaPlayer => {
		var div = createActiveMediaPlayerDiv(mediaPlayer, data.fullControls, true);

		if (div) {
			activeMediaPlayersDiv.appendChild(div);
		}
	});

	var statusDiv = document.getElementById('status');
	statusDiv.innerHTML = '';
	for (i = 0; i < activeMediaPlayers.length; ++i) {
		if (activeMediaPlayers[i].distance >= 0 && activeMediaPlayers[i].distance <= activeMediaPlayers[i].info.range) {
			var div = createActiveMediaPlayerDiv(activeMediaPlayers[i], data.fullControls, false);

			if (div) {
				statusDiv.appendChild(div);
				break;
			}
		}
	}

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

	var usableMediaPlayersValue = usableMediaPlayersSelect.value;
	var presetValue = presetSelect.value;

	var presetKeys = Object.keys(presets).sort();

	if (presetKeys.length > 0) {
		if (data.anyUrl) {
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

	if (usableMediaPlayers.length == 0) {
		usableMediaPlayersSelect.disabled = true;
		presetSelect.disabled = true;
		urlInput.disabled = true;
		volumeInput.disabled = true;
		offsetInput.disabled = true;
		loopCheckbox.disabled = true;
		filterCheckbox.disabled = true;
		lockedCheckbox.disabled = true;
		videoCheckbox.disabled = true;
		videoSizeInput.disabled = true;
		mutedInput.disabled = true;
		playButton.disabled = true;
	} else {
		usableMediaPlayersSelect.innerHTML = '<option></option>';

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
				option.innerHTML += mediaPlayer.handle.toString(16) + ' (' + Math.floor(mediaPlayer.distance) + 'm)';
			}

			if (mediaPlayer.handle == usableMediaPlayersValue) {
				option.selected = true;
			}

			usableMediaPlayersSelect.appendChild(option);
		});

		if (presetSelect.value == '') {
			urlInput.disabled = false;
			filterCheckbox.disabled = false;
			videoCheckbox.disabled = false;
			videoSizeInput.disabled = false;
		} else {
			urlInput.disabled = true;
			filterCheckbox.disabled = true;
			videoCheckbox.disabled = true;

			if (presets[presetSelect.value] && presets[presetSelect.value].video) {
				videoSizeInput.disabled = false;
				videoCheckbox.checked = true;
			} else {
				videoSizeInput.disabled = true;
				videoCheckbox.checked = false;
			}
		}

		if (data.fullControls) {
			lockedCheckbox.disabled = false;
		} else {
			lockedCheckbox.checked = false
			lockedCheckbox.disabled = true;
		}

		usableMediaPlayersSelect.disabled = false;
		presetSelect.disabled = false;
		volumeInput.disabled = false;
		offsetInput.disabled = false;
		loopCheckbox.disabled = false;
		mutedInput.disabled = false;

		if (usableMediaPlayersSelect.value == '' || (presetSelect.value == '' && urlInput.value == '')) {
			playButton.disabled = true;
		} else {
			playButton.disabled = false;
		}

		if (videoCheckbox.checked) {
			videoSizeInput.style.display = 'inline-block';
		} else {
			videoSizeInput.style.display = 'none';
		}
	}

	if (data.anyUrl) {
		urlInput.style.display = 'inline-block';
		document.getElementById('filter-container').style.display = 'inline-block';
	} else {
		urlInput.style.display = 'none';
		document.getElementById('filter-container').style.display = 'none';
	}

	document.getElementById('base-volume').innerHTML = data.baseVolume;
	document.getElementById('set-base-volume').value = data.baseVolume;
}

function showUi() {
	document.getElementById('ui').style.display = 'flex';
}

function hideUi() {
	document.getElementById('ui').style.display = 'none';
}

function toggleStatus() {
	var statusDiv = document.getElementById('status');

	if (statusDiv.style.display == 'grid') {
		statusDiv.style.display = 'none';
	} else {
		statusDiv.style.display = 'grid';
	}
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
	var minAttenuationInput = document.getElementById('min-attenuation');
	var maxAttenuationInput = document.getElementById('max-attenuation');
	var rangeInput = document.getElementById('range');
	var visualizationSelect = document.getElementById('visualization');

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
	var minAttenuation = parseFloat(minAttenuationInput.value);
	var maxAttenuation = parseFloat(maxAttenuationInput.value);
	var range = parseFloat(rangeInput.value);
	var visualization = visualizationSelect.value;

	if (isNaN(volume)) {
		volume = 100;
	}

	if (isNaN(videoSize)) {
		videoSize = defaultVideoSize;
	}

	if (isNaN(minAttenuation)) {
		minAttenuation = defaultMinAttenuation;
	}

	if (isNaN(maxAttenuation)) {
		maxAttenuation = defaultMaxAttenuation;
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

	sendMessage('play', {
		handle: handle,
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
			min: minAttenuation,
			max: maxAttenuation
		},
		range: range,
		visualization: visualization
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
		if (resp.volume) {
			document.getElementById('volume').value = resp.volume;
		} else {
			document.getElementById('volume').value = 100;
		}

		if (resp.attenuation) {
			document.getElementById('min-attenuation').value = resp.attenuation.min;
			document.getElementById('max-attenuation').value = resp.attenuation.max;
		} else {
			document.getElementById('min-attenuation').value = defaultMinAttenuation;
			document.getElementById('max-attenuation').value = defaultMaxAttenuation;
		}

		if (resp.range) {
			document.getElementById('range').value = resp.range;
		} else {
			document.getElementById('range').value = defaultRange;
		}
	});
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
	}
});

window.addEventListener('load', () => {
	sendMessage('startup', {}).then(resp => resp.json()).then(resp => {
		isRDR = resp.isRDR;
		defaultMinAttenuation = resp.defaultMinAttenuation;
		defaultMaxAttenuation = resp.defaultMaxAttenuation;
		defaultRange = resp.defaultRange;

		document.getElementById('min-attenuation').value = defaultMinAttenuation;
		document.getElementById('max-attenuation').value = defaultMaxAttenuation;
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

	document.getElementById('start-media-player').addEventListener('keyup', function(event) {
		if (event.keyCode == 13) {
			event.preventDefault();
			startMediaPlayer();
		}
	});

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
			document.getElementById('min-attenuation').value = defaultMinAttenuation;
			document.getElementById('max-attenuation').value = defaultMaxAttenuation;
			document.getElementById('range').value = defaultRange;
			document.getElementById('volume').value = 100;
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
			document.getElementById('video').checked = true;
		}
	});

	document.getElementById('usable-media-players').addEventListener('input', function(event) {
		if (this.value != '') {
			setMediaPlayerDefaults(parseInt(this.value));
		}
	});
});