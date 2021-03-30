# RedM synchronized music player

Allows players to play music from a phonograph object.

# Features

- NUI-based, using [MediaElement.js](https://www.mediaelementjs.com/) to support HTML5 media, HLS, YouTube, and more.

- Synchronized between players.

- Multiple phonographs can play different songs at the same time.

- Dynamic sound attenuation based on whether the player and phonograph are in the same interior room.

- Optional "phonograph" filter can be applied to any audio.

- Show video on a screen displayed above the phonograph.

- Permissions system and ability to lock phonographs.

- Configure default phonographs which are spawned and play music automatically.

# Examples

| | | |
|-|-|-|
|[![Attenuation Example](https://i.imgur.com/BTkglVYm.jpg)](https://imgur.com/BTkglVY)| [![Phonograph Filter](https://i.imgur.com/L8sWpOCm.jpg)](https://imgur.com/L8sWpOC) | [![Video](https://i.imgur.com/2jRYlSem.jpg)](https://imgur.com/2jRYlSe) |

# Commands

| Command                                                                          | Description                                     |
|----------------------------------------------------------------------------------|-------------------------------------------------|
| `/phono`                                                                         | Open the phonograph control panel.              |
| `/phono play [url] [volume] [time] [loop] [filter] [lock] [video] [size] [mute]` | Play music on the nearest phonograph.           |
| `/phono pause`                                                                   | Pause playback on the nearest phonograph.       |
| `/phono stop`                                                                    | Stop playback on the nearest phonograph.        |
| `/phono status`                                                                  | Show the status of the nearest phonograph.      |
| `/phono songs`                                                                   | Show preset song selection.                     |
| `/phonovol [volume]`                                                             | Set a personal base volume for all phonographs. |

# Exports

## Server

### startByNetworkId

```lua
handle = exports.phonograph:startByNetworkId(netId, url, title, volume, offset, duration, loop, filter, locked, video, videoSize, muted)
```

Starts playing something on a networked phonograph object, using its network ID.

### startByCoords

```lua
handle = exports.phonograph:startByCoords(x, y, z, url, title, volume, offset, duration, loop, filter, locked, video, videoSize, muted)
```

Starts playing something on a non-networked phonograph object, using its coordinates on the world map.

### stop

```lua
exports.phonograph:stop(handle)
```

Stops a phonograph and removes its handle.

### pause

```lua
exports.phonograph:pause(handle)
```

Pause or resume a phonograph temporarily.

### lock

```lua
exports.phonograph:lock(handle)
```

Locks an active phonograph so that only privileged users can interact with it.

### unlock

```lua
exports.phonograph:unlock(handle)
```

Unlocks an active phonograph so anyone can interact with it.

### mute

```lua
exports.phonograph:mute(handle)
```

Mutes an active phonograph.

### unmute

```lua
exports.phonograph:unmute(handle)
```

Unmutes an active phonograph.
