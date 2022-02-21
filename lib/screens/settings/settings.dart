import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:radiosai/screens/settings/general/app_theme.dart';
import 'package:radiosai/screens/settings/general/starting_radio_stream.dart';
import 'package:radiosai/widgets/settings/settings_section.dart';
import 'package:url_launcher/url_launcher.dart';

class Settings extends StatefulWidget {
  const Settings({
    Key? key,
  }) : super(key: key);

  static const String route = 'settings';

  @override
  _Settings createState() => _Settings();
}

class _Settings extends State<Settings> {
  // empty package info before initPackageInfo
  PackageInfo _packageInfo = PackageInfo(
    appName: '',
    packageName: '',
    version: '',
    buildNumber: '',
  );

  final EdgeInsetsGeometry _contentPadding = const EdgeInsets.only(left: 20);

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  /// Get app package information
  Future<void> _initPackageInfo() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  @override
  Widget build(BuildContext context) {
    // check if dark theme
    bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
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
        color: Theme.of(context).backgroundColor,
        height: MediaQuery.of(context).size.height,
        child: Scrollbar(
          radius: const Radius.circular(8),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  _generalSection(),
                  _storageSection(),
                  _aboutSection(),
                  _moreDetailsSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// general section
  Widget _generalSection() {
    return SettingsSection(
      title: 'General Settings',
      child: Column(
        children: [
          StartingRadioStream(
            contentPadding: _contentPadding,
          ),
          AppTheme(
            contentPadding: _contentPadding,
          ),
        ],
      ),
    );
  }

  /// storage section
  Widget _storageSection() {
    return SettingsSection(
      title: 'Storage',
      child: Column(
        children: [
          ListTile(
            contentPadding: _contentPadding,
            title: const Text('Clear cache'),
            onTap: () {
              DefaultCacheManager().emptyCache();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Cleared cache'),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 1),
              ));
            },
          ),
        ],
      ),
    );
  }

  /// about section
  Widget _aboutSection() {
    return SettingsSection(
      title: 'About',
      child: Column(
        children: [
          ListTile(
            contentPadding: _contentPadding,
            title: const Text('About Sai'),
            subtitle: const Text('Who is Sri Sathya Sai Baba?'),
            onTap: () {
              _urlLaunch(
                  'http://media.radiosai.org/journals/Portal/bhagavan.htm');
            },
          ),
          ListTile(
            contentPadding: _contentPadding,
            title: const Text('About Radio Sai'),
            onTap: () {
              _urlLaunch('https://www.radiosai.org');
            },
          ),
          const Divider(),
          ListTile(
            contentPadding: _contentPadding,
            title: const Text('Version'),
            subtitle: Text('v${_packageInfo.version}'),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  /// more details section
  Widget _moreDetailsSection() {
    return SettingsSection(
      title: 'More details',
      child: Column(
        children: [
          ListTile(
            contentPadding: _contentPadding,
            title: const Text('Website'),
            subtitle: const Text('https://immadisairaj.github.io/radiosai'),
            onTap: () {
              _urlLaunch('https://immadisairaj.github.io/radiosai');
            },
          ),
          ListTile(
            contentPadding: _contentPadding,
            title: const Text('Contact'),
            onTap: () {
              _urlLaunch('mailto:immadirajendra.sai@gmail.com');
            },
          ),
          ListTile(
            contentPadding: _contentPadding,
            title: const Text('Privacy Policy'),
            onTap: () {
              _urlLaunch(
                  'https://immadisairaj.github.io/radiosai/privacy_policy.html');
            },
          ),
          const Divider(),
          ListTile(
            contentPadding: _contentPadding,
            title: const Text('Open source licenses'),
            onTap: () {
              showLicensePage(
                context: context,
                applicationName: _packageInfo.appName,
                applicationVersion: _packageInfo.version,
              );
            },
          ),
        ],
      ),
    );
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
