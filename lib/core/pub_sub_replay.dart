import 'dart:async';

class PubSubReplay<T> {
  T? _lastMessage;
  final List<StreamController<T>> _subscribers = [];
  void Function(PubSubReplay<T> queue)? _onNoLastMessage;

  PubSubReplay({void Function(PubSubReplay<T> queue)? onNoLastMessage})
      : _onNoLastMessage = onNoLastMessage;

  void publish(T message) {
    _lastMessage = message;
    for (var subscriber in _subscribers) {
      subscriber.add(message);
    }
  }

  Stream<T> subscribe() {
    StreamController<T> controller = StreamController<T>.broadcast();
    controller.onListen = () {
      if (_lastMessage != null) {
        controller.add(_lastMessage!);
      } else {
        _onNoLastMessage?.call(this);
        _onNoLastMessage = null;
      }
    };
    _subscribers.add(controller);

    controller.onCancel = () {
      _subscribers.remove(controller);
    };
    return controller.stream;
  }
}
