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
import 'package:audio_session/audio_session.dart';

// Test audio_service and just_audio
void _entrypoint() async => AudioServiceBackground.run(() => AudioPlayerTask());
// TODO: fix the whole audio service task
class AudioPlayerTask extends BackgroundAudioTask {
  AudioPlayer _player = new AudioPlayer();
  // AudioProcessingState _skipState;
  // late StreamSubscription<PlaybackEvent> _eventSubscription;

  @override
  Future<void> onStart(Map<String, dynamic> params) async {
    
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.speech());

    // _player.currentIndexStream.listen((index) {
    //   if(index != null) AudioServiceBackground.setMediaItem(queue[index]);
    // });
     
    // _eventSubscription = _player.playbackEventStream.listen((event) {broadcastState()});
    // _player.setAudioSource(AudioSource.uri(Uri.parse(MyConstants.of(context).streamLink[index])));
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

  AudioPlayer _player;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    // Test just_audio
    _player = AudioPlayer();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.black,
    ));

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

    // Test just_audio
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.speech());
    _player.playbackEventStream.listen((event) {},
        onError: (Object e, StackTrace stackTrace) {
      print('A stream error occurred: $e');
    });

    try {
      // Test just_audio
      _player.setAudioSource(AudioSource.uri(Uri.parse(MyConstants.of(context).streamLink[index])));
      _player.play();

      // await _flutterRadioPlayer.init("Radio Sai", "radiosai", MyConstants.of(context).streamLink[index], "false");
      // await _flutterRadioPlayer.play();

      // // Test audio_service and just_audio
      // Map<String, dynamic> params = new Map();
      // params['title'] = MyConstants.of(context).streamName[index];
      // params['link'] = MyConstants.of(context).streamLink[index];
      // print(params['title']);
      // await AudioService.start(backgroundTaskEntrypoint: _entrypoint,
      //   params: params,
      //   androidNotificationChannelName: 'radiosai',
      //   androidNotificationIcon: 'mipmap/ic_launcher',
      //   androidNotificationColor: 0xFF000000,
      //   androidEnableQueue: false);
      // await _player.setUrl(params['link']);
      // _player.play();
      // await AudioService.customAction('stream', MyConstants.of(context).streamLink[index]);
      // AudioService.play();
    } on Exception {
      print("Execption while registering");
    }
  }

  Future<void> playRadioService() async {
    // await _flutterRadioPlayer.play();

    // Test just_audio
    await _player.play();
  }

  Future<void> stopRadioService() async {
    // await _flutterRadioPlayer.stop();
    // Test audio_service and just_audio
    await _player.stop();
    // await AudioService.stop();
    // _player.dispose(); TODO: add dispose in dispose function
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
          // TODO: fix the functionality of updating stream
          updateStreamIndex()
            .then((value) => setState(() {}));
          // setState(() {
          //   // await _player.playing
          //   // .then((value) {
          //     // if(_player.playing) {
          //     try {
          //       updateStreamIndex();
          //     } catch(Exception) {
          //       updateStreamIndex();
          //     }
          //     // }
          //   // });
          // });
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
          audioPlayer: _player,
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
                            // StreamBuilder(
                            //   stream: _flutterRadioPlayer.isPlayingStream,
                            //   initialData: widget.playerState,
                            //   builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                            //     String returnData = snapshot.data;
                            //     print("object data: " + returnData);
                            //     switch(returnData) {
                            //       case FlutterRadioPlayer.flutter_radio_paused:
                            //         _flutterRadioPlayer.play();
                            //         return Text('Loading stream..'); // TODO: add loading widget
                            //       case FlutterRadioPlayer.flutter_radio_stopped:
                            //         return Text('Play');
                            //         break;
                            //       case FlutterRadioPlayer.flutter_radio_loading:
                            //       // TODO: add loading widget
                            //         return Text("Loading stream..");
                            //       case FlutterRadioPlayer.flutter_radio_error:
                            //       // doesn't handle error state
                            //         // TODO: add notify to retry or check internet or so
                            //         return Text('Retry');
                            //         break;
                            //       default:
                            //         return Text('Playing');
                            //     }
                            //   },
                            // ),

                            // Test just_audio
                            StreamBuilder<PlayerState>(
                              stream: _player.playerStateStream,
                              builder: (context, snapshot) {
                                final playerState = snapshot.data;
                                final processingState = playerState?.processingState;
                                final playing = playerState?.playing;
                                if (processingState == ProcessingState.loading ||
                                    processingState == ProcessingState.buffering) {
                                  return Container(
                                    margin: EdgeInsets.all(8.0),
                                    width: 64.0,
                                    height: 64.0,
                                    child: CircularProgressIndicator(),
                                  );
                                } else if (playing != true) {
                                  return Text('Play');
                                } else if (processingState != ProcessingState.completed) {
                                  return Text('Playing!');
                                }
                                return Text('Error');
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
