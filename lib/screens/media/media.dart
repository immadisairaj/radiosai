import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:ext_storage/ext_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
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
  bool _isLoading = true;

  String baseUrl = 'https://radiosai.org/program/Download.php';
  String mediaBaseUrl = 'https://dl.radiosai.org/';
  String mediaFileType = '.mp3';
  String finalUrl = '';

  List<String> _finalMediaData = ['null'];
  List<String> _finalMediaLinks = [];

  String _mediaDirectory = '';
  ReceivePort _port = ReceivePort();
  // TODO: maybe make this list to know which one is downloaded
  // or add a task list?
  bool isDownloading = false;

  @override
  void initState() {
    _isLoading = true;
    super.initState();
    _getDirectoryPath();
    _updateURL();

    // Flutter Downloader
    _bindBackgroundIsolate();
    FlutterDownloader.registerCallback(downloadCallback);
  }

  @override
  void dispose() {
    _unbindBackgroundIsolate();
    super.dispose();
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
            if (_isLoading == false || _finalMediaData[0] != 'null')
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
                        child: ListView.builder(
                            shrinkWrap: true,
                            primary: false,
                            padding: EdgeInsets.only(top: 2, bottom: 2),
                            itemCount: _finalMediaData.length,
                            itemBuilder: (context, index) {
                              String mediaFileName = '${_finalMediaData[index]}$mediaFileType';
                              // replace '_' to ' ' in the text and retain it's original name
                              String mediaName = _finalMediaData[index];
                              mediaName = mediaName.replaceAll('_', ' ');
                              var mediaFilePath = '$_mediaDirectory/$mediaFileName';
                              var mediaFile = new File(mediaFilePath);
                              var isFileExist = mediaFile.existsSync();
                              return Column(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(left: 8, right: 8),
                                    child: Card(
                                      elevation: 0,
                                      color: isDarkTheme
                                          ? Colors.grey[800]
                                          : Colors.grey[200],
                                      child: InkWell(
                                        child: Padding(
                                          padding: EdgeInsets.only(
                                              top: 2, bottom: 2),
                                          child: Center(
                                            child: ListTile(
                                              title: Text(mediaName),
                                              trailing: Visibility(
                                                visible: !isFileExist,
                                                child: IconButton(
                                                  icon: Icon(
                                                      Icons.download_outlined),
                                                  onPressed: () {
                                                    _downloadMediaFile(
                                                        _finalMediaLinks[index]);
                                                  },
                                                ),
                                              ),
                                              // trailing: IconButton(
                                              //   icon: Icon(Icons
                                              //       .add_to_queue_outlined),
                                              //   onPressed: () {
                                              //     // TODO: change this later
                                              //     // only adds when the queue is already present
                                              //     addToQueue(mediaName,
                                              //         _finalMediaLinks[index]);
                                              //     Navigator.push(
                                              //         context,
                                              //         MaterialPageRoute(
                                              //             builder: (context) =>
                                              //                 MediaPlayer()));
                                              //   },
                                              // ),
                                            ),
                                          ),
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        onTap: () async {
                                          // TODO: move to player/something
                                          await startPlayer(mediaName,
                                              _finalMediaLinks[index], isFileExist);
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      MediaPlayer()));
                                        },
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
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

  _updateURL() {
    var data = new Map<String, dynamic>();
    data['allfids'] = widget.fids;

    String url = '$baseUrl?allfids=${data['allfids']}';
    finalUrl = url;
    _getData(data);
  }

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
      mediaLinks.add('$mediaBaseUrl${mediaFiles[i]}$mediaFileType');
    }

    setState(() {
      // set the data
      _finalMediaData = mediaFiles;
      _finalMediaLinks = mediaLinks;

      // loading is done
      _isLoading = false;
    });
  }

  _downloadMediaFile(String fileLink) async {
    var permission = await _canSave();
    if (!permission) {
      _showSnackBar(context, 'Accept storage permission to save image',
          Duration(seconds: 2));
      return;
    }
    await new Directory(_mediaDirectory).create(recursive: true);
    final fileName = fileLink.replaceAll('$mediaBaseUrl', '');

    // download only when the file is not available
    // downloading an available file will delete the file
    _showSnackBar(context, 'downloading', Duration(seconds: 1));
    isDownloading = true;
    final taskId = await FlutterDownloader.enqueue(
      url: fileLink,
      savedDir: _mediaDirectory,
      fileName: fileName,
      showNotification: false,
    );
  }

  // sets the path for directory
  // doesn't care if the directory is created or not
  _getDirectoryPath() async {
    final publicDirectoryPath = await _getPublicPath();
    final albumName = 'Sai Voice/Media';
    final mediaDirectoryPath = '$publicDirectoryPath/$albumName';

    setState(() {
      // update the media directory
      _mediaDirectory = mediaDirectoryPath;
    });
  }

  Future<String> _getPublicPath() async {
    var path = await ExtStorage.getExternalStorageDirectory();
    return path;
  }

  Future<bool> _canSave() async {
    var status = await Permission.storage.request();
    if (status.isGranted || status.isLimited) {
      return true;
    } else {
      return false;
    }
  }

  void _showSnackBar(BuildContext context, String text, Duration duration) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
      behavior: SnackBarBehavior.floating,
      duration: duration,
    ));
  }

  Future<void> startPlayer(String name, String link, bool isFileExists) async {
    if (AudioService.playbackState.playing) {
      if (AudioService.queue != null && AudioService.queue.length != 0) {
        String fileId = _getFileFromUri(link, mediaBaseUrl, _mediaDirectory);
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
        initRadioService(name, link, isFileExists);
      }
    } else {
      if (AudioService.running) {
        // if the radio player is paused
        await AudioService.stop();
        initRadioService(name, link, isFileExists);
      }
      // initialize the radio service
      initRadioService(name, link, isFileExists);
    }
  }

  void initRadioService(String name, String link, bool isFileExists) async {
    final tempMediaItem = await getMediaItem(name, link, isFileExists);

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

  // add a new media item to the end of the queue
  // doesn't add and returns false if item already in queue
  Future<bool> addToQueue(String name, String link, bool isFileExists) async {
    final tempMediaItem = await getMediaItem(name, link, isFileExists);
    if (AudioService.queue.contains(tempMediaItem)) {
      // TODO: show that the current is already in queue or something
      return false;
    } else {
      await AudioService.addQueueItem(tempMediaItem);
      return true;
    }
  }

  // move the media item to the end of the queue
  // check if the item is already in queue before calling
  Future<void> moveToLast(String name, String link, bool isFileExists) async {
    if (AudioService.queue != null && AudioService.queue.length > 1) {
      final tempMediaItem = await getMediaItem(name, link, isFileExists);
      await AudioService.removeQueueItem(tempMediaItem);
      await AudioService.addQueueItem(tempMediaItem);
    }
    return;
  }

  Future<MediaItem> getMediaItem(String name, String link, bool isFileExists) async {
    // Get the path of image for artUri in notification
    String path = await getNotificationImage();

    if (isFileExists) {
      link = _changeLinkToFile(link, mediaBaseUrl, _mediaDirectory);
    }

    String fileId = _getFileFromUri(link, mediaBaseUrl, _mediaDirectory);

    Map<String, dynamic> _extras = {
      'uri': link,
    };

    // Set media item to tell the clients what is playing
    // extras['uri'] contains the audio source
    final tempMediaItem = MediaItem(
      id: fileId,
      album: "Radio Sai Global Harmony",
      title: name,
      artUri: Uri.parse('file://$path'),
      extras: _extras,
    );

    return tempMediaItem;
  }

  // changes link to file - removes base url and appends directory
  // returns file URI
  String _changeLinkToFile(String link, String baseUrl, String directory) {
    link = link.replaceAll(baseUrl, '');
    return 'file://$directory/$link';
  }

  // changes link to file - removes base url or removes directory
  // returns file with extension
  String _getFileFromUri(String link, String baseUrl, String directory) {
    link = link.replaceAll(baseUrl, '');
    link = link.replaceAll('file://$directory/', '');
    return link;
  }

  // for refreshing the data
  Future<void> _refresh() async {
    await DefaultCacheManager().removeFile(finalUrl);
    setState(() {
      _isLoading = true;
      _updateURL();
    });
  }

  // Get notification image stored in file,
  // if not stored, then store the image
  Future<String> getNotificationImage() async {
    String path = await getFilePath();
    File file = File(path);
    bool fileExists = file.existsSync();
    // if the image already exists, return the path
    if (fileExists) return path;
    // store the image into path from assets then return the path
    final byteData =
        await rootBundle.load('assets/sai_listens_notification.jpg');
    // if file is not created, create to write into the file
    file.create(recursive: true);
    await file.writeAsBytes(byteData.buffer.asUint8List());
    return path;
  }

  // Get the file path of the notification image
  Future<String> getFilePath() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;
    String filePath = '$appDocPath/sai_listens_notification.jpg';
    return filePath;
  }

  // Shimmer effect while loading the content
  Widget _showLoading(bool isDarkTheme) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Shimmer.fromColors(
        baseColor: isDarkTheme ? Colors.grey[500] : Colors.grey[300],
        highlightColor: isDarkTheme ? Colors.grey[300] : Colors.grey[100],
        enabled: true,
        child: Column(
          children: [
            // 2 shimmer boxes
            for (int i = 0; i < 2; i++) _shimmerContent(),
          ],
        ),
      ),
    );
  }

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

  void _bindBackgroundIsolate() {
    bool isSuccess = IsolateNameServer.registerPortWithName(
        _port.sendPort, 'downloader_send_port');
    if (!isSuccess) {
      _unbindBackgroundIsolate();
      _bindBackgroundIsolate();
      return;
    }
    _port.listen((data) {
      String id = data[0];
      DownloadTaskStatus status = data[1];
      int progress = data[2];

      if(status == DownloadTaskStatus.failed) {
        // remove the file if the task failed
        FlutterDownloader.remove(taskId: id);
        setState(() {
          _showSnackBar(context, 'failed downloading', Duration(seconds: 1));
          isDownloading = false;
        });
        return;
      }

      if (status == DownloadTaskStatus.complete) {
        // show that it is downloaded
        setState(() {
          _showSnackBar(context, 'downloaded', Duration(seconds: 1));
          isDownloading = false;
          // TODO: if the currently downloaded file is in queue,
          // replace the queue item/change id of the queue item
        });
        return;
      }
    });
  }

  void _unbindBackgroundIsolate() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
  }

  static void downloadCallback(
      String id, DownloadTaskStatus status, int progress) {
    final SendPort send =
        IsolateNameServer.lookupPortByName('downloader_send_port');
    send.send([id, status, progress]);
  }
}
