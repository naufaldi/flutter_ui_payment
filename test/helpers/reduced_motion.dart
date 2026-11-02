import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The three ways reduced motion reaches the kit (D65, D66). Run a B9 test
/// under every value:
///
/// ```dart
/// for (final setup in ReducedMotion.values) {
///   testWidgets('opens still (${setup.name})', (tester) async {
///     await tester.pumpWidget(setup.apply(tester, app(home)));
///     await expectStill(tester, () => tester.tap(find.text('Open')));
///   });
/// }
/// ```
///
/// Call [apply] before the first `pumpWidget`. `reduceMotion` isn't part of
/// `MediaQueryData`, so a widget built before it is set only sees it on its
/// next rebuild.
///
/// `FakeAccessibilityFeatures` defaults every flag to false, including
/// `autoPlayVideos` and `autoPlayAnimatedImages`, which a real device leaves
/// on. The platform setups turn those two back on, so each setup changes only
/// the flag it names.
enum ReducedMotion {
  /// The host's or app's override, `MediaQuery(disableAnimations: true)`,
  /// the condition B9 names.
  mediaQuery,

  /// iOS Settings → Accessibility → Motion → Reduce Motion, which the engine
  /// delivers only as `accessibilityFeatures.reduceMotion`.
  iosReduceMotion,

  /// Android "Remove animations", delivered as
  /// `accessibilityFeatures.disableAnimations`. `MediaQuery.fromView`
  /// rebuilds with it (checked in `motion_test.dart`), so it needs no
  /// MediaQuery override, and the SDK's own controllers slow down too.
  androidRemoveAnimations;

  /// Sets this setup up for the rest of the test and returns [app] wrapped as
  /// it needs. The platform values are cleared on teardown.
  Widget apply(WidgetTester tester, Widget app) {
    switch (this) {
      case mediaQuery:
        return Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: app,
          ),
        );
      case iosReduceMotion:
        _setFeatures(
          tester,
          const FakeAccessibilityFeatures(
            reduceMotion: true,
            autoPlayVideos: true,
            autoPlayAnimatedImages: true,
          ),
        );
        return app;
      case androidRemoveAnimations:
        _setFeatures(
          tester,
          const FakeAccessibilityFeatures(
            disableAnimations: true,
            autoPlayVideos: true,
            autoPlayAnimatedImages: true,
          ),
        );
        return app;
    }
  }

  static void _setFeatures(
    WidgetTester tester,
    FakeAccessibilityFeatures features,
  ) {
    tester.platformDispatcher.accessibilityFeaturesTestValue = features;
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }
}

/// Runs [act], pumps one frame and expects nothing to be animating (B9).
///
/// Drive the change with state (a `setState`, a new widget property) or a
/// kit call rather than a tap on Material ink where you can: the ink ripple
/// is an SDK exception (D67) and counts as a running animation.
Future<void> expectStill(
  WidgetTester tester,
  FutureOr<void> Function() act,
) async {
  await act();
  await tester.pump();
  expect(tester.hasRunningAnimations, isFalse, reason: 'B9: nothing animates');
}
