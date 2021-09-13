import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:radiosai/audio_service/audio_manager.dart';
import 'package:radiosai/audio_service/notifiers/loading_notifier.dart';
import 'package:radiosai/audio_service/notifiers/play_button_notifier.dart';
import 'package:radiosai/audio_service/notifiers/progress_notifier.dart';
import 'package:radiosai/audio_service/notifiers/repeat_button_notifier.dart';
import 'package:radiosai/audio_service/service_locator.dart';
import 'package:radiosai/helper/download_helper.dart';
import 'package:radiosai/helper/media_helper.dart';
import 'package:radiosai/screens/media_player/playing_queue.dart';
import 'package:share_plus/share_plus.dart';

class MediaPlayer extends StatefulWidget {
  MediaPlayer({
    Key key,
  }) : super(key: key);

  @override
  _MediaPlayer createState() => _MediaPlayer();
}

class _MediaPlayer extends State<MediaPlayer> {
  /// external media directory to where the files have to
  /// download.
  ///
  /// Sets when initState is called
  String _mediaDirectory = '';

  /// set of download tasks
  List<DownloadTaskInfo> _downloadTasks;

  AudioManager _audioManager;

  @override
  void initState() {
    // get audio manager
    _audioManager = getIt<AudioManager>();
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
    // bool isBiggerScreen = (height * 0.1 >= 70); // full screen
    bool isSmallerScreen = (height * 0.1 < 30); // 1/4 screen

    return Scaffold(
      body: SafeArea(
        child: Container(
          color: backgroundColor,
          child: Center(
            child: Column(
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
                            _shareButton(),
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
                    ValueListenableBuilder<ProgressBarState>(
                      valueListenable: _audioManager.progressNotifier,
                      builder: (context, value, child) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 16, right: 16),
                          child: ProgressBar(
                            total: value.total,
                            progress: value.current,
                            buffered: value.buffered,
                            timeLabelType: TimeLabelType.remainingTime,
                            timeLabelTextStyle:
                                Theme.of(context).textTheme.caption,
                            onSeek: _audioManager.seek,
                          ),
                        );
                      },
                    ),
                  ],
                ),

                // Text Display.
                ValueListenableBuilder<String>(
                  valueListenable: _audioManager.currentSongTitleNotifier,
                  builder: (context, mediaTitle, child) {
                    double textSize = (isSmallerScreen) ? 15 : 20;
                    return SizedBox(
                      height: (isSmallerScreen) ? textSize * 2 : textSize * 3.5,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 20, right: 20),
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
                ValueListenableBuilder<List<String>>(
                  valueListenable: _audioManager.queueNotifier,
                  builder: (context, queueList, child) {
                    final queue = queueList;
                    if (queue == null || queue.isEmpty)
                      Navigator.maybePop(context);
                    double iconSize = width / 9;

                    return ValueListenableBuilder<String>(
                      valueListenable: _audioManager.currentSongTitleNotifier,
                      builder: (context, mediaTitle, child) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 8, right: 8),
                          child: Material(
                            color: Colors.transparent,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // repeat mode button
                                ValueListenableBuilder<RepeatState>(
                                  valueListenable:
                                      _audioManager.repeatButtonNotifier,
                                  builder: (context, value, child) {
                                    int repeatModeInt = 0;
                                    switch (value) {
                                      case RepeatState.off:
                                        repeatModeInt = 0;
                                        break;
                                      case RepeatState.repeatQueue:
                                        repeatModeInt = 1;
                                        break;
                                      case RepeatState.repeatSong:
                                        repeatModeInt = 2;
                                        break;
                                      default:
                                        repeatModeInt = 0;
                                    }
                                    IconData repeatModeIcon =
                                        (repeatModeInt == 2)
                                            ? CupertinoIcons.repeat_1
                                            : CupertinoIcons.repeat;
                                    return IconButton(
                                      icon: Icon(repeatModeIcon),
                                      splashRadius: 24,
                                      iconSize: iconSize - 15,
                                      color: (repeatModeInt > 0)
                                          ? Theme.of(context).accentColor
                                          : null,
                                      onPressed: _audioManager.repeat,
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: Icon(CupertinoIcons.backward_end),
                                  splashRadius: 24,
                                  iconSize: iconSize - 10,
                                  onPressed: _audioManager.previous,
                                ),
                                // seek 10 seconds backward
                                ValueListenableBuilder<ProgressBarState>(
                                    valueListenable:
                                        _audioManager.progressNotifier,
                                    builder: (context, value, child) {
                                      Duration position = value.current;
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
                                                _audioManager
                                                    .seek(seekPosition);
                                              },
                                      );
                                    }),
                                // Play/pause buttons
                                ValueListenableBuilder<PlayButtonState>(
                                  valueListenable:
                                      _audioManager.playButtonNotifier,
                                  builder: (context, playState, child) {
                                    final playing =
                                        (playState == PlayButtonState.playing);
                                    return Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // loading indicator
                                        ValueListenableBuilder<LoadingState>(
                                          valueListenable:
                                              _audioManager.loadingNotifier,
                                          builder: (context, loadingState,
                                              snapshot) {
                                            bool isLoading = (loadingState ==
                                                LoadingState.loading);
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
                                ValueListenableBuilder<ProgressBarState>(
                                    valueListenable:
                                        _audioManager.progressNotifier,
                                    builder: (context, value, child) {
                                      Duration position = value.current;
                                      Duration duration = value.total;
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
                                                _audioManager
                                                    .seek(seekPosition);
                                              },
                                      );
                                    }),
                                IconButton(
                                  icon: Icon(CupertinoIcons.forward_end),
                                  splashRadius: 24,
                                  iconSize: iconSize - 10,
                                  onPressed: (mediaTitle != null &&
                                          queue != null &&
                                          queue.isNotEmpty &&
                                          mediaTitle == queue.last)
                                      ? null
                                      : (mediaTitle != null)
                                          ? _audioManager.next
                                          : null,
                                ),
                                // shuffle mode button
                                ValueListenableBuilder<bool>(
                                  valueListenable: _audioManager
                                      .isShuffleModeEnabledNotifier,
                                  builder: (context, isShuffle, child) {
                                    return IconButton(
                                      icon: Icon(CupertinoIcons.shuffle),
                                      splashRadius: 24,
                                      iconSize: iconSize - 15,
                                      color: (isShuffle)
                                          ? Theme.of(context).accentColor
                                          : null,
                                      onPressed: _audioManager.shuffle,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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
                                      builder: (context) => PlayingQueue()));
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// widget for top menu
  ///
  /// options for the current playing song/player
  Widget _options(bool isDarkTheme) {
    List<String> optionsList = [
      // TODO: fix download and then uncomment below line
      // 'Download',
      'Share',
      'View Playing Queue',
    ];
    return StreamBuilder<MediaItem>(
        stream: _audioManager.currentMediaItem,
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
                    case 'Share':
                      _shareMediaFileLink(
                          MediaHelper.getLinkFromFileId(mediaId));
                      break;
                  }
                },
              ),
            ),
          );
        });
  }

  Widget _shareButton() {
    return StreamBuilder<MediaItem>(
        stream: _audioManager.currentMediaItem,
        builder: (context, snapshot) {
          final mediaItem = snapshot.data;
          final mediaId = (mediaItem != null && mediaItem?.id != null)
              ? mediaItem.id
              : 'loading media...';
          if (mediaId == 'loading media...')
            return IconButton(
              icon: Icon(Icons.share_outlined),
              iconSize: 25,
              splashRadius: 24,
              onPressed: () {},
            );

          return IconButton(
            icon: Icon(Icons.share_outlined),
            splashRadius: 24,
            iconSize: 25,
            onPressed: () {
              _shareMediaFileLink(MediaHelper.getLinkFromFileId(mediaId));
            },
          );
        });
  }

  /// play button
  IconButton playButton(double iconSize) => IconButton(
        icon: Icon(CupertinoIcons.play),
        splashRadius: 25,
        iconSize: iconSize,
        onPressed: _audioManager.play,
      );

  /// pause button
  IconButton pauseButton(double iconSize) => IconButton(
        icon: Icon(CupertinoIcons.pause),
        splashRadius: 25,
        iconSize: iconSize,
        onPressed: _audioManager.pause,
      );

  void _showSnackBar(BuildContext context, String text, Duration duration) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
      behavior: SnackBarBehavior.floating,
      duration: duration,
    ));
  }

  /// sets the path for directory
  ///
  /// doesn't care if the directory is created or not
  _getDirectoryPath() async {
    final mediaDirectoryPath = await MediaHelper.getDirectoryPath();
    setState(() {
      // update the media directory
      _mediaDirectory = mediaDirectoryPath;
    });
  }

  /// call to download the media file.
  ///
  /// pass the url [fileLink] to where it is in the internet
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
      // showNotification: false,
      showNotification: true,
      openFileFromNotification: false,
    );
    int i = _downloadTasks.indexOf(task);
    _downloadTasks[i].taskId = taskId;
  }

  /// call to share the media link.
  ///
  /// pass the url [fileLink] to where it is in the internet
  _shareMediaFileLink(String fileLink) {
    String subject = "Checkout this audio from radiosai!";
    String text = fileLink +
        "\n\nShared using Sai Voice app" +
        "\nInstall from https://play.google.com/store/apps/details?id=com.immadisairaj.radiosai";
    Share.share(text, subject: subject);
  }

  /// returns if the app has permission to save in external path
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
  final PlaybackState playbackState;

  MediaState(this.mediaItem, this.position, this.playbackState);
}
