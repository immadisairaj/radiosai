import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:radiosai/audio_service/audio_manager.dart';
import 'package:radiosai/audio_service/notifiers/play_button_notifier.dart';
import 'package:radiosai/audio_service/service_locator.dart';
import 'package:radiosai/bloc/radio/radio_index_bloc.dart';
import 'package:radiosai/bloc/radio/radio_loading_bloc.dart';
// import 'package:radiosai/helper/download_helper.dart';
import 'package:radiosai/helper/media_helper.dart';
import 'package:radiosai/helper/navigator_helper.dart';
import 'package:radiosai/screens/media_player/media_player.dart';
import 'package:radiosai/screens/media_player/playing_queue.dart';
import 'package:radiosai/screens/radio/radio_player.dart';
import 'package:uni_links/uni_links.dart';

class RadioHome extends StatefulWidget {
  const RadioHome({
    Key key,
  }) : super(key: key);

  @override
  _RadioHome createState() => _RadioHome();
}

bool _initialUriIsHandled = false;

class _RadioHome extends State<RadioHome> {
  AudioManager _audioManager;

  @override
  void initState() {
    // get audio manager
    _audioManager = getIt<AudioManager>();

    super.initState();

    // handle app links
    _handleIncomingLinks();
    _handleInitialUri();

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

  _validateAndPlayMedia(Uri uri) async {
    String receivedLink = uri.toString();
    String name = MediaHelper.getNameFromLink(receivedLink);
    // TODO: check if the navigator already contains mediaplayer
    // if it contains, no need to navigate again

    // This is the same code from media.dart (on tap a media item)
    bool hasInternet =
        Provider.of<InternetConnectionStatus>(context, listen: false) ==
            InternetConnectionStatus.connected;
    // No download option. So,
    // everything is considered to use internet
    if (hasInternet) {
      final response = await http.head(uri);
      if (response.statusCode != 200) {
        _showSnackBar(context, 'Link is not valid', const Duration(seconds: 1));
        return;
      }
      // treated as file is absent
      startPlayer(name, receivedLink, false);
    } else {
      _showSnackBar(context, 'Connect to the Internet and try again',
          const Duration(seconds: 2));
    }
  }

  // ****************** //
  //   Audio Service    //
  // ****************** //
  // Copy of exact methods from media.dart

  /// start the media player
  ///
  /// when there is no media playing,
  /// there is media playing (skips to play this)
  ///
  /// handles the stop if the radio player is playing
  ///
  /// pass the following parameters:
  ///
  /// [name] - media name;
  /// [link] - media link (url);
  /// [isFileExists] - if whether file exists in external storage
  Future<void> startPlayer(String name, String link, bool isFileExists) async {
    // checks if the audio service is running
    if (_audioManager.playButtonNotifier.value == PlayButtonState.playing ||
        _audioManager.mediaTypeNotifier.value == MediaType.media) {
      // check if radio is running / media is running
      if (_audioManager.mediaTypeNotifier.value == MediaType.media) {
        // if trying to add the current playing media
        if (_audioManager.currentSongTitleNotifier.value == name) {
          // if the current playing media is paused, play else navigate
          if (_audioManager.playButtonNotifier.value !=
              PlayButtonState.playing) {
            _audioManager.play();
          }
          _showSnackBar(context, 'This is same as currently playing',
              const Duration(seconds: 2));
          getIt<NavigationService>().navigateTo(MediaPlayer.route);
          return;
        }

        _audioManager.pause();

        // doesn't add to queue if already exists
        bool isAdded = await addToQueue(name, link, isFileExists);
        if (!isAdded) {
          // if already exists, move to last
          await moveToLast(name, link, isFileExists);
        }

        // play the media
        int index = _audioManager.queueNotifier.value.indexOf(name);
        await _audioManager.load();
        await _audioManager.skipToQueueItem(index);
        // navigate to media player
        _openMediaPlayer();
        _audioManager.play();
      } else {
        // if radio player is running, stop and play media
        _audioManager.stop();
        await initMediaService(name, link, isFileExists)
            .then((value) => _openMediaPlayer());
      }
    } else {
      // initialize the media service
      initMediaService(name, link, isFileExists)
          .then((value) => _openMediaPlayer());
    }
  }

  /// initialize the media player when no player is playing
  Future<void> initMediaService(
      String name, String link, bool isFileExists) async {
    final tempMediaItem =
        await MediaHelper.generateMediaItem(name, link, isFileExists);

    // passing params to send the source to play
    Map<String, dynamic> _params = {
      'id': tempMediaItem.id,
      'album': tempMediaItem.album,
      'title': tempMediaItem.title,
      'artist': tempMediaItem.artist,
      'artUri': tempMediaItem.artUri.toString(),
      'extrasUri': tempMediaItem.extras['uri'],
    };

    _audioManager.stop();
    await _audioManager.init(MediaType.media, _params);
  }

  /// add a new media item to the end of the queue
  ///
  /// doesn't add and returns false, if item already in queue
  ///
  /// else, adds to the queue and returns true
  Future<bool> addToQueue(String name, String link, bool isFileExists) async {
    final tempMediaItem =
        await MediaHelper.generateMediaItem(name, link, isFileExists);
    if (_audioManager.queueNotifier.value.contains(tempMediaItem.title)) {
      return false;
    } else {
      await _audioManager.addQueueItem(tempMediaItem);
      return true;
    }
  }

  /// move the media item to the end of the queue
  ///
  /// Note: check if the item is already in queue before calling
  Future<void> moveToLast(String name, String link, bool isFileExists) async {
    if (_audioManager.queueNotifier.value != null &&
        _audioManager.queueNotifier.value.length > 1) {
      final tempMediaItem =
          await MediaHelper.generateMediaItem(name, link, isFileExists);
      await _audioManager.removeQueueItemWithTitle(tempMediaItem.title);
      return _audioManager.addQueueItem(tempMediaItem);
    }
    return;
  }

  /// Navigates to Media Player Screen - if it's in stack or no
  _openMediaPlayer() {
    // Copied this code from audio_handler.dart from notifications listen
    // if audio is media, then open media player
    if (!getIt<NavigationService>().isCurrentRoute(MediaPlayer.route)) {
      // if current route is media player, keep it as it is
      if (getIt<NavigationService>().isCurrentRoute(PlayingQueue.route)) {
        // if current route is playing queue, pop till media player
        getIt<NavigationService>().popUntil(MediaPlayer.route);
      } else {
        // if media player is not in tree, push media player
        getIt<NavigationService>().navigateTo(MediaPlayer.route);
      }
    }
  }

  /// show snack bar for the current context
  ///
  /// pass current [context],
  /// [text] to display and
  /// [duration] for how much time to display
  void _showSnackBar(BuildContext context, String text, Duration duration) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
      behavior: SnackBarBehavior.floating,
      duration: duration,
    ));
  }

  /// Handle incoming links - the ones that the app will recieve from the OS
  /// while already started.
  void _handleIncomingLinks() {
    // It will handle app links while the app is already started - be it in
    // the foreground or in the background.
    uriLinkStream.listen((Uri uri) {
      // _sub = uriLinkStream.listen((Uri uri) {
      if (!mounted) return;
      // print('got uri: $uri');
      _validateAndPlayMedia(uri);
      // setState(() {
      //   _latestUri = uri;
      //   _err = null;
      // });
    }, onError: (Object err) {
      if (!mounted) return;
      // error has recieved and no need to send anything
      // setState(() {
      //   _latestUri = null;
      //   if (err is FormatException) {
      //     _err = err;
      //   } else {
      //     _err = null;
      //   }
      // });
    });
  }

  /// Handle the initial Uri - the one the app was started with
  ///
  /// **ATTENTION**: `getInitialLink`/`getInitialUri` should be handled
  /// ONLY ONCE in your app's lifetime, since it is not meant to change
  /// throughout your app's life.
  ///
  /// We handle all exceptions, since it is called from initState.
  Future<void> _handleInitialUri() async {
    // In this example app this is an almost useless guard, but it is here to
    // show we are not going to call getInitialUri multiple times, even if this
    // was a weidget that will be disposed of (ex. a navigation route change).
    if (!_initialUriIsHandled) {
      _initialUriIsHandled = true;
      // print('_handleInitialUri called');
      try {
        final uri = await getInitialUri();
        if (uri == null) {
          // No uri is returned. Do nothing
        } else {
          // print('got initial uri: $uri');
          _validateAndPlayMedia(uri);
        }
        if (!mounted) return;
        // initialUri = uri
      } on PlatformException {
        // Platform messages may fail but we ignore the exception
        // print('falied to get initial uri');
      } on FormatException catch (err) {
        if (!mounted) return;
        // print('malformed initial uri');
      }
    }
  }
}
