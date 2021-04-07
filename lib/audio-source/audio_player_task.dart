import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerTask extends BackgroundAudioTask {
  final _player = AudioPlayer();

  @override
  Future<void> onStart(Map<String, dynamic> params) async {
    // TODO: implement onStart
    
    final mediaItem = MediaItem(
      id: params['audioSource'],
      album: "Radio Sai Global Harmony",
      title: params['audioName'],
      // TODO: make the below link to store and call the absolute path
      artUri: Uri.parse('https://i.pinimg.com/originals/aa/64/21/aa6421dc59f3a6163f9cf1f32dfe7943.jpg'),
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
  
}