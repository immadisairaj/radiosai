import 'dart:async';
import 'package:rxdart/rxdart.dart';

class PlayingBloc {
  bool _playing;

  PlayingBloc(bool value) {
    _actionController.stream.listen(_changeStream);
  }

  final _playingStream = BehaviorSubject<bool>.seeded(false);
  Stream get playingStream => _playingStream.stream;
  Sink get _addValue => _playingStream.sink;

  StreamController _actionController = StreamController();
  void get resetCount => _actionController.sink.add(null);
  StreamSink get changePlayingState => _actionController.sink;

  void _changeStream(data) async {
    if (data == null) {
      _playing = false;
    } else {
      _playing = data;
    }
    _addValue.add(_playing);
  }

  void dispose() {
    _playingStream.close();
    _actionController.close();
  }
}