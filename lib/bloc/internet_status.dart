import 'dart:async';

import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart'
    as iccp;

class InternetStatus {
  StreamController<iccp.InternetStatus> internetStatusStreamController =
      StreamController<iccp.InternetStatus>();

  late final StreamSubscription listener;

  /// Initialize the stream of data if the device is connected to the internet
  /// from internet_connection_checker
  InternetStatus() {
    listener =
        iccp.InternetConnection().onStatusChange.listen((internetStatus) {
      internetStatusStreamController.add(internetStatus);
    });
  }

  cancelListener() {
    listener.cancel();
  }
}
