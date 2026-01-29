import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:radiosai/helper/navigator_helper.dart';

class MyConstants extends InheritedWidget {
  static MyConstants? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MyConstants>();

  const MyConstants({required super.child, super.key});

  /// The list of radio sai stream https source names and links
  final Map<String, String> radioStreamHttps = const {
    'Prasanthi Stream': 'https://stream.sssmediacentre.org:8443/asia',
    // 'Africa Stream': 'https://stream.sssmediacentre.org:8443/afri',
    // 'America Stream': 'https://stream.sssmediacentre.org:8443/ameri',
    'Bhajan Stream': 'https://stream.sssmediacentre.org:8443/bhajan',
    'Discourse Stream': 'https://stream.sssmediacentre.org:8443/discourse',
    'Telugu Stream': 'https://stream.sssmediacentre.org:8443/telugu',
  };

  final Map<String, String> radioStreamImages = const {
    'Prasanthi Stream':
        'https://radiosai.immadisairaj.dev/images/prasanthiStream.png',
    'Bhajan Stream':
        'https://radiosai.immadisairaj.dev/images/bhajanStream.png',
    'Discourse Stream':
        'https://radiosai.immadisairaj.dev/images/discourseStream.png',
    'Telugu Stream':
        'https://radiosai.immadisairaj.dev/images/teluguStream.png',
  };

  /// The list of items in the top menu bar
  final Map<dynamic, String> menuTitles = const {
    MenuNavigation.schedule: 'Schedule',
    MenuNavigation.saiInspires: 'Sai Inspires',
    // MenuNavigation.audio: 'Audio',
    MenuNavigation.settings: 'Settings',
  };

  /// The list of android icons in the top menu bar
  final Map<dynamic, IconData> menuTitleAndroidIcons = const {
    MenuNavigation.schedule: Icons.schedule_outlined,
    MenuNavigation.saiInspires: Icons.text_snippet_outlined,
    MenuNavigation.audio: Icons.library_music_outlined,
    MenuNavigation.settings: Icons.settings_outlined,
  };

  /// The list of ios icons in the top menu bar
  final Map<dynamic, IconData> menuTitleIosIcons = const {
    MenuNavigation.schedule: CupertinoIcons.time,
    MenuNavigation.saiInspires: CupertinoIcons.text_quote,
    MenuNavigation.audio: CupertinoIcons.music_albums,
    MenuNavigation.settings: CupertinoIcons.settings,
  };

  /// list of radio streams for radio sai schedule
  final Map<String, int> scheduleStream = const {
    'Prasanthi Stream': 1,
    // 'Africa Stream': 3,
    // 'America Stream': 2,
    'Discourse Stream': 6,
    'Telugu Stream': 5,
  };

  /// list of audio archive images with names
  final Map<String, String> audioArchive = const {
    'assets/audio_archive/baba_sings.jpg': 'Baba Sings',
    'assets/audio_archive/vedam.jpg': 'Vedic Chants',
    'assets/audio_archive/karaoke.jpg': 'Sai Bhajans Karaoke',
    'assets/audio_archive/ringtones.jpg': 'Ringtones & Special Audios',
    'assets/audio_archive/thursday_live.jpg': 'Thursday Live',
    'assets/audio_archive/musings.jpg': 'Musings',
    'assets/audio_archive/medical.jpg': 'Medical Marvels',
    'assets/audio_archive/seva.jpg': 'Service',
    'assets/audio_archive/fleeting_moments.jpg':
        'Fleeting Moments Lasting Memories',
    'assets/audio_archive/study_circle.jpg': 'Study Circle',
    'assets/audio_archive/anecdotes.jpg': 'Anecdotes to Awaken',
    'assets/audio_archive/loving_legend.jpg': 'Loving Legend Living Legacies',
    'assets/audio_archive/bhajan_tutor.jpg': 'Bhajan Tutor',
    'assets/audio_archive/oneness.jpg': 'Moments of Oneness',
    'assets/audio_archive/dramas.jpg': 'Dramas',
    'assets/audio_archive/talks.jpg': 'Talks',
    'assets/audio_archive/tales.jpg': 'Tales that Transform',
    'assets/audio_archive/chinnikatha.jpg': 'Chinna Kathas',
    'assets/audio_archive/sse.jpg': 'SSE on Air',
    'assets/audio_archive/matter.jpg': 'Matter of Conscience',
    'assets/audio_archive/learning_with_love.jpg': 'Learning with Love',
    'assets/audio_archive/tryst.jpg': 'Tryst with Divinity',
  };

