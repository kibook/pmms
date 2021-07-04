# FiveM/RedM synchronized music player

Allows players to play music from objects such as phonographs, radios or TVs.

# Features

- NUI-based, using [MediaElement.js](https://www.mediaelementjs.com/) to support HTML5 media, HLS, YouTube, and more.

- Synchronized between players.

- Multiple objects can play different things at the same time.

- Dynamic sound attenuation based on whether the player and object are in the same interior room.

- Optional phonograph/radio filter can be applied to any audio.

- Play video on a TV screen with DUI (FiveM only), or on a screen displayed above the object.

- Permissions system and ability to lock objects so only certain players can control them.

- Configure default objects which are spawned and play music/video automatically.

# Examples

| | | |
|-|-|-|
|[![Attenuation Example](https://i.imgur.com/BTkglVYm.jpg)](https://imgur.com/BTkglVY)| [![Phonograph Filter](https://i.imgur.com/L8sWpOCm.jpg)](https://imgur.com/L8sWpOC) | [![Video](https://i.imgur.com/2jRYlSem.jpg)](https://imgur.com/2jRYlSe) |
|[![FiveM basic audio](https://i.imgur.com/CofS0VPm.jpg)](https://imgur.com/CofS0VP)|[![FiveM DUI example](https://i.imgur.com/ndZwPvDm.jpg)](https://imgur.com/ndZwPvD)|[![DUI render target proximity](https://i.imgur.com/m2KddI6m.jpg)](https://imgur.com/m2KddI6)|

# Commands

> **Note**
> 
> The command names can be customized. These are the defaults.

| Command                                                                          | Description                                       |
|----------------------------------------------------------------------------------|---------------------------------------------------|
| `/phono`                                                                         | Open the media player control panel.              |
| `/phono_play [url] [time] [loop] [filter] [lock] [video] [size] [mute]`          | Play music on the nearest media player.           |
| `/phono_pause`                                                                   | Pause playback on the nearest media player.       |
| `/phono_stop`                                                                    | Stop playback on the nearest media player.        |
| `/phono_status`                                                                  | Show the status of the nearest media player.      |
| `/phono_presets`                                                                 | List presets.                                     |
| `/phono_vol [volume]`                                                            | Set a personal base volume for all media players. |
| `/phono_ctl`                                                                     | Advanced media player control.                    |
| `/phono_add`                                                                     | Add or modify a media player model preset.        |

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
