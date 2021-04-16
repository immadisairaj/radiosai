import 'package:flutter/material.dart';
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
    return Scaffold(
      body: Stack(
        children: [
          RadioHome(),
          TopMenu(),
        ],
      ),
    );
  }
}
