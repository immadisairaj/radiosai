import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:radiosai/audio_service/audio_manager.dart';
import 'package:radiosai/audio_service/notifiers/play_button_notifier.dart';
import 'package:radiosai/audio_service/service_locator.dart';
import 'package:radiosai/helper/media_helper.dart';
import 'package:radiosai/helper/navigator_helper.dart';
import 'package:radiosai/helper/scaffold_helper.dart';
import 'package:radiosai/screens/media_player/media_player.dart';
import 'package:radiosai/screens/sai_inspires/sai_image.dart';
import 'package:radiosai/widgets/bottom_media_player.dart';
import 'package:radiosai/widgets/no_data.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';

class SaiInspires extends StatefulWidget {
  const SaiInspires({
    super.key,
  });

  static const String route = 'saiInspires';

  @override
  State<SaiInspires> createState() => _SaiInspires();
}

class _SaiInspires extends State<SaiInspires> {
  /// contains the updated base url of the sai inspires page
  final String baseUrl =
      'https://api.sssmediacentre.org/web/saiinspire/filterBy';

  /// contains the url for the sai inspires audio
  ///
  /// the one from the [baseUrl] of result.relatedItems[0].id to be appended
  /// to this url
  final String audioBaseUrl = 'https://api.sssmediacentre.org/web/audio';

  final DateTime now = DateTime.now();

  /// date for the sai inspires
  DateTime? selectedDate;

  /// image url for the selected date
  String? imageFinalUrl = '';

  /// sai inspires source url for the selected date
  late String finalUrl;

  /// audio url for the sai inspires; fetch data from this to get mp3 url
  String? audioFinalUrl = '';

  /// hero tag for the hero widgets (2 screen widget animation)
  final String heroTag = 'SaiInspiresImage';

  /// variable to show the loading screen
  bool _isLoading = true;

  String _dateText = ''; // date text id is 'Head'
  String _thoughtOfTheDay = 'THOUGHT OF THE DAY';
  String _contentText = ''; // content text id is 'Content'
  String _byBaba = '-BABA';
  String _quote = '';

  AudioManager? _audioManager;

  @override
  void initState() {
    // get audio manager
    _audioManager = getIt<AudioManager>();

    selectedDate = now;
    _updateURL(selectedDate!);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sai Inspires'),
        actions: <Widget>[
          IconButton(
            icon: Icon((Platform.isAndroid)
                ? Icons.share_outlined
                : CupertinoIcons.share),
            tooltip: 'Share Sai Inspires',
            splashRadius: 24,
            onPressed: () => _share(context),
          ),
          IconButton(
            icon: Icon((Platform.isAndroid)
                ? Icons.date_range_outlined
                : CupertinoIcons.calendar),
            tooltip: 'Select date',
            splashRadius: 24,
            onPressed: () => (Platform.isAndroid)
                ? _selectDate(context)
                : _selectDateIOS(context),
          ),
        ],
      ),
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: AnimatedCrossFade(
          crossFadeState:
              _isLoading ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(seconds: 1),
          firstChild: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: Stack(
              children: [
                InteractiveViewer(
                  constrained: false,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Column(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.35,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: (imageFinalUrl == '')
                                ? Container()
                                : Material(
                                    child: InkWell(
                                      child: Hero(
                                        tag: heroTag,
                                        child: CachedNetworkImage(
                                          imageUrl: imageFinalUrl!,
                                          errorWidget: (context, url, error) =>
                                              const Icon(Icons.error),
                                          // shimmer place holder for loading
                                          placeholder: (context, placeholder) =>
                                              Shimmer.fromColors(
                                            baseColor: Theme.of(context)
                                                .colorScheme
                                                .secondaryContainer,
                                            highlightColor: Theme.of(context)
                                                .colorScheme
                                                .onSecondaryContainer,
                                            enabled: true,
                                            child: SizedBox(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.5,
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  0.4,
                                            ),
                                          ),
                                        ),
                                      ),
                                      onTap: () => _viewImage(),
                                    ),
                                  ),
                          ),
                        ),
                        // show the play audio button only if the audio
                        // url is present
                        audioFinalUrl != null && audioFinalUrl != ''
                            ? Padding(
                                padding: const EdgeInsets.all(10),
                                child: ElevatedButton(
                                  onPressed: () => _playAudio(context),
                                  child: const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Text(
                                      'Play Audio',
                                    ),
                                  ),
                                ),
                              )
                            : Container(),
                        SizedBox(
                          width: MediaQuery.of(context).size.width,
                          child: Padding(
                            padding: const EdgeInsets.only(
                                left: 20, right: 20, top: 8),
                            child: _content(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // show when no data is retrieved
                if (_contentText == 'null')
                  NoData(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    text:
                        'No Data Available,\ncheck your internet and try again',
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                        _updateURL(selectedDate!);
                      });
                    },
                  ),
                // show when no data is retrieved and timeout
                if (_contentText == 'timeout')
                  NoData(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    text:
                        'No Data Available,\nURL timeout, try again after some time',
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                        _updateURL(selectedDate!);
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
      ),
      bottomNavigationBar: const BottomMediaPlayer(),
    );
  }

