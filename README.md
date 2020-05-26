# Isolate Handler

Effortless isolates abstraction layer with support for inter-isolate
communication. These isolates (unlike the standard ones in Flutter)
*can* call platform plugins.

## Getting Started

#### What's an isolate?

In the words of the [Dart documentation](https://api.dartlang.org/stable/2.4.1/dart-isolate/dart-isolate-library.html) 
itself, isolates are:

> Independent workers that are similar to threads but don't share
> memory, communicating only via messages.

In short, Dart is a single-threaded language, but it has support for
concurrent execution of code through isolates.

This means that you can use isolates to execute code you want to run
alongside your main thread, which is particularly useful for keeping
your Flutter application running smoothly.

For more detailed information, please
[read this excellent article](https://www.didierboelens.com/2019/01/futures---isolates---event-loop/) 
by Didier Boelens.

#### Why should I use Isolate Handler?

**Short answer**: Isolate Handler allows easy spawning of—as well as
communication between—isolates.

Dart already has a very clean interface for spawning and interacting
with isolates, using Isolate Handler instead of the regular interface only
provides a slightly simpler way of keeping track of and communicating with them.
Besides, it allows the isolates to call platform plugins, overcoming a limitation
of the original ones (platform plugins use platform channels for communication
between the Dart and the hative sides and stock isolates don't set up the
necessary UI engine that the platform channels rely on).

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
sending data to an isolate and receiving some back.

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
void entryPoint(SendPort context) {
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

## Breaking changes from 0.2.0

Due to a change in the Flutter framework, the previously used method to set up an extra
communication channel cannot be used any more. From now on, this package depends
on https://pub.dev/packages/flutter_isolate to use an alternative method to establish
the platform channel so that the isolates can call platform plugins.

This solution is mostly transparent but it results in two changes. First, as it can be seen
in the code above, the parameter passed to the `entryPoint()` function changed type.
It was a `HandledIsolateContext` earlier but it is a `SendPort` now.

The second change pertains to the way external plugins are called from the isolates.
There is no need for any setup now, just call the plugin just like you would call
it from the main thread. See the `example` subproject for a sample.

It is worth noting that running native plugins from a Dart isolate does not
offer any real performance advantage as all native code is run on the main (UI)
thread by default. Your UI and main thread can be much more responsive if you
use it properly but you cannot expect the platform channel calls to run in parallel.
