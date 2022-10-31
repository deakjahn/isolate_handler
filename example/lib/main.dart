import 'package:flutter/material.dart';
/// Welcome to the Isolate Handler example
///
/// In this example we will take a look at how to spawn an isolate and allow it
/// to communicate with the main isolate. The isolate will be using a plugin, too.
///
/// This will be a simple, but complete project. We will start an isolate and
/// send it a string, have it add a path to it and return the value.
///
/// We will also give our isolate a name to make it easy to access from
/// anywhere.

import 'package:isolate_handler/isolate_handler.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
// Let's create a new IsolateHandler instance. This is what we will use
// to spawn isolates.
  final isolates = IsolateHandler();

// Variable where we can store the message.
  String pathMessage = 'The documents folder is ';

  @override
  void initState() {
    super.initState();

    // Start the isolate at the `entryPoint` function. We will be dealing with
    // string types here, so we will restrict communication to that type. If no type
    // is given, the type will be dynamic instead.
    isolates.spawn<String>(entryPoint,
        // Here we give a name to the isolate, by which we can access is later,
        // for example when sending it data and when disposing of it.
        name: 'path',
        // onReceive is executed every time data is received from the spawned
        // isolate. We will let the setPath function deal with any incoming
        // data.
        onReceive: setPath,
        // Executed once when spawned isolate is ready for communication. We will
        // send the isolate a request to perform its task right away.
        onInitialized: () => isolates.send(pathMessage, to: 'path'));
  }

  void setPath(String path) {
    // Show the new message.
    setState(() {
      pathMessage = path;
    });

    // We will no longer be needing the isolate, let's dispose of it.
    isolates.kill('path');
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Isolate Handler example'),
          ),
          body: Center(child: Text(pathMessage)),
        ),
      );
}

// This function happens in the isolate.
void entryPoint(Map<String, dynamic> context) {
  // Calling initialize from the entry point with the context is
  // required if communication is desired. It returns a messenger which
  // allows listening and sending information to the main isolate.
  final messenger = HandledIsolate.initialize(context);

  // Triggered every time data is received from the main isolate.
  messenger.listen((msg) async {
    // Use a plugin to get some new value to send back to the main isolate.
    final dir = await getApplicationDocumentsDirectory();
    messenger.send(msg + dir.path);
  });
}
