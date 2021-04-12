import 'package:flutter/material.dart';

class MyConstants extends InheritedWidget {
  static MyConstants of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MyConstants>();

  const MyConstants({Widget child, Key key}) : super(key: key, child: child);

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

  // TODO: change the list to exact titles
  // The list of items in the top menu bar
  final List<String> menuTitles = const [
    'Schedule',
    'Sai Inspires',
    'Vedam',
    'Other Programs',
    'Settings',
  ];

  @override
  bool updateShouldNotify(MyConstants oldWidget) => false;
}
