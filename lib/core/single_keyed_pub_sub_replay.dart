import 'dart:async';

class SingleKeyedPubSubReplay<K, T> {
  final Map<K, T> _lastMessage = <K, T>{};
  K _currentKey;
  final List<StreamController<T>> _subscribers = [];
  final void Function(SingleKeyedPubSubReplay<K, T> queue, T currentKey)? _onNoLastMessage;

  SingleKeyedPubSubReplay({required K currentKey, void Function(SingleKeyedPubSubReplay<K, T> queue, T currentKey)? onNoLastMessage})
      : _onNoLastMessage = onNoLastMessage, _currentKey = currentKey;

  get currentKey {
    return _currentKey;
  }

  set currentKey(newValue) {
    _currentKey = newValue;
    _checkAndInitialize();
  }

  void _checkAndInitialize({ StreamController<T>? singleTarget }) {
    if (_lastMessage.containsKey(currentKey)) {
      publish(_lastMessage[currentKey] as T, keyCheck: currentKey, singleTarget: singleTarget);
    } else {
      _onNoLastMessage?.call(this, currentKey);
    }
  }

  void reset(K key) {
    _lastMessage.remove(key);
    if (currentKey == key) {
      _checkAndInitialize();
    }
  }

  void publish(T message, { K? keyCheck, StreamController<T>? singleTarget }) {
    if (keyCheck != null && currentKey != keyCheck) {
      _lastMessage[keyCheck] = message;
      return;
    }
    _lastMessage[currentKey] = message;
    if (singleTarget != null) {
      singleTarget.add(message);
    }
    for (var subscriber in _subscribers) {
      subscriber.add(message);
    }
  }

  Stream<T> subscribe() {
    StreamController<T> controller = StreamController<T>.broadcast();
    controller.onListen = () {
      _checkAndInitialize(singleTarget: controller);
    };
    _subscribers.add(controller);

    controller.onCancel = () {
      _subscribers.remove(controller);
    };
    return controller.stream;
  }
}
