import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'package:flutter_ui_payment_example/coordinator/demo_coordinator.dart';
import 'package:flutter_ui_payment_example/main.dart';
import 'package:flutter_ui_payment_example/themes.dart';
import 'package:integration_test/integration_test.dart';

import 'support.dart';

/// Native proof for the refined flow screens and the component gallery.
/// Run with `flutter drive` and test_driver/integration_driver.dart.
/// Files are prefixed `refined_`/`kit_` so earlier evidence is kept.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture refined flow and gallery sections', (tester) async {
    if (Platform.isAndroid) await binding.convertFlutterSurfaceToImage();
    final app = await launch(tester);
    final platform = Platform.isIOS ? 'ios' : 'android';

    Future<void> shot(String name) async {
      await settle(tester);
      await tester.pump(const Duration(milliseconds: 400));
      await binding.takeScreenshot('${platform}_$name');
    }

    const looks = {
      'light': DemoSettings(locale: Locale('en')),
      'dark': DemoSettings(themeMode: ThemeMode.dark),
      'light_200': DemoSettings(textScale: 2),
    };
    for (final MapEntry(key: look, value: settings) in looks.entries) {
      app.updateSettings(settings);
      await tester.pump();

      await runScenario(tester, app, 'K07', variant: 2);
      await shot('refined_kyc_review_$look');

      var c = await runScenario(tester, app, 'H02');
      await pumpUntil(tester, () => c.quote != null && !c.quoting);
      await shot('refined_checkout_$look');

      c = await runScenario(tester, app, 'P06');
      await pumpUntil(tester, () => c.quote != null && !c.quoting);
      c.reviewOrder();
      await c.confirm();
      await pumpUntil(tester, () => c.step == FlowStep.authorize);
      await c.authorize();
      await pumpUntil(
        tester,
        () => c.attempt?.submission == SubmissionState.outcomeUnknown,
      );
      await shot('refined_status_unknown_$look');
    }

    // Gallery, Indonesian, Lumen brand for one pass to show theming.
    Future<void> section(String label, String name, {String look = ''}) async {
      await tester.tap(find.byTooltip('Buka navigasi'));
      await settle(tester);
      // At 200% text the drawer list scrolls; items below are not built yet.
      final item = find.descendant(
        of: find.byType(Drawer),
        matching: find.text(label),
      );
      await tester.scrollUntilVisible(
        item,
        120,
        scrollable: find.descendant(
          of: find.byType(Drawer),
          matching: find.byType(Scrollable),
        ),
      );
      // scrollUntilVisible stops once the item is partly visible; at 200%
      // text that can leave its center under the bottom navigation bar.
      await tester.ensureVisible(item);
      await settle(tester);
      await tester.tap(item);
      await settle(tester);
      await shot('kit_$name$look');
    }

    for (final (look, settings) in [
      ('', const DemoSettings()),
      ('_dark', const DemoSettings(themeMode: ThemeMode.dark)),
      ('_200', const DemoSettings(textScale: 2)),
    ]) {
      app.updateSettings(settings);
      app.selectTab(2);
      await settle(tester);
      await section('Interaksi', 'interaction', look: look);
      await section('Promosi', 'promo', look: look);
      await section('Checkout', 'checkout', look: look);
      await section('Riwayat', 'history', look: look);
    }

    app.updateSettings(const DemoSettings(brand: DemoBrand.lumen));
    await settle(tester);
    await section('Checkout', 'checkout_lumen');

    // Drawer open, showing selected and disabled items.
    await tester.tap(find.byTooltip('Buka navigasi'));
    await settle(tester);
    await shot('kit_navigation_drawer');
    await tester.tap(
      find.descendant(of: find.byType(Drawer), matching: find.text('Navigasi')),
    );
    await settle(tester);

    app.updateSettings(const DemoSettings());
    await settle(tester);

    // Sheet with the destructive confirmation behind it.
    await section('Sheet & drawer', 'sheets');
    await tester.tap(find.text('Tutup vs. batalkan pembayaran'));
    await settle(tester);
    await shot('kit_sheet_pending');
    await tester.tap(find.text('Minta pembatalan'));
    await settle(tester);
    await shot('kit_sheet_confirm');
    await tester.tap(find.text('Tetap bayar'));
    await settle(tester);
    await tester.tap(find.byTooltip('Tutup panel'));
    await settle(tester);

    // History detail sheet for an unconfirmed payment.
    await section('Riwayat', 'history_detail_base');
    await tester.tap(find.text('Paket Belajar · 1 bulan'));
    await settle(tester);
    await shot('kit_history_detail_unknown');
    await tester.tap(find.byTooltip('Tutup panel'));
    await settle(tester);

    // Video: real playback of the bundled clip. Position must advance.
    await section('Video', 'video_ready');
    final player = tester.widget<PaymentVideoPlayer>(
      find.byType(PaymentVideoPlayer),
    );
    await pumpUntil(
      tester,
      () => player.controller.value.phase == VideoPhase.ready,
      reason: 'video loaded',
    );
    await tester.tap(find.byTooltip('Putar'));
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final position = player.controller.value.position;
    // ignore: avoid_print
    print('VIDEO_POSITION_MS=${position.inMilliseconds}');
    expect(position, greaterThan(const Duration(seconds: 2)));
    await binding.takeScreenshot('${platform}_kit_video_playing');
    await tester.tap(find.byTooltip('Jeda'));
    await settle(tester);
    expect(player.controller.value.phase, VideoPhase.paused);

    // Switching away pauses (tickers off in the hidden tab).
    await tester.tap(find.byTooltip('Putar'));
    await settle(tester);
    app.selectTab(0);
    await settle(tester);
    expect(player.controller.value.phase, VideoPhase.paused);
  });
}
