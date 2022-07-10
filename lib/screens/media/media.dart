import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
// import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:internet_connection_checker/internet_connection_checker.dart';
// import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:radiosai/audio_service/audio_manager.dart';
import 'package:radiosai/audio_service/notifiers/play_button_notifier.dart';
import 'package:radiosai/audio_service/service_locator.dart';
import 'package:radiosai/bloc/media/media_screen_bloc.dart';
// import 'package:radiosai/helper/download_helper.dart';
import 'package:radiosai/helper/media_helper.dart';
import 'package:radiosai/helper/navigator_helper.dart';
import 'package:radiosai/helper/scaffold_helper.dart';
import 'package:radiosai/screens/media_player/media_player.dart';
import 'package:radiosai/widgets/bottom_media_player.dart';
import 'package:radiosai/widgets/no_data.dart';
import 'package:shimmer/shimmer.dart';

class Media extends StatefulWidget {
  const Media({
    super.key,
    required this.fids,
    this.title,
  });

  final String? fids;
  final String? title;

  @override
  _Media createState() => _Media();
}

class _Media extends State<Media> {
  /// variable to show the loading screen
  bool _isLoading = true;

  /// contains the base url of the downloads page
  final String baseUrl =
      'https://schedule.sssmediacentre.org/program/Download.php';

  /// the url with all the parameters (a unique url)
  String finalUrl = '';

  /// final data retrieved from the net
  ///
  /// connected with [_finalMediaLinks] and have same length
  ///
  /// can be ['null'] or ['timeout'] or data.
  /// Each have their own display widgets
  List<String> _finalMediaData = ['null'];

  /// final data (media links) retrieved from the net
  ///
  /// connected with [_finalMediaData] and have same length
  List<String> _finalMediaLinks = [];

  /// external media directory to where the files have to
  /// download.
  ///
  /// Sets when initState is called
  String _mediaDirectory = '';

  // /// set of download tasks
  // late List<DownloadTaskInfo> _downloadTasks;

  AudioManager? _audioManager;

  @override
  void initState() {
    // get audio manager
    _audioManager = getIt<AudioManager>();

    _isLoading = true;
    super.initState();
    _getDirectoryPath();
    _updateURL();

    // _downloadTasks = DownloadHelper.getDownloadTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            (widget.title == null) ? const Text('Media') : Text(widget.title!),
      ),
      body: AnimatedCrossFade(
        crossFadeState:
            _isLoading ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        duration: const Duration(seconds: 1),
        firstChild: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height,
          ),
          child: Stack(
            children: [
              if (_finalMediaData[0][0] != 'null' &&
                  _finalMediaData[0][0] != 'timeout')
                Scrollbar(
                  radius: const Radius.circular(8),
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics()),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.only(
                              top: 10,
                              left: 10,
                              right: 10,
                              bottom:
                                  MediaQuery.of(context).viewPadding.bottom),
                          child: Card(
                            shape: const RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)),
                            ),
                            elevation: 1,
                            color: Theme.of(context)
                                .colorScheme
                                .secondaryContainer,

