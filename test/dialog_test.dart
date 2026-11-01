import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';

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
