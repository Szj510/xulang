import 'dart:math' as math;

import 'package:flutter/widgets.dart';

double orbitPlaneRotation(Size viewport) =>
    viewport.height >= viewport.width ? -.08 : -.06;

int orbitRingCount(int itemCount) {
  if (itemCount <= 1) return 0;
  return itemCount <= 7 ? 1 : 2;
}

Size orbitRadii(Size viewport, {required bool outer}) {
  final portrait = viewport.height >= viewport.width;
  if (portrait) {
    return Size(
      viewport.width * (outer ? .44 : .34),
      viewport.height * (outer ? .16 : .06),
    );
  }
  return Size(
    viewport.width * (outer ? .43 : .34),
    viewport.height * (outer ? .30 : .14),
  );
}

Offset orbitPoint({
  required Offset center,
  required double radiusX,
  required double radiusY,
  required double angle,
  required double planeRotation,
}) {
  final x = math.cos(angle) * radiusX;
  final y = math.sin(angle) * radiusY;
  final cosine = math.cos(planeRotation);
  final sine = math.sin(planeRotation);
  return center + Offset(x * cosine - y * sine, x * sine + y * cosine);
}

double orbitAngleForPoint({
  required Offset point,
  required Offset center,
  required double radiusX,
  required double radiusY,
  required double planeRotation,
}) {
  final delta = point - center;
  final cosine = math.cos(planeRotation);
  final sine = math.sin(planeRotation);
  final localX = delta.dx * cosine + delta.dy * sine;
  final localY = -delta.dx * sine + delta.dy * cosine;
  return math.atan2(localY / radiusY, localX / radiusX);
}
