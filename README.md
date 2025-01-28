# [BUG] [WEB] `KeyboardListener`'s and `Focus.onKeyEvent`'s `KeyUpEvent` do not work correctly in JS and WASM builds

The `KeyboardListener` and `Focus.onKeyEvent` that replace `RawKeyboardListener` and `Focus.onKey` have a bug in triggering the `KeyUpEvent` correctly in the JS and WASM builds. The `KeyUpEvent` is not triggered when a key is released when pressing multiple keys in sequence and releasing them in reverse order. This bug is not present in VM builds.

A reproduction issue sample app is provided in the code sample section.

This issue reproduces on all current Flutter channels.

## Background

We discovered this bug after starting to more actively pushing and using WEB builds of the game platform [HypeHype](https://app.hypehype.com/).
We had already migrated from the deprecated `RawKeyboardListener` to the new `KeyboardListener` and its related APIs, but due to this issue we had to revert the migration and continue to use the deprecated `RawKeyboardListener` and its related APIs.

When making games, having correct n-key rollover function and n-key release sequence is critical, as game-play typically depends on being able to press multiple keys at the same time and having the game react correctly to their triggered key down and key up release order.

## Request to hold removal of deprecated `RawKeyboardListener` and related APIs until issue is fixed

We kindly ask if you can hold the removal of the deprecated `RawKeyboardListener` and its related APIs, until this issue is resolved and its fix has landed in the Flutter stable channel.

The  `RawKeyboardListener` and its related APIs are scheduled for removal here https://github.com/flutter/flutter/issues/136419 by @gspencergoog.


## Expected behaviour

When pressing multiple keys in sequence and releasing them in reverse order, the `KeyUpEvent` should be triggered for each key in the correct release order.

Using the reproduction keyboard event listener demo app, we can see that in a **VM build** the `KeyUpEvent` is triggered correctly for each key in the correct order.

**Using the VM build with `RawKeyboardListener` or `Focus.onKey` APIs**
1. Press and hold `[1]` then, press and hold `[2]` then press and hold `[3]`.
2. Release `[3]`, keep holding `[2]` and `[1]`.
3. Release `[2]`, keep holding `[1]`, the `RawKeyUpEvent` for `[2]` is triggered.
4. Release `[1]`, the `RawKeyUpEvent` for `[1]` is triggered.

This is CORRECT and **expected** behaviour.

**Using the VM build with `KeyboardListener` or `Focus.onKeyEvent` APIs**
1. Press and hold `[1]` then, press and hold `2` then press and hold `[3]`.
2. Release `[3]`, keep holding `[2]` and `[1]`.
3. Release `[2]`, keep holding `[1]`, the `KeyUpEvent` for `[2]` is triggered.
4. Release `[1]`, the `KeyUpEvent` for `[1]` is triggered.

This is CORRECT and **expected** behaviour.

This is demonstrated in the video recording below:

## Actual behavior

When pressing multiple keys in sequence and releasing them in reverse order, the `KeyUpEvent` is not triggered for each key in the correct order on WEB builds. The same incorrect result is present in both JS and WASM builds. The previous key that were pressed are triggered automatically when last key is released, slightly after it, or not at all.

**Using WEB VM build with `RawKeyboardListener` or `Focus.onKey` APIs**
1. Press and hold `[1]` then, press and hold `[2]` then press and hold `[3]`.
2. Release `[3]`, keep holding `[2]` and `[1]`.
3. Release `[2]`, keep holding `[1]`, the `RawKeyUpEvent` for `[2]` is triggered.
4. Release `[1]`, the `RawKeyUpEvent` for `[1]` is triggered.

This is CORRECT and **expected** behaviour.

**Using the VM build with `KeyboardListener` or `Focus.onKeyEvent` APIs**
1. Press and hold `[1]` then, press and hold `[2]` then press and hold `[3]`.
2. Release `[3]`, keep holding `[2]` and `[1]`, the `KeyUpEvent` for `[2]` is triggered shortly after, despite `[2]` still being pressed.
3. Release `[2]`, keep holding `[1]`, the actual `KeyUpEvent` for `[2]` is not triggered.
4. Release `[1]`, the `KeyUpEvent` for `1` is not triggered.

This is incorrect and **not expected** behaviour when using the `KeyboardListener` and related APIs on WEB builds.

This is demonstrated in the video recording below:


## Code sample

See this repo

## Flutter version

This issue reproduces on all current Flutter channels, the latest tested master version is `3.29.0-1.0.pre.127`.

```console
flutter doctor -v
[✓] Flutter (Channel master, 3.29.0-1.0.pre.127, on macOS 15.2 24C101 darwin-arm64, locale en-US) [1,489ms]
    • Flutter version 3.29.0-1.0.pre.127 on channel master at /Users/rydmike/fvm/versions/master
    • Upstream repository https://github.com/flutter/flutter.git
    • Framework revision 9e273d5e6e (6 hours ago), 2025-01-27 19:43:46 -0800
    • Engine revision 9e273d5e6e
    • Dart version 3.8.0 (build 3.8.0-24.0.dev)
    • DevTools version 2.42.0

[✓] Android toolchain - develop for Android devices (Android SDK version 34.0.0) [902ms]
    • Android SDK at /Users/rydmike/Library/Android/sdk
    • Platform android-34, build-tools 34.0.0
    • Java binary at: /Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/java
      This is the JDK bundled with the latest Android Studio installation on this machine.
      To manually set the JDK path, use: `flutter config --jdk-dir="path/to/jdk"`.
    • Java version OpenJDK Runtime Environment (build 17.0.9+0-17.0.9b1087.7-11185874)
    • All Android licenses accepted.

[✓] Xcode - develop for iOS and macOS (Xcode 16.2) [517ms]
    • Xcode at /Applications/Xcode.app/Contents/Developer
    • Build 16C5032a
    • CocoaPods version 1.16.2

[✓] Chrome - develop for the web [68ms]
    • Chrome at /Applications/Google Chrome.app/Contents/MacOS/Google Chrome

[✓] Android Studio (version 2023.2) [68ms]
    • Android Studio at /Applications/Android Studio.app/Contents
    • Flutter plugin can be installed from:
      🔨 https://plugins.jetbrains.com/plugin/9212-flutter
    • Dart plugin can be installed from:
      🔨 https://plugins.jetbrains.com/plugin/6351-dart
    • Java version OpenJDK Runtime Environment (build 17.0.9+0-17.0.9b1087.7-11185874)

[✓] IntelliJ IDEA Community Edition (version 2024.3.2) [67ms]
    • IntelliJ at /Applications/IntelliJ IDEA CE.app
    • Flutter plugin version 83.0.4
    • Dart plugin version 243.23654.44

[✓] VS Code (version 1.96.4) [10ms]
    • VS Code at /Applications/Visual Studio Code.app/Contents
    • Flutter extension version 3.102.0

[✓] Connected device (2 available) [5.6s]
    • macOS (desktop) • macos  • darwin-arm64   • macOS 15.2 24C101 darwin-arm64
    • Chrome (web)    • chrome • web-javascript • Google Chrome 132.0.6834.110

[✓] Network resources [618ms]
    • All expected network resources are available.
```