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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Archive'),
      ),
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: _audioArchiveGrid(),
      ),
      bottomNavigationBar: const BottomMediaPlayer(),
    );
  }

  Widget _audioArchiveGrid() {
    return Scrollbar(
      child: GridView(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewPadding.bottom),
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
                shadowColor: Theme.of(context).colorScheme.onSecondary,
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
      bool isLink =
          MyConstants.of(context)!.audioArchiveLink.containsKey(title);
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
      if (await canLaunchUrl(Uri.parse(urlString))) {
        await launchUrl(Uri.parse(urlString));
      }
    } catch (e) {
      // do nothing
    }
  }
}
