import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RadioIndexBloc {
  Future<SharedPreferences> prefs = SharedPreferences.getInstance();
  int _index;
  // key for present shared preferences
  final _indexKey = 'radioIndex';
  // key for initial radio index shared preferences
  final _initialIndexKey = 'initialRadioIndex';

  // Initialize the stream for radio index:
  // index of radio sai streams.
  // Uses, shared preferences to store the stream
  RadioIndexBloc() {
    prefs.then((value) {
      int openOption;
      // shared preferences for starting option
      if (value.get(_initialIndexKey) != null) {
        openOption = value.getInt(_initialIndexKey) ?? -1;
      } else {
        openOption = -1;
        value.setInt(_initialIndexKey, openOption);
      }

      // if the user opts recent, open recently closed stream
      // else, open the selected option
      if (openOption < 0) {
        if (value.get(_indexKey) != null) {
          _index = value.getInt(_indexKey) ?? 0;
        } else {
          _index = 0;
        }
      } else {
        _index = openOption;
      }

      _actionController.stream.listen(_changeStream);
      _addValue.add(_index);
      // add in shared prefences as to ensure proper
      // radio index opens when opened next time
      value.setInt(_indexKey, _index);
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
