import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:radiosai/helper/download_helper.dart';
import 'package:radiosai/screens/radio/radio_home.dart';
import 'package:radiosai/widgets/top_media_player.dart';
import 'package:radiosai/widgets/top_menu.dart';

class Home extends StatefulWidget {
  const Home({
    Key key,
  }) : super(key: key);

  @override
  _Home createState() => _Home();
}

class _Home extends State<Home> {
  @override
  void initState() {
    super.initState();
    // lock orientation to portrait (later maybe can handle landscape?)
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    // setting back to original form after dispose
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // to show if the download is happened in the whole app
      // calling from download helper is a must
      key: DownloadHelper.getScaffoldKey(),
      body: Stack(
        children: [
          const RadioHome(),
          TopMenu(),
          TopMediaPlayer(),
        ],
      ),
    );
  }
}
