# Compatibility

What each platform needs, where the number comes from, and what was actually run. Checked on 30 October 2026 with Flutter 3.44.6 (stable).

**Scope (D64, owner decision 1 Nov 2026).** Phase 1 targets iOS on iPhone and iPad, and Android phones and tablets. Web is documentation only, not a product target. Desktop (macOS, Windows, Linux) is out of scope.

## Android

| Question | Answer | Source |
| --- | --- | --- |
| Lowest Android the SDK supports | API 24 (Android 7.0) | `flutter.minSdkVersion` in the installed Flutter 3.44.6 Gradle plugin (`packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt`); docs.flutter.dev/reference/supported-platforms states the same floor |
| Example app setting | `minSdk = flutter.minSdkVersion` (24); compile/target 36 | `example/android/app/build.gradle.kts` |
| Highest minimum among dependencies | 24 (`video_player_android` 2.9.5; Media3 ExoPlayer 1.9.2 underneath) | plugin `build.gradle.kts`; the Android manifest merger would fail if any library required more than the app's 24 |
| Merged manifest | `minSdkVersion="24"`, `targetSdkVersion="36"` (debug, profile and release) | `example/build/app/intermediates/merged_manifests/*/AndroidManifest.xml` |
| ABIs in the release APK | `armeabi-v7a`, `arm64-v8a`, `x86_64` | `flutter build apk --release`, APK contents |
| Actually run on | Android 11 (API 30) arm64 emulator, 60 Hz, Impeller over OpenGL ES | the oldest system image installed on this machine |

What that means:

- **Declared and built for Android 7.0+.** Nothing in the package raises the floor; it has no Android dependency at all. Only the example's video adapter adds one, at the same floor.
- **Tested on Android 11 only.** No API 24–29 image is installed, and none was downloaded for this pass. Android 7–10 behavior is unverified, not proven broken.
- **32-bit ARM is built, not run.** The release APK contains `armeabi-v7a` code, but every run used an arm64 emulator. Old 32-bit phones, their GPUs and Impeller's OpenGL ES path on them are untested.
- **Android tablets are a target (D64), not verified yet.** No Android tablet run is recorded here, and the 1 Nov 2026 UI review (D45–D63a) was captured on iOS only. The Android phone and tablet capture, review and fix pass is planned next.
- **Video:** the bundled clip is H.264 Constrained Baseline 640×360 plus AAC, the most widely decodable combination on old Android. The decoders of specific old devices are not verified.

To check an older version, first list available system images and choose one supported by the host architecture. An API 24 arm64 image must not be assumed to exist; older x86 images may need an Intel test host. Installing an image is a separate, potentially large download. After preparing a suitable emulator, run sequentially:

```sh
sdkmanager --list
emulator -avd <compatible-older-avd>
# In another terminal, after it boots:
cd example && flutter test integration_test/flow_test.dart -d emulator-5554
flutter drive --driver=test_driver/integration_driver.dart \
  --target=integration_test/kit_screenshots_test.dart -d emulator-5554
```

## iOS

- Minimum iOS 13.0: the example's deployment target and `video_player_avfoundation`'s requirement match.
- `flow_test.dart` (12 tests) passed earlier on the iPhone 16 simulator (iOS 18.1). That flow run predates the new components. The component/screenshot journey subsequently passed on the same simulator with `video_player`: real playback advanced to 4.5 seconds and paused when hidden; refined checkout at 200%, gallery, drawer and confirmation captures were inspected. The final background-loading autoplay fix is covered by a focused widget regression; it does not change default manual playback.
- The iOS simulator cannot run profile mode, so there are no iOS performance numbers.

## Web

- `flutter build web --release` succeeds. The build served locally returns the page, `main.dart.js`, CanvasKit and the video asset.
- The gallery has not been checked in a browser in this pass. The only automation-capable Chrome on this machine belonged to the user and another task, so it was left alone.
- `video_player_web` plays the bundled MP4 through an HTML video element. Browser autoplay rules don't matter because nothing autoplays.
- Web is documentation only (D64): the build is the docs site's gallery preview, not a product target, so web-specific layout and behaviour are not designed or fixed. It does not prove camera capture, native share or screen protection.

## Package

- Dart `^3.12.0`, Flutter `>=3.44.0`. The only dependency is the Flutter SDK.
- No network calls, analytics, media, camera, ad or payment SDKs in the package.
