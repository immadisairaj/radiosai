import 'package:flutter/material.dart';
// import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:radiosai/audio_service/service_locator.dart';
import 'package:radiosai/bloc/media/media_screen_bloc.dart';
import 'package:radiosai/bloc/radio_schedule/time_zone_bloc.dart';
import 'package:radiosai/bloc/settings/app_theme_bloc.dart';
import 'package:radiosai/bloc/settings/initial_radio_index_bloc.dart';
import 'package:radiosai/bloc/internet_status.dart';
import 'package:radiosai/bloc/radio/radio_loading_bloc.dart';
import 'package:radiosai/constants/constants.dart';
import 'package:radiosai/helper/download_helper.dart';
import 'package:radiosai/helper/navigator_helper.dart';
import 'package:radiosai/screens/audio_archive/audio_archive.dart';
import 'package:radiosai/screens/home.dart';
import 'package:provider/provider.dart';
import 'package:radiosai/bloc/radio/radio_index_bloc.dart';
import 'package:radiosai/screens/media_player/media_player.dart';
import 'package:radiosai/screens/media_player/playing_queue.dart';
import 'package:radiosai/screens/radio_schedule/radio_schedule.dart';
import 'package:radiosai/screens/sai_inspires/sai_inspires.dart';
import 'package:radiosai/screens/settings/settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // initialize flutter downloader
  // // TODO: change the debug to false later / remove
  // await FlutterDownloader.initialize(debug: false);

  // initialize the audio service
  await setupServiceLocator();

  runApp(MyConstants(child: MyApp()));
}

class MyApp extends StatelessWidget {
  final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorSchemeSeed: Colors.deepOrange,
  );

  final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorSchemeSeed: Colors.deepOrange,
    brightness: Brightness.dark,
  );

  MyApp({Key? key}) : super(key: key);

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
          create: (_) => RadioLoadingBloc(),
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
        // stream for app theme
        Provider<AppThemeBloc>(
          create: (_) => AppThemeBloc(),
          dispose: (_, AppThemeBloc appThemeBloc) => appThemeBloc.dispose(),
        ),
        // stream for time zone
        Provider<TimeZoneBloc>(
          create: (_) => TimeZoneBloc(),
          dispose: (_, TimeZoneBloc timeZoneBloc) => timeZoneBloc.dispose(),
        ),
        // stream for media screen updates
        Provider<MediaScreenBloc>(
          // updates the media screen based on download state
          // calling from download helper is a must
          create: (_) => DownloadHelper.getMediaScreenBloc(),
          dispose: (_, MediaScreenBloc mediaScreenBloc) =>
              mediaScreenBloc.dispose(),
        ),
      ],
      child: Consumer<AppThemeBloc>(
          // listen to change of app theme
          builder: (context, _appThemeBloc, child) {
        return StreamBuilder<String?>(
            stream: _appThemeBloc.appThemeStream as Stream<String?>?,
            builder: (context, snapshot) {
              String appTheme =
                  snapshot.data ?? MyConstants.of(context)!.appThemes[2];

              bool isSystemDefault =
                  appTheme == MyConstants.of(context)!.appThemes[2];
              bool isDarkTheme =
                  appTheme == MyConstants.of(context)!.appThemes[1];

              return MaterialApp(
                title: 'Sai Voice',
                debugShowCheckedModeBanner: false,
                themeMode: isSystemDefault
                    ? ThemeMode.system
                    : (isDarkTheme ? ThemeMode.dark : ThemeMode.light),
                theme: lightTheme,
                darkTheme: darkTheme,
                home: const Home(),
                navigatorKey: getIt<NavigationService>().navigatorKey,
                routes: {
                  MediaPlayer.route: (context) => const MediaPlayer(),
                  PlayingQueue.route: (context) => const PlayingQueue(),
                  AudioArchive.route: (context) => const AudioArchive(),
                  SaiInspires.route: (context) => const SaiInspires(),
                  Settings.route: (context) => const Settings(),
                  RadioSchedule.route: (context) => const RadioSchedule(),
                },
              );
            });
      }),
    );
  }
}
