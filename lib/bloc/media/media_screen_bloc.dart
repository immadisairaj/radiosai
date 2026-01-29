import 'dart:async';

import 'package:rxdart/rxdart.dart';

// updates the media screen based on download state
// have to use only by calling from download helper
class MediaScreenBloc {
  bool? _changed;

  // Initialize the stream for media screen state
  MediaScreenBloc() {
    _actionController.stream.listen(_changeStream);
  }

  bool? getCurrentValue() {
    return _changed;
  }

  // sets false as default value
  final _downloadsStream = BehaviorSubject<bool?>.seeded(false);
  // returns the stream to update anything based on values changed
  Stream get mediaScreenStream => _downloadsStream.stream;
  Sink get _addValue => _downloadsStream.sink;

  final StreamController _actionController = StreamController();
  // call the function changeMediaScreenState.add(value) to change the value
  StreamSink get changeMediaScreenState => _actionController.sink;

  void _changeStream(dynamic data) {
    if (data == null) {
      _changed = false;
    } else {
      _changed = data;
    }
    _addValue.add(_changed);
  }

  void dispose() {
    _downloadsStream.close();
    _actionController.close();
  }
}
