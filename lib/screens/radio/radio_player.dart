import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:radiosai/audio_service/radio_player_task.dart';
import 'package:radiosai/bloc/radio/radio_loading_bloc.dart';
import 'package:radiosai/widgets/internet_alert.dart';
import 'package:radiosai/widgets/radio/slider_handle.dart';
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

  final Radius radius;
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

  // reduce multiple snackbars when clicking many times
  bool _isSnackBarActive = false;

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
    // notification status bar color
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.black26,
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
    ));

    // handle the pause and play button
    _handlePlayingState(widget.isPlaying);
    // handle the stream change when it is changed
    _handleRadioStreamChange(
        widget.radioStreamIndex, widget.isPlaying, widget.radioLoadingBloc);
    // handle the display of loading progressing widget
    _handleLoadingState(widget.radioLoadingBloc);
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    bool isBigScreen = (height * 0.1 >= 50); // 3/4 screen
    bool isBiggerScreen = (height * 0.1 >= 70); // full screen
    bool isSmallerScreen = (height * 0.1 < 30); // 1/4 screen
    return WillPopScope(
      onWillPop: () {
        if (_panelController.isPanelOpen) return _panelController.close();
        // sends the app to background when backpress on home screen
        // achieved by adding a method in MainActivity.kt to support send app to background
        return MethodChannel('android_app_retain')
            .invokeMethod('sendToBackground');
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // using stack to show notification alert when there is no internet
        body: Stack(
          children: [
            SlidingUpPanel(
              borderRadius: BorderRadius.all(widget.radius),
              backdropEnabled: true,
              controller: _panelController,
              minHeight: height * 0.1,
              // remove the collapsed widget if the height is small (below 2 lines)
              collapsed:
                  isBigScreen ? _slidingPanelCollapsed(widget.radius) : null,
              renderPanelSheet: false,
              // handle the height of the panel for different sizes
              maxHeight: isBigScreen
                  ? (isBiggerScreen ? height * 0.54 : height * 0.57)
                  : height * 0.6,
              // remove panel if small screen
              panel: isSmallerScreen
                  ? Container()
                  : RadioStreamSelect(
                      panelController: _panelController,
                      radius: widget.radius,
                    ),
              body: GestureDetector(
                // swipe the panel when swiping from anywhere in the screen
                onVerticalDragUpdate: (details) {
                  int sensitivity = 8;
                  if (details.delta.dy < -sensitivity) {
                    if (!isSmallerScreen) {
                      _panelController.open();
                    }
                  }
                },
                child: Container(
                  height: height,
                  // color is transparent in order for container to occupy the whole height
                  color: Colors.transparent,
                  child: Align(
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
              ),
            ),
            // don't build the widget if the app builds for the first time
            if (!initialBuild) InternetAlert(hasInternet: widget.hasInternet),
          ],
        ),
      ),
    );
  }

  // main radio player widget after all streams
  Widget _slidingPanelCollapsed(Radius radius) {
    // check if dark theme
    bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        _panelController.open();
      },
      child: Container(
        margin: EdgeInsets.only(left: 10, right: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
              topLeft: widget.radius, topRight: widget.radius),
          color: isDarkTheme ? Colors.grey[700] : Colors.white,
        ),
        child: Column(
          children: [
            SizedBox(height: 12),
            SliderHandle(),
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
    bool isBigScreen = (height * 0.1 >= 50);
    bool isSmallerScreen = (height * 0.1 < 30);
    double iconSize = isBigScreen ? 40 : 30;
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
                        _handleOnPressed(
                            streamIndex, isPlaying, loadingState, hasInternet);
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
            // to display processingState, use ${describeEnum(processingState)}
            bool loadingUpdate;
            switch (processingState) {
              case AudioProcessingState.none:
                loadingUpdate = null;
                break;
              case AudioProcessingState.ready:
                loadingUpdate = false;
                break;
              case AudioProcessingState.completed:
              case AudioProcessingState.stopped:
                loadingUpdate = false;
                break;
              case AudioProcessingState.buffering:
                loadingUpdate = true;
                if (!hasInternet) {
                  loadingUpdate = false;
                  stopRadioService();
                }
                break;
              case AudioProcessingState.connecting:
                if (!hasInternet) {
                  loadingUpdate = false;
                  stopRadioService();
                }
                break;
              case AudioProcessingState.error:
                loadingUpdate = false;
                break;
              default:
                loadingUpdate = false;
            }
            if (loadingUpdate != null)
              radioLoadingBloc.changeLoadingState.add(loadingUpdate);
            // returning empty widget as there is nothing to display
            return Container(
              // when height > 0, the container has to be transparent
              color: Colors.transparent,
              // adding height to set the player display properly when height is more
              height: isBigScreen
                  ? height * 0.09
                  : (isSmallerScreen ? 0 : height * 0.08),
              width: 0,
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

  Future<void> stopRadioService() async {
    await AudioService.stop();
  }

  // handle the player when pause/play button is pressed
  void _handleOnPressed(
      int index, bool isPlaying, bool isLoading, bool hasInternet) {
    if (!isPlaying) {
      if (hasInternet) {
        initRadioService(index);
        if (!isLoading) playRadioService();
      } else {
        // display that the player is trying to load - handled by _handleLoadingState
        initRadioService(index);
        // Show a snack bar that it is unable to play
        if (_isSnackBarActive == false) {
          _isSnackBarActive = true;
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(
                content: Text('Try to play after connecting to the Internet'),
                behavior: SnackBarBehavior.floating,
                duration: Duration(milliseconds: 1500),
              ))
              .closed
              .then((value) {
            _isSnackBarActive = false;
          });
        } // do nothing in else
      }
    } else {
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

  // handle the loading progressing widget based on the running state
  void _handleLoadingState(RadioLoadingBloc loadingStreamBloc) {
    loadingStreamBloc.changeLoadingState.add(AudioService.running);
  }

  // handle the player when radio stream changes
  void _handleRadioStreamChange(int radioStreamIndex, bool isPlaying,
      RadioLoadingBloc loadingStreamBloc) async {
    // if the the index is changed, stop the radio service
    if (_tempRadioStreamIndex != radioStreamIndex) {
      widget.radioLoadingBloc.changeLoadingState.add(false);
      // load and play the new stream when the user is playing
      // stop and play the stream
      if (isPlaying) {
        await stopRadioService();
        loadingStreamBloc.changeLoadingState.add(true);
        initRadioService(radioStreamIndex);
      } else {
        // if the index is changed when user is not playing
        // then, stop the player
        await stopRadioService();
      }
    }
  }
}
