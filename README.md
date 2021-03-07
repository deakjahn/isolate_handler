# Isolate Handler

Effortless isolates abstraction layer with support for inter-isolate
communication. These isolates (unlike the standard ones in Flutter)
*can* call platform plugins.

## Getting Started

### What's an isolate?

In the words of the [Dart documentation](https://api.dartlang.org/stable/2.4.1/dart-isolate/dart-isolate-library.html) 
itself, isolates are:

> Independent workers that are similar to threads but don't share
> memory, communicating only via messages.

In short, Dart is a single-threaded language, but it has support for
concurrent execution of code through isolates.

This means that you can use isolates to execute code you want to run
alongside your main thread, which is particularly useful for keeping
your Flutter application running smoothly.

For more detailed information, please [read this excellent article](https://www.didierboelens.com/2019/01/futures---isolates---event-loop/) 
by Didier Boelens.

### Why should I use Isolate Handler?

**Short answer**: Isolate Handler allows easy spawning of—as well as
communication between—isolates.

Dart already has a very clean interface for spawning and interacting
with isolates, using Isolate Handler instead of the regular interface only
provides a slightly simpler way of keeping track of and communicating with them.
Besides, it allows the isolates to call platform plugins, overcoming a limitation
of the original ones.

Plugins in [Flutter parlance](https://flutter.dev/docs/development/packages-and-plugins/developing-packages) mean
packages that contain native code. When you depend on something in your `pubspec.yaml` file,
that might be either a package (containing Dart code only) or a plugin (containing platform code,
usually Android and iOS, maybe even more).
 
Plugins use a mechanism called platform channel to communicate between the Dart and the native sides,
a message passing mechanism using the `MethodChannel` type. This mechanism depends on elements
of the underlying UI engine to function. Standard isolates don't have that underlying engine because
it's not something they normally need but this means that any call to a plugin (eg. to something as simple
as [path_provider](https://pub.dev/packages/path_provider)) will fail.

The `FlutterIsolate` type used by this package, however, does set up that mechanism (technically by
creating a background view on the platform side) so that calls to plugins go through completely transparently,
without any code modification at all: just call as you would normally call from your main thread code.

It is worth noting, however, that running native plugins from a Dart isolate does not
offer any real performance advantage as all native code is run on the main (UI)
thread by default. In simple terms, using an isolate (unlike `async/await` itself)
will create parallel execution on a different thread. But as soon as you call a plugin from that isolate,
the platform side of that plugin will run on the UI thread again. Calling a plugin from an isolate
instead of the main app *will not* create a new thread on the native platform: only the Dart code
will enjoy the benefits, not the native part.

If your tasks are computationally intensive on the Dart side, isolates will help a lot.
If the time is spent in the plugin native side, you won't gain much unless you create your
own native threads on the native side, in the plugin itself. There is nothing you can do about it
in your main Dart app.

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
// Important: `entryPoint` should be either at root level or a static function.
// Otherwise it will throw an exception.
void entryPoint(Map<String, dynamic> context) {
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
on [flutter_isolate](https://pub.dev/packages/flutter_isolate) to use an alternative method to establish
the platform channel so that the isolates can call platform plugins.

This solution is mostly transparent but it results in two changes. First, as it can be
seen in the code above, the parameter passed to the `entryPoint()` function changed type.
It was a `HandledIsolateContext` earlier but it is a `Map<String, dynamic>` now.
It still has the same two elements as before, 'messenger' (a `SendPort`) and 'name' (a `String`).

The second change pertains to the way external plugins are called from the isolates.
There is no need for any setup now, just call the plugin just like you would call
it from the main thread. See the `example` subproject for a sample.
