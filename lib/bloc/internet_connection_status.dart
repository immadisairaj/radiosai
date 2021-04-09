import 'dart:async';

import 'package:internet_connection_checker/internet_connection_checker.dart';

class InternetConnectionService {
  StreamController<InternetConnectionStatus> connectionController = StreamController<InternetConnectionStatus>();
  
  InternetConnectionService() {
    InternetConnectionChecker().onStatusChange.listen((internetStatus) {
      connectionController.add(internetStatus);
    });
  }
}