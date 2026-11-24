import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rakit_ui/rakit_ui.dart';
import 'package:rakit_ui/src/foundation/token_resolvers.dart' show toneIcon;
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
  testWidgets('badge status remains readable at 320 dp and 200%', (
    tester,
  ) async {
    const label = 'Payment approval still pending';
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      host(
        const PaymentBadge(
          tone: StatusTone.warning,
          label: label,
          icon: Icons.schedule,
        ),
        2,
      ),
    );
    expect(find.bySemanticsLabel(label), findsOneWidget);
    final badge = tester.getRect(find.byType(PaymentBadge));
    for (final content in [find.text(label), find.byIcon(Icons.schedule)]) {
      final bounds = tester.getRect(content);
      expect(badge.intersect(bounds), bounds);
    }
    expect(tester.takeException(), isNull);
  });
  testWidgets('banner announces the changed total', (tester) async {
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
    PaymentButton hug(PaymentButtonVariant variant) => PaymentButton(
      label: 'Retry',
      width: PaymentWidth.hug,
      variant: variant,
      onPressed: () {},
    );
    final link = PaymentLink(label: 'Contact support', onPressed: () {});
    for (final actions in <List<Widget>>[
      [FilledButton(onPressed: () {}, child: const Text('Retry'))],
      [PaymentButton(label: 'Retry', onPressed: () {})],
      [hug(PaymentButtonVariant.primary)],
      [hug(PaymentButtonVariant.quiet)],
      // D48a: never two buttons, never two links.
      [
        hug(PaymentButtonVariant.secondary),
        hug(PaymentButtonVariant.secondary),
      ],
      [link, PaymentLink(label: 'Help', onPressed: () {})],
    ]) {
      await tester.pumpWidget(
        host(
          PaymentBanner(
            tone: StatusTone.warning,
            title: 'Changed',
            actions: actions,
          ),
          1,
        ),
      );
      expect(tester.takeException(), isAssertionError);
      await tester.pumpWidget(const SizedBox());
    }
    await tester.pumpWidget(
      host(
        PaymentBanner(
          tone: StatusTone.danger,
          title: 'Payment failed',
          actions: [hug(PaymentButtonVariant.secondary), link],
        ),
        1,
      ),
    );
    expect(tester.takeException(), isNull);
    // The button draws small (36 dp) inside its 48 dp target.
    final drawn = tester.getRect(
      find.descendant(
        of: find.byType(PaymentButton),
        matching: find.byType(OutlinedButton),
      ),
    );
    expect(drawn.height, 36);
    // The drawn button sits 8 under the title and 12 above the edge; its
    // 48 dp target overlaps the gap and the padding.
    expect(drawn.top - tester.getBottomLeft(find.text('Payment failed')).dy, 8);
    expect(
      tester.getRect(find.byType(PaymentBanner)).bottom - drawn.bottom,
      12,
    );
  });
  for (final scale in [1.0, 2.0]) {
    testWidgets('banner anatomy at $scale×', (tester) async {
      var dismissed = 0;
      Widget banner({VoidCallback? onDismiss}) => PaymentBanner(
        tone: StatusTone.warning,
        title: 'Total changed',
        message: 'Rp102.500 → Rp104.000',
        onDismiss: onDismiss,
        actions: [PaymentLink(label: 'Review total', onPressed: () {})],
      );
      await tester.pumpWidget(host(banner(), scale));
      final plain = tester.getSize(find.byType(PaymentBanner));
      await tester.pumpWidget(
        host(banner(onDismiss: () => dismissed++), scale),
      );
      // The close target overlaps the padding: no extra height.
      expect(tester.getSize(find.byType(PaymentBanner)), plain);
      // Title, message and action share the text column.
      final edge = tester.getTopLeft(find.text('Total changed')).dx;
      expect(tester.getTopLeft(find.text('Rp102.500 → Rp104.000')).dx, edge);
      expect(tester.getTopLeft(find.text('Review total')).dx, edge);
      // Icon and close glyph centre on the title's first line.
      final line = scale * 20;
      final firstLine =
          tester.getTopLeft(find.text('Total changed')).dy + line / 2;
      expect(
        tester.getCenter(find.byIcon(PaymentIcons.warning)).dy,
        closeTo(firstLine, 0.5),
      );
      expect(
        tester.getCenter(find.byIcon(PaymentIcons.close)).dy,
        closeTo(firstLine, 0.5),
      );
      // Dismiss reports once.
      final close = find.byIcon(PaymentIcons.close);
      await tester.tap(close);
      await tester.pump();
      await tester.tap(close, warnIfMissed: false);
      await tester.pump();
      expect(dismissed, 1);
    });
  }
  testWidgets('re-quote banner states old → new and cannot be dismissed', (
    tester,
  ) async {
    PaymentQuote quote(int revision, int fee) => PaymentQuote(
      id: 'Q-1',
      revision: revision,
      lines: [
        const QuoteLine(label: 'Paket Belajar', amount: Money.idr(100000)),
        QuoteLine(
          label: 'Service fee',
          amount: Money.idr(fee),
          kind: QuoteLineKind.fee,
        ),
      ],
      total: Money.idr(100000 + fee),
      expiresAt: DateTime.utc(2030),
    );
    await tester.pumpWidget(
      host(
        SingleChildScrollView(
          child: PaymentSummary(
            quote: quote(2, 3500),
            previousQuote: quote(1, 2500),
          ),
        ),
        1,
      ),
    );
    final banner = tester.widget<PaymentBanner>(find.byType(PaymentBanner));
    expect(banner.onDismiss, isNull);
    expect(banner.message, contains('102,500'));
    expect(banner.message, contains('103,500'));
    expect(find.byIcon(PaymentIcons.close), findsNothing);
  });
  testWidgets('long banner at 320 dp and 200% keeps both actions reachable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var retries = 0;
    var supportRequests = 0;
    await tester.pumpWidget(
      host(
        SingleChildScrollView(
          child: PaymentBanner(
            tone: StatusTone.danger,
            title: 'Pembayaran belum berhasil dikonfirmasi',
            message: 'Periksa kembali jumlah pembayaran sebelum mencoba lagi.',
            onDismiss: () {},
            actions: [
              PaymentButton(
                label: 'Coba lagi',
                variant: PaymentButtonVariant.secondary,
                width: PaymentWidth.hug,
                onPressed: () => retries++,
              ),
              PaymentLink(
                label: 'Hubungi bantuan',
                onPressed: () => supportRequests++,
              ),
            ],
          ),
        ),
        2,
      ),
    );
    expect(find.bySemanticsLabel('Coba lagi'), findsOneWidget);
    expect(find.bySemanticsLabel('Hubungi bantuan'), findsOneWidget);
    await tester.tap(find.text('Coba lagi'));
    await tester.tap(find.text('Hubungi bantuan'));
    await tester.pump();
    expect(retries, 1);
    expect(supportRequests, 1);
    expect(tester.takeException(), isNull);
  });
}
