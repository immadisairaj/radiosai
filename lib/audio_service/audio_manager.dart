import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:radiosai/audio_service/notifiers/loading_notifier.dart';
import 'package:radiosai/audio_service/notifiers/media_type_notifier.dart';
import 'package:radiosai/audio_service/notifiers/play_button_notifier.dart';
import 'package:radiosai/audio_service/notifiers/progress_notifier.dart';
import 'package:radiosai/audio_service/notifiers/repeat_button_notifier.dart';
import 'package:radiosai/audio_service/service_locator.dart';
import 'package:radiosai/helper/media_helper.dart';
import 'package:rxdart/rxdart.dart';

class AudioManager {
  // Listeners: Updates going to the UI
  final mediaTypeNotifier = MediaTypeNotifier();
  final currentSongTitleNotifier = ValueNotifier<String>('');
  final queueNotifier = ValueNotifier<List<String>>([]);
  final progressNotifier = ProgressNotifier();
  final repeatButtonNotifier = RepeatButtonNotifier();
  final isFirstSongNotifier = ValueNotifier<bool>(true);
  final playButtonNotifier = PlayButtonNotifier();
  final loadingNotifier = LoadingNotifier();
  final isLastSongNotifier = ValueNotifier<bool>(true);
  final isShuffleModeEnabledNotifier = ValueNotifier<bool>(false);

  final AudioHandler _audioHandler = getIt<AudioHandler>();

  /// if [mediaType] is [MediaType.radio],
  /// pass radioStream map which is located in "MyConstants"
  /// in [params] as params['radioStream'] &
  /// pass radio playing index in [params] as params['index'].
  ///
  /// if [mediaType] is [MediaType.media],
  /// pass mediaItem
  /// in [params].
  Future<void> init(MediaType mediaType, Map<String, dynamic> params) async {
    _setMediaType(mediaType);
    // calling clear is necessary
    await clear();
    await initAudioPlayer();
    (mediaType == MediaType.radio)
        ? await _initRadio(params)
        : await _initMedia(params);
  }

  void _setMediaType(MediaType mediaType) {
    _audioHandler.customAction('setMediaType', {'mediaType': mediaType});
  }

  /// pass radioStream map which is located in constants
  /// as params['radioStream']
  ///
  /// and index of the radio playing as params['index']
  Future<void> _initRadio(Map<String, dynamic> params) async {
    mediaTypeNotifier.value = MediaType.radio;
    final radio = await _getRadio(
      params['radioStream'],
      params['index'],
      params['artImages'],
    );
    await _loadRadio(radio);
    _listenToChangesInQueue();
    _listenToPlaybackState();
    _listenToProgress();
    _listenToChangesInSong();
    return;
  }

  /// pass [radioStream] map which is located in constants
  /// and [index] of the radio playing
  Future<MediaItem> _getRadio(
    Map<String, String> radioStream,
    int index,
    Map<String, String> artLinks,
  ) async {
    // Get the path of image for artUri in notification
    // String path = await MediaHelper.getDefaultNotificationImage();
    String key = radioStream.keys.toList()[index];
    String value = radioStream.values.toList()[index];
    String artUri = artLinks.values.toList()[index];
    return MediaItem(
      id: key,
      title: key,
      album: 'Radio Sai Global Harmony',
      artist: 'Radio Sai',
      artUri: Uri.parse(artUri),
      // artUri: Uri.parse('file://$path'),
      extras: {'uri': value},
    );
  }

  Future<void> _loadRadio(MediaItem radio) async {
    _audioHandler.addQueueItem(radio);
  }

  /// pass [radioIndex] - the index of 'radioStream'
  Future<void> playRadio(int radioIndex) async {
    // radio title is media Id
    await load();
    _audioHandler.skipToQueueItem(radioIndex);
    _audioHandler.play();
  }

  Future<void> _initMedia(Map<String, dynamic> params) async {
    mediaTypeNotifier.value = MediaType.media;
    // TODO: later make this to get media list too
    final mediaItem = _getMediaItem(params);
    await _loadMediaItem(mediaItem);
    _listenToChangesInQueue();
    _listenToPlaybackState();
    _listenToProgress();
    _listenToChangesInSong();
    pause();
    seek(Duration.zero);
    play();
  }

  MediaItem _getMediaItem(Map<String, dynamic> params) {
    // extras['uri'] contains the audio source
    // set the media item sent from params (when initializing the player)
    // for now, initializes with only 1 media item
    return MediaItem(
      id: params['id'],
      album: params['album'],
      title: params['title'],
      artist: params['artist'],
      duration: params['duration'],
      artUri: Uri.parse(params['artUri']),
      extras: {'uri': params['extrasUri']},
    );
  }

  Future<void> _loadMediaItem(MediaItem mediaItem) async {
    _audioHandler.addQueueItem(mediaItem);
  }

  ValueStream<List<MediaItem>> get queue => _audioHandler.queue;
  ValueStream<MediaItem?> get currentMediaItem => _audioHandler.mediaItem;

  void _listenToChangesInQueue() {
    _audioHandler.queue.listen((queue) {
      if (queue.isEmpty) {
        queueNotifier.value = [];
        currentSongTitleNotifier.value = '';
      } else {
        final newList = queue.map((item) => item.title).toList();
        queueNotifier.value = newList;
      }
      _updateSkipButtons();
    });
  }

