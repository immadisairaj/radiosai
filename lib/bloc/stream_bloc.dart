import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StreamBloc {
  Future<SharedPreferences> prefs = SharedPreferences.getInstance();
  int _index;

  StreamBloc() {
    prefs.then((value) {
      if(value.get('stream') != null) {
        _index = value.getInt('stream') ?? 0;
      } else {
        _index = 0;
      }
      _actionController.stream.listen(_changeStream);
      _addValue.add(_index);
    });
  }

  final _indexStream = BehaviorSubject<int>.seeded(0);
  Stream get indexStream => _indexStream.stream;
  Sink get _addValue => _indexStream.sink;

  StreamController _actionController = StreamController();
  void get resetCount => _actionController.sink.add(null);
  StreamSink get changeStreamIndex => _actionController.sink;

  void _changeStream(data) async {
    if (data == null) {
      _index = 0;
    } else {
      _index = data;
    }
    _addValue.add(_index);
    prefs.then((value) {
      value.setInt('stream', _index);
    });
  }

  void dispose() {
    _indexStream.close();
    _actionController.close();
  }
}