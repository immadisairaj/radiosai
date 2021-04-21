import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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

  String _dateText = ''; // date text id is 'Head'
  String _contentText = ''; // content text id is 'Content'

  @override
  void initState() {
    selectedDate = now;
    _updateURL(selectedDate);

    super.initState();
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sai Inspires'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.date_range_outlined),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        color: Colors.white,
        child: Stack(
          children: [
            // TODO: add refresh option?
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Column(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.35,
                      child: Padding(
                        padding: EdgeInsets.all(10),
                        child: Image.network(imageFinalUrl),
                      ),
                    ),
                    Stack(
                      children: [
                        // hide the webview behind the container and get content using JS
                        _hiddenWebView(),
                        // container displays above the webview to make the webview hidden
                        Container(
                          width: MediaQuery.of(context).size.width,
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.only(
                                left: 20, right: 20, top: 8),
                            // TODO: update text sizes
                            child: Column(
                              children: [
                                Align(
                                  alignment: Alignment(1, 0),
                                  child: Text(
                                    _dateText,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    'THOUGHT OF THE DAY',
                                    style: TextStyle(
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                                Text(
                                  _contentText,
                                  textAlign: TextAlign.justify,
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      top: 8.0, bottom: 20),
                                  child: Align(
                                    alignment: Alignment(1, 0),
                                    child: Text(
                                      '-BABA',
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
            // Shown when it is loading
            if (_isLoading)
              Container(
                color: Colors.white,
                child: Center(
                  child: _showLoading(),
                ),
              ),
            // TODO: add try again (or something) when not able to get data (eg: if no internet)
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

  // Shimmer effect while loading the content
  Widget _showLoading() {
    return Padding(
      padding: EdgeInsets.only(top: 30, left: 20, right: 20),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300],
        highlightColor: Colors.grey[100],
        enabled: true,
        child: Column(
          children: [
            Container(
              width: MediaQuery.of(context).size.width * 0.5,
              height: MediaQuery.of(context).size.height * 0.4,
              color: Colors.white,
            ),
            Padding(
              padding: EdgeInsets.only(top: 20, bottom: 10),
              child: Container(
                width: double.infinity,
                height: 8,
                color: Colors.white,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Container(
                width: double.infinity,
                height: 8,
                color: Colors.white,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Container(
                width: double.infinity,
                height: 8,
                color: Colors.white,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Container(
                width: double.infinity,
                height: 8,
                color: Colors.white,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Container(
                width: double.infinity,
                height: 8,
                color: Colors.white,
              ),
            ),
          ],
        ),
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
          contentText = contentText.substring(4);
          contentText = contentText.replaceAll('"', '');
          contentText = contentText.trim();
          setState(() {
            _dateText = dateText;
            _contentText = contentText;
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
