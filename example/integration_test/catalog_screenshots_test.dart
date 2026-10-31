import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
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
      debugPrint('Capture: $name');
      await binding.takeScreenshot('${platform}_catalog_$name');
    }

    Future<void> open(String label) async {
      await tester.tap(find.byTooltip('Open navigation'));
      await settle(tester);
      final item = find.descendant(
        of: find.byType(Drawer),
        matching: find.text(label),
      );
      await tester.scrollUntilVisible(
        item,
        180,
        scrollable: find
            .descendant(
              of: find.byType(Drawer),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.ensureVisible(item);
      await tester.tap(item);
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

    Future<void> hoverShot(String key, String message, String name) async {
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.byKey(Key(key))));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 700)),
      );
      await tester.pump();
      expect(find.text(message), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 400));
      await settle(tester);
      final bubble = find.text(message);
      final opacity = tester
          .widget<Opacity>(
            find.ancestor(of: bubble, matching: find.byType(Opacity)).first,
          )
          .opacity;
      debugPrint(
        'Tooltip proof $name rect=${tester.getRect(bubble)} opacity=$opacity',
      );
      expect(opacity, 1);
      await binding.takeScreenshot('${platform}_catalog_$name');
      await mouse.removePointer();
      await tester.pump(const Duration(seconds: 2));
      await settle(tester);
    }

    app.updateSettings(const DemoSettings(locale: Locale('en')));
    app.selectTab(2);
    await settle(tester);
    if (const bool.fromEnvironment('CAPTURE_ACTIONS_ONLY')) {
      for (final (look, settings) in [
        ('', const DemoSettings(locale: Locale('en'))),
        (
          '_dark',
          const DemoSettings(locale: Locale('en'), themeMode: ThemeMode.dark),
        ),
      ]) {
        app.updateSettings(settings);
        await settle(tester);
        await open('Controls');
        await top('PaymentIconButton · variants');
        FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.alwaysTraditional;
        Focus.of(
          tester.element(
            find.descendant(
              of: find.byKey(const Key('icon-button-focus')),
              matching: find.byType(Icon),
            ),
          ),
        ).requestFocus();
        await shot('icon_button_variants$look');
        FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic;
        FocusManager.instance.primaryFocus?.unfocus();
        await top('PaymentCopyButton · variants');
        await tapVisible(tester, find.byKey(const Key('copy-failed')));
        await top('PaymentCopyButton · variants');
        await shot('copy_button_variants$look');
      }
      return;
    }
    if (const bool.fromEnvironment('CAPTURE_TOOLTIP_ONLY')) {
      for (final (look, settings) in [
        ('', const DemoSettings(locale: Locale('en'))),
        (
          '_dark',
          const DemoSettings(locale: Locale('en'), themeMode: ThemeMode.dark),
        ),
        ('_200', const DemoSettings(locale: Locale('en'), textScale: 2)),
      ]) {
        app.updateSettings(settings);
        await settle(tester);
        await open('Feedback');
        await top('PaymentTooltip · variants');
        await hoverShot(
          'tooltip-label',
          'Payment time: 29 Oct 2026, 14:05',
          'tooltip_variants$look',
        );
      }
      app.updateSettings(const DemoSettings(locale: Locale('en')));
      await settle(tester);
      await open('Feedback');
      await top('PaymentTooltip · variants');
      await hoverShot(
        'tooltip-flip',
        'Flips to the start when there is no room',
        'tooltip_flip',
      );
      return;
    }
    if (const bool.fromEnvironment('CAPTURE_PHASE4_ONLY')) {
      for (final (look, settings) in [
        ('', const DemoSettings(locale: Locale('en'))),
        (
          '_dark',
          const DemoSettings(locale: Locale('en'), themeMode: ThemeMode.dark),
        ),
        ('_200', const DemoSettings(locale: Locale('en'), textScale: 2)),
      ]) {
        const onlyLook = String.fromEnvironment('CAPTURE_PHASE4_LOOK');
        if (onlyLook.isNotEmpty && onlyLook != look) continue;
        app.updateSettings(settings);
        await settle(tester);
        await open('Layout');
        for (final (entry, name) in [
          if (look != '_200') ('PaymentBox', 'box'),
          ('PaymentInline', 'inline'),
          if (look != '_200') ('PaymentIcon', 'icon'),
          if (look != '_200') ('PaymentImage', 'image'),
          ('PaymentCode', 'code'),
          if (look != '_200') ('PaymentDivider', 'divider'),
        ]) {
          await top('$entry · variants');
          await shot('${name}_variants$look');
        }
        await open('Forms');
        for (final (entry, name) in [
          ('PaymentTextArea', 'text_area'),
          ('PaymentSelect', 'select'),
          ('PaymentDateField', 'date_field'),
          ('PaymentFormFieldGroup', 'form_field_group'),
          ('PaymentDateRangePicker', 'date_range_picker'),
          ('PaymentChip', 'chip'),
        ]) {
          await top('$entry · variants');
          await shot('${name}_variants$look');
        }
        await top('PaymentSearchField · variants');
        await tester.tap(
          find.descendant(
            of: find.byKey(const Key('search-province')),
            matching: find.byType(EditableText),
          ),
        );
        await tester.enterText(
          find.descendant(
            of: find.byKey(const Key('search-province')),
            matching: find.byType(EditableText),
          ),
          'jawa',
        );
        await top('PaymentSearchField · variants');
        await shot('search_field_variants$look');
        FocusManager.instance.primaryFocus?.unfocus();
        await settle(tester);
        await open('Controls');
        for (final (entry, name) in [
          ('PaymentCurrencyField', 'currency_field'),
          ('PaymentTextField', 'text_field'),
        ]) {
          await top('$entry · variants');
          await shot('${name}_variants$look');
        }
        await open('Interaction');
        await top('PaymentAccordion · variants');
        await shot('accordion_variants$look');
        await top('PaymentList · variants');
        await shot('list_variants$look');
        await open('Charts');
        await top('PaymentMeterChart · variants');
        await shot('meter_chart_variants$look');
      }
      return;
    }
    if (!const bool.fromEnvironment('CAPTURE_TAIL_ONLY')) {
      const buttons = 'PaymentButton · variants';
      for (final (look, settings) in [
        ('', const DemoSettings(locale: Locale('en'))),
        ('_200', const DemoSettings(locale: Locale('en'), textScale: 2)),
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
        FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.alwaysTraditional;
        Focus.of(
          tester.element(
            find.descendant(
              of: find.byKey(const ValueKey('button-specimen-focus')),
              matching: find.text('Edit'),
            ),
          ),
        ).requestFocus();
        await shot('button_variants$look');
        FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic;
        FocusManager.instance.primaryFocus?.unfocus();
        for (final (entry, name) in [
          ('PaymentTabs', 'tabs'),
          ('PaymentCheckbox', 'checkbox'),
          ('PaymentRadio', 'radio'),
          ('PaymentSwitch', 'switch'),
          ('PaymentCurrencyField', 'currency_field'),
          ('PaymentTextField', 'text_field'),
          ('PaymentLink', 'link'),
          if (look != '_200') ('PaymentIconButton', 'icon_button'),
          if (look != '_200') ('PaymentCopyButton', 'copy_button'),
        ]) {
          await top('$entry · variants');
          if (name == 'copy_button') {
            await tapVisible(tester, find.byKey(const Key('copy-failed')));
            await top('$entry · variants');
          }
          await shot('${name}_variants$look');
        }
        await open('Foundation');
        await top('AmountText · variants');
        await shot('amount_text_variants$look');
        await open('Feedback');
        await top('PaymentBadge · variants');
        await shot('badge_variants$look');
        await top('PaymentBanner · variants');
        await shot('banner_variants$look');
        if (look != '_200') {
          await top('PaymentSpinner · variants');
          await shot('spinner_variants$look');
        }
        await top('showPaymentToast · variants');
        await tapVisible(tester, find.widgetWithText(PaymentButton, 'Pending'));
        await shot('toast_variants$look');
        clearSnackBars();
        await settle(tester);
        await top('PaymentTooltip · variants');
        await hoverShot(
          'tooltip-label',
          'Payment time: 29 Oct 2026, 14:05',
          'tooltip_variants$look',
        );
        await open('Interaction');
        await top('PaymentMenu · variants');
        await tester.tap(
          find.descendant(
            of: find.byKey(const Key('menu-specimen')),
            matching: find.byType(IconButton),
          ),
        );
        await settle(tester);
        await shot('menu_variants$look');
        await tester.tapAt(const Offset(10, 10));
        await settle(tester);
        await top('PaymentAccordion · variants');
        await shot('accordion_variants$look');
        await top('PaymentList · variants');
        await shot('list_variants$look');
        await open('Charts');
        for (final (entry, name) in [
          ('PaymentLineChart', 'line_chart'),
          ('PaymentBarChart', 'bar_chart'),
          ('PaymentMeterChart', 'meter_chart'),
          if (look != '_200') ('PaymentSparkline', 'sparkline'),
        ]) {
          await top('$entry · variants');
          await shot('${name}_variants$look');
        }
      }

      for (final dark in [false, true]) {
        final suffix = dark ? '_dark' : '';
        app.updateSettings(
          DemoSettings(
            locale: const Locale('en'),
            themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          ),
        );
        await settle(tester);
        await open('Charts');
        for (final (entry, name) in [
          ('PaymentLineChart', 'chart_line'),
          ('PaymentBarChart', 'chart_bar'),
          ('PaymentMeterChart', 'chart_meter'),
          ('PaymentSparkline · beside a KPI', 'chart_sparkline'),
          ('In context: spending above history', 'chart_in_context'),
        ]) {
          await top(entry);
          await shot('$name$suffix');
        }
        await open('Verification (KYC)');
        await top('showCaptureSourceSheet');
        await tapVisible(tester, find.text('Add a photo'));
        await shot('capture_source_sheet$suffix');
        await tester.tap(find.byTooltip('Close panel'));
        await settle(tester);
        clearSnackBars();
        await top('KycCaptureGuide');
        await shot('capture_ktp$suffix');
        await tapVisible(tester, find.text('selfie'));
        await top('KycCaptureGuide');
        await shot('capture_selfie$suffix');
      }
      app.updateSettings(const DemoSettings(locale: Locale('en')));
      await settle(tester);
      await open('Charts');
      await top('ChartModule · states');
      await shot('chart_states');
      for (final state in ['error', 'empty']) {
        await tapVisible(tester, find.text(state));
        await top('ChartModule · states');
        await shot('chart_states_$state');
      }
      await top('PaymentLineChart');
      final inspectMouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await inspectMouse.addPointer(location: Offset.zero);
      await inspectMouse.moveTo(
        tester.getCenter(find.byType(PaymentLineChart).first),
      );
      await tester.pump(const Duration(milliseconds: 400));
      await shot('chart_line_inspect');
      await inspectMouse.removePointer();
      await open('Verification (KYC)');
      await top('KycCaptureGuide');
      for (final state in ['review', 'rejected', 'permission']) {
        await tapVisible(tester, find.text(state));
        await top('KycCaptureGuide');
        await shot('capture_$state');
      }
      app.updateSettings(
        const DemoSettings(locale: Locale('en'), textScale: 2),
      );
      await settle(tester);
      await open('Charts');
      await top('In context: spending above history');
      await shot('chart_in_context_200');
      await open('Verification (KYC)');
      await top('KycCaptureGuide');
      await tapVisible(tester, find.text('selfie'));
      await top('KycCaptureGuide');
      await Scrollable.ensureVisible(
        tester.element(
          find.text(
            'Keep your face in the oval and hold the card below your chin.',
          ),
        ),
        alignment: 0,
      );
      await shot('capture_selfie_200');
    }
    await open('Interaction');
    await top('PaymentList · PaymentMenu · showPaymentConfirmDialog');
    // A longer host label exercises overflow at 200% on this iPhone width.
    final confirmation = showPaymentConfirmDialog(
      tester.element(find.byType(PaymentList).first),
      title: 'Sign out of all devices?',
      message:
          'You will need to sign in again on every device. Payments already sent are not affected.',
      confirmLabel: 'Sign out everywhere',
      destructive: true,
    );
    await shot('confirm_dialog_200');
    await tapVisible(tester, find.text('Cancel'));
    expect(await confirmation, isFalse);
    await settle(tester);
    app.updateSettings(const DemoSettings(locale: Locale('en')));
    await settle(tester);
    await open('Feedback');
    await top('showPaymentToast · variants');
    await tapVisible(tester, find.widgetWithText(PaymentButton, 'Pending'));
    await tester.pump(const Duration(seconds: 2));
    await shot('toast_updated');
    clearSnackBars();
    await settle(tester);
    await top('PaymentTooltip · variants');
    await hoverShot(
      'tooltip-flip',
      'Flips to the start when there is no room',
      'tooltip_flip',
    );

    await open('Foundation');
    tester
        .state<ScrollableState>(
          find
              .descendant(
                of: find.byType(ListView),
                matching: find.byType(Scrollable),
              )
              .first,
        )
        .position
        .jumpTo(0);
    await shot('foundation');

    await open('Interaction');
    await top('PaymentList · PaymentMenu · showPaymentConfirmDialog');
    if (const bool.fromEnvironment('CAPTURE_TAIL_ONLY')) {
      for (final (look, settings) in [
        ('', const DemoSettings(locale: Locale('en'))),
        (
          '_dark',
          const DemoSettings(locale: Locale('en'), themeMode: ThemeMode.dark),
        ),
        ('_200', const DemoSettings(locale: Locale('en'), textScale: 2)),
      ]) {
        app.updateSettings(settings);
        await settle(tester);
        await open('Feedback');
        await top('PaymentTooltip · variants');
        await hoverShot(
          'tooltip-label',
          'Payment time: 29 Oct 2026, 14:05',
          'tooltip_variants$look',
        );
      }
      app.updateSettings(const DemoSettings(locale: Locale('en')));
      await settle(tester);
      await open('Interaction');
      await top('PaymentList · PaymentMenu · showPaymentConfirmDialog');
    }
    await shot('actions');
    await tester.tap(find.byTooltip('More actions').first);
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

    await open('Video');
    await top('PaymentVideoPlayer + video_player adapter');
    await tapVisible(tester, find.text('Loading'));
    await top('PaymentVideoPlayer + video_player adapter');
    await shot('video_loading');
    await open('Interaction');
    await top('PaymentAccordionItem');
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
