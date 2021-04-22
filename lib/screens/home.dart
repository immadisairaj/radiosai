import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:radiosai/screens/radio/radio_home.dart';
import 'package:radiosai/widgets/top_menu.dart';

class Home extends StatefulWidget {
  Home({
    Key key,
  }) : super(key: key);

  @override
  _Home createState() => _Home();
}

class _Home extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        // sends the app to background when backpress on home screen 
        // add a method in MainActivity.kt to support send app to background
        return MethodChannel('android_app_retain').invokeMethod('sendToBackground');
      },
      child: Scaffold(
        body: Stack(
          children: [
            RadioHome(),
            TopMenu(),
          ],
        ),
      ),
    );
  }
}
