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
  RadioPlayer(
      {Key key,
      this.radius,
      this.radioStreamIndex,
      this.isPlaying,
      this.loadingState,
      this.radioLoadingBloc,
      this.hasInternet})
      : super(key: key);

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

  // to check if the app is built for first time
  bool initialBuild = false;

  @override
  void initState() {
    // initialize the pause play controller
    _pausePlayController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 300));

    // true when the widgets are building
    initialBuild = true;
    super.initState();
    // false the value after the build is completed
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      initialBuild = false;
    });
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
    // handle the stream change when it is changed
    _handleRadioStreamChange(widget.radioStreamIndex);
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.transparent,
      // using stack to show notification alert when there is no internet
      body: Stack(
        children: [
          SlidingUpPanel(
            borderRadius: widget.radius,
            backdropEnabled: true,
            controller: _panelController,
            minHeight: height * 0.1,
            // remove the collapsed widget if the height is small (below 4 lines)
            collapsed: (height * 0.1 >= 50)
                ? _slidingPanelCollapsed(widget.radius)
                : null,
            renderPanelSheet: (height * 0.1 >= 50) ? true : false,
            panel: RadioStreamSelect(
              panelController: _panelController,
            ),
            parallaxEnabled: true,
            parallaxOffset: 0.5,
            body: Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                height: height * 0.2,
                width: width,
                child: Container(
                  color: Colors.black54,
                  child: _playerDisplay(
                      widget.radioStreamIndex,
                      widget.isPlaying,
                      widget.loadingState,
                      widget.radioLoadingBloc,
                      widget.hasInternet),
                ),
              ),
            ),
          ),
          // don't build the widget if the app builds for the first time
          if (!initialBuild) InternetAlert(hasInternet: widget.hasInternet),
        ],
      ),
    );
  }

  // main radio player widget after all streams
  Widget _slidingPanelCollapsed(BorderRadiusGeometry radius) {
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
          ],
        ),
      ),
    );
  }

  Widget _playerDisplay(int streamIndex, bool isPlaying, bool loadingState,
      RadioLoadingBloc radioLoadingBloc, bool hasInternet) {
    double height = MediaQuery.of(context).size.height;
    double iconSize = (height * 0.1 >= 50) ? 40 : 30;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
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
                      height: iconSize,
                      width: iconSize,
                      child: CircularProgressIndicator(),
                    ),
                  IconButton(
                    splashRadius: 24,
                    splashColor: Theme.of(context).primaryColor,
                    highlightColor: Theme.of(context).primaryColor,
                    iconSize: iconSize,
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
        // Hiding the below widget as other functions are dependent on this
        // Display the status of audio player in text
        StreamBuilder<AudioProcessingState>(
          stream: AudioService.playbackStateStream
              .map((state) => state.processingState),
          builder: (context, snapshot) {
            final playerState = snapshot.data;
            final processingState = playerState ?? AudioProcessingState.none;
            // String displayText = '';
            bool loadingUpdate;
            switch (processingState) {
              case AudioProcessingState.none:
                loadingUpdate = null;
                // displayText = 'Play';
                break;
              case AudioProcessingState.ready:
                loadingUpdate = false;
                // displayText = isPlaying ? 'Playing' : 'Play';
                break;
              case AudioProcessingState.completed:
              case AudioProcessingState.stopped:
                // displayText = '${describeEnum(processingState)}';
                loadingUpdate = false;
                break;
              case AudioProcessingState.buffering:
                loadingUpdate = true;
                // displayText = 'Buffering';
                if (!hasInternet) {
                  loadingUpdate = false;
                  stopRadioService();
                }
                break;
              case AudioProcessingState.connecting:
                // displayText = 'Loading stream..';
                if (!hasInternet) {
                  loadingUpdate = false;
                  stopRadioService();
                }
                break;
              case AudioProcessingState.error:
                loadingUpdate = false;
                // displayText = 'Error.. retry';
                break;
              default:
                loadingUpdate = false;
              // displayText = '${describeEnum(processingState)}';
            }
            if (loadingUpdate != null)
              radioLoadingBloc.changeLoadingState.add(loadingUpdate);
            // returning empty widget as there is nothing to display
            return Container(
              // when height > 0, the container has to be transparent
              color: Colors.transparent,
              // adding height to set the player display properly when height is more
              height: (height * 0.1 >= 50) ? height * 0.09 : 0,
              width: 0,
            );
            // return Text(
            //   displayText,
            //   style: TextStyle(
            //     color: Colors.white,
            //     fontSize: 1,
            //   ),
            // );
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

  // handle the player when radio stream changes
  void _handleRadioStreamChange(int radioStreamIndex) {
    // if the the index is changed, stop the radio service
    if (_tempRadioStreamIndex != radioStreamIndex) {
      widget.radioLoadingBloc.changeLoadingState.add(false);
      stopRadioService();
    }
  }
}
