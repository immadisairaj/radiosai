import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:provider/provider.dart';
import 'package:radiosai/audio_service/audio_manager.dart';
import 'package:radiosai/audio_service/notifiers/play_button_notifier.dart';
import 'package:radiosai/audio_service/service_locator.dart';
import 'package:radiosai/bloc/radio/radio_index_bloc.dart';
import 'package:radiosai/bloc/radio/radio_loading_bloc.dart';
import 'package:radiosai/helper/download_helper.dart';
import 'package:radiosai/helper/media_helper.dart';
import 'package:radiosai/screens/radio/radio_player.dart';

class RadioHome extends StatefulWidget {
  const RadioHome({
    Key key,
  }) : super(key: key);

  @override
  _RadioHome createState() => _RadioHome();
}

class _RadioHome extends State<RadioHome> {
  AudioManager _audioManager;

  @override
  void initState() {
    // get audio manager
    _audioManager = getIt<AudioManager>();

    super.initState();

    // Flutter Downloader
    // DownloadHelper.bindBackgroundIsolate();
    // FlutterDownloader.registerCallback(DownloadHelper.downloadCallback);
  }

  @override
  void dispose() {
    // DownloadHelper.unbindBackgroundIsolate();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // border radius used for sliding panel
    Radius radius = const Radius.circular(24.0);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: const Image(
              fit: BoxFit.cover,
              alignment: Alignment(0, -1),
              image: AssetImage('assets/sai_listens.jpg'),
            ),
          ),
          // Container to reduce the brightness of background pic
          Container(
            color: const Color(0X2F000000),
          ),
          // Consumers of all the providers to get the stream of data
          Consumer<RadioIndexBloc>(
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

                          // listen to change of playing state
                          // from audio service
                          return ValueListenableBuilder<PlayButtonState>(
                              valueListenable: _audioManager.playButtonNotifier,
                              builder: (context, playButtonState, snapshot) {
                                bool isPlaying =
                                    playButtonState == PlayButtonState.playing;

                                // change the playing state only when radio
                                // player is playing
                                if (_audioManager.mediaTypeNotifier.value ==
                                    MediaType.media) {
                                  isPlaying = false;
                                }

                                // get the data of the internet
                                // connectivity change
                                bool hasInternet =
                                    Provider.of<InternetConnectionStatus>(
                                            context) ==
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
        ],
      ),
    );
  }
}
