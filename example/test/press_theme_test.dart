import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rakit_ui_example/main.dart';
import 'package:rakit_ui_example/screens/flow_screen.dart';
import 'package:rakit_ui_example/themes.dart';

void main() {
  test(
    'example splash follows the platform for both brands and brightnesses',
    () {
      final original = debugDefaultTargetPlatformOverride;
      try {
        for (final platform in TargetPlatform.values) {
          debugDefaultTargetPlatformOverride = platform;
          final expected = switch (platform) {
            TargetPlatform.iOS => NoSplash.splashFactory,
            TargetPlatform.android => InkSparkle.splashFactory,
            _ => ThemeData().splashFactory,
          };
          for (final brand in DemoBrand.values) {
            for (final brightness in Brightness.values) {
              final theme = buildTheme(brand, brightness);
              expect(theme.platform, platform);
              expect(theme.splashFactory, same(expected));
            }
          }
        }
      } finally {
        debugDefaultTargetPlatformOverride = original;
      }
    },
  );

  testWidgets('SDK subtree follows live Reduce Motion and keeps overrides', (
    tester,
  ) async {
    final dispatcher = tester.platformDispatcher;
    addTearDown(dispatcher.clearAccessibilityFeaturesTestValue);
    dispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures();
    await tester.pumpWidget(const DemoApp());
    await tester.pumpAndSettle();

    bool disabled() => MediaQuery.of(
      tester.element(find.byType(FlowScreen)),
    ).disableAnimations;

    expect(disabled(), isFalse);
    dispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      reduceMotion: true,
    );
    await tester.pump();
    expect(disabled(), isTrue);

    dispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures();
    await tester.pump();
    expect(disabled(), isFalse);

    final app = tester.state<DemoAppState>(find.byType(DemoApp));
    app.updateSettings(app.settings.copyWith(reduceMotion: true));
    await tester.pump();
    expect(disabled(), isTrue);
    app.updateSettings(app.settings.copyWith(reduceMotion: false));
    dispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: true,
    );
    await tester.pump();
    expect(disabled(), isTrue);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });
}
