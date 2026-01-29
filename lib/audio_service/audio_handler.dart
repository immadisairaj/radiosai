import 'package:audio_service/audio_service.dart';
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
    // _loadEmptyPlaylist();
    _notifyAudioHandlerAboutPlaybackEvents();
    _listenForDurationChanges();
    _listenForCurrentSongIndexChanges();
    _listenForSequenceStateChanges();
  }

  void _setMediaType(MediaType? mediaType) {
    _mediaType = mediaType;
  }

  // Future<void> _loadEmptyPlaylist() async {
  //   try {
  //     await _player.setAudioSource(
  //       AudioSource.uri(Uri.parse('')),
  //       initialPosition: Duration.zero,
  //     );
  //   } catch (e) {
  //     // print("Error: $e");
  //   }
  // }

  void _notifyAudioHandlerAboutPlaybackEvents() {
    _player.playbackEventStream.listen((PlaybackEvent event) {
      final playing = _player.playing;
      playbackState.add(__getPlaybackState(event, playing)!);
    });
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
        queueIndex: _player.currentIndex ?? 0,
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
        queueIndex: _player.currentIndex ?? 0,
      );
    }
  }

  void _listenForDurationChanges() {
    _player.durationStream.listen((duration) {
      final index = _player.currentIndex;
      final newQueue = queue.value;
      if (index == null || newQueue.isEmpty || duration == null) return;

      final oldMediaItem = newQueue[index];
      final newMediaItem = oldMediaItem.copyWith(duration: duration);

      // 1. Update the queue list
      final updatedQueue = List<MediaItem>.from(newQueue);
      updatedQueue[index] = newMediaItem;
      queue.add(updatedQueue);

      // 2. ONLY update the mediaItem sink if the index we just updated
      // is actually the one currently playing!
      if (index == _player.currentIndex) {
        mediaItem.add(newMediaItem);
      }
    });
  }

  void _listenForCurrentSongIndexChanges() {
    _player.currentIndexStream.listen((index) {
      final playlist = queue.value;
      if (index == null || playlist.isEmpty || index >= playlist.length) return;

      // Source of Truth check:
      // Only broadcast this as the "Now Playing" item if the player
      // is actually supposed to be on this index.
      if (mediaItem.value?.id != playlist[index].id) {
        mediaItem.add(playlist[index]);
      }
    });
  }

  void _listenForSequenceStateChanges() {
    _player.sequenceStateStream.listen((SequenceState? sequenceState) {
      final sequence = sequenceState?.effectiveSequence;
      if (sequence == null || sequence.isEmpty) return;

      final items = sequence.map((source) => source.tag as MediaItem).toList();
      queue.add(items);

      playbackState.add(
        playbackState.value.copyWith(queueIndex: _player.currentIndex),
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
      // clear method is called when starting a new player
      case 'clear':
        _player.stop();
        await _player.clearAudioSources();
        queue.add([]);
        mediaItem.add(null);
        break;
      // init method is called when starting a new player
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
    // if player played more than 3 seconds
    // then seek to beginning of the media
    if (_player.position > const Duration(seconds: 3)) {
      return _player.seek(Duration.zero, index: _player.currentIndex);
    }
    return _player.seekToPrevious();
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        _player.setLoopMode(LoopMode.off);
        break;
      case AudioServiceRepeatMode.one:
        _player.setLoopMode(LoopMode.one);
        break;
      case AudioServiceRepeatMode.group:
      case AudioServiceRepeatMode.all:
        _player.setLoopMode(LoopMode.all);
        break;
    }
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    if (shuffleMode == AudioServiceShuffleMode.none) {
      await _player.setShuffleModeEnabled(false);
    } else {
      await _player.shuffle();
      await _player.setShuffleModeEnabled(true);
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
