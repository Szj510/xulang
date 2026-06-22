import 'package:flutter_test/flutter_test.dart';
import 'package:xulang/domain/editor_history.dart';

void main() {
  test('undo and redo restore editor states', () {
    final history = EditorHistory<int>(initialValue: 0, limit: 20);

    history.push(1);
    history.push(2);

    expect(history.undo(), 1);
    expect(history.undo(), 0);
    expect(history.redo(), 1);
    expect(history.redo(), 2);
  });

  test('history retains at most twenty previous states', () {
    final history = EditorHistory<int>(initialValue: 0, limit: 20);

    for (var value = 1; value <= 25; value++) {
      history.push(value);
    }

    final undone = <int>[];
    while (history.canUndo) {
      undone.add(history.undo());
    }

    expect(undone, hasLength(20));
    expect(undone.last, 5);
  });

  test('pushing after undo clears the redo branch', () {
    final history = EditorHistory<int>(initialValue: 0, limit: 20);
    history.push(1);
    history.push(2);
    history.undo();

    history.push(9);

    expect(history.canRedo, isFalse);
    expect(history.value, 9);
  });
}
