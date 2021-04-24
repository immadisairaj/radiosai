import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';
import 'package:radiosai/constants/constants.dart';
import 'package:radiosai/screens/settings/starting_radio_stream.dart';
import 'package:radiosai/widgets/browser.dart';
import 'package:radiosai/widgets/settings_section.dart';

class Settings extends StatefulWidget {
  Settings({
    Key key,
  }) : super(key: key);

  @override
  _Settings createState() => _Settings();
}

class _Settings extends State<Settings> {
  PackageInfo _packageInfo = PackageInfo(
    appName: '',
    packageName: '',
    version: '',
    buildNumber: '',
  );

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
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              _generalSection(),
              _aboutSection(),
            ],
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
          StartingRadioStream(),
        ],
      ),
    );
  }

  Widget _aboutSection() {
    // TODO: remove hardcoding later
    return SettingsSection(
      title: 'About',
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.only(left: 10),
            title: Text('About Sai'),
            subtitle: Text('Who is Sri Sathya Sai Baba?'),
            onTap: () {
              Browser.launchURL(context,
                  'http://media.radiosai.org/journals/Portal/bhagavan.htm');
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.only(left: 10),
            title: Text('About Radio Sai'),
            subtitle: Text('What is Radio Sai?'),
            onTap: () {
              Browser.launchURL(context, 'https://www.radiosai.org');
            },
          ),
          Divider(),
          ListTile(
            contentPadding: EdgeInsets.only(left: 10),
            title: Text('Version'),
            subtitle: Text('v${_packageInfo.version}'),
            onTap: () {},
          ),
          ListTile(
            contentPadding: EdgeInsets.only(left: 10),
            title: Text('Build time'),
            // get from constants
            subtitle: Text(MyConstants.of(context).buldTime),
            onTap: () {},
          ),
          Divider(),
          ListTile(
            contentPadding: EdgeInsets.only(left: 10),
            title: Text('Website'),
            subtitle: Text('https://immadisairaj.me/radiosai'),
            onTap: () {
              Browser.launchURL(context, 'https://immadisairaj.me/radiosai');
            },
          ),
          Divider(),
          ListTile(
            contentPadding: EdgeInsets.only(left: 10),
            title: Text('Open source licenses'),
            onTap: () {
              showLicensePage(
                context: context,
                applicationName: _packageInfo.packageName,
                applicationVersion: _packageInfo.version,
                // applicationIcon: Image(image: AssetImage('assets/radiosai-logo.jpg')),
                // TODO: add other app related things
              );
            },
          ),
        ],
      ),
    );
  }
}
