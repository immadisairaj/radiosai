import 'package:audio_service/audio_service.dart';
import 'package:get_it/get_it.dart';
import 'package:radiosai/audio_service/audio_handler.dart';
import 'package:radiosai/audio_service/audio_manager.dart';

GetIt getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // audio service
  getIt.registerSingleton<AudioHandler>(await initAudioService());

  // audio manager
  getIt.registerLazySingleton<AudioManager>(() => AudioManager());
}
