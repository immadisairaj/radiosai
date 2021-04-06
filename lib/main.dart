import 'package:flutter/material.dart';
import 'package:radiosai/constants/constants.dart';
import 'package:radiosai/views/stream_player.dart';
import 'package:provider/provider.dart';
import 'package:radiosai/bloc/stream_bloc.dart';

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
    return MultiProvider(
      providers: [
        Provider<StreamBloc>(
          create: (_) => StreamBloc(),
          dispose: (_, StreamBloc streamBloc) => streamBloc.dispose(),
        ),
      ],
      child: MaterialApp(
        title: 'radiosai',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.deepOrange,
        ),
        home: StreamPlayer(),
      ),
    );
  }
}
