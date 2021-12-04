# Sai Voice

A radio player which streams audio from Radio Sai Global Harmony.

<img src="/assets/sai_voice_logo.png" height="150">

_*Special Thanks to Aman Achutan for the logo_

Om Sri Sai Ram :pray:

Sai Voice is an audio app that streams audio data broadcasted by Radio Sai Global Harmony.

| :warning: Internet is needed for the app to function properly. |
|-|

_*All the data inside the app is taken from [radiosai.org](https://www.radiosai.org)_

__Radio Streams include:__
- Asia Stream
- Africa Stream
- America Stream
- Bhajan Stream
- Discourse Stream
- Telugu Stream

| :memo: Radio Streams in iOS takes some time to load due to a constraint with the http audio source |
|-|

__Smooth:__ The app is built to keep a smooth user experience. One can change the streams they want to listen to with ease by just sliding the panel up and selecting the new stream.

__Seamless Listening:__ It is capable of running in the background until the app is removed from the process. Listen to your favourite radio stream with just one click after opening the app (an option to set the favourite stream at the start of the app)

__Media Control:__ It can handle the audio options from a handset to a headset, from lock screen notifications to earphones button click. It also pauses when another player starts and doesn't interrupt any incoming notifications.

__Dark Theme:__ The app also comes with dark theme. One can change the theme they want from settings.

__Split Screen:__ The app is suitable for split screen. Operate this app while doing work in a different app.

__Schedule:__ Look at the radio schedule of different streams from within the app. One can see and listen to the different media present in the schedule by clicking one them.

__Sai Inspires:__ Thought of the day by Sai Inspires is present inside the app. One can read it at any text size they want by zooming in. One can also share the content by clicking the copy icon (copies to clipboard). One can also view and save the image.

__Search:__ Searching through out the Radio Sai audio is now possible from the app. Once can search by filtering through category or streamed date. Listening to the audio from the search is also possible now in the app.

__Media Player:__ A new media player which is capable of playing the media seamlessly. Sharing the link to the media, adding/removing from playing queue, shuffling the queue, repeat mode, and other functions are present in the media player. Drawback of the player is the playing queue is cleared when radio is played or when the player is stopped.

__Free without ads:__ The app is free for all and will remain the same further. No ads are shown in the app. This is thanks to Radio Sai Global Harmony for providing the content without any charge. Like the Sai Organization, we believe in selfless service and do not expect anything in return.

__Open Source:__ We believe that there is nothing to hide and like you to experience the bliss of Swamy. So, the source code of the app is open-source and will remain the same in future.

__File Permissions:__ File write permission is requested only to save images from Sai Inspires. One can deny these permissions from the settings.

> "Sai Ram, and Happy Listening"

## Future Updates

_*I cannot guarantee any of the below. But, will try my best to include such features in future releases (if I can)_

- Add android auto support
- Add google chrome cast support

## Radio Player Flow

```
Stop State -> Play in app screen (user action) -> Play State
Stop State -> Change Radio Stream (user action) -> Changes Radio Stream -> Stop State
Play State -> Change Radio Stream (user action) -> Stop State -> Changes Radio Stream -> Play State
Play State -> Pause in app screen (user action) -> Stop State

Play State -> Pause in notification (user action) -> Pause State
Play State -> Stop in notification (user action) -> Stop State
```

## Motivation

I like to listen to various bhajans which made me fond of radio sai. I've installed the app and kept listening to the radio that gave me peace. I felt the application UI/UX was not up to the mark. The audio stops in between and doesn't handle audio when I receive a call or play another media. That was the start of the idea to build an app that solves these problems. I started to collect resources from where the radio is broadcasted and finally reached the point to have a public release of the app. I referred to the radio sai app and its functionality while building this app.

>I feel this app solves the problems that I (and many others) face and would like to share this with all. It's one's choice to use whichever app is comfortable

## Screenshots

<img src="/screenshots/screenshot_1.png" height="500"> <img src="/screenshots/screenshot_2.png" height="500"> <img src="/screenshots/screenshot_3.jpg" height="500"> <img src="/screenshots/screenshot_4.jpg" height="500"> <img src="/screenshots/screenshot_5.jpg" height="500"> <img src="/screenshots/screenshot_6.jpg" height="500"> <img src="/screenshots/screenshot_7.png" height="500"> <img src="/screenshots/screenshot_8.png" height="500"> <img src="/screenshots/screenshot_9.png" height="500"> <img src="/screenshots/screenshot_10.png" height="500"> <img src="/screenshots/screenshot_11.png" height="500"> <img src="/screenshots/screenshot_12.png" height="500"> <img src="/screenshots/screenshot_13.png" height="500"> <img src="/screenshots/screenshot_14.png" height="500"> <img src="/screenshots/screenshot_15.jpg" height="500"> <img src="/screenshots/screenshot_16.jpg" height="500"> <img src="/screenshots/screenshot_17.jpg" height="500"> <img src="/screenshots/screenshot_18.jpg" height="500"> <img src="/screenshots/screenshot_19.png" height="500"> <img src="/screenshots/screenshot_20.png" height="500"> <img src="/screenshots/screenshot_21.png" height="500"> <img src="/screenshots/screenshot_22.png" height="500"> <img src="/screenshots/screenshot_23.png" height="500"> <img src="/screenshots/screenshot_24.png" height="500">

## Architecture

Most of the main features use bloc architecture using providers and streams. The usage of this architecture helps the app no to completely refresh but just helpful for updating the needed components smoothly.

```bash
lib
├───audio_service   # audio service related handlers
│   └── notifiers
├───bloc            # business logic files related to screens
│   ├───media
│   ├───radio
│   ├───radio_schedule
│   └───settings
├───constants       # constants
├───helper          # helper classes
├───screens         # all screens
│   ├── audio_archive
│   ├───media
│   ├───media_player
│   ├───radio
│   ├───sai_inspires
│   ├───radio_schedule
│   └───settings
│       └───general
└───widgets         # widgets related to screens
    ├───radio
    └───settings
```
_Above is generated using "tree" command inside lib/_

## OpenSource Libraries

__shared_preferenecs:__
used to store short data locally like: saving the radio stream while closing the app and displays the same on app start, display the favourite radio stream on app start; save the user preference app theme.

__sliding_up_panel:__
used to select a different radio stream by sliding up the panel.

__shimmer:__
used to show loading progress in the data loading screens

__internet_connection_checker:__
used to detect the internet status of the device

__flutter_downloader:__
used to download files/media from the internet

__just_audio & audio_service:__
the main base of the app helps play the audio seamlessly with media control. Thank you @ryanheise

_and many other open-source libraries._


Thanks to the Open Source community for providing such great libraries and framework which was very helpful in building the application.

## Built using
<!-- keep updating this -->
- __Flutter version:__ 2.5.3
- __Dart version:__ 2.14.4
- __Visual Studio Code:__ 1.62.3
- __Operating System:__ macOS Big Monterey version 12.0.1
- __Gradle version:__ 7.0.2
- __Android Emulator:__ Pixel 4a API 30
- __iOS Simulator:__ Apple iPhone 13 iOS 15

## Privacy Policy

The Privacy Policy of the app is in the site: [immadisairaj.github.io/radiosai/privacy_policy.html](https://immadisairaj.github.io/radiosai/privacy_policy.html)

## License

This project is licensed under the GNU General Public License V2, see the [LICENSE.md](https://github.com/immadisairaj/radiosai/blob/main/LICENSE.md) for more details.
