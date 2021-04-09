import 'dart:async';
import 'package:rxdart/rxdart.dart';

class LoadingStreamBloc {
  bool _loading;

  LoadingStreamBloc(bool value) {
    _actionController.stream.listen(_changeStream);
  }

  final _loadingStream = BehaviorSubject<bool>.seeded(false);
  Stream get loadingStream => _loadingStream.stream;
  Sink get _addValue => _loadingStream.sink;

  StreamController _actionController = StreamController();
  StreamSink get changeLoadingState => _actionController.sink;

  void _changeStream(data) async {
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