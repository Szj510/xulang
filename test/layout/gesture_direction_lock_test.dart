import 'package:flutter_test/flutter_test.dart';
import 'package:xulang/layout/gesture_direction_lock.dart';

void main() {
  test('waits for intent then locks horizontal movement', () {
    final lock = GestureDirectionLock();
    lock.begin(scale: 1);

    expect(lock.update(const Offset(3, 2), scale: 1), GalleryGesture.undecided);
    expect(
      lock.update(const Offset(12, 3), scale: 1),
      GalleryGesture.horizontal,
    );
    expect(
      lock.update(const Offset(0, 30), scale: 1),
      GalleryGesture.horizontal,
    );
  });

  test('locks vertical movement for chapter navigation', () {
    final lock = GestureDirectionLock();
    lock.begin(scale: 1);

    expect(lock.update(const Offset(2, 14), scale: 1), GalleryGesture.vertical);
  });

  test('zoomed content always reserves one-finger movement for panning', () {
    final lock = GestureDirectionLock();
    lock.begin(scale: 1.4);

    expect(lock.update(const Offset(30, 2), scale: 1.4), GalleryGesture.pan);
  });

  test('a new gesture resets the previous direction', () {
    final lock = GestureDirectionLock();
    lock.begin(scale: 1);
    lock.update(const Offset(20, 1), scale: 1);
    lock.end();
    lock.begin(scale: 1);

    expect(lock.update(const Offset(1, 20), scale: 1), GalleryGesture.vertical);
  });
}
