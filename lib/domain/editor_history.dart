class EditorHistory<T> {
  EditorHistory({required T initialValue, this.limit = 20})
    : assert(limit > 0),
      _value = initialValue;

  final int limit;
  final List<T> _undo = [];
  final List<T> _redo = [];
  T _value;

  T get value => _value;
  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  void push(T next) {
    _undo.add(_value);
    if (_undo.length > limit) {
      _undo.removeAt(0);
    }
    _value = next;
    _redo.clear();
  }

  T undo() {
    if (!canUndo) return _value;
    _redo.add(_value);
    _value = _undo.removeLast();
    return _value;
  }

  T redo() {
    if (!canRedo) return _value;
    _undo.add(_value);
    _value = _redo.removeLast();
    return _value;
  }
}