                            // updates the media screen based on download state
                            child: Consumer<MediaScreenBloc>(builder:
                                (context, _mediaScreenStateBloc, child) {
                              return StreamBuilder<bool?>(
                                  stream: _mediaScreenStateBloc
                                      .mediaScreenStream as Stream<bool?>?,
                                  builder: (context, snapshot) {
                                    // can use the below commented line to know if updated
                                    // bool screenUpdate = snapshot.data ?? false;
                                    return _mediaItems();
                                  });
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              // show when no data is retrieved
              if (_finalMediaData[0] == 'null')
                NoData(
                  backgroundColor: Theme.of(context).colorScheme.background,
                  text: 'No Data Available,\ncheck your internet and try again',
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _updateURL();
                    });
                  },
                ),
              // show when no data is retrieved and timeout
              if (_finalMediaData[0] == 'timeout')
                NoData(
                  backgroundColor: Theme.of(context).colorScheme.background,
                  text:
                      'No Data Available,\nURL timeout, try again after some time',
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _updateURL();
                    });
                  },
                ),
            ],
          ),
        ),
        // Shown second child it is loading
        secondChild: Center(
          child: _showLoading(),
        ),
      ),
      bottomNavigationBar: const BottomMediaPlayer(),
    );
  }

  /// widget for media items (contains the list)
  ///
  /// showed after getting data
  Widget _mediaItems() {
    return ListView.builder(
        shrinkWrap: true,
        primary: false,
        padding: const EdgeInsets.only(top: 2, bottom: 2),
        itemCount: _finalMediaData.length,
        itemBuilder: (context, index) {
          String mediaFileName =
              '${_finalMediaData[index]}${MediaHelper.mediaFileType}';
          // replace '_' to ' ' in the text and retain it's original name
          String mediaName = _finalMediaData[index];
          mediaName = mediaName.replaceAll('_', ' ');
          var mediaFilePath = '$_mediaDirectory/$mediaFileName';
          var mediaFile = File(mediaFilePath);
          var isFileExists = mediaFile.existsSync();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8, right: 4),
                child: Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8.0),
                    onTap: () async {
                      bool hasInternet = Provider.of<InternetConnectionStatus>(
                              context,
                              listen: false) ==
                          InternetConnectionStatus.connected;
                      // No download option. So,
                      // everything is considered to use internet
                      if (hasInternet) {
                        await startPlayer(
                            mediaName, _finalMediaLinks[index], isFileExists);
                      } else {
                        getIt<ScaffoldHelper>().showSnackBar(
                            'Connect to the Internet and try again',
                            const Duration(seconds: 2));
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 4),
                      child: Center(
                        child: ListTile(
                          title: Text(mediaName),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // TODO: fix download and then uncomment below lines
                              // Visibility(
                              //   visible: !isFileExists,
                              //   child: IconButton(
                              //     icon: Icon(Icons.download_outlined),
                              //     splashRadius: 24,
                              //     onPressed: () {
                              //       _downloadMediaFile(_finalMediaLinks[index]);
                              //     },
                              //   ),
                              // ),
                              IconButton(
                                icon: const Icon(CupertinoIcons.add_circled),
                                splashRadius: 24,
                                tooltip: 'Add to playing queue',
                                onPressed: () async {
                                  // Change in radio_home.dart if changed here
                                  bool hasInternet =
                                      Provider.of<InternetConnectionStatus>(
                                              context,
                                              listen: false) ==
                                          InternetConnectionStatus.connected;
                                  // No download option. So,
                                  // everything is considered to use internet
                                  if (hasInternet) {
                                    if (!(_audioManager!
                                            .queueNotifier.value.isNotEmpty &&
                                        _audioManager!
                                                .mediaTypeNotifier.value ==
                                            MediaType.media)) {
                                      startPlayer(
                                          mediaName,
                                          _finalMediaLinks[index],
                                          isFileExists);
                                    } else {
                                      bool added = await addToQueue(
                                          mediaName,
                                          _finalMediaLinks[index],
                                          isFileExists);
                                      if (added) {
                                        getIt<ScaffoldHelper>().showSnackBar(
                                            'Added to queue',
                                            const Duration(seconds: 1));
                                      } else {
                                        getIt<ScaffoldHelper>().showSnackBar(
                                            'Already in queue',
                                            const Duration(seconds: 1));
                                      }
                                    }
                                  } else {
                                    getIt<ScaffoldHelper>().showSnackBar(
                                        'Connect to the Internet and try again',
                                        const Duration(seconds: 2));
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (index != _finalMediaData.length - 1)
                const Divider(
                  height: 2,
                  thickness: 1.5,
                ),
            ],
          );
        });
  }

  // ****************** //
  //   Retrieve Data    //
  // ****************** //

  /// sets the [finalUrl]
  ///
  /// called when initState
  ///
  /// continues the process by retrieving the data
  _updateURL() {
    var data = <String, dynamic>{};
    data['allfids'] = widget.fids;

    String url = '$baseUrl?allfids=${data['allfids']}';
    finalUrl = url;
    _getData(data);
  }

  /// retrieve the data from finalUrl
  ///
  /// continues the process by sending it to parse
  /// if the data is retrieved
  _getData(Map<String, dynamic> formData) async {
    String tempResponse = '';
    // checks if the file exists in cache
    FileInfo? fileInfo = await DefaultCacheManager().getFileFromCache(finalUrl);
    if (fileInfo == null) {
      // get data from online if not present in cache
      http.Response response;
      try {
        response = await http
            .post(Uri.parse(baseUrl), body: formData)
            .timeout(const Duration(seconds: 40));
      } on SocketException catch (_) {
        setState(() {
          // if there is no internet
          _finalMediaData = ['null'];
          finalUrl = '';
          _isLoading = false;
        });
        return;
      } on TimeoutException catch (_) {
        setState(() {
          // if timeout
          _finalMediaData = ['timeout'];
          finalUrl = '';
          _isLoading = false;
        });
        return;
      }
      tempResponse = response.body;

      // put data into cache after getting from internet
      List<int> list = tempResponse.codeUnits;
      Uint8List fileBytes = Uint8List.fromList(list);
      DefaultCacheManager().putFile(finalUrl, fileBytes);
    } else {
      // get data from file if present in cache
      tempResponse = fileInfo.file.readAsStringSync();
    }
    _parseData(tempResponse);
  }

  /// parses the data retrieved from url.
  /// sets the final data to display
  _parseData(String response) async {
    var document = parse(response);
    var mediaTags = document.getElementsByTagName('a');

    List<String> mediaFiles = [];
    List<String> mediaLinks = [];
    int length = mediaTags.length;
    for (int i = 0; i < length; i++) {
      var temp = mediaTags[i].text;
      // remove the mp3 tags (add later when playing)
      temp = temp.replaceAll('.mp3', '');
      mediaFiles.add(temp);

      // append string to get media link
      mediaLinks.add(
          '${MediaHelper.mediaBaseUrl}${mediaFiles[i]}${MediaHelper.mediaFileType}');
    }

    setState(() {
      // set the data
      _finalMediaData = mediaFiles;
      _finalMediaLinks = mediaLinks;

      // loading is done
      _isLoading = false;
    });
  }

  // // ****************** //
  // //   Download Media   //
  // // ****************** //

  // /// call to download the media file.
  // ///
  // /// pass the url [fileLink] to where it is in the internet
  // _downloadMediaFile(String fileLink) async {
  //   var permission = await _canSave();
  //   if (!permission) {
  //     getIt<ScaffoldHelper>().showSnackBar(
  //         'Accept storage permission to save image',
  //         const Duration(seconds: 2));
  //     return;
  //   }
  //   await Directory(_mediaDirectory).create(recursive: true);
  //   final fileName = fileLink.replaceAll(MediaHelper.mediaBaseUrl, '');

  //   // download only when the file is not available
  //   // downloading an available file will delete the file
  //   DownloadTaskInfo task = DownloadTaskInfo(
  //     name: fileName,
  //     link: fileLink,
  //   );
  //   if (_downloadTasks.contains(task)) return;
  //   var connectionStatus = await InternetConnectionChecker().connectionStatus;
  //   if (connectionStatus == InternetConnectionStatus.disconnected) {
  //     getIt<ScaffoldHelper>()
  //         .showSnackBar('no internet', const Duration(seconds: 1));
  //     return;
  //   }
  //   _downloadTasks.add(task);
  //   getIt<ScaffoldHelper>()
  //       .showSnackBar('downloading', const Duration(seconds: 1));
  //   // final taskId = await FlutterDownloader.enqueue(
  //   //   url: fileLink,
  //   //   savedDir: _mediaDirectory,
  //   //   fileName: fileName,
  //   //   // showNotification: false,
  //   //   showNotification: true,
  //   //   openFileFromNotification: false,
  //   // );
  //   int i = _downloadTasks.indexOf(task);
  //   // _downloadTasks[i].taskId = taskId;
  // }

  /// sets the path for directory
  ///
  /// doesn't care if the directory is created or not
  _getDirectoryPath() async {
    final mediaDirectoryPath = await MediaHelper.getDirectoryPath();
    setState(() {
      // update the media directory
      _mediaDirectory = mediaDirectoryPath;
    });
  }

  // /// returns if the app has permission to save in external path
  // Future<bool> _canSave() async {
  //   var status = await Permission.storage.request();
  //   if (status.isGranted || status.isLimited) {
  //     return true;
  //   } else {
  //     return false;
  //   }
  // }

  // ****************** //
  //   Audio Service    //
  // ****************** //
  // Change in radio_home.dart if changed here
  // Also change in sai_inspires.dart if changed here

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
    if (_audioManager!.playButtonNotifier.value == PlayButtonState.playing ||
        _audioManager!.mediaTypeNotifier.value == MediaType.media) {
      // check if radio is running / media is running
      if (_audioManager!.mediaTypeNotifier.value == MediaType.media) {
        // if trying to add the current playing media
        if (_audioManager!.currentSongTitleNotifier.value == name) {
          // if the current playing media is paused, play else navigate
          if (_audioManager!.playButtonNotifier.value !=
              PlayButtonState.playing) {
            _audioManager!.play();
          }
          getIt<ScaffoldHelper>().showSnackBar(
              'This is same as currently playing', const Duration(seconds: 2));
          getIt<NavigationService>().navigateTo(MediaPlayer.route);
          return;
        }

        _audioManager!.pause();

        // doesn't add to queue if already exists
        bool isAdded = await addToQueue(name, link, isFileExists);
        if (!isAdded) {
          // if already exists, move to last
          await moveToLast(name, link, isFileExists);
        }

        // play the media
        int index = _audioManager!.queueNotifier.value.indexOf(name);
        await _audioManager!.load();
        await _audioManager!.skipToQueueItem(index);
        // navigate to media player
        getIt<NavigationService>().navigateTo(MediaPlayer.route);
        _audioManager!.play();
      } else {
        // if radio player is running, stop and play media
        _audioManager!.stop();
        await initMediaService(name, link, isFileExists).then((value) =>
            getIt<NavigationService>().navigateTo(MediaPlayer.route));
      }
    } else {
      // initialize the media service
      initMediaService(name, link, isFileExists).then(
          (value) => getIt<NavigationService>().navigateTo(MediaPlayer.route));
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
      'extrasUri': tempMediaItem.extras!['uri'],
    };

    _audioManager!.stop();
    await _audioManager!.init(MediaType.media, _params);
  }

  /// add a new media item to the end of the queue
  ///
  /// doesn't add and returns false, if item already in queue
  ///
  /// else, adds to the queue and returns true
  Future<bool> addToQueue(String name, String link, bool isFileExists) async {
    final tempMediaItem =
        await MediaHelper.generateMediaItem(name, link, isFileExists);
    if (_audioManager!.queueNotifier.value.contains(tempMediaItem.title)) {
      return false;
    } else {
      await _audioManager!.addQueueItem(tempMediaItem);
      return true;
    }
  }

  /// move the media item to the end of the queue
  ///
  /// Note: check if the item is already in queue before calling
  Future<void> moveToLast(String name, String link, bool isFileExists) async {
    if (_audioManager!.queueNotifier.value.length > 1) {
      final tempMediaItem =
          await MediaHelper.generateMediaItem(name, link, isFileExists);
      await _audioManager!.removeQueueItemWithTitle(tempMediaItem.title);
      return _audioManager!.addQueueItem(tempMediaItem);
    }
    return;
  }

  // ****************** //
  //   Methods/widgets  //
  // ****************** //

  /// Shimmer effect while loading the content
  Widget _showLoading() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Shimmer.fromColors(
        baseColor: Theme.of(context).colorScheme.secondaryContainer,
        highlightColor: Theme.of(context).colorScheme.onSecondaryContainer,
        enabled: true,
        child: Column(
          children: [
            // 2 shimmer content
            for (int i = 0; i < 2; i++) _shimmerContent(),
          ],
        ),
      ),
    );
  }

  /// individual shimmer content for loading shimmer
  Widget _shimmerContent() {
    double width = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            width: width * 0.9,
            height: 8,
            color: Colors.white,
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            width: width * 0.9,
            height: 8,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}
