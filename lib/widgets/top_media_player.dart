import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:radiosai/audio_service/audio_manager.dart';
import 'package:radiosai/audio_service/service_locator.dart';
import 'package:radiosai/helper/media_helper.dart';
import 'package:radiosai/screens/media_player/media_player.dart';

/// Top Media Player -
/// media player to be attached in stack
///
/// To be used inside stack (at top) to display overlay behaviour
///
/// shows if the media player is playing.
/// else, returns a empty (zero container) widget
class TopMediaPlayer extends StatefulWidget {
  const TopMediaPlayer({
    key,
  }) : super(key: key);

  @override
  _TopMediaPlayer createState() => _TopMediaPlayer();
}

class _TopMediaPlayer extends State<TopMediaPlayer> {
  AudioManager _audioManager;

  @override
  void initState() {
    // get audio manager
    _audioManager = getIt<AudioManager>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
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

          return StreamBuilder<List<MediaItem>>(
              stream: _audioManager.queue,
              builder: (context, snapshot) {
                final queueList = snapshot.data;
                // empty widget if radio player is running
                if (queueList == null || queueList.isEmpty) {
                  return const SizedBox(
                    height: 0,
                    width: 0,
                  );
                }

                return Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top + 10, left: 5),
                    child: Material(
                      color: Colors.transparent,
                      child: Card(
                        elevation: 8,
                        shadowColor: Theme.of(context).colorScheme.secondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const MediaPlayer()));
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: const Padding(
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
