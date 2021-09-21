import 'package:audio_service/audio_service.dart';
import 'package:get_it/get_it.dart';
import 'package:radiosai/audio_service/audio_handler.dart';
import 'package:radiosai/audio_service/audio_manager.dart';
import 'package:radiosai/helper/navigator_helper.dart';

GetIt getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // audio service
  getIt.registerSingleton<AudioHandler>(await initAudioService());

  // audio manager
  getIt.registerLazySingleton<AudioManager>(() => AudioManager());

  // global navigator
  getIt.registerLazySingleton(() => NavigationService());
}
