import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:radiosai/bloc/media/media_screen_bloc.dart';
import 'package:radiosai/helper/download_helper.dart';
import 'package:radiosai/helper/media_helper.dart';
import 'package:radiosai/screens/media_player/media_player.dart';
import 'package:radiosai/widgets/bottom_media_player.dart';
import 'package:radiosai/widgets/no_data.dart';
import 'package:radiosai/audio_service/media_player_task.dart';
import 'package:shimmer/shimmer.dart';

void _mediaPlayerTaskEntrypoint() async {
  AudioServiceBackground.run(() => MediaPlayerTask());
}

class Media extends StatefulWidget {
  Media({
    Key key,
    @required this.fids,
  }) : super(key: key);

  final String fids;

  @override
  _Media createState() => _Media();
}

class _Media extends State<Media> {
  /// variable to show the loading screen
  bool _isLoading = true;

  /// contains the base url of the downloads page
  final String baseUrl = 'https://radiosai.org/program/Download.php';

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

  /// set of download tasks
  List<DownloadTaskInfo> _downloadTasks;

  @override
  void initState() {
    _isLoading = true;
    super.initState();
    _getDirectoryPath();
    _updateURL();

    _downloadTasks = DownloadHelper.getDownloadTasks();
  }

  @override
  Widget build(BuildContext context) {
    // check if dark theme
    bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    Color backgroundColor = isDarkTheme ? Colors.grey[700] : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: Text('Media'),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        color: backgroundColor,
        child: Stack(
          children: [
            if (_isLoading == false &&
                _finalMediaData[0][0] != 'null' &&
                _finalMediaData[0][0] != 'timeout')
              RefreshIndicator(
                onRefresh: _refresh,
                child: Scrollbar(
                  radius: Radius.circular(8),
                  child: SingleChildScrollView(
                    physics: BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics()),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        // have minimum height to reload even when 1 item is present
                        minHeight: MediaQuery.of(context).size.height * 0.9,
                      ),
                      child: Card(
                        elevation: 0,
                        color:
                            isDarkTheme ? Colors.grey[800] : Colors.grey[200],

                        // updates the media screen based on download state
                        child: Consumer<MediaScreenBloc>(
                            builder: (context, _mediaScreenStateBloc, child) {
                          return StreamBuilder<bool>(
                              stream: _mediaScreenStateBloc.mediaScreenStream,
                              builder: (context, snapshot) {
                                // can use the below commented line to know if updated
                                // bool screenUpdate = snapshot.data ?? false;
                                return _mediaItems(isDarkTheme);
                              });
                        }),
                      ),
                    ),
                  ),
                ),
              ),
            // show when no data is retrieved
            if (_finalMediaData[0] == 'null' && _isLoading == false)
              NoData(
                backgroundColor: backgroundColor,
                text: 'No Data Available,\ncheck your internet and try again',
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _updateURL();
                  });
                },
              ),
            // show when no data is retrieved and timeout
            if (_finalMediaData[0] == 'timeout' && _isLoading == false)
              NoData(
                backgroundColor: backgroundColor,
                text:
                    'No Data Available,\nURL timeout, try again after some time',
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _updateURL();
                  });
                },
              ),
            // Shown when it is loading
            if (_isLoading)
              Container(
                color: backgroundColor,
                child: Center(
                  child: _showLoading(isDarkTheme),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomMediaPlayer(),
    );
  }

  /// widget for media items (contains the list)
  ///
  /// showed after getting data
  Widget _mediaItems(bool isDarkTheme) {
    return ListView.builder(
        shrinkWrap: true,
        primary: false,
        padding: EdgeInsets.only(top: 2, bottom: 2),
        itemCount: _finalMediaData.length,
        itemBuilder: (context, index) {
          String mediaFileName =
              '${_finalMediaData[index]}${MediaHelper.mediaFileType}';
          // replace '_' to ' ' in the text and retain it's original name
          String mediaName = _finalMediaData[index];
          mediaName = mediaName.replaceAll('_', ' ');
          var mediaFilePath = '$_mediaDirectory/$mediaFileName';
          var mediaFile = new File(mediaFilePath);
          var isFileExists = mediaFile.existsSync();
          return Column(
            children: [
              Padding(
                padding: EdgeInsets.only(left: 8),
                child: Card(
                  elevation: 0,
                  color: isDarkTheme ? Colors.grey[800] : Colors.grey[200],
                  child: InkWell(
                    child: Padding(
                      padding: EdgeInsets.only(top: 2, bottom: 2),
                      child: Center(
                        child: ListTile(
                          title: Text(mediaName),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Visibility(
                                visible: !isFileExists,
                                child: IconButton(
                                  icon: Icon(Icons.download_outlined),
                                  splashRadius: 24,
                                  onPressed: () {
                                    _downloadMediaFile(_finalMediaLinks[index]);
                                  },
                                ),
                              ),
                              IconButton(
                                icon: Icon(CupertinoIcons.add_circled),
                                splashRadius: 24,
                                onPressed: () async {
                                  if (!(AudioService.queue != null &&
                                      AudioService.queue.length != 0)) {
                                    startPlayer(mediaName,
                                        _finalMediaLinks[index], isFileExists);
                                  } else {
                                    bool added = await addToQueue(mediaName,
                                        _finalMediaLinks[index], isFileExists);
                                    if (added)
                                      _showSnackBar(context, 'Added to queue',
                                          Duration(seconds: 1));
                                    else
                                      _showSnackBar(context, 'Already in queue',
                                          Duration(seconds: 1));
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                    onTap: () async {
                      await startPlayer(
                          mediaName, _finalMediaLinks[index], isFileExists);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => MediaPlayer()));
                    },
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              if (index != _finalMediaData.length - 1)
                Divider(
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
    var data = new Map<String, dynamic>();
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
    var fileInfo = await DefaultCacheManager().getFileFromCache(finalUrl);
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

  // ****************** //
  //   Download Media   //
  // ****************** //

  /// call to download the media file.
  ///
  /// pass the url [fileLink] to where it is in the internet
  _downloadMediaFile(String fileLink) async {
    var permission = await _canSave();
    if (!permission) {
      _showSnackBar(context, 'Accept storage permission to save image',
          Duration(seconds: 2));
      return;
    }
    await new Directory(_mediaDirectory).create(recursive: true);
    final fileName = fileLink.replaceAll('${MediaHelper.mediaBaseUrl}', '');

    // download only when the file is not available
    // downloading an available file will delete the file
    DownloadTaskInfo task = new DownloadTaskInfo(
      name: fileName,
      link: fileLink,
    );
    if (_downloadTasks.contains(task)) return;
    var connectionStatus = await InternetConnectionChecker().connectionStatus;
    if (connectionStatus == InternetConnectionStatus.disconnected) {
      _showSnackBar(context, 'no internet', Duration(seconds: 1));
      return;
    }
    _downloadTasks.add(task);
    _showSnackBar(context, 'downloading', Duration(seconds: 1));
    final taskId = await FlutterDownloader.enqueue(
      url: fileLink,
      savedDir: _mediaDirectory,
      fileName: fileName,
      showNotification: false,
    );
    int i = _downloadTasks.indexOf(task);
    _downloadTasks[i].taskId = taskId;
  }

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

  /// returns if the app has permission to save in external path
  Future<bool> _canSave() async {
    var status = await Permission.storage.request();
    if (status.isGranted || status.isLimited) {
      return true;
    } else {
      return false;
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

  // ****************** //
  //   Audio Service    //
  // ****************** //

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
    if (AudioService.playbackState.playing) {
      if (AudioService.queue != null && AudioService.queue.length != 0) {
        String fileId = await MediaHelper.getFileIdFromUri(link);
        // if trying to add the current playing media, do nothing
        if (AudioService.currentMediaItem.id == fileId) return;

        // doesn't add to queue if already exists
        bool isAdded = await addToQueue(name, link, isFileExists);
        if (!isAdded) {
          // if already exists, move to last
          await moveToLast(name, link, isFileExists);
        }

        // play the media
        AudioService.skipToQueueItem(fileId);
      } else {
        // if radio player is playing
        await AudioService.stop();
        initMediaService(name, link, isFileExists);
      }
    } else {
      if (AudioService.running) {
        // if the radio player is paused
        await AudioService.stop();
        initMediaService(name, link, isFileExists);
      }
      // initialize the radio service
      initMediaService(name, link, isFileExists);
    }
  }

  /// initialize the media player when no player is playing
  void initMediaService(String name, String link, bool isFileExists) async {
    final tempMediaItem =
        await MediaHelper.generateMediaItem(name, link, isFileExists);

    try {
      // passing params to send the source to play
      Map<String, dynamic> _params = {
        'id': tempMediaItem.id,
        'album': tempMediaItem.album,
        'title': tempMediaItem.title,
        'artUri': tempMediaItem.artUri.toString(),
        'extrasUri': tempMediaItem.extras['uri'],
      };

      AudioService.connect();
      await AudioService.start(
        backgroundTaskEntrypoint: _mediaPlayerTaskEntrypoint,
        params: _params,
        // clear the notification when paused
        androidStopForegroundOnPause: true,
        androidEnableQueue: true,
        androidNotificationChannelName: 'Media Player',
      );
    } on PlatformException {
      print("Execption while registering");
    }
  }

  /// add a new media item to the end of the queue
  ///
  /// doesn't add and returns false, if item already in queue
  ///
  /// else, adds to the queue and returns true
  Future<bool> addToQueue(String name, String link, bool isFileExists) async {
    final tempMediaItem =
        await MediaHelper.generateMediaItem(name, link, isFileExists);
    if (AudioService.queue.contains(tempMediaItem)) {
      return false;
    } else {
      await AudioService.addQueueItem(tempMediaItem);
      return true;
    }
  }

  /// move the media item to the end of the queue
  ///
  /// Note: check if the item is already in queue before calling
  Future<void> moveToLast(String name, String link, bool isFileExists) async {
    if (AudioService.queue != null && AudioService.queue.length > 1) {
      final tempMediaItem =
          await MediaHelper.generateMediaItem(name, link, isFileExists);
      await AudioService.removeQueueItem(tempMediaItem);
      await AudioService.addQueueItem(tempMediaItem);
    }
    return;
  }

  // ****************** //
  //   Methods/widgets  //
  // ****************** //

  /// refresh the data
  Future<void> _refresh() async {
    await DefaultCacheManager().removeFile(finalUrl);
    setState(() {
      _isLoading = true;
      _updateURL();
    });
  }

  /// Shimmer effect while loading the content
  Widget _showLoading(bool isDarkTheme) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Shimmer.fromColors(
        baseColor: isDarkTheme ? Colors.grey[500] : Colors.grey[300],
        highlightColor: isDarkTheme ? Colors.grey[300] : Colors.grey[100],
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
      padding: EdgeInsets.only(bottom: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(bottom: 10),
            width: width * 0.9,
            height: 8,
            color: Colors.white,
          ),
          Container(
            margin: EdgeInsets.only(bottom: 10),
            width: width * 0.9,
            height: 8,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}
