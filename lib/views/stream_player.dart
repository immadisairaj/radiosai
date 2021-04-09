import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:radiosai/audio-source/audio_player_task.dart';
import 'package:radiosai/bloc/loading_stream_bloc.dart';
import 'package:radiosai/bloc/stream_bloc.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:radiosai/constants/constants.dart';
import 'package:radiosai/views/stream_select.dart';

void _entrypoint() => AudioServiceBackground.run(() => AudioPlayerTask());

class StreamPlayer extends StatefulWidget {
  StreamPlayer({Key key}) : super(key: key);

  @override
  _StreamPlayer createState() => _StreamPlayer();
}

class _StreamPlayer extends State<StreamPlayer> with SingleTickerProviderStateMixin {
  AnimationController _animationController;

  PanelController _panelController = new PanelController();

  int _tempStreamIndex = 0;

  @override
  void initState() {
    _animationController = AnimationController(vsync: this, duration: Duration(milliseconds: 300));
    super.initState();
  }

  void updateStreamIndex(bool isPlaying, bool isLoading) {
    if(isPlaying && !isLoading) {
      stopRadioService();
    }
  }

  void initRadioService(int index) {
    try {
      Map<String, dynamic> _params = {
        'audioSource': MyConstants.of(context).streamLink[index],
        'audioName': MyConstants.of(context).streamName[index],
      };
      AudioService.connect();
      AudioService.start(
        backgroundTaskEntrypoint: _entrypoint,
        params: _params,
        androidStopForegroundOnPause: true,
      );

      setState(() {
        _tempStreamIndex = index;
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

  @override
  void dispose() async {
    await AudioService.stop();
    super.dispose();
  }

  void _handleOnPressed(int index, bool isPlaying, bool isLoading, LoadingStreamBloc loadingStreamBloc) {
    if(!isPlaying) {
      loadingStreamBloc.changeLoadingState.add(true);
      initRadioService(index);
      if(!isLoading) playRadioService();
    } else {
      loadingStreamBloc.changeLoadingState.add(false);
      stopRadioService();
    }
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
            return Consumer<LoadingStreamBloc>(
              builder: (context, _loadingBloc, child) {
                return StreamBuilder<bool>(
                  stream: _loadingBloc.loadingStream,
                  builder: (context, snapshot) {
                    bool loadingState = snapshot.data ?? false;
                    return StreamBuilder<bool>(
                      stream: AudioService.playbackStateStream
                              .map((state) => state.playing)
                              .distinct(),
                      builder: (context, snapshot) {
                        final isPlaying = snapshot.data ?? false;
                        _handlePlayingState(isPlaying);
                        return mainPlayer(streamIndex, radius, isPlaying, loadingState, _loadingBloc);
                      }
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget mainPlayer(int streamIndex, BorderRadiusGeometry radius, bool isPlaying, bool loadingState, LoadingStreamBloc _loadingBloc) {
    return Scaffold(
      body: SlidingUpPanel(
        borderRadius: radius,
        backdropEnabled: true,
        controller: _panelController,
        onPanelClosed: () {
          setState(() {
            if(streamIndex != null && _tempStreamIndex != streamIndex) updateStreamIndex(isPlaying, loadingState);
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
          loadingStreamBloc: _loadingBloc,
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
                child: playingDisplay(streamIndex, isPlaying, loadingState, _loadingBloc),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget playingDisplay(int streamIndex, bool isPlaying, bool loadingState, LoadingStreamBloc _loadingBloc) {
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
        Stack(
          alignment: Alignment.center,
          children: [
            if(loadingState)
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
                  progress: _animationController,
                ),
                onPressed: () async {
                  if(streamIndex != null) _handleOnPressed(streamIndex, isPlaying, loadingState, _loadingBloc);
                },
              )
            ),
          ],
        ),
        StreamBuilder<AudioProcessingState>(
          stream: AudioService.playbackStateStream
                  .map((state) => state.processingState),
          builder: (context, snapshot) {
            final playerState = snapshot.data;
            final processingState = playerState ?? AudioProcessingState.none;
            String displayText = '';
            switch(processingState) {
              case AudioProcessingState.none:
                displayText = 'Play';
                break;
              case AudioProcessingState.ready:
                _loadingBloc.changeLoadingState.add(false);
                displayText = isPlaying ? 'Playing' : 'Play';
                break;
              case AudioProcessingState.completed:
              case AudioProcessingState.stopped:
                displayText = '${describeEnum(processingState)}';
                _loadingBloc.changeLoadingState.add(false);
                break;
              case AudioProcessingState.buffering:
                _loadingBloc.changeLoadingState.add(true);
                displayText = 'Buffering';
                break;
              case AudioProcessingState.connecting:
                displayText = 'Loading stream..';
                break;
              case AudioProcessingState.error:
                _loadingBloc.changeLoadingState.add(false);
                displayText = 'Error.. retry';
                break;
              default:
                _loadingBloc.changeLoadingState.add(false);
                displayText = '${describeEnum(processingState)}'; 
            }
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
}
