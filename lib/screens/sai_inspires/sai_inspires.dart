import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SaiInspires extends StatefulWidget {
  SaiInspires({
    Key key,
  }) : super(key: key);

  @override
  _SaiInspires createState() => _SaiInspires();
}

class _SaiInspires extends State<SaiInspires> {
  WebViewController _webViewController;

  final String imageBaseUrl = 'http://media.radiosai.org/sai_inspires';
  final String baseUrl = 'https://www.radiosai.org/pages/ThoughtText.asp';

  final DateTime now = DateTime.now();
  DateTime selectedDate;
  String imageFinalUrl;
  String finalUrl;

  bool _isLoading = true;
  bool _isCopying = false;

  String _dateText = ''; // date text id is 'Head'
  final String _thoughtOfTheDay = 'THOUGHT OF THE DAY';
  String _contentText = ''; // content text id is 'Content'
  final String _byBaba = '-BABA';

  @override
  void initState() {
    selectedDate = now;
    _updateURL(selectedDate);

    super.initState();
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
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
                            : Image.network(imageFinalUrl),
                      ),
                    ),
                    Stack(
                      children: [
                        // hide the webview behind the container and get content using JS
                        if (_isLoading) _hiddenWebView(),
                        // container displays above the webview to make the webview hidden
                        Container(
                          width: MediaQuery.of(context).size.width,
                          color: backgroundColor,
                          child: Padding(
                            padding: const EdgeInsets.only(
                                left: 20, right: 20, top: 8),
                            child: Column(
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
                                      color: Colors.red,
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
                                  padding: const EdgeInsets.only(
                                      top: 8.0, bottom: 20),
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
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // show when no data is retrieved
            if (_contentText == 'null') _noData(backgroundColor),
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

  // update the URL after picking the new date
  _updateURL(DateTime date) async {
    String imageFormattedDate = DateFormat('yyyyMMdd').format(date);
    String formattedDate = DateFormat('dd/MM/yyyy').format(date);
    imageFinalUrl =
        '$imageBaseUrl/${date.year}/uploadimages/SI_$imageFormattedDate.jpg';
    finalUrl = '$baseUrl?mydate=$formattedDate';
    if (_webViewController != null) await _webViewController.loadUrl(finalUrl);
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
        // if data is visible, copy to clipboard
        Clipboard.setData(ClipboardData(
                text:
                    '$_dateText\n\n$_thoughtOfTheDay\n\n$_contentText\n\n$_byBaba'))
            .then((value) {
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

  // handle when no data is retrieved
  Widget _noData(Color backgroundColor) {
    return Container(
      color: backgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20),
              child: Text(
                'No Data Available,\ncheck your internet and try again',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              child: Text(
                'Retry',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _updateURL(selectedDate);
                });
              },
            )
          ],
        ),
      ),
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

  // hide the webview behind the container and get content using JS
  Widget _hiddenWebView() {
    return Positioned.fill(
      child: WebView(
        initialUrl: finalUrl,
        javascriptMode: JavascriptMode.unrestricted,
        onPageFinished: (url) async {
          // get the data to show at the top
          String dateText = await _webViewController.evaluateJavascript(
              "document.getElementById('Head').textContent");
          String contentText = await _webViewController.evaluateJavascript(
              "document.getElementById('Content').textContent");

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

            // if data is not proper, don't set the image
            if (contentText == 'null') imageFinalUrl = '';

            // loading is done
            _isLoading = false;
          });
        },
        onWebViewCreated: (controller) {
          _webViewController = controller;
        },
      ),
    );
  }
}
