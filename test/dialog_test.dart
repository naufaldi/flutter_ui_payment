import 'dart:async';
import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rakit_ui/rakit_ui.dart';

const compact = Size(393, 844);
const wide = Size(1024, 768);

// The text scale wraps the whole app, so it reaches the pushed route too.
Widget app(
  Widget child, {
  double scale = 1,
  Locale locale = const Locale('en'),
}) => MaterialApp(
  locale: locale,
  supportedLocales: const [Locale('en'), Locale('id')],
  localizationsDelegates: const [
    PaymentLocalizations.delegate,
    ...GlobalMaterialLocalizations.delegates,
  ],
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: Scaffold(body: child),
);

void surface(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// A button that opens the confirmation, and a reader for its result.
(Widget, bool? Function()) opener({
  String confirmLabel = 'Confirm',
  String? cancelLabel,
  bool destructive = false,
}) {
  bool? result;
  final open = Builder(
    builder: (context) => TextButton(
      onPressed: () async {
        result = await showPaymentConfirmDialog(
          context,
          title: 'Remove card?',
          message: 'You can add it again later.',
          confirmLabel: confirmLabel,
          cancelLabel: cancelLabel,
          destructive: destructive,
        );
      },
      child: const Text('Open'),
    ),
  );
  return (open, () => result);
}

/// Confirm and cancel rects, in that order.
(Rect, Rect) actionRects(WidgetTester tester, String confirm, String cancel) =>
    (
      tester.getRect(find.widgetWithText(PaymentButton, confirm)),
      tester.getRect(find.widgetWithText(PaymentButton, cancel)),
    );

void main() {
  testWidgets('async removal locks repeat activation and keeps host recovery', (
    tester,
  ) async {
    surface(tester, const Size(320, 640));
    final semantics = tester.ensureSemantics();
    final firstWrite = Completer<bool>();
    final secondWrite = Completer<bool>();
    final failed = ValueNotifier(false);
    addTearDown(failed.dispose);
    var writes = 0;
    bool? result;
    late ModalRoute<bool> prompt;
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showPaymentAsyncConfirmDialog(
                context,
                title: 'Remove statement?',
                description: Builder(
                  builder: (context) {
                    prompt = ModalRoute.of<bool>(context)!;
                    return ValueListenableBuilder(
                      valueListenable: failed,
                      builder: (_, showFailure, _) => showFailure
                          ? Semantics(
                              liveRegion: true,
                              child: const Text('Not removed. Try again.'),
                            )
                          : const Text('This cannot be undone.'),
                    );
                  },
                ),
                confirmLabel: 'Remove statement',
                pendingLabel: 'Removing statement',
                destructive: true,
                onConfirm: () async {
                  if (++writes == 1) {
                    final removed = await firstWrite.future;
                    failed.value = !removed;
                    return removed;
                  }
                  return secondWrite.future;
                },
              );
            },
            child: const Text('Open'),
          ),
        ),
        scale: 2,
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(Focus.of(tester.element(find.text('Cancel'))).hasFocus, isTrue);
    final confirm = find.text('Remove statement');
    await tester.tap(confirm);
    await tester.tap(confirm); // Same frame: the old enabled UI is still built.
    await tester.tap(find.text('Cancel'));
    await tester.binding.handlePopRoute();
    expect(writes, 1);
    expect(result, isNull);

    await tester.pump();
    final busy = find.semantics.byValue('Removing statement').evaluate().single;
    expect(busy.flagsCollection.isLiveRegion, isTrue);
    expect(
      tester
          .getSemantics(confirm)
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isFalse,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.tapAt(const Offset(4, 4));
    await tester.drag(find.text('Remove statement?'), const Offset(0, 280));
    expect(result, isNull);

    firstWrite.complete(false);
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Not removed. Try again.'), findsOneWidget);
    expect(result, isNull);
    expect(writes, 1);
    await tester.tap(confirm);
    await tester.pump();
    expect(writes, 2);
    prompt.addLocalHistoryEntry(LocalHistoryEntry());
    secondWrite.complete(true);
    await tester.pumpAndSettle();
    expect(find.text('Remove statement?'), findsNothing);
    expect(result, isTrue);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('system Back cannot pop the parent of a pending nested confirm', (
    tester,
  ) async {
    surface(tester, const Size(360, 640));
    final write = Completer<bool>();
    bool? result;
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => unawaited(
              Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: const Text('Saved records')),
                    body: Navigator(
                      onGenerateRoute: (_) => MaterialPageRoute<void>(
                        builder: (context) => TextButton(
                          onPressed: () async {
                            result = await showPaymentAsyncConfirmDialog(
                              context,
                              title: 'Remove record?',
                              description: const Text('This cannot be undone.'),
                              confirmLabel: 'Remove record',
                              onConfirm: () => write.future,
                            );
                          },
                          child: const Text('Open confirmation'),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            child: const Text('Open records'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open records'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open confirmation'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove record'));
    await tester.binding.handlePopRoute();
    expect(result, isNull);
    write.complete(true);
    await tester.pumpAndSettle();

    expect(find.text('Saved records'), findsOneWidget);
    expect(find.text('Open confirmation'), findsOneWidget);
    expect(find.text('Remove record?'), findsNothing);
    expect(result, isTrue);
  });

  testWidgets('wide dialog uses enter and reverse-duration exit', (
    tester,
  ) async {
    surface(tester, wide);
    late BuildContext context;
    await tester.pumpWidget(
      app(
        Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
      ),
    );
    unawaited(
      showPaymentConfirmDialog(
        context,
        title: 'Confirm payment',
        message: 'Continue?',
        confirmLabel: 'Confirm',
      ),
    );
    await tester.pumpAndSettle();
    final route = ModalRoute.of(tester.element(find.byType(Dialog)))!;
    expect(route.transitionDuration, const Duration(milliseconds: 220));
    expect(route.reverseTransitionDuration, const Duration(milliseconds: 150));
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 149));
    expect(find.byType(Dialog), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1, microseconds: 1));
    await tester.pump();
    expect(find.byType(Dialog), findsNothing);
  });

  for (final (name, size) in [('compact', compact), ('wide', wide)]) {
    for (final destructive in [false, true]) {
      for (final action in [
        'Confirm',
        'Cancel',
        'barrier',
        'Escape',
        'Enter',
        if (size == compact) 'swipe',
      ]) {
        testWidgets('$name destructive=$destructive $action', (tester) async {
          surface(tester, size);
          final (open, read) = opener(destructive: destructive);
          await tester.pumpWidget(app(open));
          await tester.tap(find.text('Open'));
          await tester.pumpAndSettle();
          expect(find.byType(PaymentButton), findsNWidgets(2));
          final (confirm, cancel) = actionRects(tester, 'Confirm', 'Cancel');
          if (size == compact) {
            // D45: a bottom sheet, confirm stacked above cancel, both full
            // width on one 16 dp inset.
            expect(find.byType(BottomSheet), findsOneWidget);
            expect(confirm.bottom, lessThanOrEqualTo(cancel.top));
            expect(confirm.width, size.width - 32);
            expect(cancel.width, confirm.width);
            expect(confirm.left, 16);
            expect(cancel.left, 16);
          } else {
            // One row of equal-width buttons, confirm trailing.
            expect(find.byType(Dialog), findsOneWidget);
            expect(confirm.top, cancel.top);
            expect(confirm.width, cancel.width);
            expect(cancel.right, lessThan(confirm.left));
            expect(
              tester
                  .getSize(
                    find
                        .descendant(
                          of: find.byType(Dialog),
                          matching: find.byType(Material),
                        )
                        .first,
                  )
                  .width,
              400,
            );
          }
          final focusLabel = destructive ? 'Cancel' : 'Confirm';
          expect(
            Focus.of(tester.element(find.text(focusLabel))).hasFocus,
            isTrue,
          );
          switch (action) {
            case 'barrier':
              await tester.tapAt(const Offset(4, 4));
            case 'Escape':
              await tester.sendKeyEvent(LogicalKeyboardKey.escape);
            case 'Enter':
              await tester.sendKeyEvent(LogicalKeyboardKey.enter);
            case 'swipe':
              await tester.fling(
                find.text('Remove card?'),
                const Offset(0, 400),
                1000,
              );
            default:
              await tester.tap(find.text(action));
          }
          await tester.pumpAndSettle();
          expect(find.text('Remove card?'), findsNothing);
          expect(
            read(),
            action == 'Confirm' || (action == 'Enter' && !destructive),
          );
        });
      }
    }
  }

  for (final (scale, locale, confirm, cancel) in [
    (1.0, const Locale('en'), 'Remove card', 'Cancel'),
    (2.0, const Locale('en'), 'Remove card', 'Cancel'),
    (1.0, const Locale('id'), 'Kirim permintaan pembatalan', 'Tetap bayar'),
    (2.0, const Locale('id'), 'Kirim permintaan pembatalan', 'Tetap bayar'),
  ]) {
    testWidgets('compact layout is identical at $scale× in $locale', (
      tester,
    ) async {
      surface(tester, const Size(320, 640));
      final (open, _) = opener(
        confirmLabel: confirm,
        cancelLabel: locale.languageCode == 'id' ? cancel : null,
        destructive: true,
      );
      await tester.pumpWidget(app(open, scale: scale, locale: locale));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final (top, bottom) = actionRects(tester, confirm, cancel);
      expect(bottom.top - top.bottom, greaterThanOrEqualTo(8));
      expect(top.width, 320 - 32);
      expect(bottom.width, top.width);
      // Text and actions share the 16 dp start edge.
      expect(tester.getTopLeft(find.text('Remove card?')).dx, 16);
      expect(top.left, 16);
      // Both actions stay on screen at 200%.
      expect(bottom.bottom, lessThanOrEqualTo(640));
    });
  }
}
