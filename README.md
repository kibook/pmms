# RedM synchronized music player

Allows players to play music from a phonograph object.

# Features

- NUI with HTML5 audio and video

- Synchronized between players

- Multiple phonographs can play different songs at the same time

- Dynamic sound attenuation based on whether the player and phonograph are in the same interior room

- YouTube video support

- Optional "phonograph" filter can be applied to any audio

- Show video on a screen displayed above the phonograph

- Permissions system and ability to lock phonographs

- Configure default phonographs which are spawned and play music automatically

# Examples

| | | |
|-|-|-|
|[![Attenuation Example](https://i.imgur.com/BTkglVYm.jpg)](https://imgur.com/BTkglVY)| [![Phonograph Filter](https://i.imgur.com/L8sWpOCm.jpg)](https://imgur.com/L8sWpOC) | [![Video](https://i.imgur.com/2jRYlSem.jpg)](https://imgur.com/2jRYlSe) |

# Commands

| Command                                                            | Description                                     |
|--------------------------------------------------------------------|-------------------------------------------------|
| `/phono`                                                           | Open the phonograph control panel.              |
| `/phono play [url] [volume] [time] [filter] [lock] [video] [size]` | Play music on the nearest phonograph.           |
| `/phono pause`                                                     | Pause playback on the nearest phonograph.       |
| `/phono stop`                                                      | Stop playback on the nearest phonograph.        |
| `/phono status`                                                    | Show the status of the nearest phonograph.      |
| `/phono songs`                                                     | Show preset song selection.                     |
| `/phonovol [volume]`                                               | Set a personal base volume for all phonographs. |
