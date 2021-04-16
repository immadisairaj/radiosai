import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:provider/provider.dart';
import 'package:radiosai/bloc/radio_index_bloc.dart';
import 'package:radiosai/bloc/radio_loading_bloc.dart';
import 'package:radiosai/screens/radio/radio_player.dart';

class RadioHome extends StatefulWidget {
  RadioHome({
    Key key,
  }) : super(key: key);

  @override
  _RadioHome createState() => _RadioHome();
}

class _RadioHome extends State<RadioHome> {
  @override
  Widget build(BuildContext context) {
    // border radius used for sliding panel
    BorderRadiusGeometry radius = BorderRadius.only(
      topLeft: Radius.circular(24.0),
      topRight: Radius.circular(24.0),
    );
    return Scaffold(
      // Consumers of all the providers to get the stream of data
      body: Consumer<RadioIndexBloc>(
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
                            // get the data of the internet connectivity change
                            bool hasInternet =
                                Provider.of<InternetConnectionStatus>(context) ==
                                    InternetConnectionStatus.connected;
                            return RadioPlayer(
                                radius: radius,
                                radioStreamIndex: radioStreamIndex,
                                isPlaying: isPlaying,
                                loadingState: loadingState,
                                radioLoadingBloc: _radioLoadingBloc,
                                hasInternet: hasInternet);
                          });
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}