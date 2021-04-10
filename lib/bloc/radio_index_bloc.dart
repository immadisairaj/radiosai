import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RadioIndexBloc {
  Future<SharedPreferences> prefs = SharedPreferences.getInstance();
  int _index;
  // key for shared preferences
  final _indexKey = 'radioIndex';

  // Initialize the stream for radio index:
  // index of radio sai streams.
  // Uses, shared preferences to store the stream
  RadioIndexBloc() {
    prefs.then((value) {
      if (value.get(_indexKey) != null) {
        _index = value.getInt(_indexKey) ?? 0;
      } else {
        _index = 0;
      }
      _actionController.stream.listen(_changeStream);
      _addValue.add(_index);
    });
  }

  // sets 0 as default value
  final _indexStream = BehaviorSubject<int>.seeded(0);
  // returns the stream to update anything based on values changed
  Stream get radioIndexStream => _indexStream.stream;
  Sink get _addValue => _indexStream.sink;

  StreamController _actionController = StreamController();
  void get resetCount => _actionController.sink.add(null);
  // call the function changeRadioIndex.add(value) to change the value
  StreamSink get changeRadioIndex => _actionController.sink;

  void _changeStream(data) async {
    if (data == null) {
      _index = 0;
    } else {
      _index = data;
    }
    _addValue.add(_index);
    prefs.then((value) {
      value.setInt(_indexKey, _index);
    });
  }

  void dispose() {
    _indexStream.close();
    _actionController.close();
  }
}
