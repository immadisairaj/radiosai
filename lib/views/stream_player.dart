import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_radio_player/flutter_radio_player.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:radiosai/audio-source/audio_player_task.dart';
import 'package:radiosai/bloc/playing_bloc.dart';
import 'package:radiosai/bloc/stream_bloc.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:radiosai/constants/constants.dart';
import 'package:radiosai/views/stream_select.dart';

void _entrypoint() => AudioServiceBackground.run(() => AudioPlayerTask());

class StreamPlayer extends StatefulWidget {
  StreamPlayer({Key key}) : super(key: key);

  // var playerState = FlutterRadioPlayer.flutter_radio_stopped;

  @override
  _StreamPlayer createState() => _StreamPlayer();
}

class _StreamPlayer extends State<StreamPlayer> with SingleTickerProviderStateMixin {
  AnimationController _animationController;
  // bool isPlaying = false;

  PanelController _panelController = new PanelController();

  // FlutterRadioPlayer _flutterRadioPlayer = new FlutterRadioPlayer();
  // AudioPlayer _player;

  int _tempStreamIndex = 0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // _player = AudioPlayer();
    _animationController = AnimationController(vsync: this, duration: Duration(milliseconds: 300));
  }

  void updateStreamIndex(bool isPlaying) {
    // setState(() {
      if(isPlaying == true) {
        // isPlaying = !isPlaying;
        // _animationController.reverse().then((value) => stopRadioService());
        stopRadioService();
      }
    // });
  }

  Future<void> initRadioService(int index) async {
    try {
      // await _flutterRadioPlayer.init("Radio Sai", "radiosai", MyConstants.of(context).streamLink[index], "false");
      // await _flutterRadioPlayer.play();
    
      // _player.setAudioSource(AudioSource.uri(
      //   Uri.parse(MyConstants.of(context).streamLink[index])
      // ));
      // _player.play();
      
      Map<String, dynamic> _params = {
        'audioSource': MyConstants.of(context).streamLink[index],
        'audioName': MyConstants.of(context).streamName[index],
      };
      await AudioService.start(backgroundTaskEntrypoint: _entrypoint, params: _params);

      setState(() {
        _tempStreamIndex = index;
      });
    } on PlatformException {
      print("Execption while registering");
    }
  }

  Future<void> playRadioService() async {
    // await _flutterRadioPlayer.play();
    
    // _player.play();
    
    await AudioService.play();
  }

  Future<void> stopRadioService() async {
    // await _flutterRadioPlayer.stop();
    
    // _player.stop();
    
    await AudioService.stop();
  }

  @override
  void dispose() async {
    // TODO: implement dispose
    await AudioService.stop();
    super.dispose();
    // _player.dispose();
  }

  void _handleOnPressed(int index, bool isPlaying) {
    // setState(() {
      // isPlaying = !isPlaying;
      if(!isPlaying) {
        // _animationController.forward().then((value) => initRadioService(index));
        initRadioService(index);
      } else {
        // _animationController.reverse().then((value) => stopRadioService());
        stopRadioService();
      }
    // });
  }

  void _handlePlayingState(bool isPlaying) {
      if(isPlaying) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
  }

  @override
  Widget build(BuildContext context) {
    BorderRadiusGeometry radius = BorderRadius.only(
      topLeft: Radius.circular(24.0),
      topRight: Radius.circular(24.0),
    );
    return Consumer<StreamBloc>(
      builder: (context, _streamBloc, child) {
        return StreamBuilder<int>(
          stream: _streamBloc.indexStream,
          builder: (context, snapshot) {
            int streamIndex = snapshot.data;
            return Consumer<PlayingBloc>(
              builder: (context, _playingBloc, child) {
                return StreamBuilder<bool>(
                  stream: _playingBloc.playingStream,
                  builder: (context, snapshot) {
                    bool playingState = snapshot.data;
                    if(playingState != null) _handlePlayingState(playingState);
                    return mainPlayer(streamIndex, radius, playingState, _playingBloc);
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget mainPlayer(int streamIndex, BorderRadiusGeometry radius, bool playingState, PlayingBloc _playingBloc) {
    return Scaffold(
      body: SlidingUpPanel(
        borderRadius: radius,
        backdropEnabled: true,
        controller: _panelController,
        onPanelClosed: () {
          setState(() {
            if(streamIndex != null && _tempStreamIndex != streamIndex) updateStreamIndex(playingState);
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
          // flutterRadioPlayer: _flutterRadioPlayer,
          // audioPlayer: _player,
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
            Container(
              color: Color(0X2F000000),
              child: Center(
                child: playingDisplay(streamIndex, playingState, _playingBloc),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget playingDisplay(int streamIndex, bool playingState, PlayingBloc _playingBloc) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          MyConstants.of(context).streamName[streamIndex ?? 0],
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
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
              if(streamIndex != null) _handleOnPressed(streamIndex, playingState);
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
        StreamBuilder<AudioProcessingState>(
          stream: AudioService.playbackStateStream
                  .map((state) => state.processingState),
          builder: (context, snapshot) {
            final playerState = snapshot.data;
            final processingState = playerState ?? AudioProcessingState.none;
            String displayText = '';
            switch(processingState) {
              case AudioProcessingState.none:
                _playingBloc.changePlayingState.add(false);
                displayText = 'Play';
                break;
              case AudioProcessingState.ready:
                _playingBloc.changePlayingState.add(true);
                displayText = 'Playing';
                break;
              case AudioProcessingState.buffering:
              case AudioProcessingState.connecting:
                _playingBloc.changePlayingState.add(false);
                displayText = 'Loading stream..';
                break;
              case AudioProcessingState.error:
                _playingBloc.changePlayingState.add(false);
                displayText = 'Error.. retry';
                break;
              default:
                _playingBloc.changePlayingState.add(false);
                displayText = '${describeEnum(processingState)}'; 
            }
            return Text(
              displayText,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
              ),
            );
            // final playing = playerState?.playing;

            // if(processingState == ProcessingState.buffering || processingState == ProcessingState.loading) {
            //   return Text('Loading stream..');
            // } else if(playing != null && !playing) {
            //   return Text('Play');
            // } else if(processingState == ProcessingState.completed) {
            //   return Text('Playing');
            // } else if(playing != null && playing) {
            //   return Text('Playing');
            // }
            // return Text('Retry');
          },
        ),
      ],
    );
  }
}
