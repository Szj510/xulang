import 'package:flutter/widgets.dart';

Matrix4 scaleCanvasAroundViewportCenter({
  required Matrix4 current,
  required double targetScale,
  required Size viewport,
}) {
  final currentScale = current.getMaxScaleOnAxis().clamp(1.0, 3.0);
  final nextScale = targetScale.clamp(1.0, 3.0);
  final translation = current.getTranslation();
  final center = Offset(viewport.width / 2, viewport.height / 2);
  final ratio = nextScale / currentScale;
  final next = Matrix4.identity()
    ..setEntry(0, 0, nextScale)
    ..setEntry(1, 1, nextScale)
    ..setTranslationRaw(
      center.dx - (center.dx - translation.x) * ratio,
      center.dy - (center.dy - translation.y) * ratio,
      0,
    );
  return clampCanvasTransform(next, viewport);
}

Matrix4 clampCanvasTransform(Matrix4 transform, Size viewport) {
  final scale = transform.getMaxScaleOnAxis().clamp(1.0, 3.0);
  final translation = transform.getTranslation();
  final minX = viewport.width * (1 - scale);
  final minY = viewport.height * (1 - scale);
  return Matrix4.identity()
    ..setEntry(0, 0, scale)
    ..setEntry(1, 1, scale)
    ..setTranslationRaw(
      translation.x.clamp(minX, 0.0),
      translation.y.clamp(minY, 0.0),
      0,
    );
}
