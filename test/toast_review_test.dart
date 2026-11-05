import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rakit_ui/rakit_ui.dart';
import 'helpers/toast.dart';

void main() {
  setUp(() {
    final semantics = TestWidgetsFlutterBinding.ensureInitialized()
        .ensureSemantics();
    addTearDown(semantics.dispose);
  });
  late BuildContext context;
  Future<void> mount(
    WidgetTester tester, {
    bool reduced = false,
    bool accessible = false,
    bool dark = false,
    double scale = 1,
    bool closeIcon = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          brightness: dark ? Brightness.dark : Brightness.light,
          snackBarTheme: SnackBarThemeData(showCloseIcon: closeIcon),
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: reduced,
            accessibleNavigation: accessible,
            textScaler: TextScaler.linear(scale),
          ),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (c) {
              context = c;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
  }

  Future<void> settleBar(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
  }

  void hosts(int count) {
    for (var i = 0; i < count; i++) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Host $i'),
          duration: const Duration(seconds: 30),
        ),
      );
    }
  }

  for (final accessible in [false, true]) {
    for (final count in [1, 2]) {
      testWidgets(
        'review replaced waiting never paints accessible=$accessible hosts=$count',
        (tester) async {
          await mount(
            tester,
            reduced: !accessible,
            accessible: accessible,
            closeIcon: true,
          );
          showPaymentToast(context, message: 'Kit K', pending: true);
          await settleBar(tester);
          hosts(count);
          showPaymentToast(context, message: 'Toast Y', pending: true);
          await settleBar(tester);
          expect(find.text('Host 0'), findsOneWidget);
          final z = showPaymentToast(
            context,
            message: 'Toast Z',
            pending: true,
          );
          for (var frame = 0; frame < 200; frame++) {
            // Drive the remaining host out explicitly. Flutter 3.44.6's timer
            // callback asserts when forwarding another zero-duration bar.
            if (frame == 64 &&
                find.textContaining('Host').evaluate().isNotEmpty) {
              ScaffoldMessenger.of(context).removeCurrentSnackBar();
            }
            await tester.pump(const Duration(milliseconds: 16));
            expectInvisibleToast(tester, 'Toast Y');
            if (find.text('Toast Z').evaluate().isEmpty &&
                find.textContaining('Host').evaluate().isEmpty) {
              final bars = tester.widgetList<Material>(
                find.descendant(
                  of: find.byType(SnackBar),
                  matching: find.byType(Material),
                ),
              );
              expect(find.byIcon(Icons.close), findsNothing);
              expect(
                bars.where((m) => m.color != null && m.color!.a != 0),
                isEmpty,
              );
              final live = tester
                  .widgetList<Semantics>(
                    find.descendant(
                      of: find.byType(SnackBar),
                      matching: find.byType(Semantics),
                    ),
                  )
                  .where((s) => s.properties.liveRegion == true);
              for (final region in live) {
                final node = tester.getSemantics(find.byWidget(region));
                expect(node.getSemanticsData().label, isEmpty);
                expect(node.childrenCount, 0);
              }
            }
          }
          expect(find.text('Toast Z'), findsOneWidget);
          z.dismiss();
          await settleBar(tester);
        },
      );
    }
  }
  testWidgets(
    'review host clear completes dropped controller when newest arrives',
    (tester) async {
      await mount(tester);
      showPaymentToast(context, message: 'Kit K', pending: true);
      await settleBar(tester);
      hosts(1);
      final y = showPaymentToast(context, message: 'Toast Y', pending: true);
      await settleBar(tester);
      var closed = false;
      unawaited(y.closed.then((_) => closed = true));
      ScaffoldMessenger.of(context).clearSnackBars();
      await settleBar(tester);
      final z = showPaymentToast(context, message: 'Toast Z', pending: true);
      await settleBar(tester);
      expect(closed, isTrue);
      z.dismiss();
      await settleBar(tester);
    },
  );
  testWidgets('review messenger disposal completes all waiting controllers', (
    tester,
  ) async {
    await mount(tester);
    final k = showPaymentToast(context, message: 'Kit K', pending: true);
    await settleBar(tester);
    hosts(1);
    final y = showPaymentToast(context, message: 'Toast Y', pending: true);
    final z = showPaymentToast(context, message: 'Toast Z', pending: true);
    var closed = 0;
    for (final c in [k, y, z]) {
      unawaited(c.closed.then((_) => closed++));
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(closed, 3);
  });
  testWidgets('review live region and swipe stay available', (tester) async {
    await mount(tester);
    final c = showPaymentToast(context, message: 'Swipe me', pending: true);
    await settleBar(tester);
    expect(find.bySemanticsLabel('Swipe me'), findsOneWidget);
    final live = tester
        .widgetList<Semantics>(
          find.descendant(
            of: find.byType(SnackBar),
            matching: find.byType(Semantics),
          ),
        )
        .where((s) => s.properties.liveRegion == true);
    expect(live, hasLength(1));
    var closed = false;
    unawaited(c.closed.then((_) => closed = true));
    await tester.drag(find.text('Swipe me'), const Offset(0, 500));
    await settleBar(tester);
    expect(find.text('Swipe me'), findsNothing);
    expect(closed, isTrue);
  });
  for (final dark in [false, true]) {
    for (final action in [false, true]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('review geometry dark=$dark action=$action scale=$scale', (
          tester,
        ) async {
          tester.view.physicalSize = const Size(320, 640);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await mount(tester, dark: dark, scale: scale);
          final c = showPaymentToast(
            context,
            message: 'Copied',
            pending: !action,
            actionLabel: action ? 'Undo' : null,
            onAction: action ? () {} : null,
          );
          await settleBar(tester);
          final materials = find.descendant(
            of: find.byType(SnackBar),
            matching: find.byWidgetPredicate(
              (w) =>
                  w is Material &&
                  w.color == PaymentTheme.of(context).textPrimary,
            ),
          );
          final material = tester.widget<Material>(materials.first);
          // Measured on 1812ba1, before moving the SnackBar surface inward.
          // At 200% the action now wraps under the message instead of
          // breaking it mid-word (D88).
          final top = action
              ? (scale == 1 ? 560.0 : 512.0)
              : (scale == 1 ? 580.0 : 560.0);
          final textRect = action
              ? (scale == 1
                    ? const Rect.fromLTRB(64, 582, 204, 602)
                    : const Rect.fromLTRB(76, 524, 296, 564))
              : (scale == 1
                    ? const Rect.fromLTRB(64, 592, 288, 612)
                    : const Rect.fromLTRB(76, 572, 288, 612));
          expect(
            tester.getRect(materials.first),
            Rect.fromLTRB(16, top, 304, 624),
          );
          expect(tester.getRect(find.text('Copied')), textRect);
          expect(
            material.color,
            dark ? const Color(0xffe6e0e9) : const Color(0xff1d1b20),
          );
          expect(
            material.shape,
            const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
          );
          expect(material.clipBehavior, Clip.hardEdge);
          expect(material.elevation, 0);
          if (action) {
            final target = tester.getSize(
              find.widgetWithText(TextButton, 'Undo'),
            );
            expect(target.width, greaterThanOrEqualTo(48));
            expect(target.height, greaterThanOrEqualTo(48));
          }
          expect(tester.takeException(), isNull);
          c.dismiss();
          await settleBar(tester);
        });
      }
    }
  }
}
