import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:radiosai/audio_service/notifiers/loading_notifier.dart';
import 'package:radiosai/audio_service/notifiers/media_type_notifier.dart';
import 'package:radiosai/audio_service/notifiers/play_button_notifier.dart';
import 'package:radiosai/audio_service/notifiers/progress_notifier.dart';
import 'package:radiosai/audio_service/notifiers/repeat_button_notifier.dart';
import 'package:radiosai/audio_service/service_locator.dart';
import 'package:radiosai/helper/media_helper.dart';

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

  _setMediaType(MediaType mediaType) {
    _audioHandler.customAction('setMediaType', {'mediaType': mediaType});
  }

  /// pass radioStream map which is located in constants
  /// as params['radioStream']
  ///
  /// and index of the radio playing as params['index']
  Future<void> _initRadio(Map<String, dynamic> params) async {
    mediaTypeNotifier.value = MediaType.radio;
    final radio = await _getRadio(
        params['radioStream'], params['index'], params['artImages']);
    await _loadRadio(radio);
    _listenToChangesInQueue();
    _listenToPlaybackState();
    _listenToCurrentPosition();
    _listenToBufferedPosition();
    _listenToTotalDuration();
    _listenToChangesInSong();
    return;
  }

  /// pass [radioStream] map which is located in constants
  /// and [index] of the radio playing
  Future<MediaItem> _getRadio(Map<String, String> radioStream, int index,
      Map<String, String> artLinks) async {
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
        extras: {'uri': value});
  }

  Future<void> _loadRadio(MediaItem radio) async {
    _audioHandler.addQueueItem(radio);
  }

  /// pass [radioIndex] - the index of 'radioStream'
  playRadio(int radioIndex) async {
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
    _listenToCurrentPosition();
    _listenToBufferedPosition();
    _listenToTotalDuration();
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
      artUri: Uri.parse(params['artUri']),
      extras: {'uri': params['extrasUri']},
    );
  }

  _loadMediaItem(MediaItem mediaItem) async {
    _audioHandler.addQueueItem(mediaItem);
    await load();
  }

  get queue => _audioHandler.queue;
  get currentMediaItem => _audioHandler.mediaItem;

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
      if (!isPlaying) {
        playButtonNotifier.value = PlayButtonState.paused;
      } else if (processingState != AudioProcessingState.completed) {
        playButtonNotifier.value = PlayButtonState.playing;
      } else {
        _audioHandler.seek(Duration.zero);
        _audioHandler.pause();
      }
    });
  }

  void _listenToCurrentPosition() {
    AudioService.position.listen((position) {
      final ProgressBarState oldState = progressNotifier.value;
      progressNotifier.value = ProgressBarState(
        current: position,
        buffered: oldState.buffered,
        total: oldState.total,
      );
    });
  }

  void _listenToBufferedPosition() {
    _audioHandler.playbackState.listen((playbackState) {
      final ProgressBarState oldState = progressNotifier.value;
      progressNotifier.value = ProgressBarState(
        current: oldState.current,
        buffered: playbackState.bufferedPosition,
        total: oldState.total,
      );
    });
  }

  void _listenToTotalDuration() {
    _audioHandler.mediaItem.listen((mediaItem) {
      final ProgressBarState oldState = progressNotifier.value;
      progressNotifier.value = ProgressBarState(
        current: oldState.current,
        buffered: oldState.buffered,
        total: mediaItem?.duration ?? Duration.zero,
      );
    });
  }

  void _listenToChangesInSong() {
    _audioHandler.mediaItem.listen((mediaItem) {
      currentSongTitleNotifier.value = mediaItem?.title ?? '';
      _updateSkipButtons();
    });
  }

  void _updateSkipButtons() {
    final mediaItem = _audioHandler.mediaItem.value;
    final playlist = _audioHandler.queue.value;
    if (playlist.length < 2 || mediaItem == null) {
      isFirstSongNotifier.value = true;
      isLastSongNotifier.value = true;
    } else {
      isFirstSongNotifier.value = playlist.first == mediaItem;
      isLastSongNotifier.value = playlist.last == mediaItem;
    }
  }

  get playbackState => _audioHandler.playbackState;

  Future<void> addQueueItem(MediaItem mediaItem) =>
      _audioHandler.addQueueItem(mediaItem);

  Future<void> removeQueueItemWithTitle(String mediaTitle) async {
    final index = queueNotifier.value.indexOf(mediaTitle);
    if (index == -1) return;
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
