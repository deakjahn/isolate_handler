## [0.2.0-hotfix1] - 2020-05-19

* Pubspec and format fix.

## [0.2.0] - 2020-05-19

* Out of alpha.
* Pubspec and format fix.

## [0.2.0-alpha1] - 2020-05-19

* **BREAKING CHANGE**: Removed support for calls to native code through
`MethodChannel`.

## [0.1.2+hotfix2] - 2020-05-18

* Added `ServicesBinding` mixin dependency `SchedulerBinding`. This is required since Flutter [#54286](https://github.com/flutter/flutter/pull/54286).

## [0.1.2+hotfix1] - 2020-03-01

* Added a null-check for name in `IsolateHandler.kill`'s dispose call. *Thanks
to @deakjahn for the suggestion.*

## [0.1.2+formatfix] - 2020-03-01

* Fixed wrong date in changelog.

* Fixed formatting using `flutter format` to better follow Flutter guidelines.

## [0.1.2] - 2020-03-01

* Fixed error introduced with Flutter version *1.12.13+hotfix.5* where the
ServicesBinding instance would not be initialized by the time isolate handler
requested use of its `defaultBinaryMessenger`. *Thanks to @deakjahn for
reporting the bug.*

* Changed `defaultBinaryMessenger` to
`ServicesBinding.instance.defaultBinaryMessenger` as it is now the recommended
way of accessing the default binary messenger.

## [0.1.1+info] - 2019-09-12

* Added warning about platform thread potentially locking up UI.

## [0.1.1] - 2019-08-27

* Changed from `MethodChannel` to `String` for channel names to future proof in
the unlikely event support for `EventChannel`s can one day be added.

## [0.1.0+formatfix2] - 2019-08-26

* Moved `example` folder


## [0.1.0+formatfix] - 2019-08-26

* Fixed formatting using `flutter format` to better follow Flutter guidelines.


## [0.1.0] - 2019-08-26

* Initial release, major feature is support for `MethodChannel` calls in isolates.
