import 'dart:async';

import 'package:internet_connection_checker/internet_connection_checker.dart';

class InternetStatus {
  StreamController<InternetConnectionStatus> internetStatusStreamController =
      StreamController<InternetConnectionStatus>();

  // Initialize the stream of data if the device is connected to the internet
  // from internet_connection_checker
  InternetStatus() {
    InternetConnectionChecker().onStatusChange.listen((internetStatus) {
      internetStatusStreamController.add(internetStatus);
    });
  }
}
