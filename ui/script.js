const minAttenuationFactor = 4.0;
const maxAttenuationFactor = 6.0;

const minVolumeFactor = 1.0;
const maxVolumeFactor = 4.0;

const maxTimeDifference = 2;

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

function showLoadingIcon() {
	document.getElementById('loading').style.display = 'block';
}

function hideLoadingIcon() {
	document.getElementById('loading').style.display = 'none';
}

function initPlayer(id, handle, url, title, volume, offset, loop, filter, locked, video, videoSize, muted, queue, coords) {
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
			media.phono.attenuationFactor = maxAttenuationFactor;
			media.phono.volumeFactor = maxVolumeFactor;

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

				if (media.duration == NaN || media.duration == Infinity || media.hlsPlayer) {
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
					queue: queue,
					coords: coords,
				});

				media.phono.initialized = true;
			});

			media.addEventListener('playing', () => {
				if (filter && !media.phono.filterAdded) {
					applyPhonographFilter(media);
					media.phono.filterAdded = true;
				}
			});

			media.play();
		}
	});
}

function getPlayer(handle, url, title, volume, offset, loop, filter, locked, video, videoSize, muted, queue, coords) {
	var id = 'player_' + handle.toString(16);

	var player = document.getElementById(id);

	if (!player && url) {
		player = initPlayer(id, handle, url, title, volume, offset, loop, filter, locked, video, videoSize, muted, queue, coords);
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
		getPlayer(data.handle, data.url, data.title, data.volume, offset, data.loop, data.filter, data.locked, data.video, data.videoSize, data.muted, data.queue, data.coords);
	} else{
		getPlayer(data.handle, data.url, data.url, data.volume, offset, data.loop, data.filter, data.locked, data.video, data.videoSize, data.muted, data.queue, data.coords);
	}
}

