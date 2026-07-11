import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xulang/layout/canvas_transform.dart';

void main() {
  const viewport = Size(400, 800);

  test('button zoom keeps the visible canvas center anchored', () {
    final transform = scaleCanvasAroundViewportCenter(
      current: Matrix4.identity(),
      targetScale: 2,
      viewport: viewport,
    );

    expect(transform.getMaxScaleOnAxis(), 2);
    expect(transform.getTranslation().x, -200);
    expect(transform.getTranslation().y, -400);
  });

  test('zoomed canvas can pan to every original edge without overshooting', () {
    final topLeft = clampCanvasTransform(
      Matrix4.identity()
        ..scaleByDouble(2, 2, 1, 1)
        ..setTranslationRaw(500, 900, 0),
      viewport,
    );
    final bottomRight = clampCanvasTransform(
      Matrix4.identity()
        ..scaleByDouble(2, 2, 1, 1)
        ..setTranslationRaw(-900, -1700, 0),
      viewport,
    );

    expect(topLeft.getTranslation().x, 0);
    expect(topLeft.getTranslation().y, 0);
    expect(bottomRight.getTranslation().x, -400);
    expect(bottomRight.getTranslation().y, -800);
  });

  test('incremental zoom preserves an existing pan position', () {
    final current = Matrix4.identity()
      ..scaleByDouble(2, 2, 1, 1)
      ..setTranslationRaw(-100, -200, 0);
    final transform = scaleCanvasAroundViewportCenter(
      current: current,
      targetScale: 3,
      viewport: viewport,
    );

    expect(transform.getTranslation().x, -250);
    expect(transform.getTranslation().y, -500);
  });
}
