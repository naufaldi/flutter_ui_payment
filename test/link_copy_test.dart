import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'first_line_test.dart' show host;

void main() {
  testWidgets('icon action is 48 dp and disabled actions do nothing', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const Center(
          child: PaymentIconButton(
            icon: PaymentIcons.close,
            tooltip: 'Close',
            onPressed: null,
          ),
        ),
        1,
      ),
    );
    expect(tester.getSize(find.byType(IconButton)), const Size(48, 48));
    expect(find.byTooltip('Close'), findsOneWidget);
  });
  testWidgets('external link speaks role and hint', (tester) async {
    final semantics = tester.ensureSemantics();
    var calls = 0;
    await tester.pumpWidget(
      host(
        PaymentLink(label: 'Policy', external: true, onPressed: () => calls++),
        1,
      ),
    );
    final node = tester.getSemantics(find.byType(PaymentLink));
    expect(node.flagsCollection.isLink, true);
    expect(node.hint, 'Opens outside the app');
    await tester.tap(find.text('Policy'));
    expect(calls, 1);
    semantics.dispose();
  });
  testWidgets('copy confirms for 1500 ms and then reverts', (tester) async {
    await tester.pumpWidget(
      host(PaymentCopyButton(value: 'DEMO', onCopy: (_) async => true), 1),
    );
    await tester.tap(find.byTooltip('Copy'));
    await tester.pump();
    expect(find.byIcon(PaymentIcons.copied), findsOneWidget);
    expect(find.text('Copied'), findsNothing);
    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.byIcon(PaymentIcons.copy), findsOneWidget);
  });
  testWidgets('false and throwing copy failures persist inline', (
    tester,
  ) async {
    for (final throws in [false, true]) {
      await tester.pumpWidget(
        host(
          PaymentCopyButton(
            key: ValueKey(throws),
            value: 'DEMO',
            onCopy: (_) async {
              if (throws) throw StateError('host failure');
              return false;
            },
          ),
          1,
        ),
      );
      await tester.tap(find.byTooltip('Copy'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Copy failed'), findsOneWidget);
    }
  });
  testWidgets('a failed copy keeps the button size and clears on retry', (
    tester,
  ) async {
    var ok = false;
    await tester.pumpWidget(
      host(
        Row(
          children: [
            PaymentCopyButton(value: 'DEMO', onCopy: (_) async => ok),
            const Text('After'),
          ],
        ),
        1,
      ),
    );
    final before = tester.getRect(find.byType(PaymentCopyButton));
    final after = tester.getTopLeft(find.text('After'));
    await tester.tap(find.byTooltip('Copy'));
    await tester.pump();
    expect(find.text('Copy failed'), findsOneWidget);
    expect(find.byIcon(PaymentIcons.danger), findsOneWidget);
    expect(tester.getRect(find.byType(PaymentCopyButton)), before);
    expect(tester.getTopLeft(find.text('After')), after);
    ok = true;
    await tester.tap(find.byTooltip('Copy'));
    await tester.pump();
    expect(find.text('Copy failed'), findsNothing);
    await tester.pump(const Duration(seconds: 2));
  });
  testWidgets('pending copy ignores repeated presses and stale completion', (
    tester,
  ) async {
    final result = Completer<bool>();
    var calls = 0;
    await tester.pumpWidget(
      host(
        PaymentCopyButton(
          value: 'DEMO',
          onCopy: (_) {
            calls++;
            return result.future;
          },
        ),
        1,
      ),
    );
    await tester.tap(find.byTooltip('Copy'));
    await tester.pump();
    await tester.tap(find.byTooltip('Copy'));
    expect(calls, 1);
    await tester.pumpWidget(host(const SizedBox(), 1));
    result.complete(true);
    await tester.pump();
    expect(tester.takeException(), null);
  });
  testWidgets('banner reports dismissal once and accepts links', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      host(
        PaymentBanner(
          tone: StatusTone.warning,
          title: 'Total changed',
          onDismiss: () => calls++,
          actions: [PaymentLink(label: 'Review', onPressed: () {})],
        ),
        1,
      ),
    );
    await tester.tap(find.byTooltip('Hide banner: Total changed'));
    await tester.tap(find.byTooltip('Hide banner: Total changed'));
    expect(calls, 1);
  });
  testWidgets('custom menu trigger opens entries', (tester) async {
    await tester.pumpWidget(
      host(
        PaymentMenu(
          trigger: (toggle, node) => PaymentButton(
            label: 'Options',
            width: PaymentWidth.hug,
            focusNode: node,
            onPressed: toggle,
          ),
          entries: [PaymentMenuItem(label: 'Download', onSelected: () {})],
        ),
        1,
      ),
    );
    await tester.tap(find.text('Options'));
    await tester.pumpAndSettle();
    expect(find.text('Download'), findsOneWidget);
  });
}
