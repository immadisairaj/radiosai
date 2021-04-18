import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  
  // final String baseUrl = 'http://media.radiosai.org/sai_inspires';
  final String imageBaseUrl = 'http://media.radiosai.org/sai_inspires';
  // final String baseUrl = 'https://www.radiosai.org/pages/calthought2.asp';
  final String baseUrl = 'https://www.radiosai.org/pages/ThoughtText.asp';

  final DateTime now = DateTime.now();
  DateTime selectedDate;
  String imageFinalUrl;
  String finalUrl;

  // String _dateText = ''; // date text id is 'Head'
  // String _contentText = ''; // content text id is 'Content'

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
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.only(top: 10),
          // TODO: add loading progress
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(10),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.3,
                  child: Image.network(imageFinalUrl),
                ),
              ),
              // Padding(
              //   padding: EdgeInsets.only(left: 10, right: 10),
              //   child: Text(_dateText),
              // ),
              // Padding(
              //   padding: EdgeInsets.all(10),
              //   child: Text('Thought of the Day'),
              // ),
              // Padding(
              //   padding: EdgeInsets.only(left: 10, right: 10),
              //   child: Text(_contentText),
              // ),
              // Padding(
              //   padding: EdgeInsets.all(10),
              //   child: Text('-BABA'),
              // ),
              // TODO: hide the webview after plugin upgrade and display
              // or add zoom effect for temporary
              Expanded(
                child: WebView(
                  initialUrl: finalUrl,
                  javascriptMode: JavascriptMode.unrestricted,
                  onPageFinished: (url) {
                    _webViewController.evaluateJavascript(
                      "document.body.style.zoom = 0.7;"
                      "document.getElementById('Home').remove();"
                      "document.getElementById('Official').remove();"
                      // "<meta name=\"viewport\" content=\"width=device-width\">"
                    );
                  },
                  onWebViewCreated: (controller) {
                    _webViewController = controller;
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _updateURL(DateTime date) async {
    // String formattedDate = DateFormat('yyyyMMdd').format(now);
    String imageFormattedDate = DateFormat('yyyyMMdd').format(date);
    String formattedDate = DateFormat('dd/MM/yyyy').format(date);
    // String finalUrl = '$baseUrl/${now.year}/SI_$formattedDate.htm';
    imageFinalUrl = '$imageBaseUrl/${date.year}/uploadimages/SI_$imageFormattedDate.jpg';
    finalUrl = '$baseUrl?mydate=$formattedDate';
    if(_webViewController != null) await _webViewController.loadUrl(finalUrl);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime picked = await showDatePicker(
      context: context,
      // Sai Inspires started on 1st May 2010
      firstDate: DateTime(2011, 2, 19),
      initialDate: selectedDate,
      lastDate: now,
    );
    if(picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        _updateURL(selectedDate);
      });
    }
  }

}
