import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:radiosai/helper/download_helper.dart';
import 'package:radiosai/helper/media_helper.dart';
import 'package:radiosai/screens/media_player/playing_queue.dart';
import 'package:rxdart/rxdart.dart';

class MediaPlayer extends StatefulWidget {
  MediaPlayer({
    Key key,
  }) : super(key: key);

  @override
  _MediaPlayer createState() => _MediaPlayer();
}

class _MediaPlayer extends State<MediaPlayer> {
  String _mediaDirectory = '';
  List<DownloadTaskInfo> _downloadTasks;

  @override
  void initState() {
    super.initState();
    _getDirectoryPath();

    _downloadTasks = DownloadHelper.getDownloadTasks();
  }

  @override
  Widget build(BuildContext context) {
    // check if dark theme
    bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    Color backgroundColor = isDarkTheme ? Colors.grey[700] : Colors.white;

    // get the heights of the screen (useful for split screen)
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    bool isBigScreen = (height * 0.1 >= 50); // 3/4 screen
    bool isBiggerScreen = (height * 0.1 >= 70); // full screen
    bool isSmallerScreen = (height * 0.1 < 30); // 1/4 screen

    return Scaffold(
      body: SafeArea(
        child: Container(
          color: backgroundColor,
          child: Center(
            child: StreamBuilder<bool>(
              stream: AudioService.runningStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.active) {
                  // Don't show anything until we've ascertained whether or not the
                  // service is running, since we want to show a different UI in
                  // each case.
                  return SizedBox();
                }
                final running = snapshot.data ?? true;
                // pop if the media player is not running
                if (!running) Navigator.maybePop(context);
                return Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // UI to show when we're running, i.e. player state/controls.

                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
                      child: Material(
                        color: Colors.transparent,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Icon(Icons.arrow_back_outlined),
                              splashRadius: 24,
                              iconSize: 25,
                              onPressed: () {
                                Navigator.maybePop(context);
                              },
                            ),
                            Row(
                              children: [
                                // TODO: maybe add a share?
                                _options(isDarkTheme),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (isBigScreen)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: SizedBox(
                              width: height * 0.35,
                              height: height * 0.35,
                              child: Image(
                                fit: BoxFit.cover,
                                alignment: Alignment(0, -1),
                                // TODO: get image from artUri
                                image: AssetImage('assets/sai_listens.jpg'),
                              ),
                            ),
                          ),

                        // A seek bar.
                        StreamBuilder<MediaState>(
                          stream: _mediaStateStream,
                          builder: (context, snapshot) {
                            final mediaState = snapshot.data;
                            return SeekBar(
                              duration: mediaState?.mediaItem?.duration ??
                                  Duration.zero,
                              position: mediaState?.position ?? Duration.zero,
                              onChangeEnd: (newPosition) {
                                AudioService.seekTo(newPosition);
                              },
                            );
                          },
                        ),
                      ],
                    ),

                    // Text Display.
                    StreamBuilder<QueueState>(
                      stream: _queueStateStream,
                      builder: (context, snapshot) {
                        final queueState = snapshot.data;
                        final mediaItem = queueState?.mediaItem;
                        final mediaTitle =
                            (queueState != null && mediaItem?.title != null)
                                ? mediaItem.title
                                : 'loading media...';
                        double textSize = (isSmallerScreen) ? 15 : 20;
                        return SizedBox(
                          height:
                              (isSmallerScreen) ? textSize * 2 : textSize * 3.5,
                          child: Center(
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(left: 20, right: 20),
                              child: Text(
                                mediaTitle,
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  fontSize: textSize,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    // Queue/player controls.
                    StreamBuilder<QueueState>(
                      stream: _queueStateStream,
                      builder: (context, snapshot) {
                        final queueState = snapshot.data;
                        final queue = queueState?.queue ?? [];
                        final mediaItem = queueState?.mediaItem;
                        double iconSize = width / 9;
                        return Padding(
                          padding: const EdgeInsets.only(left: 8, right: 8),
                          child: Material(
                            color: Colors.transparent,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // repeat mode button
                                StreamBuilder<PlaybackState>(
                                  stream: AudioService.playbackStateStream,
                                  builder: (context, snapshot) {
                                    final playbackState = snapshot.data;
                                    var repeatMode =
                                        AudioServiceRepeatMode.none;
                                    if (playbackState != null)
                                      repeatMode = playbackState.repeatMode ??
                                          AudioServiceRepeatMode.none;

                                    int repeatModeInt = 0;
                                    switch (repeatMode) {
                                      case AudioServiceRepeatMode.none:
                                        repeatModeInt = 0;
                                        break;
                                      case AudioServiceRepeatMode.all:
                                        repeatModeInt = 1;
                                        break;
                                      case AudioServiceRepeatMode.one:
                                        repeatModeInt = 2;
                                        break;
                                      default:
                                        repeatModeInt = 0;
                                    }
                                    IconData repeatModeIcon =
                                        (repeatModeInt == 2)
                                            ? CupertinoIcons.repeat_1
                                            : CupertinoIcons.repeat;

                                    final setRepeatModeInt =
                                        (repeatModeInt + 1) % 3;
                                    var setRepeatMode =
                                        AudioServiceRepeatMode.none;
                                    switch (setRepeatModeInt) {
                                      case 0:
                                        setRepeatMode =
                                            AudioServiceRepeatMode.none;
                                        break;
                                      case 1:
                                        setRepeatMode =
                                            AudioServiceRepeatMode.all;
                                        break;
                                      case 2:
                                        setRepeatMode =
                                            AudioServiceRepeatMode.one;
                                        break;
                                      default:
                                        setRepeatMode =
                                            AudioServiceRepeatMode.none;
                                    }
                                    return IconButton(
                                      icon: Icon(repeatModeIcon),
                                      splashRadius: 24,
                                      iconSize: iconSize - 15,
                                      color: (repeatModeInt > 0)
                                          ? Theme.of(context).accentColor
                                          : null,
                                      onPressed: () {
                                        AudioService.setRepeatMode(
                                            setRepeatMode);
                                      },
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: Icon(CupertinoIcons.backward_end),
                                  splashRadius: 24,
                                  iconSize: iconSize - 10,
                                  onPressed: AudioService.skipToPrevious,
                                ),
                                // seek 10 seconds backward
                                StreamBuilder<MediaState>(
                                    stream: _mediaStateStream,
                                    builder: (context, snapshot) {
                                      final mediaState = snapshot.data;
                                      Duration position = Duration.zero;
                                      if (mediaState != null)
                                        position = mediaState?.position ??
                                            Duration.zero;
                                      Duration seekPosition = (position <
                                              Duration(seconds: 10))
                                          ? Duration.zero
                                          : position - Duration(seconds: 10);
                                      return IconButton(
                                        icon:
                                            Icon(CupertinoIcons.gobackward_10),
                                        splashRadius: 24,
                                        iconSize: iconSize - 10,
                                        onPressed: (position == Duration.zero)
                                            ? null
                                            : () {
                                                AudioService.seekTo(
                                                    seekPosition);
                                              },
                                      );
                                    }),
                                // Play/pause buttons
                                StreamBuilder<bool>(
                                  stream: AudioService.playbackStateStream
                                      .map((state) => state.playing)
                                      .distinct(),
                                  builder: (context, snapshot) {
                                    final playing = snapshot.data ?? false;
                                    return Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // loading indicator
                                        StreamBuilder<AudioProcessingState>(
                                          stream: AudioService
                                              .playbackStateStream
                                              .map((state) =>
                                                  state.processingState)
                                              .distinct(),
                                          builder: (context, snapshot) {
                                            final processingState =
                                                snapshot.data ??
                                                    AudioProcessingState.none;
                                            bool isLoading = (processingState ==
                                                        AudioProcessingState
                                                            .ready ||
                                                    processingState ==
                                                        AudioProcessingState
                                                            .completed)
                                                ? false
                                                : true;
                                            return Visibility(
                                              visible: isLoading,
                                              child: SizedBox(
                                                height: iconSize + 3,
                                                width: iconSize + 3,
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                            );
                                          },
                                        ),
                                        Center(
                                          child: playing
                                              ? pauseButton(iconSize)
                                              : playButton(iconSize),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                // seek 10 seconds forward
                                StreamBuilder<MediaState>(
                                    stream: _mediaStateStream,
                                    builder: (context, snapshot) {
                                      final mediaState = snapshot.data;
                                      Duration position = Duration.zero;
                                      Duration duration = Duration.zero;
                                      if (mediaState != null) {
                                        position = mediaState?.position ??
                                            Duration.zero;
                                        if (mediaState?.mediaItem != null)
                                          duration =
                                              mediaState?.mediaItem?.duration ??
                                                  Duration.zero;
                                      }
                                      Duration seekPosition = (position >
                                              (duration -
                                                  Duration(seconds: 10)))
                                          ? duration
                                          : position + Duration(seconds: 10);
                                      return IconButton(
                                        icon: Icon(CupertinoIcons.goforward_10),
                                        splashRadius: 24,
                                        iconSize: iconSize - 10,
                                        onPressed: (position == duration)
                                            ? null
                                            : () {
                                                AudioService.seekTo(
                                                    seekPosition);
                                              },
                                      );
                                    }),
                                IconButton(
                                  icon: Icon(CupertinoIcons.forward_end),
                                  splashRadius: 24,
                                  iconSize: iconSize - 10,
                                  onPressed: (mediaItem != null &&
                                          mediaItem == queue.last)
                                      ? null
                                      : (mediaItem != null)
                                          ? AudioService.skipToNext
                                          : null,
                                ),
                                // shuffle mode button
                                StreamBuilder<PlaybackState>(
                                  stream: AudioService.playbackStateStream,
                                  builder: (context, snapshot) {
                                    final playbackState = snapshot.data;
                                    var shuffleMode =
                                        AudioServiceShuffleMode.none;
                                    if (playbackState != null)
                                      shuffleMode = playbackState.shuffleMode ??
                                          AudioServiceShuffleMode.none;

                                    bool isShuffle = (shuffleMode ==
                                        AudioServiceShuffleMode.all);

                                    final setShuffleMode = (isShuffle)
                                        ? AudioServiceShuffleMode.none
                                        : AudioServiceShuffleMode.all;
                                    return IconButton(
                                      icon: Icon(CupertinoIcons.shuffle),
                                      splashRadius: 24,
                                      iconSize: iconSize - 15,
                                      color: (isShuffle)
                                          ? Theme.of(context).accentColor
                                          : null,
                                      onPressed: () {
                                        AudioService.setShuffleMode(
                                            setShuffleMode);
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    if (!isSmallerScreen)
                      Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 8),
                        child: Material(
                          color: Colors.transparent,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              IconButton(
                                icon: Icon(CupertinoIcons.music_note_list),
                                splashRadius: 24,
                                iconSize: 25,
                                onPressed: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              PlayingQueue()));
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _options(bool isDarkTheme) {
    List<String> optionsList = [
      'Download',
      'View Playing Queue',
    ];
    return StreamBuilder<MediaItem>(
        stream: AudioService.currentMediaItemStream,
        builder: (context, snapshot) {
          final mediaItem = snapshot.data;
          final mediaId = (mediaItem != null && mediaItem?.id != null)
              ? mediaItem.id
              : 'loading media...';
          if (mediaId == 'loading media...')
            return IconButton(
              icon: Icon(Icons.more_vert),
              iconSize: 25,
              splashRadius: 24,
              onPressed: () {},
            );

          var mediaFilePath = '$_mediaDirectory/$mediaId';
          var mediaFile = File(mediaFilePath);
          var isFileExists = mediaFile.existsSync();

          return ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Material(
              color: Colors.transparent,
              child: PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                ),
                color: isDarkTheme ? Colors.grey[800] : Colors.grey[300],
                iconSize: 25,
                offset: const Offset(-10, 10),
                itemBuilder: (context) {
                  return optionsList.map<PopupMenuEntry<String>>((value) {
                    bool enabled = true;
                    String text = value;
                    // if already downloaded, disable download button
                    if (value == 'Download' && isFileExists) {
                      enabled = false;
                      text = 'Downloaded';
                    }
                    return PopupMenuItem<String>(
                      enabled: enabled,
                      value: value,
                      child: Text(
                        text,
                      ),
                    );
                  }).toList();
                },
                onSelected: (value) {
                  switch (value) {
                    case 'View Playing Queue':
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => PlayingQueue()));
                      break;
                    case 'Download':
                      _downloadMediaFile(
                          MediaHelper.getLinkFromFileId(mediaId));
                      break;
                  }
                },
              ),
            ),
          );
        });
  }

  /// A stream reporting the combined state of the current media item and its
  /// current position.
  Stream<MediaState> get _mediaStateStream =>
      Rx.combineLatest2<MediaItem, Duration, MediaState>(
          AudioService.currentMediaItemStream,
          AudioService.positionStream,
          (mediaItem, position) => MediaState(mediaItem, position));

  /// A stream reporting the combined state of the current queue and the current
  /// media item within that queue.
  Stream<QueueState> get _queueStateStream =>
      Rx.combineLatest2<List<MediaItem>, MediaItem, QueueState>(
          AudioService.queueStream,
          AudioService.currentMediaItemStream,
          (queue, mediaItem) => QueueState(queue, mediaItem));

  IconButton playButton(double iconSize) => IconButton(
        icon: Icon(CupertinoIcons.play),
        splashRadius: 25,
        iconSize: iconSize,
        onPressed: AudioService.play,
      );

  IconButton pauseButton(double iconSize) => IconButton(
        icon: Icon(CupertinoIcons.pause),
        splashRadius: 25,
        iconSize: iconSize,
        onPressed: AudioService.pause,
      );

  void _showSnackBar(BuildContext context, String text, Duration duration) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
      behavior: SnackBarBehavior.floating,
      duration: duration,
    ));
  }

  // sets the path for directory
  // doesn't care if the directory is created or not
  _getDirectoryPath() async {
    final mediaDirectoryPath = await MediaHelper.getDirectoryPath();
    setState(() {
      // update the media directory
      _mediaDirectory = mediaDirectoryPath;
    });
  }

  _downloadMediaFile(String fileLink) async {
    var permission = await _canSave();
    if (!permission) {
      _showSnackBar(context, 'Accept storage permission to save image',
          Duration(seconds: 2));
      return;
    }
    await new Directory(_mediaDirectory).create(recursive: true);
    final fileName = fileLink.replaceAll('${MediaHelper.mediaBaseUrl}', '');

    // download only when the file is not available
    // downloading an available file will delete the file
    DownloadTaskInfo task = new DownloadTaskInfo(
      name: fileName,
      link: fileLink,
    );
    if (_downloadTasks.contains(task)) return;
    var connectionStatus = await InternetConnectionChecker().connectionStatus;
    if (connectionStatus == InternetConnectionStatus.disconnected) {
      _showSnackBar(context, 'no internet', Duration(seconds: 1));
      return;
    }
    _downloadTasks.add(task);
    _showSnackBar(context, 'downloading', Duration(seconds: 1));
    final taskId = await FlutterDownloader.enqueue(
      url: fileLink,
      savedDir: _mediaDirectory,
      fileName: fileName,
      showNotification: false,
    );
    int i = _downloadTasks.indexOf(task);
    _downloadTasks[i].taskId = taskId;
  }

  Future<bool> _canSave() async {
    var status = await Permission.storage.request();
    if (status.isGranted || status.isLimited) {
      return true;
    } else {
      return false;
    }
  }
}

class QueueState {
  final List<MediaItem> queue;
  final MediaItem mediaItem;

  QueueState(this.queue, this.mediaItem);
}

class MediaState {
  final MediaItem mediaItem;
  final Duration position;

  MediaState(this.mediaItem, this.position);
}

class SeekBar extends StatefulWidget {
  final Duration duration;
  final Duration position;
  final ValueChanged<Duration> onChanged;
  final ValueChanged<Duration> onChangeEnd;

  SeekBar({
    @required this.duration,
    @required this.position,
    this.onChanged,
    this.onChangeEnd,
  });

  @override
  _SeekBarState createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  double _dragValue;
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final value = min(_dragValue ?? widget.position.inMilliseconds.toDouble(),
        widget.duration.inMilliseconds.toDouble());
    if (_dragValue != null && !_dragging) {
      _dragValue = null;
    }

    Duration remaining = widget.duration - widget.position;
    return Stack(
      children: [
        Slider.adaptive(
          min: 0.0,
          max: widget.duration.inMilliseconds.toDouble(),
          value: value,
          onChanged: (value) {
            if (!_dragging) {
              _dragging = true;
            }
            setState(() {
              _dragValue = value;
            });
            if (widget.onChanged != null) {
              widget.onChanged(Duration(milliseconds: value.round()));
            }
          },
          onChangeEnd: (value) {
            if (widget.onChangeEnd != null) {
              widget.onChangeEnd(Duration(milliseconds: value.round()));
            }
            _dragging = false;
          },
        ),
        Positioned(
          left: 16.0,
          bottom: 0.0,
          child: Text(
              RegExp(r'((^0*[1-9]\d*:)?\d{2}:\d{2})\.\d+$')
                      .firstMatch('${widget.position}')
                      ?.group(1) ??
                  '${widget.position}',
              style: Theme.of(context).textTheme.caption),
        ),
        Positioned(
          right: 16.0,
          bottom: 0.0,
          child: Text(
              RegExp(r'((^0*[1-9]\d*:)?\d{2}:\d{2})\.\d+$')
                      .firstMatch('$remaining')
                      ?.group(1) ??
                  '${widget.duration}',
              style: Theme.of(context).textTheme.caption),
        ),
      ],
    );
  }
}
