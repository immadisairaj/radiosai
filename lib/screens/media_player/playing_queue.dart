import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:radiosai/audio_service/audio_manager.dart';
import 'package:radiosai/audio_service/notifiers/play_button_notifier.dart';
import 'package:radiosai/audio_service/service_locator.dart';

class PlayingQueue extends StatefulWidget {
  const PlayingQueue({
    Key? key,
  }) : super(key: key);

  static const String route = 'playingQueue';

  @override
  _PlayingQueue createState() => _PlayingQueue();
}

class _PlayingQueue extends State<PlayingQueue> {
  AudioManager? _audioManager;

  @override
  void initState() {
    // get audio manager
    _audioManager = getIt<AudioManager>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // check if dark theme
    bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    Color backgroundColor = Theme.of(context).backgroundColor;

    // get the heights of the screen (useful for split screen)
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    // bool isBigScreen = (height * 0.1 >= 50); // 3/4 screen
    // bool isBiggerScreen = (height * 0.1 >= 70); // full screen
    bool isSmallerScreen = (height * 0.1 < 30); // 1/4 screen

    return Scaffold(
      body: SafeArea(
        child: Container(
          color: backgroundColor,
          child: Center(
            child: Column(
              children: [
                if (!isSmallerScreen)
                  GestureDetector(
                    onTap: () {
                      // pop to media player
                      Navigator.maybePop(context);
                    },
                    child: Container(
                      height: height * 0.1,
                      width: width,
                      color: Colors.transparent,
                      child: Material(
                        color: Colors.transparent,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              icon: Icon((Platform.isAndroid)
                                  ? Icons.keyboard_arrow_down_outlined
                                  : CupertinoIcons.back),
                              splashRadius: 24,
                              iconSize: 25,
                              onPressed: () {
                                // pop to media player
                                Navigator.maybePop(context);
                              },
                            ),
                            ValueListenableBuilder<String>(
                              valueListenable:
                                  _audioManager!.currentSongTitleNotifier,
                              builder: (context, mediaTitle, child) {
                                return SizedBox(
                                  width: width * 0.65,
                                  child: Text(
                                    // Display Audio Title
                                    mediaTitle,
                                    textAlign: TextAlign.start,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 18,
                                    ),
                                  ),
                                );
                              },
                            ),
                            // Pause/Play button
                            ValueListenableBuilder<PlayButtonState>(
                                valueListenable:
                                    _audioManager!.playButtonNotifier,
                                builder: (context, playState, child) {
                                  final playing =
                                      (playState == PlayButtonState.playing);

                                  return playing ? pauseButton() : playButton();
                                }),
                          ],
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: ValueListenableBuilder<List<String>>(
                    valueListenable: _audioManager!.queueNotifier,
                    builder: (context, queueList, child) {
                      if (queueList.isEmpty) {
                        return const Center(
                          child: Text('No files in queue'),
                        );
                      }

                      return ValueListenableBuilder<String>(
                          valueListenable:
                              _audioManager!.currentSongTitleNotifier,
                          builder: (context, currentMediaTitle, child) {
                            return Scrollbar(
                              radius: const Radius.circular(8),
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(
                                    parent: AlwaysScrollableScrollPhysics()),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  primary: false,
                                  padding:
                                      const EdgeInsets.only(top: 2, bottom: 2),
                                  itemCount: queueList.length,
                                  itemBuilder: (context, index) {
                                    final mediaTitle = queueList[index];
                                    bool isCurrentItem = false;
                                    if (mediaTitle == currentMediaTitle) {
                                      isCurrentItem = true;
                                    }
                                    return _queueItemWidget(
                                        context,
                                        mediaTitle,
                                        isCurrentItem,
                                        queueList.length,
                                        isDarkTheme);
                                  },
                                ),
                              ),
                            );
                          });
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      child: Padding(
                        padding: const EdgeInsets.only(
                            left: 10, right: 10, top: 8, bottom: 8),
                        child: Text(
                          'CLEAR',
                          style: TextStyle(
                            fontSize: 20,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                      onTap: () async {
                        // stop the player and clear the queue
                        _audioManager!.clear();
                        Navigator.maybePop(context);
                      },
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

  /// widget for each queue item
  ///
  /// also shows if the widget is playing (with different color)
  Widget _queueItemWidget(BuildContext context, String mediaTitle,
      bool isCurrentItem, int length, bool isDarkTheme) {
    Color? selectedColor = isDarkTheme ? Colors.grey[800] : Colors.grey[300];
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.only(left: 10, right: 10),
        child: Card(
          elevation: 0,
          color: isCurrentItem ? selectedColor : Colors.transparent,
          child: InkWell(
            child: Padding(
              padding: const EdgeInsets.only(top: 5, left: 5, bottom: 5),
              child: ListTile(
                leading: const SizedBox(
                  height: 40,
                  width: 40,
                  child: Image(
                    fit: BoxFit.cover,
                    alignment: Alignment(0, -1),
                    // TODO: get image from artUri
                    image: AssetImage('assets/sai_listens.jpg'),
                  ),
                ),
                title: Text(mediaTitle),
                trailing: IconButton(
                    icon: const Icon(CupertinoIcons.minus_circle),
                    splashRadius: 24,
                    tooltip: 'Remove from playing queue',
                    onPressed: () async {
                      if (length == 1) {
                        _audioManager!.stop();
                        Navigator.maybePop(context);
                      } else {
                        await _audioManager!
                            .removeQueueItemWithTitle(mediaTitle);
                      }
                    }),
              ),
            ),
            onTap: () {
              if (isCurrentItem) return;
              int index =
                  _audioManager!.queueNotifier.value.indexOf(mediaTitle);
              _audioManager!.skipToQueueItem(index);
            },
            borderRadius: BorderRadius.circular(8.0),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),
    );
  }

  /// play button
  IconButton playButton() => IconButton(
        icon: const Icon(CupertinoIcons.play),
        splashRadius: 24,
        iconSize: 25,
        onPressed: _audioManager!.play,
      );

  /// pause button
  IconButton pauseButton() => IconButton(
        icon: const Icon(CupertinoIcons.pause),
        splashRadius: 24,
        iconSize: 25,
        onPressed: _audioManager!.pause,
      );
}
