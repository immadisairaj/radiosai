import 'package:flutter/material.dart';

class ScaffoldHelper {
  /// the scaffold key which is used by the whole app
  ///
  /// attaches to the base page of the app
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  /// shows the snack bar using the global scaffold key
  ///
  /// Use getIt<ScaffoldHelper>().showSnackBar
  ///
  /// pass [text] to display and
  /// [duration] for how much time to display
  void showSnackBar(String text, Duration duration) {
    ScaffoldMessenger.of(scaffoldKey.currentContext!).showSnackBar(SnackBar(
      content: Text(text),
      behavior: SnackBarBehavior.floating,
      duration: duration,
    ));
  }
}
