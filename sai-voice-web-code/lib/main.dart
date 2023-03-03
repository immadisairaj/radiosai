import 'dart:math';

import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sai Voice',
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      home: const MyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    double iconSize = min(height, width) * 0.5;

    return Scaffold(
      backgroundColor: const Color(0xFFCC0C63),
      body: SafeArea(
        child: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8.0, 20.0, 8.0, 20.0),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height - 40,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: iconSize,
                        width: iconSize,
                        child: const RiveAnimation.asset(
                          'assets/sai_voice_logo.riv',
                          fit: BoxFit.cover,
                        ),
                      ),
                      Text(
                        'Sai Voice',
                        style: GoogleFonts.robotoMono(
                          textStyle: TextStyle(
                            fontSize: (height < width)
                                ? iconSize * 0.2
                                : iconSize * 0.3,
                            color: Colors.white,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      (height < width)
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: () {
                                      _launchUrl(Uri.parse(
                                          'https://play.google.com/store/apps/details?id=com.immadisairaj.radiosai'));
                                    },
                                    child: Image.asset(
                                      'assets/google-play-badge.png',
                                      height: (height < width)
                                          ? iconSize * 0.23
                                          : iconSize * 0.3,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: () {
                                      _launchUrl(Uri.parse(
                                          'https://play.google.com/store/apps/details?id=com.immadisairaj.radiosai'));
                                    },
                                    child: Image.asset(
                                      'assets/google-play-badge.png',
                                      height: (height < width)
                                          ? iconSize * 0.2
                                          : iconSize * 0.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            _launchUrl(Uri.parse(
                                'https://github.com/immadisairaj/radiosai'));
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'More Information: ',
                                style: GoogleFonts.ptMono(
                                  color: Colors.white,
                                  fontSize: (height < width)
                                      ? iconSize * 0.06
                                      : iconSize * 0.1,
                                ),
                              ),
                              Image.asset(
                                'assets/github.png',
                                height: (height < width)
                                    ? iconSize * 0.08
                                    : iconSize * 0.15,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _launchUrl(Uri url) async {
    if (!await launchUrl(url)) throw 'Could not launch $url';
  }
}
