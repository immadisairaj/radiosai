import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:radiosai/audio_service/audio_manager.dart';
import 'package:radiosai/audio_service/notifiers/loading_notifier.dart';
import 'package:radiosai/audio_service/service_locator.dart';
import 'package:radiosai/bloc/radio/radio_loading_bloc.dart';
import 'package:radiosai/constants/constants.dart';
import 'package:radiosai/helper/media_helper.dart';
import 'package:radiosai/screens/radio/radio_stream_select.dart';
import 'package:radiosai/widgets/internet_alert.dart';
import 'package:radiosai/widgets/radio/slider_handle.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class RadioPlayer extends StatefulWidget {
  const RadioPlayer(
      {super.key,
      this.radius,
      this.radioStreamIndex,
      this.isPlaying,
      this.loadingState,
      this.radioLoadingBloc,
      this.hasInternet});

  final Radius? radius;
  final int? radioStreamIndex;
  final bool? isPlaying;
  final bool? loadingState;
  final RadioLoadingBloc? radioLoadingBloc;
  final bool? hasInternet;

  @override
  State<RadioPlayer> createState() => _RadioPlayer();
}

class _RadioPlayer extends State<RadioPlayer>
    with SingleTickerProviderStateMixin {
  /// Controller used for animating pause and play
  late AnimationController _pausePlayController;

  /// Controller used for handling sliding panel
  final PanelController _panelController = PanelController();

  /// Temporary index used for handling the radio stream index
  /// change while radio is in playing state
  int _tempRadioStreamIndex = 0;

  /// to check if the app is built for first time
  bool initialBuild = false;

  /// reduce multiple snackbars when clicking many times
  bool _isSnackBarActive = false;

  AudioManager? _audioManager;

  @override
  void initState() {
    // get audio manager
    _audioManager = getIt<AudioManager>();
    // initialize the pause play controller
    _pausePlayController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));

    // true when the widgets are building
    initialBuild = true;
    super.initState();

    // false the value after the build is completed
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      initialBuild = false;
    });
  }

  @override
  void dispose() {
    _audioManager!.stop();
    _pausePlayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // notification status bar color
    // SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    //   statusBarColor: Colors.black26,
    //   statusBarBrightness: Brightness.dark,
    //   statusBarIconBrightness: Brightness.light,
    // ));

    // handle the pause and play button
    _handlePlayingState(widget.isPlaying!);
    // handle the stream change when it is changed
    _handleRadioStreamChange(
        widget.radioStreamIndex, widget.isPlaying, widget.radioLoadingBloc);
    // handle the display of loading progressing widget
    _handleLoadingState(widget.radioLoadingBloc);

    // get the heights of the screen (useful for split screen)
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    bool isBigScreen = (height * 0.1 >= 50); // 3/4 screen
    bool isBiggerScreen = (height * 0.1 >= 70); // full screen
    bool isSmallerScreen = (height * 0.1 < 30); // 1/4 screen
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) async {
        bool toPop = false;
        if (_panelController.isPanelOpen) {
          toPop = await _panelController.close().then((value) => value as bool);
        } else {
          // sends the app to background when backpress on home screen
          // achieved by adding a method in MainActivity.kt to support send app to background
          toPop =
              await const MethodChannel('com.immadisairaj/android_app_retain')
                  .invokeMethod('sendToBackground')
                  .then((value) => value as bool);
        }

        if (toPop && context.mounted) {
          Navigator.maybePop(context);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // using stack to show notification alert when there is no internet
        body: Stack(
          children: [
            SlidingUpPanel(
              borderRadius: BorderRadius.all(widget.radius!),
              backdropEnabled: true,
              controller: _panelController,
              minHeight: height * 0.1,
              // remove the collapsed widget if the height is small (below 2 lines)
              collapsed:
                  isBigScreen ? _slidingPanelCollapsed(widget.radius) : null,
              renderPanelSheet: false,
              // handle the height of the panel for different sizes
              // it was 0.54 for bigger, 0.57 for big small, 0.6 for mid - 6 str
              maxHeight: isBigScreen
                  ? (isBiggerScreen ? height * 0.38 : height * 0.4)
                  : height * 0.45,
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
                            widget.loadingState!,
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

  /// main radio player widget after all streams
  Widget _slidingPanelCollapsed(Radius? radius) {
    return GestureDetector(
      onTap: () {
        _panelController.open();
      },
      child: Container(
        margin: const EdgeInsets.only(left: 10, right: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
              topLeft: widget.radius!, topRight: widget.radius!),
          color: Theme.of(context).colorScheme.secondaryContainer,
        ),
        child: const Column(
          children: [
            SizedBox(height: 12),
            SliderHandle(),
            SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.fitHeight,
              child: Text(
                'Select Stream',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// widget for player display
  ///
  /// shows the stream and play/pause button
  Widget _playerDisplay(int? streamIndex, bool? isPlaying, bool loadingState,
      RadioLoadingBloc? radioLoadingBloc, bool? hasInternet) {
    double height = MediaQuery.of(context).size.height;
    bool isBigScreen = (height * 0.1 >= 50);
    bool isSmallerScreen = (height * 0.1 < 30);
    double iconSize = isBigScreen ? 40 : 30;

    String playingRadioStreamName = MyConstants.of(context)!
        .radioStreamHttps
        .keys
        .toList()[streamIndex ?? 0];
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
                playingRadioStreamName,
                style: const TextStyle(
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
                      child: const CircularProgressIndicator(),
                    ),
                  IconButton(
                    splashRadius: 24,
                    highlightColor: Theme.of(context).colorScheme.primary,
                    iconSize: iconSize,
                    color: Colors.white,
                    icon: AnimatedIcon(
                      icon: AnimatedIcons.play_pause,
                      progress: _pausePlayController,
                    ),
                    onPressed: () {
                      if (streamIndex != null) {
                        _handleOnPressed(streamIndex, isPlaying!, hasInternet);
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
        ValueListenableBuilder<LoadingState>(
          valueListenable: _audioManager!.loadingNotifier,
          builder: (context, loadingState, snapshot) {
            bool loadingUpdate = loadingState == LoadingState.loading;
            if (loadingUpdate == true &&
                _audioManager!.mediaTypeNotifier.value == MediaType.media) {
              loadingUpdate = false;
            }
            radioLoadingBloc!.changeLoadingState.add(loadingUpdate);
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

  /// initial the radio service to start playing
  initRadioService(int index) async {
    // Register the audio service and start playing
    await _audioManager!.init(MediaType.radio, {
      'radioStream': MyConstants.of(context)!.radioStreamHttps,
      'index': index,
      'artImages': MyConstants.of(context)!.radioStreamImages
    });
    _audioManager!.playRadio(index);
    // setting the temporary radio stream index to track the
    // previous data after the index is updated
    setState(() {
      _tempRadioStreamIndex = index;
    });
  }

  /// play the radio
  void playRadioService() {
    _audioManager!.play();
  }

  /// stop the radio
  void stopRadioService() {
    _audioManager!.stop();
  }

  /// handle the player when pause/play button is pressed
  void _handleOnPressed(int index, bool isPlaying, bool? hasInternet) {
    if (!isPlaying) {
      if (_audioManager!.mediaTypeNotifier.value == MediaType.media) {
        // stop if media player is loaded
        _audioManager!.clear();
        _startRadioPlayer(index, isPlaying, hasInternet!);
      } else {
        if (!widget.loadingState!) {
          _startRadioPlayer(index, isPlaying, hasInternet!);
        }
        // don't respond when the radio player has started and is loading
      }
    } else {
      stopRadioService();
    }
  }

  /// start the radio player
  ///
  /// handles stop if any media is playing
  void _startRadioPlayer(int index, bool isPlaying, bool hasInternet) {
    if (hasInternet) {
      initRadioService(index);
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
  }

  /// handle play icon to animate based on audio playing state
  void _handlePlayingState(bool isPlaying) {
    if (isPlaying) {
      _pausePlayController.forward();
    } else {
      _pausePlayController.reverse();
    }
  }

  /// handle the loading progressing widget based on the running state
  void _handleLoadingState(RadioLoadingBloc? loadingStreamBloc) {
    // change state only when radio player is playing
    if (_audioManager!.mediaTypeNotifier.value == MediaType.radio) {
      loadingStreamBloc!.changeLoadingState
          .add(_audioManager!.loadingNotifier.value == LoadingState.loading);
    }
  }

  /// handle the player when radio stream changes
  void _handleRadioStreamChange(int? radioStreamIndex, bool? isPlaying,
      RadioLoadingBloc? loadingStreamBloc) async {
    // if the the index is changed, stop the radio service
    if (_tempRadioStreamIndex != radioStreamIndex) {
      widget.radioLoadingBloc!.changeLoadingState.add(false);
      // load and play the new stream when the user is playing
      // stop and play the stream
      if (isPlaying!) {
        loadingStreamBloc!.changeLoadingState.add(true);
        await _audioManager!.clear();
        initRadioService(radioStreamIndex!);
      } else {
        // if the index is changed when user is not playing
        // then, do nothing
        // await stopRadioService();
      }
    }
  }
}
