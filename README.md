# Isolate Handler

Effortless isolates abstraction layer with support for MethodChannel
calls.

## Getting Started

#### What's an isolate?

In the words of the [Dart documentation](https://api.dartlang.org/stable/2.4.1/dart-isolate/dart-isolate-library.html) 
itself, isolates are:

> Independent workers that are similar to threads but don't share
> memory, communicating only via messages.

In short, Dart is a single-threaded language, but it has support for
concurrent execution of code through these so-called isolates.

This means that you can use isolates to execute code you want to run
alongside your main thread, which is particularly useful for keeping
your Flutter application running smoothly.

For more detailed information, please
[read this excellent article](https://www.didierboelens.com/2019/01/futures---isolates---event-loop/) 
by Didier Boelens.

#### Why should I use Isolate Handler?

**Short answer**: access to `MethodChannel` calls from within isolates in
Flutter.

Dart already has a very clean interface for spawning and interacting
with isolates, using Isolate Handler instead of the regular interface
provides only a slightly simpler way of communicating with isolates.

Aside from that and access to isolates through names, the real
motivation behind this package was to support access to native code from
within an isolate when using as part of Flutter on a mobile device.

Isolate Handler makes this relatively seamless, only requiring a list of
channels be provided.

## Using Isolate Handler

### Spawning an isolate

Spawning an isolate with Isolate Handler is really simple:

```dart
IsolateHandler().spawn(entryPoint);
```

This is similar to how isolates are spawned normally, with the exception
that Isolate Handler does not expect a message parameter, only an entry
point. Messaging has been abstracted away and a communications channel
is instead opened automatically.

### Communicating with an isolate

Just spawning an isolate provides no benefit over simply using
`Isolate.spawn`, so let's move on to a slightly more useful example;
sending data to isolate and receiving some back.

Let's do a complete project where we start an isolate and send it an
integer, have it add one to our count and return the value. We will also
give our isolate a name to make it easy to access from anywhere.

```dart
final isolates = IsolateHandler();
int counter = 0;

void main() {
  // Start the isolate at the `entryPoint` function.
  isolates.spawn<int>(entryPoint,
    name: "counter",
    // Executed every time data is received from the spawned isolate.
    onReceive: setCounter,
    // Executed once when spawned isolate is ready for communication.
    onInitialized: () => isolates.send(counter, to: "counter")
  );
}

// Set new count and display current count.
void setCounter(int count) {
  counter = count;
  print("Counter is now $counter");
  
  // We will no longer be needing the isolate, let's dispose of it.
  isolates.kill("counter");
}

// This function happens in the isolate.
void entryPoint(HandledIsolateContext context) {
  // Calling initialize from the entry point with the context is
  // required if communication is desired. It returns a messenger which
  // allows listening and sending information to the main isolate.
  final messenger = HandledIsolate.initialize(context);

  // Triggered every time data is received from the main isolate.
  messenger.listen((count) {
    // Add one to the count and send the new value back to the main
    // isolate.
    messenger.send(++count);
  });
}
```

### Call to `invokeMethod` from isolate

Now that we know how to use Isolate Handler to create and communicate
with isolates, let's take a look at how to use it for its main purpose;
accessing native calls from within the isolate.

We will modify the code from our previous example a little bit to make
it request the new count from native instead of just adding one by
itself:

```dart
final isolates = IsolateHandler();
int counter = 0;

// Let's store our channels in a top-level Map for convenience.
const Map<String, MethodChannel> channels = {
  'counter': const MethodChannel('isolates.example/counter'),
};

void main() {
  // Start the isolate at the `entryPoint` function.
  isolates.spawn<int>(entryPoint,
    name: "counter",
    // Executed every time data is received from the spawned isolate.
    onReceive: setCounter,
    // Executed once when spawned isolate is ready for communication.
    onInitialized: () => isolates.send(counter, to: "counter"),
    // Let's tell isolate handler we might end up calling any of the
    // channels in the map.
    channels: channels.values.toList()
  );
}

// Set new count and display current count.
void setCounter(int count) {
  counter = count;
  print("Counter is now $counter");
  
  // We will no longer be needing the isolate, let's dispose of it.
  isolates.kill("counter");
}

// This function happens in the isolate.
void entryPoint(HandledIsolateContext context) {
  // Calling initialize from the entry point with the context is
  // required if communication is desired. It returns a messenger which
  // allows listening and sending information to the main isolate.
  final messenger = HandledIsolate.initialize(context);

  // Triggered every time data is received from the main isolate. We can
  // now ignore incoming data as count is kept on the native side.
  messenger.listen((data) async {
    final int result = await channels['counter'].invokeMethod('getNewCount');
    messenger.send(result);
  });
}
```

That's it. The only real change that happened is that we supplied our
Isolate Handler with a list of channels we might need to invoke a
method on and we also added an `invokeMethod` call inside our isolate.

## Limitations

* At the moment only `MethodChannel` is supported, `EventChannel`
streams are not. Support for them may or may not be added in the future.

* Isolate Handler uses `setMockMessageHandler` to intercept calls. As
there can only be one mock message handler active at any time, another
may not be set within the isolate for the one of the registered
channels.

* Custom message handlers are also not supported at the time.

If any other limitations are found or if adding support for any of the
already known limitations is important to you, please raise an issue and
support may be added as time permits.

## Bugs

None known at the moment.
