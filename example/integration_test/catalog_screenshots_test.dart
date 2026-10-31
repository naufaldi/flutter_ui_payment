import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment_example/main.dart';
import 'package:integration_test/integration_test.dart';

import 'support.dart';

/// English, one-component-per-shot captures for the docs component catalog:
/// the controls in light and dark, plus the interaction components that the
/// `kit_` set only shows in Indonesian. Files are prefixed `catalog_` so
/// earlier evidence is kept. Run with `flutter drive` and
/// test_driver/integration_driver.dart.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture catalog entries', (tester) async {
    if (Platform.isAndroid) await binding.convertFlutterSurfaceToImage();
    final app = await launch(tester);
    final platform = Platform.isIOS ? 'ios' : 'android';

    Future<void> shot(String name) async {
      await settle(tester);
      await tester.pump(const Duration(milliseconds: 400));
      await binding.takeScreenshot('${platform}_catalog_$name');
    }

    Future<void> open(String label) async {
      await tester.tap(find.byTooltip('Open navigation'));
      await settle(tester);
      await tester.tap(
        find.descendant(of: find.byType(Drawer), matching: find.text(label)),
      );
      await settle(tester);
    }

    // Scrolls the gallery until the entry's caption is at the top.
    Future<void> top(String entry) async {
      final caption = find.text(entry);
      await tester.scrollUntilVisible(
        caption,
        200,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await Scrollable.ensureVisible(tester.element(caption));
      await settle(tester);
    }

    void clearSnackBars() => tester
        .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger).first)
        .clearSnackBars();

    const buttons = 'PaymentButton · variants';
    const choices = 'PaymentCheckbox · PaymentRadio · PaymentSwitch';
    const tabs =
        'PaymentTabs · PaymentTooltip · PaymentSpinner · PaymentDivider';

    for (final (look, settings) in [
      ('', const DemoSettings(locale: Locale('en'))),
      (
        '_dark',
        const DemoSettings(locale: Locale('en'), themeMode: ThemeMode.dark),
      ),
    ]) {
      app.updateSettings(settings);
      app.selectTab(2);
      await settle(tester);
      await open('Controls');
      await top(buttons);
      await shot('controls_buttons$look');
      await top(choices);
      await shot('controls_choices$look');
      await top(tabs);
      await shot('controls_tabs$look');
    }

    // Tooltip, light.
    app.updateSettings(const DemoSettings(locale: Locale('en')));
    await settle(tester);
    await top(tabs);
    // A mouse hover keeps the tooltip open without drawing a test pointer,
    // which a held touch would put into the capture.
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.byIcon(Icons.info_outline)));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 400));
    await binding.takeScreenshot('${platform}_catalog_controls_tooltip');
    await mouse.removePointer();
    await tester.pump(const Duration(seconds: 3));
    await settle(tester);

    await open('Foundation');
    await shot('foundation');

    await open('Interaction');
    await top('ActionTile · ActionMenu · showPaymentConfirmDialog');
    await shot('actions');
    await tester.tap(find.byTooltip('More actions'));
    await settle(tester);
    await shot('menu_open');
    await tester.tap(find.text('Sign out everywhere'));
    await settle(tester);
    await shot('confirm_dialog');
    await tester.tap(find.text('Cancel'));
    await settle(tester);
    await shot('snackbar');
    clearSnackBars();
    await settle(tester);

    await top('ExpandableSection');
    await shot('expandable');
    // The last entries cannot scroll to the top, so this frame also shows
    // the expandable section; the picker switches the fixture state.
    await top('LoadingSkeleton · StateMessage');
    await shot('states');
    for (final state in ['empty', 'error']) {
      await tester.tap(find.text(state));
      await settle(tester);
      await shot('states_$state');
    }
  });
}
