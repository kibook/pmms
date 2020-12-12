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

function getYoutubeInfo(id) {
	return new Promise(function(resolve, reject) {
		fetch('https://redm.khzae.net/phonograph/yt?v=' + id + '&metadata=1').then(resp => {
			return resp.json();
		}).then(resp => {
			return resolve(resp);
		}).catch(err => {
			return reject(err);
		});
	});
}

function interpretUrl(url) {
	var isYoutube = url.match(/(?:youtu|youtube)(?:\.com|\.be)\/([\w\W]+)/i);

	if (isYoutube) {
		var id = isYoutube[1].match(/watch\?v=|[\w\W]+/gi);
		id = (id.length > 1) ? id.splice(1) : id;
		id = id.toString();

		return getYoutubeInfo(id);
	} else {
		return new Promise(function(resolve, reject) {
			resolve({url: url});
		});
	}
}

function showLoadingIcon() {
	document.getElementById('loading').style.display = 'block';
}

function hideLoadingIcon() {
	document.getElementById('loading').style.display = 'none';
}

function initPlayer(id, handle, url, title, volume, offset, filter, locked, video, videoSize, coords) {
	interpretUrl(url).then(info => {
		url = info.url;

		if (info.title) {
			title = info.title;
		}

		player = document.createElement('video');
		player.crossOrigin = 'anonymous';
		player.id = id;
		player.setAttribute('data-attenuationFactor', maxAttenuationFactor);
		player.setAttribute('data-volumeFactor', maxVolumeFactor);
		player.className = 'player';
		if (video) {
			player.style.display = 'block';
		} else {
			player.style.display = 'none';
		}
		document.body.appendChild(player);

		if (filter) {
			applyPhonographFilter(player);
		}

		player.addEventListener('error', () => {
			hideLoadingIcon();

			sendMessage('initError', {
				url: url
			});

			player.remove();
		});

		player.addEventListener('canplay', () => {
			hideLoadingIcon();

			sendMessage('init', {
				handle: handle,
				url: url,
				title: title,
				volume: volume,
				offset: offset,
				filter: filter,
				locked: locked,
				video: video,
				videoSize: videoSize,
				coords: coords
			});
		}, {once: true});

		player.src = url;
		player.volume = 0;
	}).catch(err => {
		console.log(err);

		sendMessage('initError', {
			url: url
		});

		hideLoadingIcon();
	});
}

