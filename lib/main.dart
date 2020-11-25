import 'package:flutter/material.dart';
import 'package:radiosai/constants/constants.dart';
import 'package:radiosai/views/stream_player.dart';

void main() {
  runApp(
    MyConstants(
      child: MyApp()
      )
    );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'radiosai',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
      ),
      home: StreamPlayer(),
    );
  }
}
