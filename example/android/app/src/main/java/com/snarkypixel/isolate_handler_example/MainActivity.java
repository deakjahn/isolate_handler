package com.snarkypixel.isolate_handler_example;

import android.os.*;

import io.flutter.app.*;
import io.flutter.plugins.*;

public class MainActivity extends FlutterActivity {
  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    GeneratedPluginRegistrant.registerWith(this);
  }
}
