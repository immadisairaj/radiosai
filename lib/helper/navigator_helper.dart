import 'package:flutter/material.dart';

class NavigationService {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Push the [routeName] page in the navigator
  Future<dynamic> navigateTo(String routeName) {
    return navigatorKey.currentState.pushNamed(routeName);
  }

  /// Repeteadly pop the navigated routes until [routeName]
  void popUntil(String routeName) {
    return navigatorKey.currentState.popUntil(ModalRoute.withName(routeName));
  }

  /// returns if the [routeName] is currently top route,
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

  /// Repeatedly pop till it is the first page
  void popToBase() {
    return navigatorKey.currentState.popUntil((route) => route.isFirst);
  }
}
