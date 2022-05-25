import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:radiosai/audio_service/service_locator.dart';
import 'package:radiosai/helper/scaffold_helper.dart';
import 'package:radiosai/screens/sai_inspires/sai_image.dart';
import 'package:radiosai/widgets/no_data.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';

class SaiInspires extends StatefulWidget {
  const SaiInspires({
    super.key,
  });

  static const String route = 'saiInspires';

  @override
  _SaiInspires createState() => _SaiInspires();
}

class _SaiInspires extends State<SaiInspires> {
  /// contains the updated base url of the sai inspires page
  final String baseUrl =
      'https://api.sssmediacentre.org/web/saiinspire/filterBy';

  final DateTime now = DateTime.now();

  /// date for the sai inspires
  DateTime? selectedDate;

  /// image url for the selected date
  String? imageFinalUrl = '';

  /// sai inspires source url for the selected date
  late String finalUrl;

  /// hero tag for the hero widgets (2 screen widget animation)
  final String heroTag = 'SaiInspiresImage';

  /// variable to show the loading screen
  bool _isLoading = true;

  String _dateText = ''; // date text id is 'Head'
  String _thoughtOfTheDay = 'THOUGHT OF THE DAY';
  String _contentText = ''; // content text id is 'Content'
  String _byBaba = '-BABA';
  String _quote = '';

  @override
  void initState() {
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
                    backgroundColor: Theme.of(context).colorScheme.background,
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
                    backgroundColor: Theme.of(context).colorScheme.background,
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

    setState(() {
      // set the data
      _dateText = dateText;
      _contentText = contentText;
      // _contentText = description.body!.innerHtml;
      _thoughtOfTheDay = topText;
      _byBaba = fromText;
      _quote = mainBody['remark'];

      imageFinalUrl = mainBody['thumbnail'];

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
    DateTime? _picked;
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        color: Theme.of(context).colorScheme.background,
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
                onDateTimeChanged: (picked) {
                  _picked = picked;
                },
              ),
            ),
            SizedBox(
              height: 70,
              child: CupertinoButton(
                child: const Text('OK'),
                onPressed: () {
                  if (_picked != null && _picked != selectedDate) {
                    setState(() {
                      _isLoading = true;
                      selectedDate = _picked;
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
      textData = 'Sai Inspires - ' + textData;
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
        Share.shareFiles([imageFile!.path], text: textData);
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
