import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
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
import 'package:shimmer/shimmer.dart';

class Media extends StatefulWidget {
  const Media({super.key, required this.mediaFiles, this.title});

  final List<String>? mediaFiles;
  final String? title;

  @override
  State<Media> createState() => _Media();
}

class _Media extends State<Media> {
  /// variable to show the loading screen
  bool _isLoading = true;

  // /// contains the base url of the downloads page
  // final String baseUrl =
  //     'https://schedule.sssmediacentre.org/program/Download.php';

  // /// the url with all the parameters (a unique url)
  // String finalUrl = '';

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
    _parseData();

    // _downloadTasks = DownloadHelper.getDownloadTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: (widget.title == null)
            ? const Text('Media')
            : Text(widget.title!),
      ),
      body: AnimatedCrossFade(
        crossFadeState: _isLoading
            ? CrossFadeState.showSecond
            : CrossFadeState.showFirst,
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
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: 10,
                            left: 10,
                            right: 10,
                            bottom: MediaQuery.of(context).viewPadding.bottom,
                          ),
                          child: Column(
                            children: [
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton.icon(
                                  icon: const Icon(CupertinoIcons.play_circle),
                                  label: Text('Play All'),
                                  onPressed: playAllClick,
                                ),
                              ),
                              Card(
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(10),
                                  ),
                                ),
                                elevation: 1,
                                color: Theme.of(
                                  context,
                                ).colorScheme.secondaryContainer,

                                // updates the media screen based on download state
                                child: Consumer<MediaScreenBloc>(
                                  builder: (context, mediaScreenStateBloc, child) {
                                    return StreamBuilder<bool?>(
                                      stream:
                                          mediaScreenStateBloc.mediaScreenStream
                                              as Stream<bool?>?,
                                      builder: (context, snapshot) {
                                        // can use the below commented line to know if updated
                                        // bool screenUpdate = snapshot.data ?? false;
                                        return _mediaItems();
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        // Shown second child it is loading
        secondChild: Center(child: _showLoading()),
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
                    bool hasInternet =
                        Provider.of<InternetStatus>(context, listen: false) ==
                        InternetStatus.connected;
                    // No download option. So,
                    // everything is considered to use internet
                    if (hasInternet) {
                      await startPlayer(
                        mediaName,
                        _finalMediaLinks[index],
                        isFileExists,
                      );
                    } else {
                      getIt<ScaffoldHelper>().showSnackBar(
                        'Connect to the Internet and try again',
                        const Duration(seconds: 2),
                      );
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
                                mediaPlusClick(
                                  mediaName,
                                  _finalMediaLinks[index],
                                  isFileExists,
                                );
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
              const Divider(height: 2, thickness: 1.5),
          ],
        );
      },
    );
  }

  void playAllClick() async {
    if (_preCachedMediaItems.isEmpty) return;

    await _audioManager!.stop();
    await _audioManager!.clear();

    // Initialize with the first pre-cached item
    await initMediaService(_preCachedMediaItems[0]);

    getIt<NavigationService>().navigateTo(MediaPlayer.route);
    _audioManager!.play();

    // Add the rest of the pre-cached items immediately
    if (_preCachedMediaItems.length > 1) {
      await _audioManager!.addQueueItems(_preCachedMediaItems.sublist(1));
    }
  }

  void mediaPlusClick(String name, String link, bool isFileExists) async {
    bool hasInternet =
        Provider.of<InternetStatus>(context, listen: false) ==
        InternetStatus.connected;
    if (!hasInternet) {
      getIt<ScaffoldHelper>().showSnackBar(
        'Connect to the Internet',
        const Duration(seconds: 2),
      );
      return;
    }

    // Find the cached item
    MediaItem? item;
    try {
      item = _preCachedMediaItems.firstWhere((i) => i.title == name);
    } catch (e) {
      item = await MediaHelper.generateMediaItem(name, link, isFileExists);
    }

    if (_audioManager!.queue.value.isEmpty ||
        _audioManager!.mediaTypeNotifier.value == MediaType.radio) {
      // If player is idle, just start it
      startPlayer(name, link, isFileExists);
    } else {
      // Check if ID is already in the active queue
      if (_audioManager!.queue.value.any((i) => i.id == item!.id)) {
        getIt<ScaffoldHelper>().showSnackBar(
          'Already in queue',
          const Duration(seconds: 1),
        );
      } else {
        await _audioManager!.addQueueItem(item);
        getIt<ScaffoldHelper>().showSnackBar(
          'Added to queue',
          const Duration(seconds: 1),
        );
      }
    }
  }

  List<MediaItem> _preCachedMediaItems = [];

  /// parses the data retrieved from schedule.
  /// sets the final data to display
  // Add this variable to your State class

  Future<void> _parseData() async {
    List<String> mediaFiles = [];
    List<String> mediaLinks = [];
    List<Future<MediaItem>> cacheTasks = [];

    for (var media in widget.mediaFiles!) {
      var temp = media.replaceAll('.mp3', '');
      mediaFiles.add(temp);

      String link =
          '${MediaHelper.mediaBaseUrl}/$temp${MediaHelper.mediaFileType}';
      mediaLinks.add(link);

      // Start generating the item immediately in the background
      String mediaName = temp.replaceAll('_', ' ');
      bool isFileExists = File(
        '$_mediaDirectory/$temp${MediaHelper.mediaFileType}',
      ).existsSync();

      cacheTasks.add(
        MediaHelper.generateMediaItem(mediaName, link, isFileExists),
      );
    }

    setState(() {
      _finalMediaData = mediaFiles;
      _finalMediaLinks = mediaLinks;
    });

    // Wait for all items to be ready in the background
    _preCachedMediaItems = await Future.wait(cacheTasks);

    setState(() {
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
  //   if (connectionStatus == InternetStatus.disconnected) {
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
  Future<void> _getDirectoryPath() async {
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
    final am = _audioManager!;

    // 1. Quick check: Is it already playing?
    if (am.currentSongTitleNotifier.value == name &&
        am.mediaTypeNotifier.value == MediaType.media) {
      if (am.playButtonNotifier.value != PlayButtonState.playing) am.play();
      getIt<NavigationService>().navigateTo(MediaPlayer.route);
      return;
    }

    // 2. USE CACHED CONTENT: Find the item in our pre-cached list
    MediaItem? item;
    try {
      item = _preCachedMediaItems.firstWhere((i) => i.title == name);
    } catch (e) {
      // Fallback if not in cache (safety net)
      item = await MediaHelper.generateMediaItem(name, link, isFileExists);
    }

    // 3. Handle Radio-to-Media or Empty Player switch
    if (am.mediaTypeNotifier.value == MediaType.radio ||
        am.queue.value.isEmpty) {
      await initMediaService(item);
      getIt<NavigationService>().navigateTo(MediaPlayer.route);
      am.play(); // Added play here to ensure it starts immediately
      return;
    }

    // 4. Already in Media Mode: Manage Queue
    am.pause();

    final existingIndex = am.queue.value.indexWhere((i) => i.id == item!.id);
    if (existingIndex != -1) {
      await am.removeQueueItemAt(existingIndex);
    }

    await am.addQueueItem(item);

    // 5. Play the item
    final newIndex = am.queue.value.length - 1;
    await am.load();
    await am.skipToQueueItem(newIndex);

    getIt<NavigationService>().navigateTo(MediaPlayer.route);
    am.play();
  }

  /// initialize the media player when no player is playing
  Future<void> initMediaService(MediaItem item) async {
    Map<String, dynamic> params = {
      'id': item.id,
      'album': item.album,
      'title': item.title,
      'artist': item.artist,
      'duration': item.duration,
      'artUri': item.artUri.toString(),
      'extrasUri': item.extras!['uri'],
    };

    await _audioManager!.stop();
    await _audioManager!.init(MediaType.media, params);
  }

  /// add a new media item to the end of the queue
  ///
  /// doesn't add and returns false, if item already in queue
  ///
  /// else, adds to the queue and returns true
  Future<bool> addToQueue(String name, String link, bool isFileExists) async {
    final tempMediaItem = await MediaHelper.generateMediaItem(
      name,
      link,
      isFileExists,
    );

    // Check against the actual MediaItem objects in the queue using ID
    final alreadyExists = _audioManager!.queue.value.any(
      (item) => item.id == tempMediaItem.id,
    );

    if (alreadyExists) {
      return false;
    } else {
      await _audioManager!.addQueueItem(tempMediaItem);
      return true;
    }
  }

  /// move the media item to the end of the queue
  ///
  /// Note: check if the item is already in queue before calling
  Future<void> moveToLast(String name) async {
    final currentQueue = _audioManager!.queue.value;

    // Search the current active queue by title
    final index = currentQueue.indexWhere((item) => item.title == name);

    if (index != -1 && currentQueue.length > 1) {
      final existingItem = currentQueue[index];

      // Remove by index (very fast)
      await _audioManager!.removeQueueItemAt(index);

      // Re-add the same object to the end
      await _audioManager!.addQueueItem(existingItem);
    }
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