function getPlayer(handle, url, title, volume, offset, filter, locked, video, videoSize, coords) {
	var id = 'player_' + handle.toString(16);

	var player = document.getElementById(id);

	if (!player && url) {
		player = initPlayer(id, handle, url, title, volume, offset, filter, locked, video, videoSize, coords);
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

function applyPhonographFilter(player) {
	var context = new (window.AudioContext || window.webkitAudioContext)();
	var source = context.createMediaElementSource(player);

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

	var noise = document.createElement('audio');
	noise.src = 'https://redm.khzae.net/phonograph/noise.webm';

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

function init(data) {
	if (data.url == '') {
		return;
	}

	showLoadingIcon();

	var offset = parseTimecode(data.offset);

	if (data.title) {
		getPlayer(data.handle, data.url, data.title, data.volume, offset, data.filter, data.locked, data.video, data.videoSize, data.coords);
	} else{
		try {
			jsmediatags.read(data.url, {
				onSuccess: function(tag) {
					var title;

					if (tag.tags.title) {
						title = tag.tags.title;
					} else {
						title = data.url;
					}

					getPlayer(data.handle, data.url, title, data.volume, offset, data.filter, data.locked, data.video, data.videoSize, data.coords);
				},
				onError: function(error) {
					getPlayer(data.handle, data.url, data.url, data.volume, offset, data.filter, data.locked, data.video, data.videoSize, data.coords);
				}
			});
		} catch (err) {
			console.log(err);

			sendMessage('initError', {
				url: data.url
			});

			hideLoadingIcon();
		}
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
		handle: handle,
		paused: Math.floor(Date.now() / 1000)
	});
}

function stop(handle) {
	var player = getPlayer(handle);

	if (player) {
		player.remove();
	}
}

function setAttenuationFactor(player, target) {
	var attenuationFactor = parseFloat(player.getAttribute('data-attenuationFactor'));

	if (attenuationFactor > target) {
		attenuationFactor -= 0.1;
	} else {
		attenuationFactor += 0.1;
	}

	player.setAttribute('data-attenuationFactor', attenuationFactor);
}

function setVolumeFactor(player, target) {
	var volumeFactor = parseFloat(player.getAttribute('data-volumeFactor'));

	if (volumeFactor > target) {
		volumeFactor -= 0.1;
	} else {
		volumeFactor += 0.1;
	}

	player.setAttribute('data-volumeFactor', volumeFactor);
}

function calculateFocalLength(fov) {
	const x = 43.266615300557;
	var f = x / 2 * Math.tan(Math.PI * fov / 360);
	return 1 / f * 50;
}

function update(data) {
	var player = getPlayer(data.handle, data.url, data.title, data.volume, data.offset, data.filter, data.locked, data.video, data.videoSize, data.coords);

	if (player) {
		if (data.paused) {
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

			if (player.src != data.url) {
				player.src = data.url;
			}

			if (player.readyState > 0) {
				var volume;

				if (data.distance < 0) {
					volume = 0;
				} else {
					var attenuationFactor = parseFloat(player.getAttribute('data-attenuationFactor'));
					var volumeFactor = parseFloat(player.getAttribute('data-volumeFactor'));

					volume = (((100 - data.distance * attenuationFactor) / 100) / volumeFactor) * (data.volume / 100);
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

			player.style.left = data.screenX * 100 + '%';
			player.style.top  = data.screenY * 100 + '%';
			player.style.width = data.videoSize * scale + 'vw';
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

function timeToString(time) {
	var h = Math.floor(time / 60 / 60);
	var m = Math.floor(time / 60) % 60;
	var s = Math.floor(time) % 60;

	return String(h).padStart(2, '0') + ':' + String(m).padStart(2, '0') + ':' + String(s).padStart(2, '0');
}

function createActivePhonographDiv(phonograph, fullControls) {
	var player = getPlayer(phonograph.handle);

	if (player) {
		var div = document.createElement('div');
		div.className = 'active-phonograph';

		var handleDiv = document.createElement('div');
		handleDiv.className = 'active-phonograph-handle';
		handleDiv.innerHTML = phonograph.handle.toString(16);

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
		if (player.duration && player.duration != Infinity) {
			timeSpan.innerHTML = timeToString(player.currentTime) + '/' + timeToString(player.duration);
		} else {
			timeSpan.innerHTML = timeToString(player.currentTime);
		}

		var seekBackwardButton = document.createElement('button');
		seekBackwardButton.className = 'control-button';
		seekBackwardButton.innerHTML = '<i class="fas fa-backward"></i>';
		seekBackwardButton.addEventListener('click', event => {
			sendMessage('seekBackward', {
				handle: phonograph.handle
			});
		});
		if (phonograph.info.locked && !fullControls) {
			seekBackwardButton.disabled = true;
		}

		var seekForwardButton = document.createElement('button');
		seekForwardButton.className = 'control-button';
		seekForwardButton.innerHTML = '<i class="fas fa-forward"></i>';
		seekForwardButton.addEventListener('click', event => {
			sendMessage('seekForward', {
				handle: phonograph.handle
			});
		});
		if (phonograph.info.locked && !fullControls) {
			seekForwardButton.disabled = true;
		}

		timeDiv.appendChild(seekBackwardButton);
		timeDiv.appendChild(timeSpan);
		timeDiv.appendChild(seekForwardButton);

		var videoSizeDiv;
		if (phonograph.info.video > 0) {
			var videoSizeDiv = document.createElement('div');
			videoSizeDiv.className = 'active-phonograph-video-size';

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

		var videoButton = document.createElement('button');
		videoButton.className = 'control-button';
		if (player.videoTracks.length > 0) {
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
		controlsDiv.appendChild(videoButton);
		controlsDiv.appendChild(pauseResumeButton);
		controlsDiv.appendChild(stopButton);

		div.appendChild(handleDiv);
		div.appendChild(distanceDiv);
		div.appendChild(titleDiv);
		div.appendChild(volumeDiv);
		div.appendChild(timeDiv);
		if (videoSizeDiv) {
			div.appendChild(videoSizeDiv);
		}
		div.appendChild(controlsDiv);

		return div;
	} else {
		return null;
	}
}

function updateUi(data) {
	var activePhonographs = JSON.parse(data.activePhonographs);

	var activePhonographsDiv = document.getElementById('active-phonographs');
	activePhonographsDiv.innerHTML = '';
	activePhonographs.forEach(phonograph => {
		var div = createActivePhonographDiv(phonograph, data.fullControls);

		if (div) {
			activePhonographsDiv.appendChild(div);
		}
	});

	var statusDiv = document.getElementById('status');
	statusDiv.innerHTML = '';
	for (i = 0; i < activePhonographs.length; ++i) {
		if (activePhonographs[i].distance >= 0 && activePhonographs[i].distance <= data.maxDistance) {
			var div = createActivePhonographDiv(activePhonographs[i], data.fullControls);

			if (div) {
				statusDiv.appendChild(div);
				break;
			}
		}
	}

	var inactivePhonographs = JSON.parse(data.inactivePhonographs);
	var presets = JSON.parse(data.presets);

	var inactivePhonographsSelect = document.getElementById('inactive-phonographs');
	var presetSelect = document.getElementById('preset');
	var urlInput = document.getElementById('url');
	var volumeInput = document.getElementById('volume');
	var offsetInput = document.getElementById('offset');
	var filterCheckbox = document.getElementById('filter');
	var lockedCheckbox = document.getElementById('locked');
	var videoCheckbox = document.getElementById('video');
	var videoSizeInput = document.getElementById('video-size');
	var playButton = document.getElementById('play-button');

	var inactivePhonographsValue = inactivePhonographsSelect.value;
	var presetValue = presetSelect.value;

	inactivePhonographsSelect.innerHTML = '';

	if (presetValue == 'random') {
		presetSelect.innerHTML = '<option></option><option value="random" selected="true">Random</option>';
	} else {
		presetSelect.innerHTML = '<option></option><option value="random">Random</option>';
	}

	var presetKeys = Object.keys(presets).sort();

	if (presetKeys.length > 0) {
		presetKeys.forEach(key => {
			var option = document.createElement('option');

			option.value = key;
			option.innerHTML = presets[key].title;

			if (key == presetValue) {
				option.selected = true;
			}

			presetSelect.appendChild(option);
		});

		presetSelect.style.display = 'block';
	} else {
		presetSelect.style.display = 'none';
	}

	if (inactivePhonographs.length == 0) {
		inactivePhonographsSelect.disabled = true;
		presetSelect.disabled = true;
		urlInput.disabled = true;
		volumeInput.disabled = true;
		offsetInput.disabled = true;
		filterCheckbox.disabled = true;
		lockedCheckbox.disabled = true;
		videoCheckbox.disabled = true;
		videoSizeInput.disabled = true;
		playButton.disabled = true;
		urlInput.value = '';
	} else {
		inactivePhonographs.forEach(phonograph => {
			var option = document.createElement('option');

			option.value = phonograph.handle;
			option.innerHTML = phonograph.handle.toString(16) + ' (' + Math.floor(phonograph.distance) + 'm)';

			if (phonograph.handle == inactivePhonographsValue) {
				option.selected = true;
			}

			inactivePhonographsSelect.appendChild(option);
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
			videoSizeInput.disabled = true;
		}

		if (data.fullControls) {
			lockedCheckbox.disabled = false;
		} else {
			lockedCheckbox.checked = false
			lockedCheckbox.disabled = true;
		}

		inactivePhonographsSelect.disabled = false;
		presetSelect.disabled = false;
		volumeInput.disabled = false;
		offsetInput.disabled = false;

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

	if (statusDiv.style.display == 'flex') {
		statusDiv.style.display = 'none';
	} else {
		statusDiv.style.display = 'flex';
	}
}

function startPhonograph() {
	var handleInput = document.getElementById('inactive-phonographs');
	var presetSelect = document.getElementById('preset');
	var urlInput = document.getElementById('url');
	var volumeInput = document.getElementById('volume');
	var offsetInput = document.getElementById('offset');
	var filterCheckbox = document.getElementById('filter');
	var lockedCheckbox = document.getElementById('locked');
	var videoCheckbox = document.getElementById('video');
	var videoSizeInput = document.getElementById('video-size');

	var handle = parseInt(handleInput.value);

	var url;
	if (presetSelect.value == '') {
		url = urlInput.value;
	} else {
		url = presetSelect.value;
	}

	var volume = parseInt(volumeInput.value);
	var offset = offsetInput.value;
	var filter = filterCheckbox.checked;
	var locked = lockedCheckbox.checked;
	var video = videoCheckbox.checked;
	var videoSize = parseInt(videoSizeInput.value);

	if (!volume) {
		volume = 100;
	}

	if (!videoSize) {
		videoSize = 50;
	}

	sendMessage('play', {
		handle: handle,
		url: url,
		volume: volume,
		offset: offset,
		filter: filter,
		locked: locked,
		video: video,
		videoSize: videoSize
	});

	presetSelect.value = '';
	urlInput.value = '';
	volumeInput.value = 100;
	offsetInput.value = '00:00:00';
}

window.addEventListener('message', event => {
	switch (event.data.type) {
		case 'init':
			init(event.data);
			break;
		case 'play':
			play(event.data.handle);
			break;
		case 'pause':
			pause(event.data.handle);
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
