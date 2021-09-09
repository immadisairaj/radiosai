import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:radiosai/screens/media_player/media_player.dart';

/// Top Media Player -
/// media player to be attached in stack
///
/// To be used inside stack (at top) to display overlay behaviour
///
/// shows if the media player is playing.
/// else, returns a empty (zero container) widget
class TopMediaPlayer extends StatefulWidget {
  TopMediaPlayer({
    key,
  }) : super(key: key);

  @override
  _TopMediaPlayer createState() => _TopMediaPlayer();
}

class _TopMediaPlayer extends State<TopMediaPlayer> {
  @override
  Widget build(BuildContext context) {
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

                return Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top + 10, left: 5),
                    child: Material(
                      color: Colors.transparent,
                      child: Card(
                        elevation: 8,
                        shadowColor: Theme.of(context).primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => MediaPlayer()));
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
                            child: Text(
                              'Playing..',
                              style: TextStyle(
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              });
        });
  }
}
