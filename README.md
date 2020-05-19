# Isolate Handler

Effortless isolates abstraction layer.

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

**Short answer**: Isolate Handler allows easy spawning of—as well as
communication between—isolates.

Dart already has a very clean interface for spawning and interacting
with isolates, using Isolate Handler instead of the regular interface only
provides a slightly simpler way of keeping track of and communicating with
isolates.

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

### Calls to `invokeMethod` from isolates

This was previously supported, but support has been removed due to changes in
Flutter making it infeasible.

It is worth noting that running native plugins from a Dart isolate does not
offer any performance advantage as all native code is run on the main (UI)
thread.

In order to improve performance of a native plugin, the plugin must create its
own thread on the native platform.
