import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:radiosai/bloc/settings/initial_radio_index_bloc.dart';
import 'package:radiosai/bloc/internet_status.dart';
import 'package:radiosai/bloc/radio/radio_loading_bloc.dart';
import 'package:radiosai/constants/constants.dart';
import 'package:radiosai/screens/home.dart';
import 'package:provider/provider.dart';
import 'package:radiosai/bloc/radio/radio_index_bloc.dart';

void main() {
  runApp(MyConstants(child: MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // providers for changing widgets using streams
    return MultiProvider(
      providers: [
        // stream for radio sai stream index
        Provider<RadioIndexBloc>(
          create: (_) => RadioIndexBloc(),
          dispose: (_, RadioIndexBloc radioIndexBloc) =>
              radioIndexBloc.dispose(),
        ),
        // stream for radio loading state
        Provider<RadioLoadingBloc>(
          create: (_) => RadioLoadingBloc(false),
          dispose: (_, RadioLoadingBloc radioLoadingBloc) =>
              radioLoadingBloc.dispose(),
        ),
        // stream for internet connectivity status
        StreamProvider<InternetConnectionStatus>(
          initialData: InternetConnectionStatus.connected,
          create: (context) {
            return InternetStatus().internetStatusStreamController.stream;
          },
        ),
        // stream for initial radio sai stream index
        Provider<InitialRadioIndexBloc>(
          create: (_) => InitialRadioIndexBloc(),
          dispose: (_, InitialRadioIndexBloc initialRadioIndexBloc) =>
              initialRadioIndexBloc.dispose(),
        ),
      ],
      child: MaterialApp(
        title: 'Sai Voice',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.deepOrange,
        ),
        home: AudioServiceWidget(child: Home()),
      ),
    );
  }
}
