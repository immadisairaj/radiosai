import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppThemeBloc {
  Future<SharedPreferences> prefs = SharedPreferences.getInstance();
  String _theme;
  // key for app theme shared preferences
  final _appThemeKey = 'appTheme';
  // initial theme
  final String initialTheme = 'System default';

  // Initialize the stream for app theme:
  // Uses, shared preferences to store the theme
  AppThemeBloc() {
    prefs.then((value) {
      if (value.get(_appThemeKey) != null) {
        _theme = value.getString(_appThemeKey) ?? initialTheme;
      } else {
        _theme = initialTheme;
      }

      _actionController.stream.listen(_changeStream);
      _addValue.add(_theme);
    });
  }

  // sets initial theme (system default) as default value
  final _themeStream = BehaviorSubject<String>.seeded('System default');
  // returns the stream to update anything based on values changed
  Stream get appThemeStream => _themeStream.stream;
  Sink get _addValue => _themeStream.sink;

  StreamController _actionController = StreamController();
  void get resetCount => _actionController.sink.add(null);
  // call the function changeAppTheme.add(value) to change the value
  StreamSink get changeAppTheme => _actionController.sink;

  void _changeStream(data) async {
    if (data == null) {
      _theme = initialTheme;
    } else {
      _theme = data;
    }
    _addValue.add(_theme);
    prefs.then((value) {
      value.setString(_appThemeKey, _theme);
    });
  }

  void dispose() {
    _themeStream.close();
    _actionController.close();
  }
}
