import 'package:flutter/material.dart';

class NavigationService {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<dynamic> navigateTo(String routeName) {
    return navigatorKey.currentState.pushNamed(routeName);
  }

  void popUntil(String routeName) {
    return navigatorKey.currentState.popUntil(ModalRoute.withName(routeName));
  }

  bool isCurrentRoute(String routeName) {
    bool isCurrent = false;
    navigatorKey.currentState.popUntil((route) {
      if (route.settings.name == routeName) {
        isCurrent = true;
      }
      return true;
    });
    return isCurrent;
  }

  void popToBase() {
    return navigatorKey.currentState.popUntil((route) => route.isFirst);
  }
}
