import 'dart:async';

class PubSubQueue<T> {
  final List<T> _queue = [];
  final List<StreamController<T>> _subscribers = [];

  void publish(T message) {
    if (_subscribers.isEmpty) {
      _queue.add(message);
    } else {
      for (var subscriber in _subscribers) {
        subscriber.add(message);
      }
    }
  }

  Stream<T> subscribe() {
    StreamController<T> controller = StreamController<T>.broadcast();
    controller.onListen = () {
      _subscribers.add(controller);
      while (controller.hasListener && _queue.isNotEmpty) {
        var message = _queue.removeLast();
        if (message == null) {
          break;
        }
        controller.add(message);
      }
    };
    controller.onCancel = () {
      _subscribers.remove(controller);
    };
    return controller.stream;
  }
}
