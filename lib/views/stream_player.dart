import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_radio_player/flutter_radio_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:radiosai/constants/constants.dart';
import 'package:radiosai/views/stream_select.dart';
// Test audio_service and just_audio
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

// Test audio_service and just_audio
void _entrypoint() async => AudioServiceBackground.run(() => AudioPlayerTask());

class AudioPlayerTask extends BackgroundAudioTask {
  var _player = AudioPlayer();

  @override
  Future<void> onStart(Map<String, dynamic> params) async {
    // final mediaItem = MediaItem(
    //   id: 'radiosai',
    //   album: 'Radio Sai',
    //   title: params['title']);
      print(params['title']);
      // AudioServiceBackground.setMediaItem(mediaItem);

      // _player.playerStateStream.listen((playerState) {
      //   AudioServiceBackground.setState(
      //     controls: [
      //       playerState.playing ? MediaControl.pause : MediaControl.play
      //     ],
      //     processingState: {
      //       ProcessingState.none: AudioProcessingState.none,
      //       ProcessingState.loading: AudioProcessingState.connecting,
      //       ProcessingState.buffering: AudioProcessingState.buffering,
      //       ProcessingState.ready: AudioProcessingState.ready,
      //       ProcessingState.completed: AudioProcessingState.completed,
      //     }[playerState.processingState],
      //     playing: playerState.playing,
      //   );
      // });
      _player.play();
      await _player.setUrl(params['link']);
    return super.onStart(params);
  }

  @override
  Future onCustomAction(String name, arguments) async {
    if(name == 'stream') {
      await _player.setUrl(arguments);
    }
    return super.onCustomAction(name, arguments);
  }

  @override
  Future<void> onPlay() {
    _player.play();
    return super.onPlay();
  }

  @override
  Future<void> onPause() {
    _player.stop();
    return super.onPause();
  }

  @override
  Future<void> onStop() {
    _player.stop();
    return super.onStop();
  }
}

class StreamPlayer extends StatefulWidget {
  StreamPlayer({Key key}) : super(key: key);

  var playerState = FlutterRadioPlayer.flutter_radio_stopped;

  @override
  _StreamPlayer createState() => _StreamPlayer();
}

class _StreamPlayer extends State<StreamPlayer> with SingleTickerProviderStateMixin {
  AnimationController _animationController;
  bool isPlaying = false;

  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  Future<int> _streamIndex;

  PanelController _panelController = new PanelController();

  FlutterRadioPlayer _flutterRadioPlayer = new FlutterRadioPlayer();

  var _player = AudioPlayer();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _animationController = AnimationController(vsync: this, duration: Duration(milliseconds: 300));
    _streamIndex = _prefs.then((SharedPreferences prefs) {return (prefs.getInt('stream') ?? 0);});
  }

  Future<void> updateStreamIndex() async {
    setState(() {
      _streamIndex = _prefs.then((SharedPreferences prefs) {return (prefs.getInt('stream') ?? 0);});
      if(isPlaying == true) {
        isPlaying = !isPlaying;
        _animationController.reverse().then((value) => stopRadioService());
      }
    });
  }

  Future<void> initRadioService(int index) async {
    try {
      // await _flutterRadioPlayer.init("Radio Sai", "radiosai", MyConstants.of(context).streamLink[index], "false");
      // await _flutterRadioPlayer.play();
      // Test audio_service and just_audio
      Map<String, dynamic> params = new Map();
      params['title'] = MyConstants.of(context).streamName[index];
      params['link'] = MyConstants.of(context).streamLink[index];
      print(params['title']);
      await AudioService.start(backgroundTaskEntrypoint: _entrypoint,
        params: params,
        androidNotificationChannelName: 'radiosai',
        androidNotificationIcon: 'mipmap/ic_launcher',
        androidNotificationColor: 0xFF000000,
        androidEnableQueue: false);
      // await _player.setUrl(params['link']);
      // _player.play();
      // await AudioService.customAction('stream', MyConstants.of(context).streamLink[index]);
      // AudioService.play();
    } on Exception {
      print("Execption while registering");
    }
  }

  Future<void> playRadioService() async {
    await _flutterRadioPlayer.play();
  }

  Future<void> stopRadioService() async {
    // await _flutterRadioPlayer.stop();
    // Test audio_service and just_audio
    _player.stop();
    await AudioService.stop();
  }

  void _handleOnPressed(int index) {
    setState(() async {
      isPlaying = !isPlaying;
      if(isPlaying) {
        _animationController.forward().then((value) => initRadioService(index));
        //await initRadioService();
      } else {
        _animationController.reverse().then((value) => stopRadioService());
        // await stopRadioService();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    BorderRadiusGeometry radius = BorderRadius.only(
      topLeft: Radius.circular(24.0),
      topRight: Radius.circular(24.0),
    );
    return Scaffold(
      body: SlidingUpPanel(
        borderRadius: radius,
        backdropEnabled: true,
        controller: _panelController,
        onPanelClosed: () {
          setState(() async {
            await _flutterRadioPlayer.isPlaying()
            .then((value) {
              if(!value) {
                updateStreamIndex();
              }
            });
          });
        },
        collapsed: GestureDetector(
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
        ),
        panel: StreamList(
          flutterRadioPlayer: _flutterRadioPlayer,
          panelController: _panelController,
          animationController: _animationController,
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
            Center(
              child: FutureBuilder<int>(
                future: _streamIndex,
                builder: (BuildContext context, AsyncSnapshot<int> snapshotInt) {
                  switch(snapshotInt.connectionState) {
                    case ConnectionState.waiting:
                      return const CircularProgressIndicator();
                    default:
                      if(snapshotInt.hasError) {
                        return Text('Error');
                      } else {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              MyConstants.of(context).streamName[snapshotInt.data],
                            ),
                            Opacity(
                              opacity: 0.7,
                              child: IconButton(
                                iconSize: 90,
                                color: Colors.white,
                                icon: AnimatedIcon(
                                  icon: AnimatedIcons.play_pause,
                                  progress: _animationController,
                                ),
                                onPressed: () async {
                                  _handleOnPressed(snapshotInt.data);
                                },
                              )
                            ),
                            StreamBuilder(
                              stream: _flutterRadioPlayer.isPlayingStream,
                              initialData: widget.playerState,
                              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                                String returnData = snapshot.data;
                                print("object data: " + returnData);
                                switch(returnData) {
                                  case FlutterRadioPlayer.flutter_radio_paused:
                                    _flutterRadioPlayer.play();
                                    return Text('Loading stream..'); // TODO: add loading widget
                                  case FlutterRadioPlayer.flutter_radio_stopped:
                                    return Text('Play');
                                    break;
                                  case FlutterRadioPlayer.flutter_radio_loading:
                                  // TODO: add loading widget
                                    return Text("Loading stream..");
                                  case FlutterRadioPlayer.flutter_radio_error:
                                  // doesn't handle error state
                                    // TODO: add notify to retry or check internet or so
                                    return Text('Retry');
                                    break;
                                  default:
                                    return Text('Playing');
                                }
                              },
                            ),
                          ],
                        );
                      }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
