# Sai Voice

A radio player which streams audio from Radio Sai Global Harmony.

Om Sri Sai Ram

Sai Voice is an audio app that streams audio data broadcasted by Radio Sai Global Harmony.

Internet is needed for the app to function properly.

*All the data inside the app is taken from radiosai.org

Audio Streams include:
Asia Stream, Africa Stream, America Stream, Bhajan Stream, Discourse Stream and Telugu Stream.

Smooth: The app is built to keep a smooth and simple user experience. One can change the streams they want to listen to with ease just by sliding the panel up and selecting the new stream.

Seemless Listening: It is capable of running in the background until the app is removed from the process. Listen to your favourite stream with just one click after opening the app (an option to set the favourite stream at the start of the app)

Media Control: It can handle the audio options from handset to a headset, from lock screen notifications to earphones button click. It also pauses when another player starts and doesn't interrupt any incoming notifications.

Schedule: Look at the radio schedule from within the app.

Sai Inspires: Thought of the day by Sai Inspires is also present inside the app. One can read it at any text size they want by zooming.

Free: The app is free for all and will remain the same further. The app will not be having any kind of ads at any point in time.

Open Source: We believe that there is nothing to hide and just like contribute to the betterment of the app. So, the source code of the app is completely open-source and will remain the same in future.

Happy Listening.

## Future Updates

*I cannot guarantee any of the below. But, I will try my best to include such features in future releases(if I can)

- Add a player for vedam which supports all media controls
- Add android auto support
- Add google chrome cast support

## Motivation

I am a sai devotee. I like to listen to various bhajans and so liked radio sai very much. I have installed the radio sai app on my device and keep listening to the radio which gives me peace. But, also as an app developer, I didn't like the UI much, which also includes the audio breaking in between and few other components. That is the start of the idea to build such an app. I started to collect resources from where the radio is broadcasted and finally reached the point to have a public release of the app. I referred to the radio sai app while building this.

*I do not want to say the radio sai app is bad. They put a great effort into building that app and which is still serving. I just want to say that it's completely your choice to use whichever app is comfortable for you.

## Screenshots

<!-- TODO: add screenshots -->

## Architecture

Most of the main features use bloc architecture using providers and streams. The usage of this architecture helps the app no to completely refresh but just helpful for updating the needed components smoothly.

## OpenSource Libraries

### shared_preferenecs

used to store short data locally like: saving the radio stream while closing the app and displays the same on app start, display the favourite radio stream on app start.

### sliding_up_panel

used to select a different radio stream by sliding up the panel.

### webview_flutter

it is hidden inside the Sai Inspires screen which is used to retrieve the data from the web and display it on the top.

### shimmer

used to show loading progress in the Sai Inspires

### flutter_custom_tabs

it is used for redirecting the URL from the app to chrome powered browser

### internet_connection_checker

used to detect the internet status of the device

### just_audio & audio_service

the main base of the app helps play the audio seamlessly with media control

and many other open-source libraries.

I thank the Open Source community for providing such great libraries and framework which helped me build the application.

## Privacy Policy

The Privacy Policy of the app is located in the site [immadisairaj.me/radiosai/privacy_policy.html](https://immadisairaj.me/radiosai/privacy_policy.html)

## License

<!-- TODO: add link or something -->
