import 'package:flutter/material.dart';
import 'package:radiosai/constants/constants.dart';
import 'package:radiosai/screens/media/media.dart';
import 'package:radiosai/screens/search/search.dart';
import 'package:radiosai/widgets/bottom_media_player.dart';
import 'package:url_launcher/url_launcher.dart';

class AudioArchive extends StatefulWidget {
  const AudioArchive({
    Key? key,
  }) : super(key: key);

  static const String route = 'audioArchive';

  @override
  _AudioArchive createState() => _AudioArchive();
}

class _AudioArchive extends State<AudioArchive> {
  @override
  Widget build(BuildContext context) {
    // check if dark theme
    bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    Color backgroundColor = Theme.of(context).backgroundColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Archive'),
        backgroundColor:
            MaterialStateColor.resolveWith((Set<MaterialState> states) {
          return states.contains(MaterialState.scrolledUnder)
              ? ((isDarkTheme)
                  ? Colors.grey[700]!
                  : Theme.of(context).colorScheme.secondary)
              : Theme.of(context).primaryColor;
        }),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        color: backgroundColor,
        child: _audioArchiveGrid(isDarkTheme),
      ),
      bottomNavigationBar: const BottomMediaPlayer(),
    );
  }

  Widget _audioArchiveGrid(bool isDarkTheme) {
    return Scrollbar(
      child: GridView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
        ),
        children: MyConstants.of(context)!.audioArchive.keys.map((imageAsset) {
          return Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Card(
                elevation: 5,
                shadowColor:
                    isDarkTheme ? Colors.white : Theme.of(context).primaryColor,
                child: InkWell(
                  onTap: () {
                    _navigateAudioArchive(
                        MyConstants.of(context)!.audioArchive[imageAsset]);
                  },
                  child: Ink(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(imageAsset),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _navigateAudioArchive(String? title) {
    bool isMedia = MyConstants.of(context)!.audioArchiveFids.containsKey(title);
    if (isMedia) {
      // if contains media, navigate to media screen
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => Media(
                    fids: MyConstants.of(context)!.audioArchiveFids[title!],
                    title: title,
                  )));
    } else {
      bool isLink = MyConstants.of(context)!.audioArchiveLink.containsKey(title);
      if (isLink) {
        // if contains link, launch the url
        _urlLaunch(MyConstants.of(context)!.audioArchiveLink[title!]);
      } else {
        bool isSearch =
            MyConstants.of(context)!.audioArchiveSearch.containsKey(title);
        if (isSearch) {
          // ic contains search, navigate to search screen
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => Search(
                        initialSearch:
                            MyConstants.of(context)!.audioArchiveSearch[title!],
                        initialSearchTitle: title,
                      )));
        }
      }
    }
  }

  /// launch the url from url_launcher
  _urlLaunch(urlString) async {
    try {
      if (await canLaunch(urlString)) {
        await launch(urlString);
      }
    } catch (e) {
      // do nothing
    }
  }
}
