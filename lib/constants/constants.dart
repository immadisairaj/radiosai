import 'package:flutter/material.dart';

class MyConstants extends InheritedWidget {
  static MyConstants of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<MyConstants>();

  const MyConstants({Widget child, Key key}): super(key: key, child: child);

  final List<String> streamLink = const [
    'http://stream.radiosai.net:8002',
    'http://stream.radiosai.net:8004',
    'http://stream.radiosai.net:8006',
    'http://stream.radiosai.net:8000',
    'http://stream.radiosai.net:8008',
    'http://stream.radiosai.net:8020'
  ];

  final List<String> streamName = const [
    'Asia Stream',
    'Africa Stream',
    'America Stream',
    'Bhajan Stream',
    'Discourse Stream',
    'Telugu Stream',
  ];

  @override
  bool updateShouldNotify(MyConstants oldWidget) => false;
}
