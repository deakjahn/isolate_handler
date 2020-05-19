import 'dart:isolate';

/// Context of [HandledIsolate].
///
/// Used to establish communication between isolates.
class HandledIsolateContext {
  /// Listening [SendPort] of [HandledIsolate], ready to accept a new
  /// `sendPort`. Free communications channel. Must not be null.
  final SendPort messenger;

  /// Name used by [IsolateHandler] to identify isolate.
  final String name;

  /// Context of [HandledIsolate].
  ///
  /// Used to establish communication between isolates.
  ///
  /// Throws if either `messenger` or `dataChannel` is null.
  HandledIsolateContext(

      /// Listening [SendPort] of [HandledIsolate], ready to accept a new
      /// `sendPort`. Used for free communications. Must not be null.
      this.messenger,
      this.name)
      : assert(messenger != null);
}
