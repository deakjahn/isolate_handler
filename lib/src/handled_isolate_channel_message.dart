import 'dart:typed_data';

/// Data container for sending information about intercepted [MethodChannel]
/// messages to the main isolate for handling.
class HandledIsolateChannelMessage {
  /// Name of the channel from which the message originated.
  final String channel;
  /// Data contained in the channel message.
  final ByteData data;
  /// Identifying name of source isolate.
  final String source;

  const HandledIsolateChannelMessage(this.channel, this.data, this.source);
}
