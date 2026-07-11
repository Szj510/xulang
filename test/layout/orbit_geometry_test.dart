import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xulang/domain/gallery_document.dart';
import 'package:xulang/layout/orbit_geometry.dart';

void main() {
  test('orbit point and angle conversion share the tilted plane', () {
    const viewport = Size(390, 844);
    const center = Offset(195, 413);
    const angle = .72;
    final rotation = orbitPlaneRotation(viewport);
    final point = orbitPoint(
      center: center,
      radiusX: 140,
      radiusY: 290,
      angle: angle,
      planeRotation: rotation,
    );

    expect(rotation, lessThan(0));
    expect(
      orbitAngleForPoint(
        point: point,
        center: center,
        radiusX: 140,
        radiusY: 290,
        planeRotation: rotation,
      ),
      closeTo(angle, .000001),
    );
    expect(point.dx, isNot(closeTo(center.dx + 140 * .752, .5)));
  });

  test('portrait orbit uses a stronger plane tilt than landscape', () {
    expect(
      orbitPlaneRotation(const Size(390, 844)).abs(),
      greaterThan(orbitPlaneRotation(const Size(844, 390)).abs()),
    );
  });

  test('orbit adds the second ring only after six satellites', () {
    expect(orbitRingCount(1), 0);
    expect(orbitRingCount(2), 1);
    expect(orbitRingCount(7), 1);
    expect(orbitRingCount(8), 2);
    expect(orbitRingCount(maxGalleryPlacementsPerChapter), 2);
  });
}