  /// list of audio archive names and fids
  final Map<String, String> audioArchiveFids = const {
    'Baba Sings':
        '5965,5967,6223,6737,6738,6876,6879,7006,7159,7161,7163,7165,7327,7461,7644,7646,25601,25602,25605,25628,25629,25630,25631,25633,25634,25635,25636,25714,26164,26166,26187,26188,26190,26217,26219,26231,26248,26459,26581,26715,27010,27301,27575,27576,27929,27974,5963,5964,5966,5968,5969,6096,6097,6098,6099,6101,6102,6103,6174,6175,6176,6177,6217,6218,6219,6220,6221,6222,6739,6740,6741,6742,6743,6822,6823,6824,6825,6826,6827,6872,6873,6874,6875,6877,6878,7003,7004,7005,7007,7008,7009,7010,7084,7085,7086,7087,7088,7157,7158,7160,7162,7164,7166,7324,7325,7326,7328,7329,7330,7400,7401,7402,7403,7459,7460,7462,7463,7464,7465,7466,7645,7647,7648,7782,7783,7876,7918,8049,10775,10776,10777,10778,10779,17550,17551,27532,27533,27534,27535,27536,27537,27538,27539,27540',
    'Vedic Chants':
        '11352,11353,11354,11355,22376,22417,22418,22432,22433,22434,22435,22469,22470,22471,22495,22496,22497,22498,22499,22500,22501,22502,22518,22519,22520,22521,22522,22523,22524,22543,22544,22545,22546,22547,22568,22569,22570,22571,22572,22573,26328,26329,26330,26331,26332,26333',
  };

  /// list of audio archive names and links
  final Map<String, String> audioArchiveLink = const {
    // TODO: these won't be supported in the future, have to remove
    'Sai Bhajans Karaoke':
        'https://media.radiosai.org/journals/Archives/Sai-Bhajans_Karaoke-Archive.htm',
    'Ringtones & Special Audios':
        'https://media.radiosai.org/journals/Archives/darshan-video/Radio-Sai-Ringtones-and-Devotional-music.htm',
    'Thursday Live':
        'https://media.radiosai.org/journals/Archives/thursday_live_archive.htm',
  };

  /// list of audio archive names and search parameters
  final Map<String, String> audioArchiveSearch = const {
    'Musings': 'musings',
    'Medical Marvels': 'medical marvels',
    'Service': 'service in the name of sai',
    'Fleeting Moments Lasting Memories': 'Fleeting Moments Lasting Memories',
    'Study Circle': 'study circle',
    'Anecdotes to Awaken': 'Anecdotes to Awaken',
    'Loving Legend Living Legacies': 'LOVING LEGEND LIVING LEGACIES',
    'Bhajan Tutor': 'Bhajan Classroom',
    'Moments of Oneness': 'moments of oneness',
    'Dramas': 'drama students',
    'Talks': 'talk prasanthi',
    'Tales that Transform': 'tales that transform',
    'Chinna Kathas': 'CK CD',
    'SSE on Air': 'sse on air',
    'Matter of Conscience': 'a matter of conscience',
    'Learning with Love': 'Learning with Love',
    'Tryst with Divinity': 'tryst with divinity',
  };

  /// list of app themes
  // Note: don't change or move the values
  final List<String> appThemes = const ['Light', 'Dark', 'System default'];

  @override
  bool updateShouldNotify(MyConstants oldWidget) => false;
}
