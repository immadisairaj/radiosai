import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

class MediaPlayerTask extends BackgroundAudioTask {
  // final _mediaLibrary = MediaLibrary();
  AudioPlayer _player = new AudioPlayer();
  ConcatenatingAudioSource concatenatingAudioSource;
  AudioProcessingState _skipState;
  Seeker _seeker;
  StreamSubscription<PlaybackEvent> _eventSubscription;

  // List<MediaItem> get queue => <MediaItem>[
  //   MediaItem(
  //     id: "https://s3.amazonaws.com/scifri-segments/scifri201711241.mp3",
  //     album: "Science Friday",
  //     title: "From Cat Rheology To Operatic Incompetence",
  //     artist: "Science Friday and WNYC Studios",
  //     duration: Duration(milliseconds: 2856950),
  //     artUri: Uri.parse(
  //         "https://media.wnyc.org/i/1400/1400/l/80/1/ScienceFriday_WNYCStudios_1400.jpg"),
  //   ),
  // ];
  // List<MediaItem> get queue => _mediaLibrary.items;
  List<MediaItem> mediaQueue;
  List<MediaItem> get queue => mediaQueue;
  int get index => _player.currentIndex;
  MediaItem get mediaItem => index == null ? null : queue[index];

  @override
  Future<void> onStart(Map<String, dynamic> params) async {
    // initialize the queue
    mediaQueue = [];

    // Get the path of image for artUri in notification
    String path = await getNotificationImage();

    // Get the duration of the audio file
    int duration = await getDuration(params['audioSource']);

    // Set media item to tell the clients what is playing
    final tempMediaItem = MediaItem(
      id: params['audioSource'],
      album: "Radio Sai Global Harmony",
      title: params['audioName'],
      artist: "Radio Sai",
      duration: Duration(milliseconds: duration),
      artUri: Uri.parse('file://$path'),
    );

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
          // In this example, the service stops when reaching the end.
          onStop();
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
          queue.map((item) => AudioSource.uri(Uri.parse(item.id))).toList(),
    );
    try {
      await _player.setAudioSource(concatenatingAudioSource);
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
      case 'addToQueue':
        // Get the path of image for artUri in notification
        String path = await getNotificationImage();

        // Get the duration of the audio file
        int duration = await getDuration(params['audioSource']);

        // Set media item to tell the clients what is playing
        final tempMediaItem = MediaItem(
          id: params['audioSource'],
          album: "Radio Sai Global Harmony",
          title: params['audioName'],
          artist: "Radio Sai",
          duration: Duration(milliseconds: duration),
          artUri: Uri.parse('file://$path'),
        );

        mediaQueue.add(tempMediaItem);
        await concatenatingAudioSource
            .add(AudioSource.uri(Uri.parse(tempMediaItem.id)));

        // broadcast the queue
        AudioServiceBackground.setQueue(queue);
        break;
    }
    return super.onCustomAction(name, params);
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
  Future<void> onPlay() => _player.play();

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

  // called on swipe of notification (when paused)
  @override
  Future<void> onTaskRemoved() => onStop();

  @override
  Future<void> onStop() async {
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
    await AudioServiceBackground.setState(
      controls: [
        MediaControl.skipToPrevious,
        _player.playing ? MediaControl.pause : MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: [
        MediaAction.seekTo,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      ],
      androidCompactActions: [0, 1, 3],
      processingState: _getProcessingState(),
      playing: _player.playing,
      position: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
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

  // Get the duration of the media
  Future<int> getDuration(String mediaLink) async {
    // takes a lot of time to get the media data and holds off the UI
    // have to find another way to get the duration
    var retriever;
    try {
      retriever = new MetadataRetriever();
      await retriever.setUri(Uri.parse(mediaLink));
    } catch (e) {
      print(e);
    }
    Metadata metadata = await retriever.metadata;
    print(metadata.trackDuration.toString());
    return metadata.trackDuration;
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

// /// Provides access to a library of media items. In your app, this could come
// /// from a database or web service.
// class MediaLibrary {
//   final _items = <MediaItem>[
//     MediaItem(
//       id: "https://s3.amazonaws.com/scifri-segments/scifri201711241.mp3",
//       album: "Science Friday",
//       title: "From Cat Rheology To Operatic Incompetence",
//       artist: "Science Friday and WNYC Studios",
//       duration: Duration(milliseconds: 2856950),
//       artUri: Uri.parse(
//           "https://media.wnyc.org/i/1400/1400/l/80/1/ScienceFriday_WNYCStudios_1400.jpg"),
//     ),
//     // MediaItem(
//     //   // This can be any unique id, but we use the audio URL for convenience.
//     //   id: "http://dl.radiosai.org/SPECIAL_RUSSIAN_SONGS.mp3",
//     //   album: "Science Friday",
//     //   title: "Special Russian Songs",
//     //   artist: "RS",
//     //   duration: Duration(milliseconds: 3150916),
//     //   artUri: Uri.parse(
//     //       "https://media.wnyc.org/i/1400/1400/l/80/1/ScienceFriday_WNYCStudios_1400.jpg"),
//     // ),
//   ];

//   List<MediaItem> get items => _items;
// }
