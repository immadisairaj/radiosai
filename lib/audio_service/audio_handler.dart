import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:radiosai/audio_service/service_locator.dart';
import 'package:radiosai/helper/media_helper.dart';
import 'package:radiosai/helper/navigator_helper.dart';
import 'package:radiosai/screens/media_player/media_player.dart';
import 'package:radiosai/screens/media_player/playing_queue.dart';

// copied and changed from
// https://github.com/suragch/flutter_audio_service_demo/

Future<AudioHandler> initAudioService() async {
  return await AudioService.init(
    builder: () => MyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.immadisairaj.radiosai.audio',
      androidNotificationChannelName: 'Sai Voice',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );
}

class MyAudioHandler extends BaseAudioHandler {
  // audio player uses just_audio
  final _player = AudioPlayer();
  // playing media type
  MediaType? _mediaType = MediaType.radio;

  MyAudioHandler() {
    _listenToNotificationClickEvent();
  }

  /// listens to notification click event of audio_service
  void _listenToNotificationClickEvent() {
    // notification click when audio playing
    AudioService.notificationClicked.listen((clicked) {
      if (clicked && _mediaType == MediaType.media) {
        // replicating same in radio_home.dart for incoming url's
        // if audio is media, then open media player
        if (!getIt<NavigationService>().isCurrentRoute(MediaPlayer.route)) {
          // if current route is media player, keep it as it is
          if (getIt<NavigationService>().isCurrentRoute(PlayingQueue.route)) {
            // if current route is playing queue, pop till media player
            getIt<NavigationService>().popUntil(MediaPlayer.route);
          } else {
            // if media player is not in tree, push media player
            getIt<NavigationService>().navigateTo(MediaPlayer.route);
          }
        }
      } else if (clicked && _mediaType == MediaType.radio) {
        // if audio is radio, then pop to first index
        getIt<NavigationService>().popToBase();
      }
    });
  }

  // initialized before playing
  void _initAudioHandler() {
    _notifyAudioHandlerAboutPlaybackEvents();
    _listenForDurationChanges();
    _listenForSequenceStateChanges();
  }

  void _setMediaType(MediaType? mediaType) {
    _mediaType = mediaType;
  }

  void _notifyAudioHandlerAboutPlaybackEvents() {
    _player.playbackEventStream.listen((PlaybackEvent event) {
      final playing = _player.playing;
      playbackState.add(__getPlaybackState(event, playing)!);
    });
  }

  int _getShuffledIndex() {
    final sequence = _player.sequenceState.effectiveSequence;
    final currentSource = _player.sequenceState.currentSource;
    if (currentSource == null || sequence.isEmpty) return 0;
    return sequence.indexOf(currentSource);
  }

  PlaybackState? __getPlaybackState(PlaybackEvent event, bool playing) {
    if (_mediaType == MediaType.radio) {
      return playbackState.value.copyWith(
        controls: [(playing) ? MediaControl.pause : MediaControl.play],
        systemActions: {MediaAction.playPause},
        androidCompactActionIndices: const [0],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: _getShuffledIndex(),
      );
    } else {
      return playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          (playing) ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
          MediaAction.skipToNext,
          MediaAction.skipToPrevious,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        repeatMode: const {
          LoopMode.off: AudioServiceRepeatMode.none,
          LoopMode.one: AudioServiceRepeatMode.one,
          LoopMode.all: AudioServiceRepeatMode.all,
        }[_player.loopMode]!,
        shuffleMode: (_player.shuffleModeEnabled)
            ? AudioServiceShuffleMode.all
            : AudioServiceShuffleMode.none,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: _getShuffledIndex(),
      );
    }
  }

  void _listenForDurationChanges() {
    _player.durationStream.listen((duration) {
      final index = _getShuffledIndex();
      final newQueue = queue.value;
      if (newQueue.isEmpty || duration == null) return;

      final oldMediaItem = newQueue[index];
      final newMediaItem = oldMediaItem.copyWith(duration: duration);

      final updatedQueue = List<MediaItem>.from(newQueue);
      updatedQueue[index] = newMediaItem;
      queue.add(updatedQueue);

      if (index == _getShuffledIndex()) {
        mediaItem.add(newMediaItem);
      }
    });
  }

  void _listenForSequenceStateChanges() {
    _player.sequenceStateStream.listen((sequenceState) {
      final sequence = sequenceState.effectiveSequence;
      final items = sequence.map((s) => s.tag).whereType<MediaItem>().toList();

      queue.add(items);

      final currentItem = sequenceState.currentSource?.tag as MediaItem?;
      if (currentItem != null) {
        mediaItem.add(currentItem);
      }

      playbackState.add(
        playbackState.value.copyWith(
          queueIndex: sequence.indexOf(sequenceState.currentSource!),
        ),
      );
    });
  }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    // manage Just Audio
    final audioSource = mediaItems.map(_createAudioSource);
    _player.addAudioSources(audioSource.toList());
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    // manage Just Audio
    final audioSource = _createAudioSource(mediaItem);
    _player.addAudioSource(audioSource);
  }

  AudioSource _createAudioSource(MediaItem mediaItem) {
    return AudioSource.uri(
      Uri.parse(mediaItem.extras!['uri']),
      tag: mediaItem,
      headers: {'Content-Type': 'audio/mpeg'},
    );
  }

  @override
  Future<void> removeQueueItemAt(int index) async {
    // manage Just Audio
    _player.removeAudioSourceAt(index);
  }

  @override
  Future customAction(String name, [Map<String, dynamic>? extras]) async {
    switch (name) {
      case 'setMediaType':
        _setMediaType(extras!['mediaType']);
        break;
      case 'dispose':
        _player.stop();
        _player.dispose();
        break;
      case 'clear':
        _player.stop();
        await _player.clearAudioSources();
        queue.add([]);
        mediaItem.add(null);
        break;
      case 'init':
        _initAudioHandler();
        break;
      case 'load':
        await _player.load();
        break;
    }
    return super.customAction(name, extras);
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= queue.value.length) return;
    _player.seek(Duration.zero, index: index);
  }

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() async {
    if (_player.position > const Duration(seconds: 3)) {
      return _player.seek(Duration.zero, index: _getShuffledIndex());
    }
    return _player.seekToPrevious();
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    LoopMode loopMode;
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        loopMode = LoopMode.off;
        break;
      case AudioServiceRepeatMode.one:
        loopMode = LoopMode.one;
        break;
      case AudioServiceRepeatMode.all:
      case AudioServiceRepeatMode.group:
        loopMode = LoopMode.all;
        break;
    }
    await _player.setLoopMode(loopMode);
    playbackState.add(playbackState.value.copyWith(repeatMode: repeatMode));
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    final bool enable = shuffleMode == AudioServiceShuffleMode.all;

    try {
      if (enable) {
        await _player.shuffle();
        await _player.setShuffleModeEnabled(true);
      } else {
        await _player.setShuffleModeEnabled(false);
      }

      playbackState.add(playbackState.value.copyWith(shuffleMode: shuffleMode));
    } catch (e) {
      debugPrint('Error setting shuffle mode: $e');
      playbackState.add(
        playbackState.value.copyWith(
          shuffleMode: _player.shuffleModeEnabled
              ? AudioServiceShuffleMode.all
              : AudioServiceShuffleMode.none,
        ),
      );
    }
  }

  @override
  Future<void> stop() {
    _player.stop();
    return super.stop();
  }

  // called on swipe of notification (when paused)
  @override
  Future<void> onTaskRemoved() {
    stop();
    _player.dispose();
    return super.onTaskRemoved();
  }
}
