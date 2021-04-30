import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';

// use Browser.launchURL(context, url);
// as this is a static method to launch url in custom chrome tabs
class Browser {
  static void launchURL(BuildContext context, String urlString) async {
    try {
      await launch(
        urlString,
        option: new CustomTabsOption(
          toolbarColor: Theme.of(context).primaryColor,
          enableDefaultShare: true,
          enableUrlBarHiding: true,
          showPageTitle: true,
          animation: new CustomTabsAnimation(
              startEnter: 'slide_up',
              startExit: 'android:anim/fade_out',
              endEnter: 'android:anim/fade_in',
              endExit: 'slide_down'),
          // if chrome is not available
          extraCustomTabs: [
            'org.mozilla.firefox',
            'com.microsoft.emmx',
            'com.brave.browser',
          ],
        ),
      );
    } catch (e) {
      // do nothing as of now
    }
  }
}
