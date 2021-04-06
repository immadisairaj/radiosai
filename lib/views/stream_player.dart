import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_radio_player/flutter_radio_player.dart';
import 'package:provider/provider.dart';
import 'package:radiosai/bloc/stream_bloc.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:radiosai/constants/constants.dart';
import 'package:radiosai/views/stream_select.dart';

class StreamPlayer extends StatefulWidget {
  StreamPlayer({Key key}) : super(key: key);

  var playerState = FlutterRadioPlayer.flutter_radio_stopped;

  @override
  _StreamPlayer createState() => _StreamPlayer();
}

class _StreamPlayer extends State<StreamPlayer> with SingleTickerProviderStateMixin {
  AnimationController _animationController;
  bool isPlaying = false;

  PanelController _panelController = new PanelController();

  FlutterRadioPlayer _flutterRadioPlayer = new FlutterRadioPlayer();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _animationController = AnimationController(vsync: this, duration: Duration(milliseconds: 300));
  }

  void updateStreamIndex() {
    setState(() {
      if(isPlaying == true) {
        isPlaying = !isPlaying;
        _animationController.reverse().then((value) => stopRadioService());
      }
    });
  }

  Future<void> initRadioService(int index) async {
    try {
      await _flutterRadioPlayer.init("Radio Sai", "radiosai", MyConstants.of(context).streamLink[index], "false");
      await _flutterRadioPlayer.play();
    } on PlatformException {
      print("Execption while registering");
    }
  }

  Future<void> playRadioService() async {
    await _flutterRadioPlayer.play();
  }

  Future<void> stopRadioService() async {
    await _flutterRadioPlayer.stop();
  }

  void _handleOnPressed(int index) {
    setState(() async {
      isPlaying = !isPlaying;
      if(isPlaying) {
        _animationController.forward().then((value) => initRadioService(index));
      } else {
        _animationController.reverse().then((value) => stopRadioService());
      }
    });
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
          stream: _streamBloc.pressedCount,
          builder: (context, snapshot) {
            int streamIndex = snapshot.data;
            return player(context, _streamBloc, streamIndex, radius);
          },
        );
      },
    );
  }

  Widget player(BuildContext context, StreamBloc _streamBloc, int streamIndex, BorderRadiusGeometry radius) {
    return Scaffold(
      body: SlidingUpPanel(
        borderRadius: radius,
        backdropEnabled: true,
        controller: _panelController,
        onPanelClosed: () {
          setState(() {
            updateStreamIndex();
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    MyConstants.of(context).streamName[streamIndex],
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
                        _handleOnPressed(streamIndex);
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
