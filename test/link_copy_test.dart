import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'first_line_test.dart' show host;

void main() {
  testWidgets('link text sits on the column edge, the target extends out', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: PaymentLink(label: 'Edit', onPressed: () {}),
              ),
              PaymentSection(
                title: 'Your details',
                trailing: PaymentLink(label: 'Edit', onPressed: () {}),
                child: const SizedBox(height: 8),
              ),
            ],
          ),
        ),
        1,
      ),
    );
    final texts = find.text('Edit');
    expect(tester.getTopLeft(texts.first).dx, 16);
    expect(tester.getTopRight(texts.last).dx, 800 - 16);
    expect(
      tester.getSize(find.byType(PaymentLink).first).width,
      greaterThanOrEqualTo(48),
    );
  });
  // #65: a lone quiet button's text starts on the column edge like a
  // link's; its box hangs outward by its padding, and rows keep it centred.
  group('quiet button on the column edge (#65)', () {
    Widget column(List<Widget> children, double scale, {TextDirection? dir}) {
      final body = Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 16,
          children: [
            const SizedBox(width: double.infinity),
            ...children,
          ],
        ),
      );
      return host(
        dir == null ? body : Directionality(textDirection: dir, child: body),
        scale,
      );
    }

    PaymentButton quiet(
      String label, {
      PaymentSize size = PaymentSize.medium,
      VoidCallback? onPressed,
    }) => PaymentButton(
      label: label,
      variant: PaymentButtonVariant.quiet,
      width: PaymentWidth.hug,
      size: size,
      onPressed: onPressed ?? () {},
    );

    for (final scale in [1.0, 2.0]) {
      for (final size in PaymentSize.values) {
        for (final label in ['Edit', 'Not now, remind me next week']) {
          testWidgets('$size "$label" at $scale', (t) async {
            await t.pumpWidget(column([quiet(label, size: size)], scale));
            expect(t.getTopLeft(find.text(label)).dx, 16);
            // The box hangs into the 16 dp gutter, never past it.
            final ink = t.getRect(find.byType(TextButton));
            expect(ink.left, lessThan(16));
            expect(ink.left, greaterThanOrEqualTo(0));
            final target = t.getSize(find.byType(PaymentButton));
            expect(target.width, greaterThanOrEqualTo(48));
            expect(target.height, greaterThanOrEqualTo(48));
            expect(t.takeException(), isNull);
          });
        }
      }
    }

    testWidgets('right to left, the text starts on the right edge', (t) async {
      await t.pumpWidget(column([quiet('Edit')], 1, dir: TextDirection.rtl));
      expect(t.getTopRight(find.text('Edit')).dx, 800 - 16);
    });

    testWidgets('a trailing slot puts the text on the end edge', (t) async {
      await t.pumpWidget(
        column([
          SizedBox(
            width: 800 - 32,
            child: PaymentSection(
              title: 'Your details',
              trailing: quiet('Edit'),
              child: const SizedBox(height: 8),
            ),
          ),
        ], 1),
      );
      expect(t.getTopRight(find.text('Edit')).dx, 800 - 16);
    });

    testWidgets('the whole target takes taps; a neighbour keeps its own', (
      t,
    ) async {
      var first = 0, second = 0;
      await t.pumpWidget(
        column([
          Wrap(
            spacing: 8,
            children: [
              quiet('Not now', onPressed: () => first++),
              quiet('Later', onPressed: () => second++),
            ],
          ),
        ], 1),
      );
      final a = t.getRect(find.byType(TextButton).first);
      final b = t.getRect(find.byType(TextButton).last);
      expect(a.right, lessThanOrEqualTo(b.left));
      final box = t.getRect(find.byType(PaymentButton).first);
      expect(box.width, greaterThanOrEqualTo(48));
      await t.tapAt(t.getCenter(find.text('Not now')));
      // The end of the first box that the hang leaves bare.
      await t.tapAt(Offset(a.right - 1, a.center.dy));
      await t.tapAt(Offset(a.right + 1, a.center.dy));
      await t.tapAt(t.getCenter(find.text('Later')));
      await t.pump();
      expect((first, second), (2, 1));
    });

    testWidgets('rows and full-width stacks keep the label centred', (t) async {
      Future<void> centred(Widget child, double width) async {
        await t.pumpWidget(column([SizedBox(width: width, child: child)], 1));
        final ink = t.getRect(find.byType(TextButton));
        expect(
          t.getCenter(find.text('Cancel')).dx,
          moreOrLessEquals(ink.center.dx, epsilon: 0.5),
        );
        expect(ink.width, greaterThanOrEqualTo(112));
        expect(ink.left, greaterThanOrEqualTo(16));
      }

      final row = PaymentButtonGroup(
        collapse: PaymentButtonGroupCollapse.none,
        children: [
          quiet('Cancel'),
          PaymentButton(
            label: 'Save',
            width: PaymentWidth.hug,
            onPressed: () {},
          ),
        ],
      );
      // One row of hug buttons, then the same group stacked full width.
      await centred(row, 600);
      await centred(row, 200);
      expect(t.getSize(find.byType(TextButton)).width, 200);
      // A stretched column fills the slot, as D45 / D62 footers do.
      await t.pumpWidget(
        host(
          SizedBox(
            width: 300,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [quiet('Cancel')],
            ),
          ),
          1,
        ),
      );
      final ink = t.getRect(find.byType(TextButton));
      expect(ink.width, 300);
      expect(t.getCenter(find.text('Cancel')).dx, ink.center.dx);
    });

    testWidgets('app bar actions keep the centred label', (t) async {
      await t.pumpWidget(
        host(
          AdaptiveNavShell(
            title: const Text('Shell'),
            sections: const [
              PaymentNavSection(
                items: [
                  PaymentNavItem(id: 'a', label: 'Home', icon: Icons.home),
                ],
              ),
            ],
            selectedId: 'a',
            onSelected: (_) {},
            actions: [quiet('Done')],
            body: const SizedBox(),
          ),
          1,
        ),
      );
      final ink = t.getRect(find.byType(TextButton));
      expect(ink.width, greaterThanOrEqualTo(112));
      expect(t.getRect(find.byType(PaymentButton)), ink);
      expect(t.getCenter(find.text('Done')).dx, ink.center.dx);
    });
  });
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
