import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TimeZoneBloc {
  Future<SharedPreferences> prefs = SharedPreferences.getInstance();
  String _timeZone;
  // key for time zone shared preferences
  final _timeZoneKey = 'timeZone';
  // initial time zone
  final String initialTimeZone = 'INDIA';

  // Initialize the stream for time zone:
  // Uses, shared preferences to store the time zone
  TimeZoneBloc() {
    prefs.then((value) {
      if (value.get(_timeZoneKey) != null) {
        _timeZone = value.getString(_timeZoneKey) ?? initialTimeZone;
      } else {
        _timeZone = initialTimeZone;
      }

      _actionController.stream.listen(_changeStream);
      _addValue.add(_timeZone);
    });
  }

  // sets initial time zone (INDIA) as default value
  final _timeZoneStream = BehaviorSubject<String>.seeded('INDIA');
  // returns the stream to update anything based on values changed
  Stream get timeZoneStream => _timeZoneStream.stream;
  Sink get _addValue => _timeZoneStream.sink;

  StreamController _actionController = StreamController();
  void get resetCount => _actionController.sink.add(null);
  // call the function changeTimeZone.add(value) to change the value
  StreamSink get changeTimeZone => _actionController.sink;

  void _changeStream(data) async {
    if (data == null) {
      _timeZone = initialTimeZone;
    } else {
      _timeZone = data;
    }
    _addValue.add(_timeZone);
    prefs.then((value) {
      value.setString(_timeZoneKey, _timeZone);
    });
  }

  void dispose() {
    _timeZoneStream.close();
    _actionController.close();
  }
}
