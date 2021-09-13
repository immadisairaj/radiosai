import 'package:flutter/foundation.dart';

class LoadingNotifier extends ValueNotifier<LoadingState> {
  LoadingNotifier() : super(_initialValue);
  static const _initialValue = LoadingState.done;
}

enum LoadingState {
  loading,
  done,
}
