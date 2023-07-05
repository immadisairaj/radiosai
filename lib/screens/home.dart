import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:radiosai/audio_service/service_locator.dart';
import 'package:radiosai/helper/scaffold_helper.dart';
import 'package:radiosai/screens/radio/radio_home.dart';
import 'package:radiosai/widgets/top_media_player.dart';
import 'package:radiosai/widgets/top_menu.dart';

class Home extends StatefulWidget {
  const Home({
    super.key,
  });

  @override
  State<Home> createState() => _Home();
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
      // scaffold key for whole app to show snackbar
      key: getIt<ScaffoldHelper>().scaffoldKey,
      body: const Stack(
        children: [
          RadioHome(),
          TopMenu(),
          TopMediaPlayer(),
        ],
      ),
    );
  }
}
