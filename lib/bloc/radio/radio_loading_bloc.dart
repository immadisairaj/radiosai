import 'dart:async';
import 'package:rxdart/rxdart.dart';

class RadioLoadingBloc {
  bool _loading;

  // Initialize the stream for radio player loading state
  RadioLoadingBloc() {
    _actionController.stream.listen(_changeStream);
  }

  // sets false as default value
  final _loadingStream = BehaviorSubject<bool>.seeded(false);
  // returns the stream to update anything based on values changed
  Stream get radioLoadingStream => _loadingStream.stream;
  Sink get _addValue => _loadingStream.sink;

  StreamController _actionController = StreamController();
  // call the function changeLoadingState.add(value) to change the value
  StreamSink get changeLoadingState => _actionController.sink;

  void _changeStream(data) {
    if (data == null) {
      _loading = false;
    } else {
      _loading = data;
    }
    _addValue.add(_loading);
  }

  void dispose() {
    _loadingStream.close();
    _actionController.close();
  }
}
