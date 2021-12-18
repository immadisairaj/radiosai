import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InitialRadioIndexBloc {
  Future<SharedPreferences> prefs = SharedPreferences.getInstance();
  int? _index;
  // key for initial radio index shared preferences
  final _initialIndexKey = 'initialRadioIndex';

  // Initialize the stream for radio index:
  // index of radio sai streams.
  // Uses, shared preferences to store the stream
  InitialRadioIndexBloc() {
    prefs.then((value) {
      if (value.get(_initialIndexKey) != null) {
        _index = value.getInt(_initialIndexKey) ?? -1;
      } else {
        _index = 0;
      }

      _actionController.stream.listen(_changeStream);
      _addValue.add(_index);
    });
  }

  // sets 0 as default value
  final _indexStream = BehaviorSubject<int?>.seeded(0);
  // returns the stream to update anything based on values changed
  Stream get initialRadioIndexStream => _indexStream.stream;
  Sink get _addValue => _indexStream.sink;

  final StreamController _actionController = StreamController();
  void get resetCount => _actionController.sink.add(null);
  // call the function changeRadioIndex.add(value) to change the value
  StreamSink get changeInitialRadioIndex => _actionController.sink;

  void _changeStream(data) async {
    if (data == null) {
      _index = 0;
    } else {
      _index = data;
    }
    _addValue.add(_index);
    prefs.then((value) {
      value.setInt(_initialIndexKey, _index!);
    });
  }

  void dispose() {
    _indexStream.close();
    _actionController.close();
  }
}
