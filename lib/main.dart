import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:radiosai/bloc/internet_connection_status.dart';
import 'package:radiosai/bloc/loading_stream_bloc.dart';
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
        Provider<LoadingStreamBloc>(
          create: (_) => LoadingStreamBloc(false),
          dispose: (_, LoadingStreamBloc loadingStreamBloc) => loadingStreamBloc.dispose(),
        ),
        StreamProvider<InternetConnectionStatus>(
          create: (context) {
            return InternetConnectionService().connectionController.stream;
          },
        ),
      ],
      child: MaterialApp(
        title: 'radiosai',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.deepOrange,
        ),
        home: AudioServiceWidget(child: StreamPlayer()),
      ),
    );
  }
}
