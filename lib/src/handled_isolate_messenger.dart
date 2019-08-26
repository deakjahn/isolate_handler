import 'dart:async';

import 'dart:isolate';

/// Communication channel for sending data between [HandledIsolate] instances.
class HandledIsolateMessenger<T> {
  /// Called in `connectTo` once `_sendPortOverride` has been set.
  final void Function() _onEstablishedConnection;

  /// Messenger port used for communication between isolates.
  final ReceivePort _port = ReceivePort();

  /// Acts as preferred [SendPort] when set.
  SendPort _sendPortOverride;

  /// True after instance has traded `sendPort`s with another instance.
  bool _connectionEstablished = false;

  /// Broadcast stream of `inPort`.
  Stream<T> _broadcast;

  /// Port through which [HandledIsolateMessenger] receives data.
  ReceivePort get inPort => _port;

  /// Port through which data is sent to the connected [HandledIsolateMessenger]
  /// instance.
  SendPort get outPort => _sendPortOverride ?? _port.sendPort;

  /// True after instance has traded `sendPort`s with another instance.
  bool get connectionEstablished => _connectionEstablished;

  /// Broadcast stream of `inPort`.
  Stream<T> get broadcast => _broadcast;

  /// Communication channel for sending data between [HandledIsolate] instances.
  ///
  /// If `remotePort` is set, connects this instance's `outPort` to it.
  HandledIsolateMessenger({SendPort remotePort, void Function() onInitialized})
      : _onEstablishedConnection = onInitialized {
    _broadcast = _port.asBroadcastStream();
    if (remotePort != null) {
      connectTo(remotePort);
    }
  }

  /// Connect this instance to the given [SendPort].
  ///
  /// Overrides the default `outPort` of this messenger with the supplied one.
  /// Calls `_onEstablishedConnection` after port has been overridden.
  ///
  /// `sendPort` must not be null.
  void connectTo(SendPort sendPort) {
    assert(sendPort != null);
    _sendPortOverride = sendPort;

    if (_onEstablishedConnection != null) {
      _onEstablishedConnection();
    }

    _connectionEstablished = true;
  }

  /// Send a message to the connected [HandledIsolate] instance.
  void send(T message) {
    outPort.send(message);
  }

  /// Intermediary message handler.
  ///
  /// Listens for [SendPort] messages and intercepts them to establish
  /// connection to the sender. Otherwise passes the data on to `onData`.
  ///
  /// Throws if `onData` is null.
  void _listenResponse(dynamic message, void Function(T) onData) {
    assert(onData != null);
    if (_sendPortOverride == null && message is SendPort) {
      connectTo(message);
    } else {
      onData(message);
    }
  }

  /// Returns a [StreamSubscription] which returns messages from the connected
  /// [HandledIsolate] instance.
  ///
  /// Note that `onError` and `cancelOnError` are ignored since a [ReceivePort]
  /// will never receive an error.
  ///
  /// The `onDone` handler will be called when the stream closes.
  /// The stream closes when `close` is called on `inPort`.
  StreamSubscription<T> listen(void onData(var message),
          {Function onError, void onDone(), bool cancelOnError}) =>
      _port.listen((var message) => _listenResponse(message, onData),
          onError: onError, onDone: onDone, cancelOnError: cancelOnError);

  /// Disposes of the [HandledIsolateMessenger] by closing the receiving port.
  void dispose() {
    _port.close();
  }
}
