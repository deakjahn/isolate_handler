import 'dart:isolate';

import 'package:flutter/services.dart';

/// Context of [HandledIsolate].
///
/// Used to establish communication between isolates.
class HandledIsolateContext {
  /// Listening [SendPort] of [HandledIsolate], ready to accept a new
  /// `sendPort`. Free communications channel. May not be null.
  final SendPort messenger;

  /// Listening [SendPort] of [HandledIsolate], ready to accept a new
  /// `sendPort`. Data communications channel. May not be null.
  final SendPort dataChannel;

  /// List of channels the isolate should intercept and pass to the main
  /// isolate.
  ///
  /// If access is needed to native code through channels in the isolate, the
  /// channels must be registered with the IsolateHandler first.
  final List<MethodChannel> channels;

  /// Name used by [IsolateHandler] to identify isolate.
  final String name;

  /// Context of [HandledIsolate].
  ///
  /// Used to establish communication between isolates.
  ///
  /// Throws if either `messenger` or `dataChannel` is null.
  HandledIsolateContext(

      /// Listening [SendPort] of [HandledIsolate], ready to accept a new
      /// `sendPort`. Used for free communications. May not be null.
      this.messenger,

      /// Listening [SendPort] of [HandledIsolate], ready to accept a new
      /// `sendPort`. Used for data sharing between isolates. May not be null.
      this.dataChannel,

      /// List of channels the isolate should intercept and pass to the main
      /// isolate.
      this.channels,
      this.name)
      : assert(messenger != null),
        assert(dataChannel != null);
}
