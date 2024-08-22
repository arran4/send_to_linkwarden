import 'dart:async';

class IndividualKeyedPubSubReplayStream<K, T> implements Stream<T> {
  final Stream<T> _realStream;
  K _currentKey;
  final IndividualKeyedPubSubReplay<K, T> _parent;

  IndividualKeyedPubSubReplayStream(this._realStream, K currentKey, this._parent) : _currentKey = currentKey;

  K get currentKey {
    return _currentKey;
  }

  set currentKey(K newValue) {
    _parent.moveSubscription(_currentKey, newValue);
    _currentKey = newValue;
  }


  @override
  Future<bool> any(bool Function(T element) test) {
    return _realStream.any(test);
  }

  @override
  Stream<T> asBroadcastStream({void Function(StreamSubscription<T> subscription)? onListen, void Function(StreamSubscription<T> subscription)? onCancel}) {
    return _realStream.asBroadcastStream(onListen: onListen, onCancel: onCancel);
  }

  @override
  Stream<E> asyncExpand<E>(Stream<E>? Function(T event) convert) {
    return _realStream.asyncExpand(convert);
  }

  @override
  Stream<E> asyncMap<E>(FutureOr<E> Function(T event) convert) {
    return _realStream.asyncMap(convert);
  }

  @override
  Stream<R> cast<R>() {
    return _realStream.cast<R>();
  }

  @override
  Future<bool> contains(Object? needle) {
    return _realStream.contains(needle);
  }

  @override
  Stream<T> distinct([bool Function(T previous, T next)? equals]) {
    return _realStream.distinct(equals);
  }

  @override
  Future<E> drain<E>([E? futureValue]) {
    return _realStream.drain(futureValue);
  }

  @override
  Future<T> elementAt(int index) {
    return _realStream.elementAt(index);
  }

  @override
  Future<bool> every(bool Function(T element) test) {
    return _realStream.every(test);
  }

  @override
  Stream<S> expand<S>(Iterable<S> Function(T element) convert) {
    return _realStream.expand(convert);
  }

  @override
  Future<T> get first => _realStream.first;

  @override
  Future<T> firstWhere(bool Function(T element) test, {T Function()? orElse}) {
    return _realStream.firstWhere(test, orElse: orElse);
  }

  @override
  Future<S> fold<S>(S initialValue, S Function(S previous, T element) combine) {
    return _realStream.fold(initialValue, combine);
  }

  @override
  Future<void> forEach(void Function(T element) action) {
    return _realStream.forEach(action);
  }

  @override
  Stream<T> handleError(Function onError, {bool Function(dynamic error)? test}) {
    return _realStream.handleError(onError, test: test);
  }

  @override
  bool get isBroadcast => _realStream.isBroadcast;

  @override
  Future<bool> get isEmpty => _realStream.isEmpty;

  @override
  Future<String> join([String separator = ""]) {
    return _realStream.join(separator);
  }

  @override
  Future<T> get last => _realStream.last;

  @override
  Future<T> lastWhere(bool Function(T element) test, {T Function()? orElse}) {
    return _realStream.lastWhere(test, orElse: orElse);
  }

  @override
  Future<int> get length => _realStream.length;

  @override
  StreamSubscription<T> listen(void Function(T event)? onData, {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return _realStream.listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  @override
  Stream<S> map<S>(S Function(T event) convert) {
    return _realStream.map(convert);
  }

  @override
  Future pipe(StreamConsumer<T> streamConsumer) {
    return _realStream.pipe(streamConsumer);
  }

  @override
  Future<T> reduce(T Function(T previous, T element) combine) {
    return _realStream.reduce(combine);
  }

  @override
  Future<T> get single => _realStream.single;

  @override
  Future<T> singleWhere(bool Function(T element) test, {T Function()? orElse}) {
    return _realStream.singleWhere(test, orElse: orElse);
  }

  @override
  Stream<T> skip(int count) {
    return _realStream.skip(count);
  }

  @override
  Stream<T> skipWhile(bool Function(T element) test) {
    return _realStream.skipWhile(test);
  }

  @override
  Stream<T> take(int count) {
    return _realStream.take(count);
  }

  @override
  Stream<T> takeWhile(bool Function(T element) test) {
    return _realStream.takeWhile(test);
  }

  @override
  Stream<T> timeout(Duration timeLimit, {void Function(EventSink<T> sink)? onTimeout}) {
    return _realStream.timeout(timeLimit, onTimeout: onTimeout);
  }

  @override
  Future<List<T>> toList() {
    return _realStream.toList();
  }

  @override
  Future<Set<T>> toSet() {
    return _realStream.toSet();
  }

  @override
  Stream<S> transform<S>(StreamTransformer<T, S> streamTransformer) {
    return _realStream.transform(streamTransformer);
  }

  @override
  Stream<T> where(bool Function(T event) test) {
    return _realStream.where(test);
  }
}


class IndividualKeyedPubSubReplay<K, T> {
  final Map<K, T> _lastMessage = <K, T>{};
  final Map<K, List<StreamController<T>>> _subscribers = {};
  final void Function(IndividualKeyedPubSubReplay<K, T> queue, K currentKey)? _onNoLastMessage;

  IndividualKeyedPubSubReplay({required K currentKey, void Function(IndividualKeyedPubSubReplay<K, T> queue, K currentKey)? onNoLastMessage})
      : _onNoLastMessage = onNoLastMessage;

  void _checkAndInitialize({ required K currentKey, StreamController<T>? singleTarget }) {
    if (_lastMessage.containsKey(currentKey)) {
      publish(_lastMessage[currentKey] as T, currentKey: currentKey, singleTarget: singleTarget);
    } else {
      _onNoLastMessage?.call(this, currentKey);
    }
  }

  void reset(K key) {
    _lastMessage.remove(key);
    _checkAndInitialize(currentKey: key);
  }

  void publish(T message, { required K currentKey, StreamController<T>? singleTarget }) {
    _lastMessage[currentKey] = message;
    if (singleTarget != null) {
      singleTarget.add(message);
    }
    if (_subscribers.containsKey(currentKey)) {
      for (StreamController<T> subscriber in _subscribers[currentKey]!) {
        subscriber.add(message);
      }
    }
  }

  IndividualKeyedPubSubReplayStream<K, T> subscribe({required K initialKey}) {
    StreamController<T> controller = StreamController<T>.broadcast();
    controller.onListen = () {
      _checkAndInitialize(currentKey: initialKey, singleTarget: controller);
    };
    if (!_subscribers.containsKey(initialKey)) {
      _subscribers[initialKey] = [controller];
    }
    _subscribers[initialKey]!.add(controller);
    IndividualKeyedPubSubReplayStream<K, T> stream = IndividualKeyedPubSubReplayStream<K, T>(controller.stream, initialKey, this);
    controller.onCancel = () {
      _subscribers.remove(controller);
    };
    return stream;
  }

  void moveSubscription(K currentKey, K newValue, ) {}
}
