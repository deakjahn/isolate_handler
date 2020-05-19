import 'dart:isolate';

/// Welcome to the Isolate Handler example
///
/// In this example we will take a look at how to spawn an isolate and allow it
/// to communicate with the main isolate.
///
/// This will be a simple, but complete project. We will start an isolate and
/// send it an integer, have it add one to our count and return the value.
///
/// We will also give our isolate a name to make it easy to access from
/// anywhere.

// First, let's do our imports
import 'package:isolate_handler/isolate_handler.dart';

// With that out of the way, let's create a new IsolateHandler instance. This
// is what we will use to spawn isolates.
final isolates = IsolateHandler();

// Variable where we can store the current count.
int counter = 0;

void main() {
  // Start the isolate at the `entryPoint` function. We will be dealing with
  // int types here, so we will restrict communication to that type. If no type
  // is given, the type will be dynamic instead.
  isolates.spawn<int>(entryPoint,
      // Here we give a name to the isolate, by which we can access is later,
      // for example when sending it data and when disposing of it.
      name: 'counter',
      // onReceive is executed every time data is received from the spawned
      // isolate. We will let the setCounter function deal with any incoming
      // data.
      onReceive: setCounter,
      // Executed once when spawned isolate is ready for communication. We will
      // send the isolate a request to perform a count right away.
      onInitialized: () => isolates.send(counter, to: 'counter'));
}

void setCounter(int count) {
  // Set new count and display current count.
  counter = count;

  // Show the new count.
  print('Counter is now $counter');

  // We will no longer be needing the isolate, let's dispose of it.
  isolates.kill('counter');
}

// This function happens in the isolate.
void entryPoint(SendPort context) {
  // Calling initialize from the entry point with the context is
  // required if communication is desired. It returns a messenger which
  // allows listening and sending information to the main isolate.
  final messenger = HandledIsolate.initialize(context);

  // Triggered every time data is received from the main isolate.
  messenger.listen((count) async {
    // Add one to the count and send the new value back to the main
    // isolate.
    messenger.send(++count);
  });
}
