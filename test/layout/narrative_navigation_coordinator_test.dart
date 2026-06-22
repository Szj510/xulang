import 'package:flutter_test/flutter_test.dart';
import 'package:xulang/layout/gesture_direction_lock.dart';
import 'package:xulang/layout/narrative_axis.dart';
import 'package:xulang/layout/narrative_navigation_coordinator.dart';

void main() {
  late NarrativeNavigationCoordinator coordinator;

  setUp(() => coordinator = NarrativeNavigationCoordinator());

  test('does not hand off when a vertical gesture starts before the end', () {
    coordinator.begin(progress: .8, axis: NarrativeAxis.vertical, itemCount: 3);

    expect(
      coordinator.update(const Offset(0, -90), GalleryGesture.vertical),
      ChapterNavigationIntent.none,
    );
  });

  test('hands off to next once after accumulated drag from the end', () {
    coordinator.begin(progress: 1, axis: NarrativeAxis.vertical, itemCount: 3);

    expect(
      coordinator.update(const Offset(0, -40), GalleryGesture.vertical),
      ChapterNavigationIntent.none,
    );
    expect(
      coordinator.update(const Offset(0, -20), GalleryGesture.vertical),
      ChapterNavigationIntent.next,
    );
    expect(
      coordinator.update(const Offset(0, -80), GalleryGesture.vertical),
      ChapterNavigationIntent.none,
    );
  });

  test('hands off to previous from the start boundary', () {
    coordinator.begin(progress: 0, axis: NarrativeAxis.vertical, itemCount: 3);

    expect(
      coordinator.update(const Offset(0, 60), GalleryGesture.vertical),
      ChapterNavigationIntent.previous,
    );
  });

  test('landscape vertical swipes navigate at any progress', () {
    coordinator.begin(
      progress: .4,
      axis: NarrativeAxis.horizontal,
      itemCount: 3,
    );
    expect(
      coordinator.update(const Offset(0, -60), GalleryGesture.vertical),
      ChapterNavigationIntent.next,
    );

    coordinator.begin(
      progress: .4,
      axis: NarrativeAxis.horizontal,
      itemCount: 3,
    );
    expect(
      coordinator.update(const Offset(0, 60), GalleryGesture.vertical),
      ChapterNavigationIntent.previous,
    );
    expect(
      coordinator.update(const Offset(0, 60), GalleryGesture.vertical),
      ChapterNavigationIntent.none,
    );
  });

  test('single-item narratives arm next at their shared boundary', () {
    coordinator.begin(progress: 0, axis: NarrativeAxis.vertical, itemCount: 1);

    expect(
      coordinator.update(const Offset(0, -60), GalleryGesture.vertical),
      ChapterNavigationIntent.next,
    );
  });

  test('single-item narratives also arm previous at their shared boundary', () {
    coordinator.begin(progress: 0, axis: NarrativeAxis.vertical, itemCount: 1);

    expect(
      coordinator.update(const Offset(0, 60), GalleryGesture.vertical),
      ChapterNavigationIntent.previous,
    );
  });

  test('wrong direction and unowned gestures do not navigate', () {
    coordinator.begin(progress: 1, axis: NarrativeAxis.vertical, itemCount: 3);

    expect(
      coordinator.update(const Offset(0, 60), GalleryGesture.vertical),
      ChapterNavigationIntent.none,
    );
    expect(
      coordinator.update(const Offset(60, 0), GalleryGesture.horizontal),
      ChapterNavigationIntent.none,
    );
    expect(
      coordinator.update(const Offset(0, -60), GalleryGesture.undecided),
      ChapterNavigationIntent.none,
    );
    expect(
      coordinator.update(const Offset(0, -60), GalleryGesture.pan),
      ChapterNavigationIntent.none,
    );
  });

  test('end clears movement but only begin rearms dispatch', () {
    coordinator.begin(progress: 1, axis: NarrativeAxis.vertical, itemCount: 3);
    expect(
      coordinator.update(const Offset(0, -60), GalleryGesture.vertical),
      ChapterNavigationIntent.next,
    );

    coordinator.end();
    expect(
      coordinator.update(const Offset(0, -60), GalleryGesture.vertical),
      ChapterNavigationIntent.none,
    );

    coordinator.begin(progress: 0, axis: NarrativeAxis.vertical, itemCount: 3);
    expect(
      coordinator.update(const Offset(0, 60), GalleryGesture.vertical),
      ChapterNavigationIntent.previous,
    );
  });
}
