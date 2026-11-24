import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rakit_ui/rakit_ui.dart';
import 'package:rakit_ui_example/qris_checkout_demo.dart';

import 'support.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'QRIS example scans and checks the same attempt after code expiry',
    (tester) async {
      const captureScreens = bool.fromEnvironment('CAPTURE_QRIS');
      final code = find.byType(PaymentImage);
      final check = find.text('Cek status');
      var now = qrisDemoStart;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      Future<void> tap(Finder target) async {
        await tester.tap(target);
        await tester.pumpAndSettle();
      }

      Future<void> choose(String name) async {
        await tap(find.byTooltip('Skenario demo'));
        await tap(find.text(name).last);
      }

      Future<void> showCode() async {
        await Scrollable.ensureVisible(tester.element(code), alignment: .75);
        await tester.pumpAndSettle();
        expect(code.hitTestable(), findsOneWidget);
        final image = find.descendant(
          of: code,
          matching: find.byType(RawImage),
        );
        expect(tester.widget<RawImage>(image).image, isNotNull);
      }

      PaymentAttempt current() => tester
          .widget<PaymentStatusView>(find.byType(PaymentStatusView))
          .attempt;

      for (final dark in [false, true]) {
        for (final scale in [1.0, 2.0]) {
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          await tester.pumpWidget(
            QrisCheckoutDemo(
              key: UniqueKey(),
              initialDark: dark,
              delay: Duration.zero,
              clock: () => now,
            ),
          );
          await tester.pumpAndSettle();
          expect(check.hitTestable(), findsOneWidget);
          expect(find.text('Ruang Bayar Akademi'), findsOneWidget);
          expect(find.textContaining('152.500'), findsOneWidget);
          final suffix = '${dark ? '_dark' : ''}${scale == 2 ? '_200' : ''}';
          if (captureScreens) {
            await capture(
              binding,
              tester,
              '${scale == 2 ? 'after_qris' : 'android_block_qris'}$suffix',
            );
          }
          await showCode();
          if (captureScreens && scale == 2) {
            await capture(binding, tester, 'android_block_qris$suffix');
          }
        }
      }

      final attemptId = current().attemptId;
      now = qrisDemoExpiry;
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(code, findsNothing);
      expect(find.text('Kode QR kedaluwarsa'), findsOneWidget);
      expect(current().status, PaymentStatus.pending);
      expect(check.hitTestable(), findsOneWidget);
      if (captureScreens) {
        tester.platformDispatcher.textScaleFactorTestValue = 1.0;
        await tester.pumpAndSettle();
        final warning = find.text('Kode QR kedaluwarsa');
        await tester.ensureVisible(warning);
        await tester.pumpAndSettle();
        await capture(binding, tester, 'android_block_qris_elapsed');
      }
      await tap(check);
      expect(current().attemptId, attemptId);
      expect(find.text('Pembayaran berhasil'), findsOneWidget);

      now = qrisDemoStart;
      tester.platformDispatcher.textScaleFactorTestValue = 1.0;
      await choose('Respons QRIS hilang');
      expect(find.text('Hasil belum terkonfirmasi'), findsOneWidget);
      expect(code, findsNothing);
      if (captureScreens) {
        await capture(binding, tester, 'android_block_qris_unknown');
      }
      await tap(check);
      expect(current().attemptId, attemptId);
      await showCode();

      await choose('Cek status gagal');
      await tap(check);
      expect(find.text('Menunggu'), findsOneWidget);
      expect(current().observation, Observation.unavailable);
      expect(code, findsNothing);
      if (captureScreens) {
        await capture(binding, tester, 'after_qris_check_failed');
      }
      await tap(check);
      expect(current().attemptId, attemptId);
      expect(find.text('Pembayaran berhasil'), findsOneWidget);
      expect(code, findsNothing);

      final app = await launch(tester);
      app.selectTab(2);
      await settle(tester);
      await openGalleryPage(tester, 'QRIS checkout');
      expect(find.text('QRIS payment'), findsOneWidget);
      expect(find.text('Check status').hitTestable(), findsOneWidget);
      await showCode();
      if (captureScreens) {
        await capture(binding, tester, 'after_qris_gallery');
      }
      expect(tester.takeException(), isNull);
    },
  );
}
