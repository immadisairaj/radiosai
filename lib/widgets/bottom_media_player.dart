import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:radiosai/screens/media_player/media_player.dart';
import 'package:rxdart/rxdart.dart';

class BottomMediaPlayer extends StatefulWidget {
  BottomMediaPlayer({
    Key key,
  }) : super(key: key);

  @override
  _BottomMediaPlayer createState() => _BottomMediaPlayer();
}

class _BottomMediaPlayer extends State<BottomMediaPlayer> {
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

    if (isSmallerScreen)
      return Container(
        height: 0,
        width: 0,
      );

    return StreamBuilder<bool>(
        stream: AudioService.runningStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.active) {
            // Don't show anything until we've ascertained whether or not the
            // service is running, since we want to show a different UI in
            // each case.
            return Container(
              height: 0,
              width: 0,
            );
          }
          final running = snapshot.data ?? false;
          // empty widget if the media player is not running
          if (!running)
            return Container(
              height: 0,
              width: 0,
            );

          return StreamBuilder<List<MediaItem>>(
              stream: AudioService.queueStream,
              builder: (context, snapshot) {
                final queueList = snapshot.data;
                // empty widget if radio player is running
                if (queueList == null || queueList.length == 0)
                  return Container(
                    height: 0,
                    width: 0,
                  );

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => MediaPlayer()));
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
                          SizedBox(
                            height: 40,
                            width: 40,
                            child: Image(
                              fit: BoxFit.cover,
                              alignment: Alignment(0, -1),
                              // TODO: get image from artUri
                              image: AssetImage('assets/sai_listens.jpg'),
                            ),
                          ),
                          StreamBuilder<QueueState>(
                            stream: _queueStateStream,
                            builder: (context, snapshot) {
                              final queueState = snapshot.data;
                              final mediaItem = queueState?.mediaItem;
                              final mediaTitle = (queueState != null &&
                                      mediaItem?.title != null)
                                  ? mediaItem.title
                                  : 'loading media...';
                              return SizedBox(
                                width: width * 0.65,
                                child: Text(
                                  // Display Audio Title
                                  mediaTitle,
                                  textAlign: TextAlign.start,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 18,
                                  ),
                                ),
                              );
                            },
                          ),
                          // Pause/Play button
                          StreamBuilder<bool>(
                              stream: AudioService.playbackStateStream
                                  .map((state) => state.playing)
                                  .distinct(),
                              builder: (context, snapshot) {
                                final playing = snapshot.data ?? false;

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

  /// A stream reporting the combined state of the current queue and the current
  /// media item within that queue.
  Stream<QueueState> get _queueStateStream =>
      Rx.combineLatest2<List<MediaItem>, MediaItem, QueueState>(
          AudioService.queueStream,
          AudioService.currentMediaItemStream,
          (queue, mediaItem) => QueueState(queue, mediaItem));

  IconButton playButton() => IconButton(
        icon: Icon(CupertinoIcons.play),
        splashRadius: 24,
        iconSize: 25,
        onPressed: AudioService.play,
      );

  IconButton pauseButton() => IconButton(
        icon: Icon(CupertinoIcons.pause),
        splashRadius: 24,
        iconSize: 25,
        onPressed: AudioService.pause,
      );
}
