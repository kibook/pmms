# RedM synchronized music player

Allows players to play music from a phonograph object.

# Features

- NUI with HTML5 audio

- Music is synchronized between players

- Multiple phonographs can play different songs at the same time

- Dynamic sound attenuation based on whether the player and phonograph are in the same interior room

- YouTube video support

- Optional "phonograph" filter can be applied to any audio

# Examples

| | |
|-|-|
|[![Attenuation Example](https://i.imgur.com/BTkglVYm.jpg)](https://imgur.com/BTkglVY)| [![Phonograph Filter](https://i.imgur.com/L8sWpOCm.jpg)](https://imgur.com/L8sWpOC) |

# Commands

| Command                                      | Description                                |
|----------------------------------------------|--------------------------------------------|
| `/phono`                                     | Open the phonograph control panel.         |
| `/phono play [url] [volume] [time] [filter]` | Play music on the nearest phonograph.      |
| `/phono pause`                               | Pause playback on the nearest phonograph.  |
| `/phono stop`                                | Stop playback on the nearest phonograph.   |
| `/phono status`                              | Show the status of the nearest phonograph. |
