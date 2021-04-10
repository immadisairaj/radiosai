import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:provider/provider.dart';
import 'package:radiosai/audio_service/radio_player_task.dart';
import 'package:radiosai/bloc/radio_loading_bloc.dart';
import 'package:radiosai/bloc/radio_index_bloc.dart';
import 'package:radiosai/widgets/internet_alert.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:radiosai/constants/constants.dart';
import 'package:radiosai/screens/radio/radio_stream_select.dart';

// entry point used to initialize the audio_service to handle media controls
// and audio running in background
void _entrypoint() => AudioServiceBackground.run(() => RadioPlayerTask());

class RadioPlayer extends StatefulWidget {
  RadioPlayer({Key key}) : super(key: key);

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
    // border radius used for sliding panel
    BorderRadiusGeometry radius = BorderRadius.only(
      topLeft: Radius.circular(24.0),
      topRight: Radius.circular(24.0),
    );
    // Consumers of all the providers to get the stream of data
    return Consumer<RadioIndexBloc>(
      // listen to change of radio stream index
      builder: (context, _radioIndexBloc, child) {
        return StreamBuilder<int>(
          stream: _radioIndexBloc.radioIndexStream,
          builder: (context, snapshot) {
            int radioStreamIndex = snapshot.data ?? 0;
            // listen to change of radio player loading state
            return Consumer<RadioLoadingBloc>(
              builder: (context, _radioLoadingBloc, child) {
                return StreamBuilder<bool>(
                  stream: _radioLoadingBloc.radioLoadingStream,
                  builder: (context, snapshot) {
                    bool loadingState = snapshot.data ?? false;
                    // listen to change of playing state from audio service
                    return StreamBuilder<bool>(
                        stream: AudioService.playbackStateStream
                            .map((state) => state.playing)
                            .distinct(),
                        builder: (context, snapshot) {
                          final isPlaying = snapshot.data ?? false;
                          // handle the pause and play button
                          _handlePlayingState(isPlaying);
                          // get the data of the internet connectivity change
                          bool hasInternet =
                              Provider.of<InternetConnectionStatus>(context) ==
                                  InternetConnectionStatus.connected;
                          return radioPlayerWidget(
                              radius,
                              radioStreamIndex,
                              isPlaying,
                              loadingState,
                              _radioLoadingBloc,
                              hasInternet);
                        });
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  // main radio player widget after all streams
  Widget radioPlayerWidget(
      BorderRadiusGeometry radius,
      int streamIndex,
      bool isPlaying,
      bool loadingState,
      RadioLoadingBloc radioLoadingBloc,
      bool hasInternet) {
    return Scaffold(
      // using stack to show notification alert when there is no internet
      body: Stack(
        children: [
          SlidingUpPanel(
            borderRadius: radius,
            backdropEnabled: true,
            controller: _panelController,
            onPanelClosed: () {
              // handle if the stream is updated when panel is closed
              setState(() {
                // if the the index is changed, stop the radio service
                if (_tempRadioStreamIndex != streamIndex) {
                  radioLoadingBloc.changeLoadingState.add(false);
                  stopRadioService();
                }
              });
            },
            collapsed: slidingPanelCollapsed(radius),
            panel: RadioStreamSelect(
              panelController: _panelController,
            ),
            body: Stack(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height,
                  child: Image(
                    fit: BoxFit.fitHeight,
                    image: AssetImage('assets/sai_listens.jpg'),
                  ),
                ),
                Container(
                  color: Color(0X2F000000),
                  child: Center(
                    child: playerDisplay(streamIndex, isPlaying, loadingState,
                        radioLoadingBloc, hasInternet),
                  ),
                ),
              ],
            ),
          ),
          InternetAlert(hasInternet: hasInternet),
        ],
      ),
    );
  }

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
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          MyConstants.of(context).radioStreamName[streamIndex ?? 0],
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            // circular progress used to show the loading state
            if (loadingState)
              SizedBox(
                height: 80,
                width: 80,
                child: CircularProgressIndicator(),
              ),
            Opacity(
                opacity: 0.7,
                child: IconButton(
                  iconSize: 90,
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
                )),
          ],
        ),
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
                fontSize: 15,
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
