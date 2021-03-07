import 'dart:isolate';

import 'package:flutter_isolate/flutter_isolate.dart';

import 'handled_isolate_messenger.dart';

/// Instance of [FlutterIsolate] handled by [HandledIsolate].
class HandledIsolate<T> {
  final HandledIsolateMessenger _messenger;
  late final FlutterIsolate _isolate;
  final String _name;

  /// Instance of Dart [FlutterIsolate] handled by this instance.
  ///
  /// Must be initialized by a call to constructor before use.
  FlutterIsolate get isolate => _isolate;

  /// Capability granting the ability to pause the isolate.
  ///
  /// This capability is required by [pause].
  /// If the capability is `null`, or if it is not the correct pause capability
  /// of the isolate identified by [controlPort],
  /// then calls to [pause] will have no effect.
  ///
  /// If the isolate is spawned in a paused state, use this capability as
  /// argument to the [resume] method in order to resume the paused isolate.
  Capability? get pauseCapability => isolate.pauseCapability;

  /// Unique name used by [IsolateHandler] to identify isolate.
  String get name => _name;

  /// Instance of [HandledIsolateMessenger] communication channel.
  HandledIsolateMessenger get messenger => _messenger;

  /// Create a new instance of [HandledIsolate].
  ///
  /// Spawns a new [HandledIsolate] with an entry point of `function`.
  ///
  /// The argument [function] specifies the initial function to call in the
  /// spawned isolate. The entry-point function is invoked in the new isolate
  /// with [context] as the only argument.
  ///
  /// The function must be a top-level function or a static method that can be
  /// called with a single argument, that is, a compile-time constant function
  /// value which accepts at least one positional parameter and has at most one
  /// required positional parameter.
  ///
  /// The function may accept any number of optional parameters, as long as it
  /// *can* be called with just a single argument. The function must not be the
  /// value of a function expression or an instance method tear-off.
  ///
  /// [name] is used by [IsolateHandler] to identify the isolate. It can be any
  /// `String`, but must not be null.
  ///
  /// [function] is called by the isolate immediately upon creation, before
  /// communication channels have been fully established.
  ///
  /// If the function argument [onInitialized] is specified, it will be called
  /// once communication channels have been established, meaning that the
  /// [HandledIsolate] instance is ready to send and receive data.
  ///
  /// If the [paused] parameter is set to `true`, the isolate will start up in
  /// a paused state, just before calling the [function] function with the
  /// [context], as if by an initial call of
  /// `isolate.pause(isolate.pauseCapability)`. To resume the isolate,
  /// call `isolate.resume(isolate.pauseCapability)`.
  ///
  /// If the [errorsAreFatal], [onExit] and/or [onError] parameters are
  /// provided, the isolate will act as if, respectively, [setErrorsFatal],
  /// [addOnExitListener] and [addErrorListener] were called with the
  /// corresponding parameter and was processed before the isolate starts
  /// running.
  ///
  /// If [debugName] is provided, the spawned [Isolate] will be identifiable by
  /// this name in debuggers and logging.
  ///
  /// If [errorsAreFatal] is omitted, the platform may choose a default behavior
  /// or inherit the current isolate's behavior.
  ///
  /// You can also call the [setErrorsFatal], [addOnExitListener] and
  /// [addErrorListener] methods directly by accessing `isolate`, but unless the
  /// isolate was started as [paused], it may already have terminated before
  /// those methods can complete.
  ///
  /// Isolates need to be disposed of using `kill` when done using them.
  ///
  /// Returns spawned [HandledIsolate] instance.
  HandledIsolate({
    required String name,
    required void Function(Map<String, dynamic>) function,
    void Function()? onInitialized,
    bool paused = false,
    bool? errorsAreFatal,
    SendPort? onExit,
    SendPort? onError,
    String? debugName,
  })  : _messenger = HandledIsolateMessenger(onInitialized: onInitialized),
        _name = name {
    _init(
      function,
      paused: paused,
      errorsAreFatal: errorsAreFatal,
      onExit: onExit,
      onError: onError,
      debugName: debugName,
    );
  }

  /// Establishes communication channels between this instance and `context`.
  ///
  /// Returns main communication channel.
  static HandledIsolateMessenger initialize(Map<String, dynamic> context) {
    final messenger = context['messenger'] as SendPort;
    final msg = HandledIsolateMessenger(remotePort: messenger);
    messenger.send(msg.inPort.sendPort);
    return msg;
  }

