import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:radiosai/audio_service/service_locator.dart';
import 'package:radiosai/constants/constants.dart';
import 'package:radiosai/helper/navigator_helper.dart';
import 'package:radiosai/screens/audio_archive/audio_archive.dart';
import 'package:radiosai/screens/radio_schedule/radio_schedule.dart';
import 'package:radiosai/screens/sai_inspires/sai_inspires.dart';
import 'package:radiosai/screens/search/search.dart';
import 'package:radiosai/screens/settings/settings.dart';

/// Top Menu - menu bar to show in base page
///
/// shows a pop-up menu for different screen navigations
class TopMenu extends StatefulWidget {
  const TopMenu({
    Key key,
  }) : super(key: key);

  @override
  _TopMenu createState() => _TopMenu();
}

class _TopMenu extends State<TopMenu> {
  @override
  Widget build(BuildContext context) {
    double topPadding = MediaQuery.of(context).padding.top + 5;
    double rightPadding = MediaQuery.of(context).size.width * 0.02;
    List<String> menuTitles = MyConstants.of(context).menuTitles;
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: EdgeInsets.only(
          top: topPadding,
          right: rightPadding,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Material(
              color: Colors.transparent,
              child: IconButton(
                icon: Icon((Platform.isAndroid)
                    ? Icons.search_outlined
                    : CupertinoIcons.search),
                splashRadius: 24,
                iconSize: 30,
                tooltip: 'Search Radio Sai',
                color: Colors.white,
                onPressed: () {
                  Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, anim1, anim2) => const Search(),
                        transitionsBuilder: (context, anim1, anim2, child) =>
                            FadeTransition(opacity: anim1, child: child),
                        transitionDuration: const Duration(milliseconds: 300),
                      ));
                  // Navigator.push(context,
                  //     MaterialPageRoute(builder: (context) => Search()));
                },
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Material(
                color: Colors.transparent,
                child: PopupMenuButton<String>(
                  icon: Icon(
                    (Platform.isAndroid)
                        ? Icons.more_vert
                        : CupertinoIcons.ellipsis,
                    color: Colors.white,
                  ),
                  iconSize: 30,
                  offset: const Offset(-10, 10),
                  itemBuilder: (context) {
                    // Takes list of data from constants
                    return menuTitles.map<PopupMenuEntry<String>>((value) {
                      return PopupMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                        ),
                      );
                    }).toList();
                  },
                  onSelected: (value) {
                    switch (value) {
                      // TODO: don't hardcode this and maybe add enum
                      case 'Sai Inspires':
                        getIt<NavigationService>()
                            .navigateTo(SaiInspires.route);
                        break;
                      case 'Settings':
                        getIt<NavigationService>().navigateTo(Settings.route);
                        break;
                      case 'Schedule':
                        getIt<NavigationService>()
                            .navigateTo(RadioSchedule.route);
                        break;
                      case 'Audio Archive':
                        getIt<NavigationService>()
                            .navigateTo(AudioArchive.route);
                        break;
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
