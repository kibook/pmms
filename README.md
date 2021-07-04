# pmms - FiveM/RedM synchronized media player

pmms (Poodle's MultiMedia System) allows players to play music/video from objects such as phonographs, radios or TVs.

# Features

- NUI-based, using [MediaElement.js](https://www.mediaelementjs.com/) to support HTML5 media, HLS, YouTube, and more.

- Synchronized between players.

- Multiple objects can play different things at the same time.

- Dynamic sound attenuation based on whether the player and object are in the same interior room.

- Optional immersive filter can be applied to any audio.

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

| Command                                                                            | Description                                       |
|------------------------------------------------------------------------------------|---------------------------------------------------|
| `/pmms`                                                                            | Open the media player control panel.              |
| `/pmms_play [url] [time] [loop] [filter] [lock] [video] [size] [mute] [min] [max]` | Play music/video on the nearest media player.     |
| `/pmms_pause`                                                                      | Pause playback on the nearest media player.       |
| `/pmms_stop`                                                                       | Stop playback on the nearest media player.        |
| `/pmms_status`                                                                     | Show the status of the nearest media player.      |
| `/pmms_presets`                                                                    | List presets.                                     |
| `/pmms_vol [volume]`                                                               | Set a personal base volume for all media players. |
| `/pmms_ctl`                                                                        | Advanced media player control.                    |
| `/pmms_add`                                                                        | Add or modify a media player model preset.        |

# Exports

## Server

### startByNetworkId

```lua
handle = exports.pmms:startByNetworkId(netId, url, title, volume, offset, duration, loop, filter, locked, video, videoSize, muted, attenuation)
```

Starts playing something on a networked media player object, using its network ID.

### startByCoords

```lua
handle = exports.pmms:startByCoords(x, y, z, url, title, volume, offset, duration, loop, filter, locked, video, videoSize, muted, attenuation)
```

Starts playing something on a non-networked media player object, using its coordinates on the world map.

### stop

```lua
exports.pmms:stop(handle)
```

Stops a media player and removes its handle.

### pause

```lua
exports.pmms:pause(handle)
```

Pause or resume a media player.

### lock

```lua
exports.pmms:lock(handle)
```

Locks an active media player so that only privileged users can interact with it.

### unlock

```lua
exports.pmms:unlock(handle)
```

Unlocks an active media player so anyone can interact with it.

### mute

```lua
exports.pmms:mute(handle)
```

Mutes an active media player.

### unmute

```lua
exports.pmms:unmute(handle)
```

Unmutes an active media player.