  void _listenToPlaybackState() {
    _audioHandler.playbackState.listen((playbackState) {
      final processingState = playbackState.processingState;
      if (processingState == AudioProcessingState.loading ||
          processingState == AudioProcessingState.buffering) {
        loadingNotifier.value = LoadingState.loading;
      } else {
        loadingNotifier.value = LoadingState.done;
      }

      final isPlaying = playbackState.playing;
      if (processingState == AudioProcessingState.completed) {
        // Only pause if we aren't supposed to move to the next item
        // (e.g., end of playlist with repeat off)
        playButtonNotifier.value = PlayButtonState.paused;
      } else if (!isPlaying) {
        playButtonNotifier.value = PlayButtonState.paused;
      } else {
        playButtonNotifier.value = PlayButtonState.playing;
      }

      _updateSkipButtons();
    });
  }

  void _listenToProgress() {
    Rx.combineLatest3<Duration, PlaybackState, MediaItem?, ProgressBarState>(
      AudioService.position,
      _audioHandler.playbackState,
      _audioHandler.mediaItem,
      (position, state, item) => ProgressBarState(
        current: position,
        buffered: state.bufferedPosition,
        total: item?.duration ?? Duration.zero,
      ),
    ).listen((state) => progressNotifier.value = state);
  }

  void _listenToChangesInSong() {
    // Combine the media item and the playback state to ensure we are
    // showing the item that matches the player's currentIndex.
    CombineLatestStream.combine2<MediaItem?, PlaybackState, MediaItem?>(
      _audioHandler.mediaItem,
      _audioHandler.playbackState,
      (item, state) => item,
    ).listen((item) {
      if (item != null) {
        currentSongTitleNotifier.value = item.title;
        _updateSkipButtons();
      }
    });
  }

  void _updateSkipButtons() {
    // Use the values directly from the handler to avoid using
    // potentially stale local Notifier values during the transition
    final playlist = _audioHandler.queue.value;
    final state = _audioHandler.playbackState.value;
    final currentIndex = state.queueIndex;

    if (playlist.length < 2 || currentIndex == null) {
      isFirstSongNotifier.value = true;
      isLastSongNotifier.value = true;
    } else {
      isFirstSongNotifier.value = currentIndex == 0;
      isLastSongNotifier.value = currentIndex == playlist.length - 1;

      // Safety check: ensure current title matches the index
      if (currentIndex < playlist.length) {
        currentSongTitleNotifier.value = playlist[currentIndex].title;
      }
    }
  }

  ValueStream<PlaybackState> get playbackState => _audioHandler.playbackState;

  Future<void> addQueueItem(MediaItem mediaItem) =>
      _audioHandler.addQueueItem(mediaItem);

  Future<void> addQueueItems(List<MediaItem> mediaItems) =>
      _audioHandler.addQueueItems(mediaItems);

  Future<void> removeQueueItemWithTitle(String mediaTitle) async {
    final index = queueNotifier.value.indexOf(mediaTitle);
    if (index == -1) return;
    return _audioHandler.removeQueueItemAt(index);
  }

  Future<void> removeQueueItemAt(int index) {
    return _audioHandler.removeQueueItemAt(index);
  }

  void play() => _audioHandler.play();
  void pause() => _audioHandler.pause();

  void seek(Duration position) => _audioHandler.seek(position);

  Future<void> skipToQueueItem(int index) =>
      _audioHandler.skipToQueueItem(index);

  void previous() => _audioHandler.skipToPrevious();
  void next() => _audioHandler.skipToNext();

  /// Stops the audio.
  Future<void> stop() async {
    await _audioHandler.pause();
    return _audioHandler.stop();
  }

  /// Clears the audio queue
  Future<void> clear() async {
    await _audioHandler.pause();
    await _audioHandler.stop();
    return _audioHandler.customAction('clear');
  }

  /// Clears and initializes the player for the next set
  /// to play.
  Future<void> initAudioPlayer() {
    return _audioHandler.customAction('init');
  }

  void dispose() {
    _audioHandler.customAction('dispose');
  }

  void repeat() {
    repeatButtonNotifier.nextState();
    final RepeatState repeatMode = repeatButtonNotifier.value;
    switch (repeatMode) {
      case RepeatState.off:
        _audioHandler.setRepeatMode(AudioServiceRepeatMode.none);
        break;
      case RepeatState.repeatSong:
        _audioHandler.setRepeatMode(AudioServiceRepeatMode.one);
        break;
      case RepeatState.repeatQueue:
        _audioHandler.setRepeatMode(AudioServiceRepeatMode.all);
        break;
    }
  }

  void shuffle() {
    final enable = !isShuffleModeEnabledNotifier.value;
    isShuffleModeEnabledNotifier.value = enable;
    if (enable) {
      _audioHandler.setShuffleMode(AudioServiceShuffleMode.all);
    } else {
      _audioHandler.setShuffleMode(AudioServiceShuffleMode.none);
    }
  }

  Future<void> load() {
    return _audioHandler.customAction('load');
  }
}
