import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:html/parser.dart';
import 'package:intl/intl.dart';
import 'package:radiosai/screens/sai_inspires/sai_image.dart';
import 'package:radiosai/widgets/no_data.dart';
import 'package:shimmer/shimmer.dart';

class SaiInspires extends StatefulWidget {
  SaiInspires({
    Key key,
  }) : super(key: key);

  @override
  _SaiInspires createState() => _SaiInspires();
}

class _SaiInspires extends State<SaiInspires> {
  final String imageBaseUrl = 'http://media.radiosai.org/sai_inspires';
  final String baseUrl = 'https://www.radiosai.org/pages/ThoughtText.asp';

  final DateTime now = DateTime.now();
  DateTime selectedDate;
  String imageFinalUrl;
  String finalUrl;

  final String heroTag = 'SaiInspiresImage';

  bool _isLoading = true;
  bool _isCopying = false;

  String _dateText = ''; // date text id is 'Head'
  String _thoughtOfTheDay = 'THOUGHT OF THE DAY';
  String _contentText = ''; // content text id is 'Content'
  String _byBaba = '-BABA';
  String _quote = '';
  bool _isOldData = false;

  @override
  void initState() {
    selectedDate = now;
    _updateURL(selectedDate);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // check if dark theme
    bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    Color backgroundColor = isDarkTheme ? Colors.grey[700] : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: Text('Sai Inspires'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.copy_outlined),
            tooltip: 'Copy to clipboard',
            splashRadius: 24,
            onPressed: () => _copyText(context),
          ),
          IconButton(
            icon: Icon(Icons.date_range_outlined),
            tooltip: 'Select date',
            splashRadius: 24,
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        color: backgroundColor,
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
                        padding: EdgeInsets.all(10),
                        child: (imageFinalUrl == '')
                            ? Container()
                            : Material(
                                child: InkWell(
                                  child: Container(
                                    color: backgroundColor,
                                    child: Hero(
                                      tag: heroTag,
                                      child: CachedNetworkImage(
                                        imageUrl: imageFinalUrl,
                                        errorWidget: (context, url, error) =>
                                            Icon(Icons.error),
                                      ),
                                    ),
                                  ),
                                  onTap: () => _viewImage(),
                                ),
                              ),
                      ),
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width,
                      color: backgroundColor,
                      child: Padding(
                        padding:
                            const EdgeInsets.only(left: 20, right: 20, top: 8),
                        child: _isOldData
                            ? _oldContent(isDarkTheme)
                            : _newContent(isDarkTheme),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // show when no data is retrieved
            if (_contentText == 'null')
              NoData(
                backgroundColor: backgroundColor,
                text: 'No Data Available,\ncheck your internet and try again',
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _updateURL(selectedDate);
                  });
                },
              ),
            // show when no data is retrieved and timeout
            if (_contentText == 'timeout')
              NoData(
                backgroundColor: backgroundColor,
                text:
                    'No Data Available,\nURL timeout, try again after some time',
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _updateURL(selectedDate);
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

  // navigate to new page to view full image
  _viewImage() {
    int urlLength = imageFinalUrl.length;
    String fileName =
        'SI_${imageFinalUrl.substring(urlLength - 12, urlLength - 4)}';
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => SaiImage(
                  heroTag: heroTag,
                  imageUrl: imageFinalUrl,
                  fileName: fileName,
                )));
  }

  // update the URL after picking the new date
  _updateURL(DateTime date) async {
    String imageFormattedDate = DateFormat('yyyyMMdd').format(date);
    String formattedDate = DateFormat('dd/MM/yyyy').format(date);
    imageFinalUrl =
        '$imageBaseUrl/${date.year}/uploadimages/SI_$imageFormattedDate.jpg';
    if (date.isAfter(new DateTime(2011, 8, 25))) {
      finalUrl = '$imageBaseUrl/${date.year}/SI_$imageFormattedDate.htm';
      _getNewData();
    } else {
      finalUrl = '$baseUrl?mydate=$formattedDate';
      _getOldData();
    }
  }

  // get data of date from 26 Aug 2011
  _getNewData() async {
    var file;
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
    var document = parse(response);

    int k;
    if (document
            .getElementsByTagName('tbody')[0]
            .children[1]
            .getElementsByTagName('font')
            .length ==
        0)
      k = 2;
    else
      k = 1;

    String dateText = document
        .getElementsByTagName('tbody')[0]
        .children[k]
        .getElementsByTagName('font')[0]
        .text;

    String top = document
        .getElementsByTagName('tbody')[0]
        .children[k]
        .getElementsByTagName('font')[1]
        .text;
    if (top.contains('Featured'))
      top = document
          .getElementsByTagName('tbody')[0]
          .children[k]
          .getElementsByTagName('font')[2]
          .text;

    String contentText = document
        .getElementsByTagName('tbody')[0]
        .children[k + 1]
        .getElementsByTagName('font')[0]
        .text;

    String from = document
        .getElementsByTagName('tbody')[0]
        .children[k + 1]
        .getElementsByTagName('font')[1]
        .text;

    int l = document.getElementsByTagName('tbody')[0].children.length;
    String quote = document
        .getElementsByTagName('tbody')[0]
        .children[l - 2]
        .getElementsByTagName('font')[0]
        .text;

    // Trim the data to remove unnecessary content
    dateText = dateText.replaceAll('"', '');
    dateText = dateText.trim();
    dateText = 'Date: $dateText';

    top = top.replaceAll('\\n', '');
    top = top.replaceAll('\\t', '');
    // to not remove " from the text add temp tag
    top = top.replaceAll('\\"', '<q>');
    top = top.replaceAll('"', '');
    // remove temp tag and replace with "
    top = top.replaceAll('<q>', '"');
    top = top.replaceAll('\n', ' ');
    // replace multiple spaces with single space
    top = top.replaceAll(RegExp(' +'), ' ');
    top = top.trim();

    contentText = contentText.replaceAll('\\n', '');
    // to not remove " from the text add temp tag
    contentText = contentText.replaceAll('\\"', '<q>');
    contentText = contentText.replaceAll('"', '');
    // remove temp tag and replace with "
    contentText = contentText.replaceAll('<q>', '"');
    contentText = contentText.replaceAll('\n', ' ');
    // replace multiple spaces with single space
    contentText = contentText.replaceAll(RegExp(' +'), ' ');
    contentText = contentText.trim();

    quote = quote.replaceAll('\n', ' ');
    // replace multiple spaces with single space
    quote = quote.replaceAll(RegExp(' +'), ' ');
    quote = quote.trim();

    setState(() {
      // set the data
      _dateText = dateText;
      _contentText = contentText;
      _thoughtOfTheDay = top;
      _byBaba = from;
      _quote = quote;

      _isOldData = false;

      // loading is done
      _isLoading = false;
    });
  }

  // get data of date before Aug 26 2011
  _getOldData() async {
    var file;
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
    var document = parse(response);
    String dateText = document.getElementById('Head').text;
    String contentText = document.getElementById('Content').text;

    // Trim the data to remove unnecessary content
    dateText = dateText.replaceAll('"', '');
    dateText = dateText.trim();
    contentText = contentText.replaceAll('\\n', '');
    // to not remove " from the text add temp tag
    contentText = contentText.replaceAll('\\"', '<q>');
    contentText = contentText.replaceAll('"', '');
    // remove temp tag and replace with "
    contentText = contentText.replaceAll('<q>', '"');
    contentText = contentText.trim();
    setState(() {
      // set the data
      _dateText = dateText;
      _contentText = contentText;
      _thoughtOfTheDay = 'THOUGHT OF THE DAY';
      _byBaba = '-BABA';

      _isOldData = true;

      // loading is done
      _isLoading = false;
    });
  }

  // select the date and update the url
  Future<void> _selectDate(BuildContext context) async {
    final DateTime picked = await showDatePicker(
      context: context,
      // Sai Inspires started on 19th Feb 2011
      firstDate: DateTime(2011, 2, 19),
      initialDate: selectedDate,
      lastDate: now,
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        _isLoading = true;
        selectedDate = picked;
        _updateURL(selectedDate);
      });
    }
  }

  // copy text if data is visible
  void _copyText(BuildContext context) {
    if (!_isCopying) {
      _isCopying = true;
      if (_contentText != 'null') {
        String copyData;
        if (_isOldData)
          copyData =
              '$_dateText\n\n$_thoughtOfTheDay\n\n$_contentText\n\n$_byBaba';
        else
          copyData =
              '$_dateText\n\n$_thoughtOfTheDay\n\n$_contentText\n\n$_byBaba\n\n$_quote';
        // if data is visible, copy to clipboard
        Clipboard.setData(ClipboardData(text: copyData)).then((value) {
          _showSnackBar(context, 'Copied to clipboard');
        });
      } else {
        // is there is no data, show snackbar that no data is available
        _showSnackBar(context, 'No data available to copy');
      }
    }
  }

  void _showSnackBar(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(
          content: Text(text),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 1),
        ))
        .closed
        .then((value) {
      _isCopying = false;
    });
  }

  // for new data >= 26 Aug 2011
  Widget _newContent(bool isDarkTheme) {
    return Column(
      children: [
        Align(
          alignment: Alignment(1, 0),
          child: SelectableText(
            _dateText,
            style: TextStyle(
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
              color: isDarkTheme ? Colors.amber : Colors.red,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SelectableText(
          _contentText,
          textAlign: TextAlign.justify,
          style: TextStyle(
            fontSize: 17,
            height: 1.3,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Align(
            alignment: Alignment(1, 0),
            child: SelectableText(
              _byBaba,
              style: TextStyle(
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
              color: isDarkTheme ? Colors.amber : Colors.red,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // for old data < 26 Aug 2011
  Widget _oldContent(bool isDarkTheme) {
    return Column(
      children: [
        Align(
          alignment: Alignment(1, 0),
          child: SelectableText(
            _dateText,
            style: TextStyle(
              fontSize: 14,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SelectableText(
            _thoughtOfTheDay,
            style: TextStyle(
              color: isDarkTheme ? Colors.amber : Colors.red,
              fontSize: 16,
            ),
          ),
        ),
        SelectableText(
          _contentText,
          textAlign: TextAlign.justify,
          style: TextStyle(
            fontSize: 17,
            height: 1.3,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 20),
          child: Align(
            alignment: Alignment(1, 0),
            child: SelectableText(
              _byBaba,
              style: TextStyle(
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Shimmer effect while loading the content
  Widget _showLoading(bool isDarkTheme) {
    return Padding(
      padding: EdgeInsets.only(top: 30, left: 20, right: 20),
      child: Shimmer.fromColors(
        baseColor: isDarkTheme ? Colors.grey[500] : Colors.grey[300],
        highlightColor: isDarkTheme ? Colors.grey[300] : Colors.grey[100],
        enabled: true,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 20),
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

  Widget _shimmerLine() {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Container(
        width: double.infinity,
        height: 8,
        color: Colors.white,
      ),
    );
  }
}
