import 'package:flutter/widgets.dart';

enum GalleryGesture { undecided, horizontal, vertical, pan }

class GestureDirectionLock {
  static const double _intentThreshold = 8;

  GalleryGesture _gesture = GalleryGesture.undecided;
  Offset _accumulated = Offset.zero;

  GalleryGesture get gesture => _gesture;

  void begin({required double scale}) {
    _accumulated = Offset.zero;
    _gesture = scale > 1.01 ? GalleryGesture.pan : GalleryGesture.undecided;
  }

  GalleryGesture update(Offset delta, {required double scale}) {
    if (_gesture != GalleryGesture.undecided) return _gesture;
    if (scale > 1.01) {
      _gesture = GalleryGesture.pan;
      return _gesture;
    }
    _accumulated += delta;
    if (_accumulated.distance < _intentThreshold) {
      return _gesture;
    }
    _gesture = _accumulated.dx.abs() > _accumulated.dy.abs()
        ? GalleryGesture.horizontal
        : GalleryGesture.vertical;
    return _gesture;
  }

  void end() {
    _accumulated = Offset.zero;
    _gesture = GalleryGesture.undecided;
  }
}
