import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:radiosai/screens/media_player/media_player.dart';
import 'package:rxdart/rxdart.dart';

class PlayingQueue extends StatefulWidget {
  PlayingQueue({
    Key key,
  }) : super(key: key);

  @override
  _PlayingQueue createState() => _PlayingQueue();
}

class _PlayingQueue extends State<PlayingQueue> {
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
                  if (!running) Navigator.maybePop(context, true);

                  return Column(
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                        Icons.keyboard_arrow_down_outlined),
                                    splashRadius: 24,
                                    iconSize: 25,
                                    onPressed: () {
                                      // pop to media player
                                      Navigator.maybePop(context);
                                    },
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

                                        return playing
                                            ? pauseButton()
                                            : playButton();
                                      }),
                                ],
                              ),
                            ),
                          ),
                        ),
                      Expanded(
                        child: StreamBuilder<QueueState>(
                          stream: _queueStateStream,
                          builder: (context, snapshot) {
                            final queueState = snapshot.data;
                            final queueList = queueState?.queue ?? [];

                            if (queueState == null ||
                                queueList == null ||
                                queueList.length == 0)
                              return Container(
                                child: Center(
                                  child: Text('No files in queue'),
                                ),
                              );

                            final currentMediaItem = queueState?.mediaItem;

                            return Scrollbar(
                              radius: Radius.circular(8),
                              child: SingleChildScrollView(
                                physics: BouncingScrollPhysics(
                                    parent: AlwaysScrollableScrollPhysics()),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  primary: false,
                                  padding: EdgeInsets.only(top: 2, bottom: 2),
                                  itemCount: queueList.length,
                                  itemBuilder: (context, index) {
                                    final mediaItem = queueList[index];
                                    bool isCurrentItem = false;
                                    if (mediaItem == currentMediaItem)
                                      isCurrentItem = true;
                                    return _queueItemWidget(context, mediaItem,
                                        isCurrentItem, queueList.length, isDarkTheme);
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            child: Padding(
                              padding: EdgeInsets.only(
                                  left: 10, right: 10, top: 8, bottom: 8),
                              child: Text(
                                'CLEAR',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Theme.of(context).accentColor,
                                ),
                              ),
                            ),
                            borderRadius: BorderRadius.circular(8.0),
                            onTap: () async {
                              // stop the player (which clears the queue)
                              await AudioService.customAction('stop');
                              Navigator.maybePop(context);
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                }),
          ),
        ),
      ),
    );
  }

  Widget _queueItemWidget(BuildContext context, MediaItem mediaItem,
      bool isCurrentItem, int length, bool isDarkTheme) {
    Color selectedColor = isDarkTheme ? Colors.grey[800] : Colors.grey[300];
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
                leading: SizedBox(
                  height: 40,
                  width: 40,
                  child: Image(
                    fit: BoxFit.cover,
                    alignment: Alignment(0, -1),
                    // TODO: get image from artUri
                    image: AssetImage('assets/sai_listens.jpg'),
                  ),
                ),
                title: Text(mediaItem.title),
                trailing: IconButton(
                  icon: Icon(CupertinoIcons.minus_circle),
                  splashRadius: 24,
                  onPressed: () async {
                    if (length == 1) {
                      await AudioService.customAction('stop');
                      Navigator.maybePop(context);
                    }
                    else await AudioService.removeQueueItem(mediaItem);
                  }
                ),
              ),
            ),
            onTap: () {
              if (isCurrentItem) return;
              AudioService.skipToQueueItem(mediaItem.id);
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
