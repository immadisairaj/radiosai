import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Settings extends StatefulWidget {
  Settings({
    Key key,
  }) : super(key: key);

  @override
  _Settings createState() => _Settings();
}

class _Settings extends State<Settings> {
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
    return _sectionBuild(
      'General Settings',
      Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.only(left: 10),
            title: Text('Starting radio stream'),
            subtitle: Text('Recently played'),
            onTap: () {
              // TODO: add chromable link to the website
            },
          ),
        ],
      ),
    );
  }

  Widget _aboutSection() {
    // TODO: remove hardcoding later
    return _sectionBuild(
      'About',
      Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.only(left: 10),
            title: Text('About Sai'),
            subtitle: Text('Who is Sri Sathya Sai Baba?'),
            onTap: () {
              // TODO: add chromable link to the website
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.only(left: 10),
            title: Text('About Radio Sai'),
            subtitle: Text('What is Radio Sai?'),
            onTap: () {
              // TODO: add chromable link to the website
            },
          ),
          Divider(),
          ListTile(
            contentPadding: EdgeInsets.only(left: 10),
            title: Text('Version'),
            subtitle: Text('0.0.1'),
            onTap: () {},
          ),
          ListTile(
            contentPadding: EdgeInsets.only(left: 10),
            title: Text('Build time'),
            subtitle: Text('21/04/2021 19:45'),
            onTap: () {},
          ),
          Divider(),
          ListTile(
            contentPadding: EdgeInsets.only(left: 10),
            title: Text('Website'),
            subtitle: Text('https://immadisairaj.me/radiosai'),
            onTap: () {
              // TODO: add chromable link to the website
            },
          ),
          Divider(),
          ListTile(
            contentPadding: EdgeInsets.only(left: 10),
            title: Text('Open source licenses'),
            onTap: () {
              showLicensePage(
                context: context,
                // applicationIcon: Image(image: AssetImage('assets/radiosai-logo.jpg')),
                // TODO: add other app related things
              );
            },
          ),
        ],
      ),
    );
  }

  // later move this to new class
  Widget _sectionBuild(String title, Widget builder) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Card(
        elevation: 0.2,
        color: Colors.grey[200],
        child: Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20, top: 10, bottom: 10),
                child: Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              builder,
            ],
          ),
        ),
      ),
    );
  }
}
