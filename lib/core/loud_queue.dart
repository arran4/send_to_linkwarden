import 'dart:async';

class LoudQueue<T> {
  List<T> _queue = [];
  final _controller = StreamController<int>.broadcast();

  Stream<int> get onQueueIncrement => _controller.stream;

  int get length => _queue.length;

  void enqueue(T item) {
    _queue.add(item);
    _controller.add(length);
  }

  T? dequeue() {
    if (_queue.isNotEmpty) {
      T item = _queue.removeAt(0);
      _controller.add(length);
      return item;
    } else {
      _controller.add(length);
      return null;
    }
  }

  void clear() {
    _queue.clear();
    _controller.add(length);
  }

  void dispose() {
    _controller.close();
  }
}