  /// Creates a [context] for this handled isolate, then spawns
  /// and returns the [FlutterIsolate].
  ///
  /// The argument [function] specifies the initial function to call in the
  /// spawned isolate. The entry-point function is invoked in the new isolate
  /// with [context] as the only argument.
  ///
  /// The function must be a top-level function or a static method that can be
  /// called with a single argument, that is, a compile-time constant function
  /// value which accepts at least one positional parameter and has at most one
  /// required positional parameter.
  ///
  /// The function may accept any number of optional parameters, as long as it
  /// *can* be called with just a single argument. The function must not be the
  /// value of a function expression or an instance method tear-off.
  ///
  /// If the [paused] parameter is set to `true`, the isolate will start up in
  /// a paused state, just before calling the [function] function with the
  /// [context], as if by an initial call of
  /// `isolate.pause(isolate.pauseCapability)`. To resume the isolate,
  /// call `isolate.resume(isolate.pauseCapability)`.
  ///
  /// If the [errorsAreFatal], [onExit] and/or [onError] parameters are
  /// provided, the isolate will act as if, respectively, [setErrorsFatal],
  /// [addOnExitListener] and [addErrorListener] were called with the
  /// corresponding parameter and was processed before the isolate starts
  /// running.
  ///
  /// If [debugName] is provided, the spawned [Isolate] will be identifiable by
  /// this name in debuggers and logging.
  ///
  /// If [errorsAreFatal] is omitted, the platform may choose a default behavior
  /// or inherit the current isolate's behavior.
  ///
  /// You can also call the [setErrorsFatal], [addOnExitListener] and
  /// [addErrorListener] methods directly by accessing `isolate`, but unless the
  /// isolate was started as [paused], it may already have terminated before
  /// those methods can complete.
  void _init(
    /// Entry point of the [Isolate]. Must be a top-level or static function.
    /// Passed to constructor. May not be null.
    Function(Map<String, dynamic>) function, {
    bool paused = false,
    bool? errorsAreFatal,
    SendPort? onExit,
    SendPort? onError,
    String? debugName,
  }) async {
    final message = {
      'messenger': messenger.outPort,
      'name': name,
    };
    _isolate = await FlutterIsolate.spawn(function, message);
  }

  /// Requests the isolate to pause.
  ///
  /// When the isolate receives the pause command, it stops
  /// processing events from the event loop queue.
  /// It may still add new events to the queue in response to, e.g., timers
  /// or receive-port messages. When the isolate is resumed,
  /// it starts handling the already enqueued events.
  ///
  /// The pause request is sent through the isolate's command port,
  /// which bypasses the receiving isolate's event loop.
  /// The pause takes effect when it is received, pausing the event loop
  /// as it is at that time.
  ///
  /// The [resumeCapability] is used to identity the pause,
  /// and must be used again to end the pause using [resume].
  /// If [resumeCapability] is omitted, a new capability object is created
  /// and used instead.
  ///
  /// If an isolate is paused more than once using the same capability,
  /// only one resume with that capability is needed to end the pause.
  ///
  /// If an isolate is paused using more than one capability,
  /// each pause must be individually ended before the isolate resumes.
  ///
  /// Returns the capability that must be used to end the pause.
  /// This is either [resumeCapability], or a new capability when
  /// [resumeCapability] is omitted.
  ///
  /// If [pauseCapability] is `null`, or it's not the pause capability
  /// of the isolate identified by [controlPort],
  /// the pause request is ignored by the receiving isolate.
  void pause([Capability? resumeCapability]) {
    isolate.pause();
  }

  /// Resumes a paused isolate.
  ///
  /// Sends a message to an isolate requesting that it ends a pause
  /// that was previously requested.
  ///
  /// When all active pause requests have been cancelled, the isolate
  /// will continue processing events and handling normal messages.
  ///
  /// If the [resumeCapability] is not one that has previously been used
  /// to pause the isolate, or it has already been used to resume from
  /// that pause, the resume call has no effect.
  void resume([Capability? resumeCapability]) {
    isolate.resume();
  }

  /// Disposes of the [Isolate] instance.
  ///
  /// Kills isolate and disposes ports used for communication.
  void dispose() {
    _isolate.kill();

    _messenger.dispose();
  }
}
