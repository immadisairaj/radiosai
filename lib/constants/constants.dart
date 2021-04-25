import 'package:flutter/material.dart';

class MyConstants extends InheritedWidget {
  static MyConstants of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MyConstants>();

  const MyConstants({Widget child, Key key}) : super(key: key, child: child);

  // TODO: change the build time after every build or get a way
  final String buldTime = '25/04/2021 13:58 IST';

  // The list of radio sai stream sources
  final List<String> radioStreamLink = const [
    'http://stream.radiosai.net:8002',
    'http://stream.radiosai.net:8004',
    'http://stream.radiosai.net:8006',
    'http://stream.radiosai.net:8000',
    'http://stream.radiosai.net:8008',
    'http://stream.radiosai.net:8020'
  ];

  // The list of radio sai stream source names
  final List<String> radioStreamName = const [
    'Asia Stream',
    'Africa Stream',
    'America Stream',
    'Bhajan Stream',
    'Discourse Stream',
    'Telugu Stream',
  ];

  // The list of items in the top menu bar
  final List<String> menuTitles = const [
    'Schedule',
    'Sai Inspires',
    // 'Vedam',
    'Audio Archive',
    'Settings',
  ];

  @override
  bool updateShouldNotify(MyConstants oldWidget) => false;
}
