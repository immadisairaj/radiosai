import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

class RadioPlayerTask extends BackgroundAudioTask {
  // audio player uses just_audio
  final _player = AudioPlayer();

  @override
  Future<void> onStart(Map<String, dynamic> params) async {
    // Get the path of image for artUri in notification
    String path = await getNotificationImage();

    // Set media item to tell the clients what is playing
    final mediaItem = MediaItem(
      id: params['audioSource'],
      album: "Radio Sai Global Harmony",
      title: params['audioName'],
      artist: "Radio Sai",
      artUri: Uri.parse('file://$path'),
    );
    // Tell the UI and media notification what we're playing.
    AudioServiceBackground.setMediaItem(mediaItem);
    // Listen to state changes on the player...
    _player.playerStateStream.listen((playerState) {
      // ... and forward them to all audio_service clients.
      AudioServiceBackground.setState(
        playing: playerState.playing,
        // Every state from the audio player gets mapped onto an audio_service state.
        processingState: {
          // ProcessingState.none: AudioProcessingState.none,
          ProcessingState.loading: AudioProcessingState.connecting,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[playerState.processingState],
        // Tell clients what buttons/controls should be enabled in the
        // current state.
        controls: [
          playerState.playing ? MediaControl.pause : MediaControl.play,
          MediaControl.stop
        ],
      );
    });

    // start playing before loading so that we can stop the player before itself
    _player.play();
    // setting the player source and when loads, it automatically plays
    await _player
        .setAudioSource(AudioSource.uri(Uri.parse(params['audioSource'])));
    return super.onStart(params);
  }

  @override
  Future<void> onPlay() {
    _player.play();
    return super.onPlay();
  }

  @override
  Future<void> onStop() {
    _player.stop();
    _player.dispose();
    return super.onStop();
  }

  @override
  Future<void> onPause() {
    _player.pause();
    return super.onPause();
  }

  // called on swipe of notification (when paused)
  @override
  Future<void> onTaskRemoved() {
    onStop();
    return super.onTaskRemoved();
  }

  // Get notification image stored in file,
  // if not stored, then store the image
  Future<String> getNotificationImage() async {
    String path = await getFilePath();
    File file = File(path);
    bool fileExists = file.existsSync();
    // if the image already exists, return the path
    if (fileExists) return path;
    // store the image into path from assets then return the path
    final byteData =
        await rootBundle.load('assets/sai_listens_notification.jpg');
    // if file is not created, create to write into the file
    file.create(recursive: true);
    await file.writeAsBytes(byteData.buffer.asUint8List());
    return path;
  }

  // Get the file path of the notification image
  Future<String> getFilePath() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;
    String filePath = '$appDocPath/sai_listens_notification.jpg';
    return filePath;
  }
}
