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

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    // String formattedDate = DateFormat('yyyyMMdd').format(now);
    String imageFormattedDate = DateFormat('yyyyMMdd').format(now);
    String formattedDate = DateFormat('MM/dd/yyyy').format(now);
    // String finalUrl = '$baseUrl/${now.year}/SI_$formattedDate.htm';
    String imageFinalUrl = '$imageBaseUrl/${now.year}/uploadimages/SI_$imageFormattedDate.jpg';
    String finalUrl = '$baseUrl?mydate=$formattedDate';
    return Scaffold(
      appBar: AppBar(
        title: Text('Sai Inspires'),
      ),
      // TODO: add zoom effect or change link
      body: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(10),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.3,
                  child: Image.network(imageFinalUrl),
                ),
              ),
              Expanded(
                child: WebView(
                  initialUrl: finalUrl,
                  javascriptMode: JavascriptMode.unrestricted,
                  onPageFinished: (url) {
                    _webViewController.evaluateJavascript('document.body.style.zoom = 0.7');
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
}
