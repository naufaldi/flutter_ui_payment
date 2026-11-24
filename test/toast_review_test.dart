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
    bool closeIcon = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          snackBarTheme: SnackBarThemeData(showCloseIcon: closeIcon),
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: reduced,
            accessibleNavigation: accessible,
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
}
