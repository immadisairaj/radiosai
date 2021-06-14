import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:package_info/package_info.dart';
import 'package:radiosai/screens/settings/general/app_theme.dart';
import 'package:radiosai/screens/settings/general/starting_radio_stream.dart';
import 'package:radiosai/widgets/settings/settings_section.dart';
import 'package:url_launcher/url_launcher.dart';

class Settings extends StatefulWidget {
  Settings({
    Key key,
  }) : super(key: key);

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

  final EdgeInsetsGeometry _contentPadding = EdgeInsets.only(left: 10);

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  // Get package information
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
        title: Text('Settings'),
      ),
      body: Container(
        color: isDarkTheme ? Colors.grey[700] : Colors.white,
        height: MediaQuery.of(context).size.height,
        child: Scrollbar(
          radius: Radius.circular(8),
          child: SingleChildScrollView(
            physics:
                BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            child: Padding(
              padding: EdgeInsets.only(bottom: 20),
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

  Widget _storageSection() {
    return SettingsSection(
      title: 'Storage',
      child: Column(
        children: [
          ListTile(
            contentPadding: _contentPadding,
            title: Text('Clear cache'),
            onTap: () {
              DefaultCacheManager().emptyCache();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
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

  Widget _aboutSection() {
    return SettingsSection(
      title: 'About',
      child: Column(
        children: [
          ListTile(
            contentPadding: _contentPadding,
            title: Text('About Sai'),
            subtitle: Text('Who is Sri Sathya Sai Baba?'),
            onTap: () {
              _urlLaunch(
                  'http://media.radiosai.org/journals/Portal/bhagavan.htm');
            },
          ),
          ListTile(
            contentPadding: _contentPadding,
            title: Text('About Radio Sai'),
            onTap: () {
              _urlLaunch('https://www.radiosai.org');
            },
          ),
          Divider(),
          ListTile(
            contentPadding: _contentPadding,
            title: Text('Version'),
            subtitle: Text('v${_packageInfo.version}'),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _moreDetailsSection() {
    return SettingsSection(
      title: 'More details',
      child: Column(
        children: [
          ListTile(
            contentPadding: _contentPadding,
            title: Text('Website'),
            subtitle: Text('https://immadisairaj.me/radiosai'),
            onTap: () {
              _urlLaunch('https://immadisairaj.me/radiosai');
            },
          ),
          ListTile(
            contentPadding: _contentPadding,
            title: Text('Contact'),
            onTap: () {
              _urlLaunch('mailto:immadirajendra.sai@gmail.com');
            },
          ),
          ListTile(
            contentPadding: _contentPadding,
            title: Text('Privacy Policy'),
            onTap: () {
              _urlLaunch(
                  'https://immadisairaj.me/radiosai/privacy_policy.html');
            },
          ),
          Divider(),
          ListTile(
            contentPadding: _contentPadding,
            title: Text('Open source licenses'),
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
