/// Effortless isolates abstraction layer.
///
/// **What's an isolate?**
///
/// In the words of the [Dart documentation](https://api.dartlang.org/stable/2.4.1/dart-isolate/dart-isolate-library.html)
/// itself, isolates are:
///
/// > Independent workers that are similar to threads but don't share
/// > memory, communicating only via messages.
///
/// In short, Dart is a single-threaded language, but it has support for
/// concurrent execution of code through these so-called isolates.
///
/// This means that you can use isolates to execute code you want to run
/// alongside your main thread, which is particularly useful for keeping
/// your Flutter application running smoothly.
///
/// For more detailed information, please
/// [read this excellent article](https://www.didierboelens.com/2019/01/futures---isolates---event-loop/)
/// by Didier Boelens.
///
/// **Using Isolate Handler**
///
/// Spawning an isolate with Isolate Handler is really simple:
///
/// ```dart
/// IsolateHandler().spawn(entryPoint);
/// ```
///
/// This is similar to how isolates are spawned normally, with the exception
/// that Isolate Handler does not expect a message parameter, only an entry
/// point. Messaging has been abstracted away and a communications channel
/// is instead opened automatically.
///
/// **Communicating with an isolate**
///
/// ```dart
/// final isolates = IsolateHandler();
/// int counter = 0;
///
/// void main() {
///   // Start a listener for ints sent from the isolate
///   isolates.spawn<int>(entryPoint,
///     name: "counter",
///     // Executed every time data is received from the spawned isolate.
///     onReceive: setCounter,
///     // Executed once when spawned isolate is ready for communication.
///     onInitialized: () => isolates.send(counter, to: "counter"),
///   );
/// }
///
/// // Set new count and display current count
/// void setCounter(int count) {
///   counter = count;
///   print("Counter is now $counter");
///
///   // We will no longer be needing the isolate, let's dispose of it
///   isolates.kill("counter");
/// }
///
/// // This function happens in the isolate.
/// void entryPoint(Map<String, dynamic> context) {
///   // Calling initialize from the entry point with the context is
///   // required if communication is desired. It returns a messenger which
///   // allows listening and sending information to the main isolate.
///   final messenger = HandledIsolate.initialize(context);
///
///   // Triggered every time data is received from the main isolate.
///   messenger.listen((count) async {
///    // Add one to the count and send the new value back to the main
///    // isolate.
///    messenger.send(++count);
///   });
/// }
/// ```
library isolate_handler;

import 'dart:isolate';

import 'src/handled_isolate.dart';

export 'src/handled_isolate.dart';
export 'src/handled_isolate_messenger.dart';

/// High-level isolate handler for Flutter.
///
/// High-level interface for spawning, interacting with and destroying
/// [FlutterIsolate] instances.
class IsolateHandler {
  final _isolates = <String, HandledIsolate>{};
  int _uid = 0;

  IsolateHandler();

  /// Map of all spawned isolates.
  Map<String, HandledIsolate> get isolates => _isolates;

  /// Spawns a new [HandledIsolate] of type `T` (`dynamic` by default) with an
  /// entry point of `function`. Note that because of the limitations of the
  /// underlying messaging mechanism of `SendPort.send()`, the list of
  /// allowed types is limited: "The content of message can be: primitive values
  /// (null, num, bool, double, String), instances of SendPort, and lists and maps
  /// whose elements are any of these. List and maps are also allowed to be cyclic."
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
  /// [function] is called by the isolate immediately upon creation, before
  /// communication channels have been fully established.
  ///
  /// If the [onReceive] function parameter is provided, it will be called every
  /// time a new message has been received from the spawned isolate. The
  /// function should be able to be called with a single argument, which will
  /// contain data of type T received from the isolate.
  ///
  /// If the function argument [onInitialized] is specified, it will be called
  /// once communication channels have been established, meaning that the
  /// [HandledIsolate] instance is ready to send and receive data.
  ///
  /// The [name] parameter specifies a unique name by which the isolate can be
  /// recalled later from the handler. If no name has been given to an isolate
  /// it will receive a generated name with a prefix of `__anonymous_` followed
  /// by a number. Avoiding names using the same format is good practice. Must
  /// be unique.
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
  /// If [debugName] is provided, the spawned [FlutterIsolate] will be identifiable by
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
  /// Throws if `name` is not unique.
  ///
  /// Returns spawned [HandledIsolate] instance.
  @pragma('vm:entry-point')
  HandledIsolate spawn<T>(
    void Function(Map<String, dynamic>) function, {
    String? name,
    void Function(T message)? onReceive,
    void Function()? onInitialized,
    bool paused = false,
    bool? errorsAreFatal,
    SendPort? onExit,
    SendPort? onError,
    String? debugName,
  }) {
    assert(name == null || !isolates.containsKey(name));

    name ??= '__anonymous_${_uid++}';
    isolates[name] = HandledIsolate<T>(
        name: name, function: function, onInitialized: onInitialized);
    isolates[name]!
        .messenger
        .listen((dynamic message) => onReceive?.call(message));
    return isolates[name]!;
  }

  /// Send message to a spawned isolate.
  ///
  /// `message` must have a type corresponding to the type passed to `spawn` if
  /// dynamic was not used. May not be null.
  ///
  /// `to` must be either a [String] containing the name of an existing isolate
  /// or a [HandledIsolate] returned by the `spawn` function. May not be null.
  ///
  /// Throws if `to` or `message` are null.
  void send(dynamic message, {required dynamic to}) {
    assert(to != null);
    assert(message != null);

    if (to is String) {
      assert(isolates.containsKey(to));
      isolates[to]!.messenger.send(message);
    } else if (to is HandledIsolate) {
      to.messenger.send(message);
    } else {
      throw TypeError();
    }
  }

  /// Dispose of isolate.
  ///
  /// Takes name of isolate as given to `spawn`.
  void kill(String name, {int priority = Isolate.beforeNextEvent}) {
    isolates[name]?.dispose(priority: priority);
    isolates.remove(name);
  }
}