  /// navigate to new page to view full image
  _viewImage() {
    String fileName = 'SI_${DateFormat('yyyyMMdd').format(selectedDate!)}';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SaiImage(
          heroTag: heroTag,
          imageUrl: imageFinalUrl,
          fileName: fileName,
        ),
      ),
    );
  }

  /// update the URL after picking the new date
  ///
  /// sets the [imageFinalUrl] and [finalUrl]
  ///
  /// takes in [date] as input
  ///
  /// continues the process by retrieving the data
  _updateURL(DateTime date) async {
    String formattedDate = DateFormat('yyyy-MM-dd').format(date);
    finalUrl = '$baseUrl?publishDate=$formattedDate';
    _getData();
  }

  /// get data of date before Jul 15 2011
  ///
  /// retrieve the data from finalUrl and set the image url
  ///
  /// parses the data too
  _getData() async {
    File file;
    try {
      file = await DefaultCacheManager()
          .getSingleFile(finalUrl)
          .timeout(const Duration(seconds: 40));
    } on SocketException catch (_) {
      setState(() {
        // if there is no internet
        _contentText = 'null';
        imageFinalUrl = '';
        _isLoading = false;
      });
      return;
    } on TimeoutException catch (_) {
      setState(() {
        // if timeout
        _contentText = 'timeout';
        imageFinalUrl = '';
        _isLoading = false;
      });
      return;
    }
    var response = file.readAsStringSync();
    final body = jsonDecode(response);

    if (body['result'] == null) {
      DefaultCacheManager().removeFile(finalUrl);
      setState(() {
        // if no data is available
        _contentText = 'null';
        imageFinalUrl = '';
        _isLoading = false;
      });
      return;
    }

    final mainBody = body['result'][0];

    String dateText = mainBody['title'];
    dateText = dateText.replaceAll('Sai Inspires - ', '');
    dateText = dateText.replaceAll('SAI INSPIRES - ', '');

    var description = parse(mainBody['description']);
    var descriptionP = description.body!.getElementsByTagName('p');
    String topText = '';
    String contentText = '';
    if (descriptionP.isEmpty) {
      String descriptionText = mainBody['description'];
      topText = description.getElementsByTagName('strong')[0].text;
      contentText = descriptionText.replaceAll(topText, '');
      contentText = contentText.replaceAll('<strong>', '');
      contentText = contentText.replaceAll('</strong>', '');
      contentText = contentText.replaceAll('<em>', '');
      contentText = contentText.replaceAll('</em>', '');
      contentText = contentText.replaceAll('\n', '');
    } else if (descriptionP.length > 2) {
      String descriptionText = description.body!.text;
      topText = descriptionP[0].text;
      contentText = descriptionText.replaceAll(topText, '');
      contentText = contentText.replaceAll('<strong>', '');
      contentText = contentText.replaceAll('</strong>', '');
      contentText = contentText.replaceAll('<em>', '');
      contentText = contentText.replaceAll('</em>', '');
      contentText = contentText.replaceAll('\n', '');
    } else {
      var descriptionS = description.body!.getElementsByTagName('span');
      if (descriptionS.isEmpty) {
        topText = descriptionP[0].text;
      } else {
        topText = descriptionS[0].text;
      }
      contentText = '${descriptionP[0].text}${descriptionP[1].text}';
      contentText = contentText.replaceAll(topText, '');
    }

    var from = parse(mainBody['info']);
    String fromText = from.body!.text;
    fromText = fromText.replaceAll('<em>', '');
    fromText = fromText.replaceAll('</em>', '');

    var returnedAudioUrl = '';
    if (mainBody['relatedItems'] != null &&
        mainBody['relatedItems'].isNotEmpty) {
      returnedAudioUrl = '$audioBaseUrl/${mainBody['relatedItems'][0]['id']}';
    }

    setState(() {
      // set the data
      _dateText = dateText;
      _contentText = contentText;
      // _contentText = description.body!.innerHtml;
      _thoughtOfTheDay = topText;
      _byBaba = fromText;
      _quote = mainBody['remark'];

      imageFinalUrl = mainBody['thumbnail'];

      audioFinalUrl = returnedAudioUrl;

      // loading is done
      _isLoading = false;
    });
  }

  /// select the date and update the url
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      // Sai Inspires started on 15th Jul 2011
      firstDate: DateTime(2011, 7, 15),
      initialDate: selectedDate!,
      lastDate: now,
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        _isLoading = true;
        selectedDate = picked;
        _updateURL(selectedDate!);
      });
    }
  }

  /// select the date and update the url for iOS
  void _selectDateIOS(BuildContext context) {
    DateTime? picked;
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        color: Theme.of(context).colorScheme.surface,
        height: 200,
        child: Column(
          children: [
            SizedBox(
              height: 120,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: selectedDate,
                // Sai Inspires started on 15th Jul 2011
                minimumDate: DateTime(2011, 7, 15),
                maximumDate: now,
                onDateTimeChanged: (pickedDateTime) {
                  picked = pickedDateTime;
                },
              ),
            ),
            SizedBox(
              height: 70,
              child: CupertinoButton(
                child: const Text('OK'),
                onPressed: () {
                  if (picked != null && picked != selectedDate) {
                    setState(() {
                      _isLoading = true;
                      selectedDate = picked;
                      _updateURL(selectedDate!);
                    });
                  }
                  Navigator.of(context).maybePop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// share Sai Inspires content if data is visible
  void _share(BuildContext context) async {
    if (_contentText != 'null') {
      // if data is visible, share the data
      String textData;
      textData = '$_dateText\n\n$_thoughtOfTheDay\n'
          '\n$_contentText\n\n$_byBaba\n\n$_quote';
      textData = 'Sai Inspires - $textData';
      // currently downloading image from old api and sharing it
      // will send only text when old api fails
      String imageFormattedDate = DateFormat('yyyyMMdd').format(selectedDate!);
      const String imageBaseUrl =
          'https://archive.sssmediacentre.org/sai_inspires';
      String imageUrl =
          '$imageBaseUrl/${selectedDate!.year}/uploadimages/SI_$imageFormattedDate.jpg';
      final response = await http.head(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        // share with image if old api is working
        File? imageFile;
        try {
          imageFile = await DefaultCacheManager()
              .getSingleFile(imageUrl)
              .timeout(const Duration(seconds: 20));
        } on Exception catch (_) {
          // do nothing
        }
        Share.shareXFiles([XFile(imageFile!.path)], text: textData);
      } else {
        // TODO: change from binary to image before sharing for new links
        // share only text if old api is not working
        Share.share(textData);
      }
    } else {
      // if there is no data, show snackbar that no data is available
      getIt<ScaffoldHelper>().showSnackBar(
          'No data available to share', const Duration(seconds: 1));
    }
  }

  /// play the audio of Sai Inspires if the url is present
  _playAudio(BuildContext context) async {
    File file;
    try {
      file = await DefaultCacheManager()
          .getSingleFile(audioFinalUrl!)
          .timeout(const Duration(seconds: 40));
    } on SocketException catch (_) {
      setState(() {
        // if there is no internet
        _contentText = 'null';
        imageFinalUrl = '';
        _isLoading = false;
      });
      return;
    } on TimeoutException catch (_) {
      setState(() {
        // if timeout
        _contentText = 'timeout';
        imageFinalUrl = '';
        _isLoading = false;
      });
      return;
    }
    var response = file.readAsStringSync();
    final body = jsonDecode(response);

    if (body['result'] == null) {
      DefaultCacheManager().removeFile(finalUrl);
      setState(() {
        getIt<ScaffoldHelper>().showSnackBar(
            'Failed getting the file, please try again',
            const Duration(seconds: 2));
      });
      return;
    }

    final mainBody = body['result'];

    final name = mainBody['title'];
    final audioMP3Url = mainBody['actualAudioUrl'];

    bool hasInternet = false;
    if (context.mounted) {
      hasInternet = Provider.of<InternetStatus>(context, listen: false) ==
          InternetStatus.connected;
    }
    // No download option. So,
    // everything is considered to use internet
    if (hasInternet) {
      await startPlayer(name, audioMP3Url, false);
    } else {
      getIt<ScaffoldHelper>().showSnackBar(
          'Connect to the Internet and try again', const Duration(seconds: 2));
    }
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
    Map<String, dynamic> params = {
      'id': tempMediaItem.id,
      'album': tempMediaItem.album,
      'title': tempMediaItem.title,
      'artist': tempMediaItem.artist,
      'artUri': tempMediaItem.artUri.toString(),
      'extrasUri': tempMediaItem.extras!['uri'],
    };

    _audioManager!.stop();
    await _audioManager!.init(MediaType.media, params);
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

  /// widget for new data >= 15 Jul 2011
  Widget _content() {
    return Column(
      children: [
        Align(
          alignment: const Alignment(1, 0),
          child: SelectableText(
            _dateText,
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
          child: SelectableText(
            _thoughtOfTheDay,
            textAlign: TextAlign.justify,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SelectableText(
          _contentText,
          textAlign: TextAlign.justify,
          style: const TextStyle(
            fontSize: 17,
            height: 1.3,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Align(
            alignment: const Alignment(1, 0),
            child: SelectableText(
              _byBaba,
              style: const TextStyle(
                fontSize: 15,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 20),
          child: SelectableText(
            _quote,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  /// Shimmer effect while loading the content
  Widget _showLoading() {
    return Padding(
      padding: const EdgeInsets.only(top: 30, left: 20, right: 20),
      child: Shimmer.fromColors(
        baseColor: Theme.of(context).colorScheme.secondaryContainer,
        highlightColor: Theme.of(context).colorScheme.onSecondaryContainer,
        enabled: true,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.5,
                height: MediaQuery.of(context).size.height * 0.4,
                color: Colors.white,
              ),
            ),
            // 5 shimmer lines
            for (int i = 0; i < 6; i++) _shimmerLine(),
          ],
        ),
      ),
    );
  }

  /// individual shimmer limes for loading shimmer
  Widget _shimmerLine() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: double.infinity,
        height: 8,
        color: Colors.white,
      ),
    );
  }
}
