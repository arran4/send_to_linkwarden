import 'dart:async';

class KeyedPubSubReplay<K, T> {
  final Map<K, T> _lastMessage = <K, T>{};
  K _currentKey;
  final List<StreamController<T>> _subscribers = [];
  void Function(KeyedPubSubReplay<K, T> queue, T currentKey)? _onNoLastMessage;

  KeyedPubSubReplay({required K currentKey, void Function(KeyedPubSubReplay<K, T> queue, T currentKey)? onNoLastMessage})
      : _onNoLastMessage = onNoLastMessage, _currentKey = currentKey;

  get currentKey {
    return _currentKey;
  }

  set currentKey(newValue) {
    _currentKey = newValue;
    _checkAndInitialize();
  }

  void _checkAndInitialize() {
    if (_lastMessage.containsKey(currentKey)) {
      publish(_lastMessage[currentKey] as T, keyCheck: currentKey);
    } else {
      _onNoLastMessage?.call(this, currentKey);
    }
  }

  void publish(T message, { K? keyCheck}) {
    if (keyCheck != null && currentKey != keyCheck) {
      _lastMessage[keyCheck] = message;
      return;
    }
    _lastMessage[currentKey] = message;
    for (var subscriber in _subscribers) {
      subscriber.add(message);
    }
  }

  Stream<T> subscribe() {
    StreamController<T> controller = StreamController<T>.broadcast();
    controller.onListen = () {
      _checkAndInitialize();
    };
    _subscribers.add(controller);

    controller.onCancel = () {
      _subscribers.remove(controller);
    };
    return controller.stream;
  }
}