function play(handle) {
	var player = getPlayer(handle);

	if (player) {
		player.currentTime = 0;
	}
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

function calculateFocalLength(fov) {
	const x = 43.266615300557;
	var f = x / 2 * Math.tan(Math.PI * fov / 360);
	return 1 / f * 50;
}

function update(data) {
	var player = getPlayer(data.handle, data.url, data.title, data.volume, data.offset, data.loop, data.filter, data.locked, data.video, data.videoSize, data.muted, data.queue, data.coords);

	if (player) {
		if (data.paused || data.distance < 0) {
			if (!player.paused) {
				player.pause();
			}
		} else {
			if (data.sameRoom) {
				setAttenuationFactor(player, minAttenuationFactor);
				setVolumeFactor(player, minVolumeFactor);
			} else {
				setAttenuationFactor(player, maxAttenuationFactor);
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
					player.volume = volume;
				} else {
					player.volume = 0;
				}

				var currentTime = data.offset % player.duration;

				if (Math.abs(currentTime - player.currentTime) > maxTimeDifference) {
					player.currentTime = currentTime;
				}

				if (player.paused) {
					player.play();
				}
			}
		}

		if (data.video && data.sameRoom && data.camDistance >= 0 && data.distance <= data.maxDistance) {
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
	var handleInput = document.getElementById('usable-phonographs');

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

function createActivePhonographDiv(phonograph, fullControls, includeQueue) {
	var player = getPlayer(phonograph.handle);

	if (player) {
		var div = document.createElement('div');
		div.className = 'active-phonograph';

		var mainDiv = document.createElement('div');
		mainDiv.className = 'active-phonograph-main';

		var handleDiv = document.createElement('div');
		handleDiv.className = 'active-phonograph-handle';

		if (phonograph.label) {
			handleDiv.innerHTML = phonograph.label;
		} else {
			handleDiv.innerHTML = phonograph.handle.toString(16);
		}

		var distanceDiv = document.createElement('div');
		distanceDiv.className = 'active-phonograph-distance';

		if (phonograph.distance >= 0) {
			distanceDiv.innerHTML = Math.floor(phonograph.distance) + 'm';
		} else {
			distanceDiv.innerHTML = '-';
		}

		var titleDiv = document.createElement('div');
		titleDiv.className = 'active-phonograph-title';
		titleDiv.innerHTML = phonograph.info.title.substring(0, 47);

		var volumeDiv = document.createElement('div');
		volumeDiv.className = 'active-phonograph-volume';

		var volumeDownButton = document.createElement('button');
		volumeDownButton.className = 'control-button';
		volumeDownButton.innerHTML = '<i class="fas fa-volume-down"></i>';
		volumeDownButton.addEventListener('click', event => {
			sendMessage('volumeDown', {
				handle: phonograph.handle
			});
		});
		if (phonograph.info.locked && !fullControls) {
			volumeDownButton.disabled = true;
		}

		var volumeUpButton = document.createElement('button');
		volumeUpButton.className = 'control-button';
		volumeUpButton.innerHTML = '<i class="fas fa-volume-up"></i>';
		volumeUpButton.addEventListener('click', event => {
			sendMessage('volumeUp', {
				handle: phonograph.handle
			});
		});
		if (phonograph.info.locked && !fullControls) {
			volumeUpButton.disabled = true;
		}

		var volumeSpan = document.createElement('span');
		volumeSpan.innerHTML = phonograph.info.volume;

		volumeDiv.appendChild(volumeDownButton);
		volumeDiv.appendChild(volumeSpan);
		volumeDiv.appendChild(volumeUpButton);

		var timeDiv = document.createElement('div');
		timeDiv.className = 'active-phonograph-time';

		var timeSpan = document.createElement('span');
		if (phonograph.info.duration) {
			timeSpan.innerHTML = timeToString(phonograph.info.offset) + '/' + timeToString(phonograph.info.duration);
		} else {
			timeSpan.innerHTML = timeToString(phonograph.info.offset);
		}

		var seekBackwardButton = document.createElement('button');
		seekBackwardButton.className = 'control-button';
		seekBackwardButton.innerHTML = '<i class="fas fa-backward"></i>';
		seekBackwardButton.addEventListener('click', event => {
			sendMessage('seekBackward', {
				handle: phonograph.handle
			});
		});

		var seekForwardButton = document.createElement('button');
		seekForwardButton.className = 'control-button';
		seekForwardButton.innerHTML = '<i class="fas fa-forward"></i>';
		seekForwardButton.addEventListener('click', event => {
			sendMessage('seekForward', {
				handle: phonograph.handle
			});
		});

		var nextButton = document.createElement('button');
		nextButton.className = 'control-button';
		nextButton.innerHTML = '<i class="fas fa-step-forward"></i>';
		if (phonograph.info.queue.length < 1) {
			nextButton.disabled = true;
		} else {
			nextButton.addEventListener('click', event => {
				sendMessage('next', {
					handle: phonograph.handle
				});
			});
		}

		if ((phonograph.info.locked && !fullControls) || !phonograph.info.duration) {
			seekBackwardButton.disabled = true;
			seekForwardButton.disabled = true;
		}

		timeDiv.appendChild(seekBackwardButton);
		timeDiv.appendChild(timeSpan);
		timeDiv.appendChild(seekForwardButton);
		timeDiv.appendChild(nextButton);

		var videoSizeDiv = document.createElement('div');
		videoSizeDiv.className = 'active-phonograph-video-size';
		if (phonograph.info.video && player.videoTracks && player.videoTracks.length > 0) {
			var videoSizeDecreaseButton = document.createElement('button');
			videoSizeDecreaseButton.className = 'control-button';
			videoSizeDecreaseButton.innerHTML = '<i class="fas fa-minus"></i>';
			videoSizeDecreaseButton.addEventListener('click', event => {
				sendMessage('decreaseVideoSize', {
					handle: phonograph.handle
				});
			});

			var videoSizeSpan = document.createElement('span');
			videoSizeSpan.innerHTML = phonograph.info.videoSize;

			var videoSizeIncreaseButton = document.createElement('button');
			videoSizeIncreaseButton.className = 'control-button';
			videoSizeIncreaseButton.innerHTML = '<i class="fas fa-plus"></i>';
			videoSizeIncreaseButton.addEventListener('click', event => {
				sendMessage('increaseVideoSize', {
					handle: phonograph.handle
				});
			});

			videoSizeDiv.appendChild(videoSizeDecreaseButton);
			videoSizeDiv.appendChild(videoSizeSpan);
			videoSizeDiv.appendChild(videoSizeIncreaseButton);
		}

		var controlsDiv = document.createElement('div');
		controlsDiv.className = 'active-phonograph-controls';

		var lockedButton = document.createElement('button');
		lockedButton.className = 'control-button';
		if (phonograph.info.locked) {
			lockedButton.innerHTML = '<i class="fas fa-lock"></i>';
			lockedButton.addEventListener('click', event => {
				unlock(phonograph.handle);
			});
		} else {
			lockedButton.innerHTML = '<i class="fas fa-unlock"></i>';
			lockedButton.addEventListener('click', event => {
				lock(phonograph.handle);
			});
		}
		if (!fullControls) {
			lockedButton.disabled = true;
		}

		var copyButton = document.createElement('button');
		copyButton.className = 'control-button';
		copyButton.innerHTML = '<i class="fas fa-clone"></i>';
		copyButton.addEventListener('click', event => {
			copy(phonograph.handle);
		});
		if (phonograph.info.locked && !fullControls) {
			copyButton.disabled = true;
		}

		var loopButton = document.createElement('button');
		loopButton.className = 'control-button';
		if (phonograph.info.loop) {
			loopButton.innerHTML = '<i class="fas fa-retweet"></i>';
		} else {
			loopButton.innerHTML = '<i class="fas fa-arrow-right"></i>';
		}
		loopButton.addEventListener('click', event => {
			setLoop(phonograph.handle, !phonograph.info.loop);
		});
		if ((phonograph.info.locked && !fullControls) || !phonograph.info.duration) {
			loopButton.disabled = true;
		}

		var videoButton = document.createElement('button');
		videoButton.className = 'control-button';
		if (player.videoTracks && player.videoTracks.length > 0) {
			if (phonograph.info.video) {
				videoButton.innerHTML = '<i class="fas fa-video"></i>';
				videoButton.addEventListener('click', event => {
					disableVideo(phonograph.handle);
				});
			} else {
				videoButton.innerHTML = '<i class="fas fa-video-slash"></i>';
				videoButton.addEventListener('click', event => {
					enableVideo(phonograph.handle);
				});
			}
		} else {
			videoButton.innerHTML = '<i class="fas fa-video-slash"></i>';
			videoButton.disabled = true;
		}
		if (phonograph.info.locked && !fullControls) {
			videoButton.disabled = true;
		}

		var muteButton = document.createElement('button');
		muteButton.className = 'control-button';
		if (phonograph.info.muted) {
			muteButton.innerHTML = '<i class="fas fa-volume-mute"></i>';
			muteButton.addEventListener('click', event => {
				unmute(phonograph.handle);
			});
		} else {
			muteButton.innerHTML = '<i class="fas fa-volume-off"></i>';
			muteButton.addEventListener('click', event => {
				mute(phonograph.handle);
			});
		}
		if (phonograph.info.locked && !fullControls) {
			muteButton.disabled = true;
		}

		var pauseResumeButton = document.createElement('button');
		pauseResumeButton.className = 'control-button';
		if (phonograph.info.paused) {
			pauseResumeButton.innerHTML = '<i class="fas fa-play"></i>';
		} else {
			pauseResumeButton.innerHTML = '<i class="fas fa-pause"></i>';
		}
		pauseResumeButton.addEventListener('click', event => {
			pause(phonograph.handle);
		});
		if (phonograph.info.locked && !fullControls) {
			pauseResumeButton.disabled = true;
		}

		var stopButton = document.createElement('button');
		stopButton.className = 'control-button';
		stopButton.innerHTML = '<i class="fas fa-stop"></i>';
		stopButton.addEventListener('click', event => {
			sendMessage('stop', {
				handle: phonograph.handle
			});
		});
		if (phonograph.info.locked && !fullControls) {
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
		mainDiv.appendChild(volumeDiv);
		mainDiv.appendChild(timeDiv);
		mainDiv.appendChild(videoSizeDiv);
		mainDiv.appendChild(controlsDiv);

		div.appendChild(mainDiv);

		if (includeQueue && phonograph.info.queue.length > 0) {
			var queueDiv = document.createElement('div');
			queueDiv.className = 'active-phonograph-queue';

			var queueHeadDiv = document.createElement('div');
			queueHeadDiv.className = 'queue-head';
			queueHeadDiv.innerHTML = '<div>Queue</div><div><i class="fas fa-volume-off"></i></div><div><i class="fas fa-clock"></i></div><div><i class="fas fa-filter"></i></div><div><i class="fas fa-video"></i></div><div><i class="fas fa-user"></i></div><div></div>';

			var queueBodyDiv = document.createElement('div');
			queueBodyDiv.className = 'queue-body';

			for (let i = 0; i < phonograph.info.queue.length; ++i) {
				var entry = phonograph.info.queue[i];

				var urlDiv = document.createElement('div');
				urlDiv.innerHTML = entry.url.substring(0, 40);

				var volumeDiv = document.createElement('div');
				volumeDiv.innerHTML = entry.volume;

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
						handle: phonograph.handle,
						index: i + 1
					});
				});

				queueBodyDiv.appendChild(urlDiv);
				queueBodyDiv.appendChild(volumeDiv);
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
	} else {
		return null;
	}
}

function updateUi(data) {
	var activePhonographs = JSON.parse(data.activePhonographs);

	var activePhonographsDiv = document.getElementById('active-phonographs');
	var queuesDiv = document.getElementById('queues');
	activePhonographsDiv.innerHTML = '';
	activePhonographs.forEach(phonograph => {
		var div = createActivePhonographDiv(phonograph, data.fullControls, true);

		if (div) {
			activePhonographsDiv.appendChild(div);
		}
	});

	var statusDiv = document.getElementById('status');
	statusDiv.innerHTML = '';
	for (i = 0; i < activePhonographs.length; ++i) {
		if (activePhonographs[i].distance >= 0 && activePhonographs[i].distance <= data.maxDistance) {
			var div = createActivePhonographDiv(activePhonographs[i], data.fullControls, false);

			if (div) {
				statusDiv.appendChild(div);
				break;
			}
		}
	}

	var usablePhonographs = JSON.parse(data.usablePhonographs);
	var presets = JSON.parse(data.presets);

	var usablePhonographsSelect = document.getElementById('usable-phonographs');
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

	var usablePhonographsValue = usablePhonographsSelect.value;
	var presetValue = presetSelect.value;

	usablePhonographsSelect.innerHTML = '';

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

	var presetKeys = Object.keys(presets).sort();

	if (presetKeys.length > 0) {
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

		presetSelect.style.display = 'block';
	} else {
		presetSelect.style.display = 'none';
	}

	if (usablePhonographs.length == 0) {
		usablePhonographsSelect.disabled = true;
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
		urlInput.value = '';
	} else {
		usablePhonographs.forEach(phonograph => {
			var option = document.createElement('option');

			option.value = phonograph.handle;

			if (phonograph.active) {
				option.innerHTML = '&#xf144; ';
			} else {
				option.innerHTML = '';
			}

			if (phonograph.label) {
				option.innerHTML += phonograph.label + ' (' + Math.floor(phonograph.distance) + 'm)';
			} else {
				option.innerHTML += phonograph.handle.toString(16) + ' (' + Math.floor(phonograph.distance) + 'm)';
			}

			if (phonograph.handle == usablePhonographsValue) {
				option.selected = true;
			}

			usablePhonographsSelect.appendChild(option);
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

		usablePhonographsSelect.disabled = false;
		presetSelect.disabled = false;
		volumeInput.disabled = false;
		offsetInput.disabled = false;
		loopCheckbox.disabled = false;

		if (presetSelect.value == '' && urlInput.value == '') {
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

function startPhonograph() {
	var handleInput = document.getElementById('usable-phonographs');
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

	if (isNaN(volume)) {
		volume = 50;
	}

	if (isNaN(videoSize)) {
		videoSize = 50;
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
		muted: muted
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
	sendMessage('startup', {});

	document.getElementById('close-ui').addEventListener('click', function(event) {
		hideUi();
		sendMessage('closeUi', {});
	});

	document.getElementById('play-button').addEventListener('click', function(event) {
		startPhonograph();
	});

	document.getElementById('start-phonograph').addEventListener('keyup', function(event) {
		if (event.keyCode == 13) {
			event.preventDefault();
			startPhonograph();
		}
	});

	document.getElementById('set-base-volume').addEventListener('input', function(event) {
		sendMessage('setBaseVolume', {
			volume: parseInt(this.value)
		});
	});
});
