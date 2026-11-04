import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';

/// B4 floor: a 320 dp phone at 200% text, with reduced motion on.
void useSmallScreenLargeText(WidgetTester tester) {
  tester.view.physicalSize = const Size(320, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = 2;
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

/// The kit button labelled [label].
Finder buttonLabeled(String label) =>
    find.byWidgetPredicate((w) => w is PaymentButton && w.label == label);

/// Whether the kit button labelled [label] accepts a tap.
bool enabled(WidgetTester tester, String label) =>
    tester.widget<PaymentButton>(buttonLabeled(label)).onPressed != null;
