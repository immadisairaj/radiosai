import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:radiosai/screens/media_player/media_player.dart';
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

  @override
  void initState() {
    _isLoading = true;
    super.initState();
    _updateURL();
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
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics()),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      // have minimum height to reload even when 1 item is present
                      minHeight: MediaQuery.of(context).size.height,
                    ),
                    child: ListView.builder(
                        shrinkWrap: true,
                        primary: false,
                        padding: EdgeInsets.only(bottom: 10),
                        itemCount: _finalMediaData.length,
                        itemBuilder: (context, index) {
                          // replace '_' to ' ' in the text and retain it's original name
                          String mediaName = _finalMediaData[index];
                          mediaName = mediaName.replaceAll('_', ' ');
                          return Padding(
                            padding: EdgeInsets.only(left: 8, right: 8),
                            child: Card(
                              color: isDarkTheme
                                  ? Colors.grey[800]
                                  : Colors.grey[200],
                              child: InkWell(
                                child: Padding(
                                  padding: EdgeInsets.only(top: 2, bottom: 2),
                                  child: Center(
                                    child: ListTile(
                                      title: Text(mediaName),
                                      // TODO: download option?
                                      trailing: IconButton(
                                        icon: Icon(Icons.add_to_queue_outlined),
                                        onPressed: () {
                                          // TODO: change this later
                                          // only adds when the queue is already present
                                          addToQueue(mediaName,
                                              _finalMediaLinks[index]);
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      MediaPlayer()));
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                                onTap: () async {
                                  // TODO: move to player/something
                                  startPlayer(
                                      mediaName, _finalMediaLinks[index]);
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
                          );
                        }),
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

  void startPlayer(String name, String link) async {
    if (AudioService.playbackState.playing) {
      if (AudioService.queue != null && AudioService.queue.length != 0) {
        // if trying to add the current playing media, do nothing
        if (AudioService.currentMediaItem.id == link) return;

        // doesn't add to queue if already exists
        bool isAdded = await addToQueue(name, link);
        if (!isAdded) {
          // if already exists, move to last
          await moveToLast(name, link);
        }

        // play the media
        AudioService.skipToQueueItem(link);
      } else {
        // if radio player is playing
        await AudioService.stop();
        initRadioService(name, link);
      }
    } else {
      // initialize the radio service
      initRadioService(name, link);
    }
  }

  void initRadioService(String name, String link) async {
    final tempMediaItem = await getMediaItem(name, link);

    try {
      // passing params to send the source to play
      Map<String, dynamic> _params = {
        'id': tempMediaItem.id,
        'album': tempMediaItem.album,
        'title': tempMediaItem.title,
        'artUri': tempMediaItem.artUri.toString(),
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
  Future<bool> addToQueue(String name, String link) async {
    final tempMediaItem = await getMediaItem(name, link);
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
  Future<void> moveToLast(String name, String link) async {
    if (AudioService.queue != null && AudioService.queue.length > 1) {
      final tempMediaItem = await getMediaItem(name, link);
      await AudioService.removeQueueItem(tempMediaItem);
      await AudioService.addQueueItem(tempMediaItem);
    }
    return;
  }

  Future<MediaItem> getMediaItem(String name, String link) async {
    // Get the path of image for artUri in notification
    String path = await getNotificationImage();

    // Set media item to tell the clients what is playing
    final tempMediaItem = MediaItem(
      id: link,
      album: "Radio Sai Global Harmony",
      title: name,
      artUri: Uri.parse('file://$path'),
    );

    return tempMediaItem;
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
}
