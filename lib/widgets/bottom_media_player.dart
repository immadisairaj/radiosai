import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:radiosai/audio_service/audio_manager.dart';
import 'package:radiosai/audio_service/notifiers/play_button_notifier.dart';
import 'package:radiosai/audio_service/service_locator.dart';
import 'package:radiosai/helper/media_helper.dart';
import 'package:radiosai/screens/media_player/media_player.dart';

/// Bottom Media Player -
/// media player to be attached in the bottomNavigationBar
///
/// shows if the media player is playing.
/// else, returns a empty (zero container) widget
class BottomMediaPlayer extends StatefulWidget {
  const BottomMediaPlayer({
    Key key,
  }) : super(key: key);

  @override
  _BottomMediaPlayer createState() => _BottomMediaPlayer();
}

class _BottomMediaPlayer extends State<BottomMediaPlayer> {
  AudioManager _audioManager;

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

    Color backgroundColor = isDarkTheme ? Colors.grey[800] : Colors.grey[300];

    // get the heights of the screen (useful for split screen)
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    bool isBigScreen = (height * 0.1 >= 50); // 3/4 screen
    bool isBiggerScreen = (height * 0.1 >= 70); // full screen
    bool isSmallerScreen = (height * 0.1 < 30); // 1/4 screen

    if (isSmallerScreen) {
      return const SizedBox(
        height: 0,
        width: 0,
      );
    }

    return ValueListenableBuilder<List<String>>(
        valueListenable: _audioManager.queueNotifier,
        builder: (context, queueList, snapshot) {
          final running = queueList.isNotEmpty &&
              _audioManager.mediaTypeNotifier.value != MediaType.radio;
          // empty widget if the media player is not running
          if (!running) {
            return const SizedBox(
              height: 0,
              width: 0,
            );
          }

          return ValueListenableBuilder<List<String>>(
              valueListenable: _audioManager.queueNotifier,
              builder: (context, queueList, snapshot) {
                // empty widget if radio player is running
                if (queueList == null || queueList.isEmpty) {
                  return const SizedBox(
                    height: 0,
                    width: 0,
                  );
                }

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const MediaPlayer()));
                  },
                  child: Container(
                    height: (isBiggerScreen) ? height * 0.08 : height * 0.1,
                    width: width,
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      border: Border(
                        top: BorderSide(
                          color: isDarkTheme ? Colors.grey[700] : Colors.white,
                        ),
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          const SizedBox(
                            height: 40,
                            width: 40,
                            child: Image(
                              fit: BoxFit.cover,
                              alignment: Alignment(0, -1),
                              // TODO: get image from artUri
                              image: AssetImage('assets/sai_listens.jpg'),
                            ),
                          ),
                          ValueListenableBuilder<String>(
                            valueListenable:
                                _audioManager.currentSongTitleNotifier,
                            builder: (context, mediaTitle, child) {
                              if (mediaTitle == '') {
                                mediaTitle = 'loading media...';
                              }
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
                              valueListenable: _audioManager.playButtonNotifier,
                              builder: (context, playState, snapshot) {
                                final playing =
                                    (playState == PlayButtonState.playing);

                                return playing ? pauseButton() : playButton();
                              }),
                        ],
                      ),
                    ),
                  ),
                );
              });
        });
  }

  IconButton playButton() => IconButton(
        icon: const Icon(CupertinoIcons.play),
        splashRadius: 24,
        iconSize: 25,
        onPressed: _audioManager.play,
      );

  IconButton pauseButton() => IconButton(
        icon: const Icon(CupertinoIcons.pause),
        splashRadius: 24,
        iconSize: 25,
        onPressed: _audioManager.pause,
      );
}
