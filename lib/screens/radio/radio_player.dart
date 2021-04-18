import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:radiosai/audio_service/radio_player_task.dart';
import 'package:radiosai/bloc/radio_loading_bloc.dart';
import 'package:radiosai/widgets/internet_alert.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:radiosai/constants/constants.dart';
import 'package:radiosai/screens/radio/radio_stream_select.dart';

// entry point used to initialize the audio_service to handle media controls
// and audio running in background
void _entrypoint() => AudioServiceBackground.run(() => RadioPlayerTask());

class RadioPlayer extends StatefulWidget {
  RadioPlayer({Key key,
        this.radius,
        this.radioStreamIndex,
        this.isPlaying,
        this.loadingState,
        this.radioLoadingBloc,
        this.hasInternet}) : super(key: key);

  final BorderRadiusGeometry radius;
  final int radioStreamIndex;
  final bool isPlaying;
  final bool loadingState;
  final RadioLoadingBloc radioLoadingBloc;
  final bool hasInternet;

  @override
  _RadioPlayer createState() => _RadioPlayer();
}

class _RadioPlayer extends State<RadioPlayer>
    with SingleTickerProviderStateMixin {
  // Controller used for animating pause and play
  AnimationController _pausePlayController;
  // Controller used for handling sliding panel
  PanelController _panelController = new PanelController();

  // Temporary index used for handling the radio stream index
  // change while radio is in playing state
  int _tempRadioStreamIndex = 0;

  @override
  void initState() {
    // initialize the pause play controller
    _pausePlayController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 300));
    super.initState();
  }

  @override
  void dispose() async {
    await AudioService.stop();
    _pausePlayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // handle the pause and play button
    _handlePlayingState(widget.isPlaying);
    return Scaffold(
      backgroundColor: Colors.transparent,
      // using stack to show notification alert when there is no internet
      body: Stack(
        children: [
          SlidingUpPanel(
            borderRadius: widget.radius,
            backdropEnabled: true,
            controller: _panelController,
            onPanelClosed: () {
              // handle if the stream is updated when panel is closed
              setState(() {
                // if the the index is changed, stop the radio service
                if (_tempRadioStreamIndex != widget.radioStreamIndex) {
                  widget.radioLoadingBloc.changeLoadingState.add(false);
                  stopRadioService();
                }
              });
            },
            collapsed: slidingPanelCollapsed(widget.radius),
            panel: RadioStreamSelect(
              panelController: _panelController,
            ),
            parallaxEnabled: true,
            parallaxOffset: 0.5,
            body: Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.22,
                width: MediaQuery.of(context).size.width,
                child: Container(
                  color: Colors.black54,
                  child: playerDisplay(widget.radioStreamIndex, widget.isPlaying, widget.loadingState,
                      widget.radioLoadingBloc, widget.hasInternet),
                ),
              ),
            ),
          ),
          InternetAlert(hasInternet: widget.hasInternet),
        ],
      ),
    );
  }

  // main radio player widget after all streams
  Widget slidingPanelCollapsed(BorderRadiusGeometry radius) {
    return GestureDetector(
      onTap: () {
        _panelController.open();
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: radius,
        ),
        child: Column(
          children: [
            SizedBox(height: 12),
            Container(
              height: 5,
              width: 30,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Select Stream',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget playerDisplay(int streamIndex, bool isPlaying, bool loadingState,
      RadioLoadingBloc radioLoadingBloc, bool hasInternet) {
    // TODO: change all the numbers to use based on media query
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 90),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  MyConstants.of(context).radioStreamName[streamIndex ?? 0],
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // circular progress used to show the loading state
                    if (loadingState)
                      SizedBox(
                        height: 40,
                        width: 40,
                        child: CircularProgressIndicator(),
                      ),
                    IconButton(
                      splashRadius: 24,
                      splashColor: Theme.of(context).primaryColor,
                      highlightColor: Theme.of(context).primaryColor,
                      iconSize: 40,
                      color: Colors.white,
                      icon: AnimatedIcon(
                        icon: AnimatedIcons.play_pause,
                        progress: _pausePlayController,
                      ),
                      onPressed: () async {
                        if (streamIndex != null) {
                          _handleOnPressed(streamIndex, isPlaying, loadingState,
                              radioLoadingBloc, hasInternet);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Hiding the text below as other functions are dependent on this
        // Display the status of audio player in text
        StreamBuilder<AudioProcessingState>(
          stream: AudioService.playbackStateStream
              .map((state) => state.processingState),
          builder: (context, snapshot) {
            final playerState = snapshot.data;
            final processingState = playerState ?? AudioProcessingState.none;
            String displayText = '';
            bool loadingUpdate;
            switch (processingState) {
              case AudioProcessingState.none:
                loadingUpdate = null;
                displayText = 'Play';
                break;
              case AudioProcessingState.ready:
                loadingUpdate = false;
                displayText = isPlaying ? 'Playing' : 'Play';
                break;
              case AudioProcessingState.completed:
              case AudioProcessingState.stopped:
                displayText = '${describeEnum(processingState)}';
                loadingUpdate = false;
                break;
              case AudioProcessingState.buffering:
                loadingUpdate = true;
                displayText = 'Buffering';
                if (!hasInternet) {
                  loadingUpdate = false;
                  stopRadioService();
                }
                break;
              case AudioProcessingState.connecting:
                displayText = 'Loading stream..';
                if (!hasInternet) {
                  loadingUpdate = false;
                  stopRadioService();
                }
                break;
              case AudioProcessingState.error:
                loadingUpdate = false;
                displayText = 'Error.. retry';
                break;
              default:
                loadingUpdate = false;
                displayText = '${describeEnum(processingState)}';
            }
            if (loadingUpdate != null)
              radioLoadingBloc.changeLoadingState.add(loadingUpdate);
            return Text(
              displayText,
              style: TextStyle(
                color: Colors.white,
                fontSize: 1,
              ),
            );
          },
        ),
      ],
    );
  }

  void initRadioService(int index) {
    // Register the audio service and start playing
    try {
      // passing params to send the source to play
      Map<String, dynamic> _params = {
        'audioSource': MyConstants.of(context).radioStreamLink[index],
        'audioName': MyConstants.of(context).radioStreamName[index],
      };
      AudioService.connect();
      AudioService.start(
        backgroundTaskEntrypoint: _entrypoint,
        params: _params,
        // clear the notification when paused
        androidStopForegroundOnPause: true,
      );

      // setting the temporary radio stream index to track the
      // previous data after the index is updated
      setState(() {
        _tempRadioStreamIndex = index;
      });
    } on PlatformException {
      print("Execption while registering");
    }
  }

  void playRadioService() {
    AudioService.play();
  }

  void stopRadioService() {
    AudioService.stop();
  }

  // handle the player when pause/play button is pressed
  void _handleOnPressed(int index, bool isPlaying, bool isLoading,
      RadioLoadingBloc loadingStreamBloc, bool hasInternet) {
    if (!isPlaying) {
      if (hasInternet) {
        loadingStreamBloc.changeLoadingState.add(true);
        initRadioService(index);
        if (!isLoading) playRadioService();
      } else {
        // TODO: handle play when no internet
        // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        //   content: Text('Try to play after connecting to the Internet'),
        // ));
      }
    } else {
      loadingStreamBloc.changeLoadingState.add(false);
      stopRadioService();
    }
  }

  // handle play icon to animate based on audio playing state
  void _handlePlayingState(bool isPlaying) {
    if (isPlaying) {
      _pausePlayController.forward();
    } else {
      _pausePlayController.reverse();
    }
  }
}
