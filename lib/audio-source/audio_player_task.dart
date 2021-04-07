import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

class AudioPlayerTask extends BackgroundAudioTask {
  final _player = AudioPlayer();

  @override
  Future<void> onStart(Map<String, dynamic> params) async {
    // TODO: implement onStart
    
    String path = await getNotificationImage();
    
    final mediaItem = MediaItem(
      id: params['audioSource'],
      album: "Radio Sai Global Harmony",
      title: params['audioName'],
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
          playerState.playing ? MediaControl.stop : MediaControl.play
        ],
      );
    });
    
    _player.setAudioSource(AudioSource.uri(
        Uri.parse(params['audioSource'])
      ));
      await _player.play();
    return super.onStart(params);
  }

  @override
  Future<void> onPlay() {
    // TODO: implement onPlay
    _player.play();
    return super.onPlay();
  }

  @override
  Future<void> onStop() {
    // TODO: implement onStop
    _player.stop();
    _player.dispose();
    return super.onStop();
  }

  @override
  Future<void> onPause() {
    // TODO: implement onPause
    _player.pause();
    return super.onPause();
  }

  Future<String> getNotificationImage() async {
    String path = await getFilePath();
    File file = File(path);
    bool fileExists = file.existsSync();
    if(fileExists) return path;
    final byteData = await rootBundle.load('assets/sai_listens_notification.jpg');
    file.create(recursive: true);
    await file.writeAsBytes(byteData.buffer.asUint8List());
    return path;
  }

  Future<String> getFilePath() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;
    String filePath = '$appDocPath/sai_listens_notification.jpg';
    return filePath;
  }
  
}