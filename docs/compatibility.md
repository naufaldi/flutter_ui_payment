# Compatibility

Platform requirements and verification coverage for integrating the kit. The platform baseline was checked on 30 October 2026 with Flutter 3.44.6 (stable). Android documentation captures include phone and tablet layouts.

The kit targets iOS on iPhone and iPad, and Android phones and tablets. Web is used for documentation and previews. Desktop (macOS, Windows, Linux) is outside the supported product scope.

## Android

| Question | Answer | Source |
| --- | --- | --- |
| Lowest Android the SDK supports | API 24 (Android 7.0) | `flutter.minSdkVersion` in the installed Flutter 3.44.6 Gradle plugin (`packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt`); docs.flutter.dev/reference/supported-platforms states the same floor |
| Example app setting | `minSdk = flutter.minSdkVersion` (24); compile/target 36 | `example/android/app/build.gradle.kts` |
| Highest minimum among dependencies | 24 (`video_player_android` 2.9.5; Media3 ExoPlayer 1.9.2 underneath) | plugin `build.gradle.kts`; the Android manifest merger would fail if any library required more than the app's 24 |
| Merged manifest | `minSdkVersion="24"`, `targetSdkVersion="36"` (debug, profile and release) | `example/build/app/intermediates/merged_manifests/*/AndroidManifest.xml` |
| ABIs in the release APK | `armeabi-v7a`, `arm64-v8a`, `x86_64` | `flutter build apk --release`, APK contents |
| Actually run on | Android 11 (API 30) arm64 emulator; documentation captures on the Android API 37 phone, 360×640 dp, dpr 2 | earlier runtime pass and the 2 November 2026 Android capture pass |

What that means:

- **Declared and built for Android 7.0+.** Nothing in the package raises the floor; it has no Android dependency at all. Only the example's video adapter adds one, at the same floor.
- **Runtime baseline on Android 11; docs captures on API 37.** Android 7–10 has not been runtime-tested.
- **32-bit ARM is built, not run.** The release APK contains `armeabi-v7a` code, but the earlier Android 11 runtime pass used an arm64 emulator. Old 32-bit phones, their GPUs and Impeller's OpenGL ES path on them are untested.
- **Android phone and tablet documentation captures are available.** They show the captured layouts on API 37 emulators; they do not establish runtime compatibility with every supported Android version or physical device.
- **Video:** the bundled clip is H.264 Constrained Baseline 640×360 plus AAC, the most widely decodable combination on old Android. The decoders of specific old devices are not verified.

To test another Android version, choose an emulator image supported by the test machine. Check image availability before installing it, then run the example flow tests. The commands below illustrate a local test setup:

```sh
sdkmanager --list
emulator -avd <compatible-older-avd>
# In another terminal, after it boots:
cd example && flutter test --no-pub integration_test/flow_test.dart -d emulator-5554
flutter drive --driver=test_driver/integration_driver.dart \
  --target=integration_test/kit_screenshots_test.dart -d emulator-5554
```

## iOS

- Minimum iOS 13.0: the example's deployment target and `video_player_avfoundation`'s requirement match.
- `flow_test.dart` (12 tests) passed earlier on the iPhone 16 simulator (iOS 18.1). That flow run predates the new components. The component/screenshot journey subsequently passed on the same simulator with `video_player`: real playback advanced to 4.5 seconds and paused when hidden; refined checkout at 200%, gallery, drawer and confirmation captures were inspected. The final background-loading autoplay fix is covered by a focused widget regression; it does not change default manual playback.
- The iOS simulator cannot run profile mode, so there are no iOS performance numbers.

## Web

- `flutter build web --release` succeeds. The build served locally returns the page, `main.dart.js`, CanvasKit and the video asset.
- The Flutter web gallery has not been browser-tested.
- `video_player_web` plays the bundled MP4 through an HTML video element. Browser autoplay rules don't matter because nothing autoplays.
- The web build is a documentation preview, outside the supported mobile product scope. It does not establish support for camera capture, native sharing or screen protection.

## Package

- Dart `^3.12.0`, Flutter `>=3.44.0`. The only dependency is the Flutter SDK.
- No network calls, analytics, media, camera, ad or payment SDKs in the package.
- Current release: `rakit_ui` 0.2.0 on pub.dev. The docs follow `main`. 0.2.0 adds the settings view's `saveDisabledReason`, overridable kit strings with `formatNumber`, and search errors inside the open phone sheet. It removes the exported `KitStrings` and `PaymentStatusLabel` extension names, a breaking change for code that names them; the changelog shows the migration. Names deprecated in 0.1.0 still compile and are removed in 0.3.0 (D123). The quick start compiles against 0.2.0.
