import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';
import 'package:radiosai/screens/settings/starting_radio_stream.dart';
import 'package:radiosai/widgets/browser.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Container(
        color: Colors.white,
        height: MediaQuery.of(context).size.height,
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                _generalSection(),
                _aboutSection(),
                _moreDetailsSection(),
              ],
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
              Browser.launchURL(context,
                  'http://media.radiosai.org/journals/Portal/bhagavan.htm');
            },
          ),
          ListTile(
            contentPadding: _contentPadding,
            title: Text('About Radio Sai'),
            onTap: () {
              Browser.launchURL(context, 'https://www.radiosai.org');
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
              Browser.launchURL(context, 'https://immadisairaj.me/radiosai');
            },
          ),
          ListTile(
            contentPadding: _contentPadding,
            title: Text('Contact'),
            // use url_launcher for mail option because
            // flutter_custom_tabs doesn't support mailto
            onTap: () async {
              final urlString = 'mailto:immadirajendra.sai@gmail.com';
              try {
                if (await canLaunch(urlString)) {
                  await launch(urlString);
                }
              } catch (e) {
                // do nothing
              }
            },
          ),
          ListTile(
            contentPadding: _contentPadding,
            title: Text('Privacy Policy'),
            onTap: () {
              Browser.launchURL(context,
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
                applicationIcon: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image(image: AssetImage('assets/radiosai-logo.jpg')),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
