import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'package:flutter_ui_payment/src/foundation/token_resolvers.dart'
    show toneIcon;
import 'first_line_test.dart' show host;

void main() {
  for (final tone in StatusTone.values) {
    testWidgets('badge default and override $tone', (tester) async {
      await tester.pumpWidget(
        host(PaymentBadge(tone: tone, label: 'Status'), 1),
      );
      expect(find.byIcon(toneIcon(tone)), findsOneWidget);
      await tester.pumpWidget(
        host(
          PaymentBadge(tone: tone, label: 'Status', icon: Icons.schedule),
          1,
        ),
      );
      expect(find.byIcon(Icons.schedule), findsOneWidget);
    });
  }
  for (final scale in [1.0, 2.0, 3.0]) {
    testWidgets('badge icon scales with a cap $scale', (tester) async {
      await tester.pumpWidget(
        host(const PaymentBadge.urgent(label: 'Action required'), scale),
      );
      final icon = tester.widget<Icon>(find.byIcon(PaymentIcons.danger));
      expect(icon.size, closeTo(scale == 1 ? 14 : 22.4, .00001));
      final context = tester.element(find.byType(PaymentBadge));
      final theme = PaymentTheme.of(context);
      expect(icon.color, theme.surface);
      expect(
        tester
            .widget<Container>(
              find
                  .descendant(
                    of: find.byType(PaymentBadge),
                    matching: find.byType(Container),
                  )
                  .first,
            )
            .decoration,
        isA<BoxDecoration>().having(
          (d) => d.color,
          'fill',
          theme.tone(StatusTone.danger).foreground,
        ),
      );
    });
  }
  testWidgets('banner gap and live region', (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      host(
        const PaymentBanner(
          tone: StatusTone.warning,
          title: 'Total changed',
          announce: true,
        ),
        1,
      ),
    );
    expect(
      tester.getTopLeft(find.text('Total changed')).dx -
          tester.getTopRight(find.byIcon(PaymentIcons.warning)).dx,
      12,
    );
    expect(
      tester.getSemantics(find.byType(PaymentBanner)),
      matchesSemantics(
        isLiveRegion: true,
        label: 'Total changed',
        textDirection: TextDirection.ltr,
      ),
    );
    semantics.dispose();
  });
  testWidgets('banner actions reject unsupported priorities and widths', (
    tester,
  ) async {
    for (final action in [
      FilledButton(onPressed: () {}, child: const Text('Retry')),
      PaymentButton(label: 'Retry', onPressed: () {}),
      PaymentButton(label: 'Retry', width: PaymentWidth.hug, onPressed: () {}),
    ]) {
      await tester.pumpWidget(
        host(
          PaymentBanner(
            tone: StatusTone.warning,
            title: 'Changed',
            actions: [action],
          ),
          1,
        ),
      );
      expect(tester.takeException(), isAssertionError);
      await tester.pumpWidget(const SizedBox());
    }
  });
  testWidgets('long banner at 320 and double text wraps actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      host(
        SingleChildScrollView(
          child: PaymentBanner(
            tone: StatusTone.danger,
            title: 'Pembayaran belum berhasil dikonfirmasi',
            message: 'Periksa kembali jumlah pembayaran sebelum mencoba lagi.',
            actions: [
              for (final variant in [
                PaymentButtonVariant.secondary,
                PaymentButtonVariant.quiet,
              ])
                PaymentButton(
                  label: 'Coba lagi',
                  variant: variant,
                  width: PaymentWidth.hug,
                  onPressed: () {},
                ),
            ],
          ),
        ),
        2,
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
