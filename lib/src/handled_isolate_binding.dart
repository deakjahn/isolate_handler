import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// A concrete binding for applications based on the Services framework.
///
/// This is the glue that binds the framework to the Flutter engine.
class IsolateServicesBinding extends BindingBase with ServicesBinding {
  /// Returns an instance of the [ServicesBinding], creating and
  /// initializing it if necessary. If one is created, it will be an
  /// [IsolateServicesBinding]. If one was previously initialized, then
  /// it will at least implement [ServicesBinding].
  static ServicesBinding ensureInitialized() {
    if (ServicesBinding.instance == null) IsolateServicesBinding();
    return ServicesBinding.instance;
  }
}
