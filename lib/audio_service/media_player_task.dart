import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class MediaPlayerTask extends BackgroundAudioTask {
  AudioPlayer _player;
  ConcatenatingAudioSource concatenatingAudioSource;
  AudioProcessingState _skipState;
  Seeker _seeker;
  StreamSubscription<PlaybackEvent> _eventSubscription;

  List<MediaItem> mediaQueue;
  List<MediaItem> get queue => mediaQueue;
  int get index => _player.currentIndex;
  MediaItem get mediaItem => index == null ? null : queue[index];

  @override
  Future<void> onStart(Map<String, dynamic> params) async {
    // initialize the just_audio player
    // global declaration might not create new player
    _player = new AudioPlayer();

    // initialize the queue
    mediaQueue = [];

    Map<String, dynamic> _extras = {
      'uri': params['extrasUri'],
    };

    // extras['uri'] contains the audio source
    final tempMediaItem = MediaItem(
      id: params['id'],
      album: params['album'],
      title: params['title'],
      artUri: Uri.parse(params['artUri']),
      extras: _extras,
    );

    // add media item to the queue
    mediaQueue.add(tempMediaItem);

    // Broadcast media item changes.
    _player.currentIndexStream.listen((index) {
      if (index != null) AudioServiceBackground.setMediaItem(queue[index]);
    });
    // Propagate all events from the audio player to AudioService clients.
    _eventSubscription = _player.playbackEventStream.listen((event) {
      _broadcastState();
    });
    // Special processing for state transitions.
    _player.processingStateStream.listen((state) {
      switch (state) {
        case ProcessingState.completed:
          // In this example, the service pauses when reaching the end.
          onPause();
          break;
        case ProcessingState.ready:
          // If we just came from skipping between tracks, clear the skip
          // state now that we're ready to play.
          _skipState = null;
          break;
        default:
          break;
      }
    });

    // Load and broadcast the queue
    AudioServiceBackground.setQueue(queue);
    concatenatingAudioSource = new ConcatenatingAudioSource(
      children:
          queue.map((item) => AudioSource.uri(Uri.parse(item.extras['uri']))).toList(),
    );
    try {
      await _player.setAudioSource(concatenatingAudioSource);
      // update the duration when just_audio decodes it
      _player.durationStream.listen((duration) {
        updateQueueWithCurrentDuration(duration);
      });
      // In this example, we automatically start playing on start.
      onPlay();
    } catch (e) {
      print("Error: $e");
      onStop();
    }
  }

  @override
  Future onCustomAction(String name, params) async {
    switch (name) {
      // use custom action to stop due to an issue
      // with when directly calling AudioService.stop
      case 'stop':
        await onStop();
        break;
    }
    return super.onCustomAction(name, params);
  }

  @override
  Future<void> onAddQueueItem(MediaItem mediaItem) async {
    mediaQueue.add(mediaItem);
    await concatenatingAudioSource
        .add(AudioSource.uri(Uri.parse(mediaItem.extras['uri'])));

    // broadcast the queue
    await AudioServiceBackground.setQueue(queue);
    return super.onAddQueueItem(mediaItem);
  }

  // remove only after checking the media item is present in the queue
  @override
  Future<void> onRemoveQueueItem(MediaItem mediaItem) async {
    int removeIndex = mediaQueue.indexOf(mediaItem);
    mediaQueue.remove(mediaItem);
    await concatenatingAudioSource.removeAt(removeIndex);

    // broadcast the queue
    await AudioServiceBackground.setQueue(queue);
    return super.onRemoveQueueItem(mediaItem);
  }

  @override
  Future<void> onUpdateQueue(List<MediaItem> queueList) async {
    mediaQueue = queueList;

    // clear the audio sources
    await concatenatingAudioSource.clear();
    // add all new audio sources
    await concatenatingAudioSource.addAll(
        queueList.map((item) => AudioSource.uri(Uri.parse(item.extras['uri']))).toList());

    // broadcast the queue
    await AudioServiceBackground.setQueue(queueList);

    return super.onUpdateQueue(queueList);
  }

  // updates the media item data with duration after decoding
  // reference from audio_service github issue 543
  void updateQueueWithCurrentDuration(Duration duration) {
    final songIndex = _player.playbackEvent.currentIndex;
    print('current index: $songIndex, duration: $duration');
    final modifiedMediaItem = mediaItem.copyWith(duration: duration);
    mediaQueue[songIndex] = modifiedMediaItem;
    AudioServiceBackground.setMediaItem(queue[songIndex]);
    AudioServiceBackground.setQueue(queue);
  }

  @override
  Future<void> onSkipToQueueItem(String mediaId) async {
    // Then default implementations of onSkipToNext and onSkipToPrevious will
    // delegate to this method.
    final newIndex = queue.indexWhere((item) => item.id == mediaId);
    if (newIndex == -1) return;
    // During a skip, the player may enter the buffering state. We could just
    // propagate that state directly to AudioService clients but AudioService
    // has some more specific states we could use for skipping to next and
    // previous. This variable holds the preferred state to send instead of
    // buffering during a skip, and it is cleared as soon as the player exits
    // buffering (see the listener in onStart).
    _skipState = newIndex > index
        ? AudioProcessingState.skippingToNext
        : AudioProcessingState.skippingToPrevious;
    // This jumps to the beginning of the queue item at newIndex.
    _player.seek(Duration.zero, index: newIndex);
    // Demonstrate custom events.
    AudioServiceBackground.sendCustomEvent('skip to $newIndex');
  }

  @override
  Future<void> onSkipToPrevious() async {
    // if player played more than 3 seconds
    // then seek to beginning of the media
    if (_player.position > Duration(seconds: 3)) {
      await _player.seek(Duration.zero, index: _player.currentIndex);
      return;
    } else {
      _skipState = AudioProcessingState.skippingToPrevious;
      await _player.seekToPrevious();
    }
    return super.onSkipToPrevious();
  }

  @override
  Future<void> onPlay() async {
    // if played when end of the queue, play from starting
    if (_player.processingState == ProcessingState.completed)
      await _player.seek(Duration.zero, index: 0);
    _player.play();
    await super.onPlay();
  }

  @override
  Future<void> onPause() => _player.pause();

  @override
  Future<void> onSeekTo(Duration position) => _player.seek(position);

  @override
  Future<void> onFastForward() => _seekRelative(fastForwardInterval);

  @override
  Future<void> onRewind() => _seekRelative(-rewindInterval);

  @override
  Future<void> onSeekForward(bool begin) async => _seekContinuously(begin, 1);

  @override
  Future<void> onSeekBackward(bool begin) async => _seekContinuously(begin, -1);

  @override
  Future<void> onSetShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    await _player
        .setShuffleModeEnabled(shuffleMode == AudioServiceShuffleMode.all);
    // broadcast shuffle state to the UI
    await _broadcastState();
    return super.onSetShuffleMode(shuffleMode);
  }

  @override
  Future<void> onSetRepeatMode(AudioServiceRepeatMode repeatMode) async {
    LoopMode loopMode;
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        loopMode = LoopMode.off;
        break;
      case AudioServiceRepeatMode.all:
        loopMode = LoopMode.all;
        break;
      case AudioServiceRepeatMode.one:
        loopMode = LoopMode.one;
        break;
      default:
        loopMode = LoopMode.off;
    }
    await _player.setLoopMode(loopMode);
    // broadcast loop state to the UI
    await _broadcastState();
    return super.onSetRepeatMode(repeatMode);
  }

  // called on swipe of notification (when paused)
  @override
  Future<void> onTaskRemoved() => onStop();

  @override
  Future<void> onStop() async {
    await _player.stop();
    await _player.dispose();
    _eventSubscription.cancel();
    // It is important to wait for this state to be broadcast before we shut
    // down the task. If we don't, the background task will be destroyed before
    // the message gets sent to the UI.
    await _broadcastState();
    // Shut down this task
    await super.onStop();
  }

  /// Jumps away from the current position by [offset].
  Future<void> _seekRelative(Duration offset) async {
    var newPosition = _player.position + offset;
    // Make sure we don't jump out of bounds.
    if (newPosition < Duration.zero) newPosition = Duration.zero;
    if (newPosition > mediaItem.duration) newPosition = mediaItem.duration;
    // Perform the jump via a seek.
    await _player.seek(newPosition);
  }

  /// Begins or stops a continuous seek in [direction]. After it begins it will
  /// continue seeking forward or backward by 10 seconds within the audio, at
  /// intervals of 1 second in app time.
  void _seekContinuously(bool begin, int direction) {
    _seeker?.stop();
    if (begin) {
      _seeker = Seeker(_player, Duration(seconds: 10 * direction),
          Duration(seconds: 1), mediaItem)
        ..start();
    }
  }

  /// Broadcasts the current state to all clients.
  Future<void> _broadcastState() async {
    LoopMode loopMode = _player.loopMode;
    AudioServiceRepeatMode audioServiceRepeatMode;
    switch (loopMode) {
      case LoopMode.off:
        audioServiceRepeatMode = AudioServiceRepeatMode.none;
        break;
      case LoopMode.all:
        audioServiceRepeatMode = AudioServiceRepeatMode.all;
        break;
      case LoopMode.one:
        audioServiceRepeatMode = AudioServiceRepeatMode.one;
        break;
      default:
        audioServiceRepeatMode = AudioServiceRepeatMode.none;
    }
    AudioServiceShuffleMode audioServiceShuffleMode =
        (_player.shuffleModeEnabled)
            ? AudioServiceShuffleMode.all
            : AudioServiceShuffleMode.none;
    await AudioServiceBackground.setState(
      controls: [
        MediaControl.skipToPrevious,
        _player.playing ? MediaControl.pause : MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: [
        MediaAction.seekTo,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      ],
      androidCompactActions: [0, 1, 2],
      processingState: _getProcessingState(),
      playing: _player.playing,
      position: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      repeatMode: audioServiceRepeatMode,
      shuffleMode: audioServiceShuffleMode,
    );
  }

  /// Maps just_audio's processing state into audio_service's playing
  /// state. If we are in the middle of a skip, we use [_skipState] instead.
  AudioProcessingState _getProcessingState() {
    if (_skipState != null) return _skipState;
    switch (_player.processingState) {
      case ProcessingState.idle:
        return AudioProcessingState.stopped;
      case ProcessingState.loading:
        return AudioProcessingState.connecting;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
      default:
        throw Exception("Invalid state: ${_player.processingState}");
    }
  }
}

class Seeker {
  final AudioPlayer player;
  final Duration positionInterval;
  final Duration stepInterval;
  final MediaItem mediaItem;
  bool _running = false;

  Seeker(
    this.player,
    this.positionInterval,
    this.stepInterval,
    this.mediaItem,
  );

  start() async {
    _running = true;
    while (_running) {
      Duration newPosition = player.position + positionInterval;
      if (newPosition < Duration.zero) newPosition = Duration.zero;
      if (newPosition > mediaItem.duration) newPosition = mediaItem.duration;
      player.seek(newPosition);
      await Future.delayed(stepInterval);
    }
  }

  stop() {
    _running = false;
  }
}
