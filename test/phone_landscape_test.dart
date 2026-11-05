import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rakit_ui/rakit_ui.dart';

import 'dialog_test.dart' show app, surface;

// D92: overlays pick their phone or wide pattern from the window's shortest
// side, so a phone keeps its phone patterns in landscape and a tablet keeps
// the wide ones in either orientation.
const phoneLandscape = Size(640, 360);
const tabletPortrait = Size(800, 1280);
const tabletLandscape = Size(1280, 800);

/// One screen with the four overlays that switch pattern at 600 dp.
Widget page() => Builder(
  builder: (context) => ListView(
    children: [
      TextButton(
        onPressed: () => showPaymentConfirmDialog(
          context,
          title: 'Sign out of all devices?',
          message:
              'You will need to sign in again on every device. Payments '
              'already sent are not affected.',
          confirmLabel: 'Sign out',
          destructive: true,
        ),
        child: const Text('Confirm'),
      ),
      PaymentMenu(
        entries: [
          PaymentMenuItem(label: 'Download PDF', onSelected: () {}),
          PaymentMenuItem(label: 'Share', onSelected: () {}),
        ],
      ),
      PaymentSearchField<String>(
        label: 'Province',
        options: const [
          PaymentSearchOption(value: 'barat', label: 'Jawa Barat'),
          PaymentSearchOption(value: 'timur', label: 'Jawa Timur'),
        ],
        selected: null,
        onSelected: (_) {},
      ),
      TextButton(
        onPressed: () => showPaymentFocusView<void>(
          context,
          builder: (_) => const PaymentFocusView(
            title: 'Report a problem',
            child: Text('What went wrong?'),
          ),
        ),
        child: const Text('Report'),
      ),
    ],
  ),
);

Future<void> openAndClose(
  WidgetTester tester,
  Finder trigger,
  void Function() expectPattern,
) async {
  await tester.ensureVisible(trigger);
  await tester.pumpAndSettle();
  await tester.tap(trigger);
  await tester.pumpAndSettle();
  expectPattern();
  // Back closes each of the four overlays.
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a phone in landscape gets the phone patterns', (tester) async {
    surface(tester, phoneLandscape);
    await tester.pumpWidget(app(page()));

    // At rest the search field is a trigger, not an inline text field.
    expect(
      find.descendant(
        of: find.byType(PaymentSearchField<String>),
        matching: find.byType(EditableText),
      ),
      findsNothing,
    );

    void sheet() {
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);
    }

    await openAndClose(tester, find.text('Confirm'), sheet);
    await openAndClose(tester, find.byTooltip('More actions'), sheet);
    await openAndClose(tester, find.byType(PaymentSearchField<String>), sheet);
    await openAndClose(tester, find.text('Report'), sheet);
  });

  // B4 on the landscape confirm sheet: nothing clipped at 200%.
  testWidgets(
    'a phone in landscape at 200% shows the whole question and both actions',
    (tester) async {
      surface(tester, phoneLandscape);
      await tester.pumpWidget(app(page(), scale: 2));
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      final screen = Offset.zero & phoneLandscape;
      for (final label in ['Sign out', 'Cancel']) {
        final action = tester.getRect(
          find.widgetWithText(PaymentButton, label),
        );
        expect(screen.contains(action.topLeft), isTrue, reason: label);
        expect(screen.contains(action.bottomRight), isTrue, reason: label);
      }
      // The message is in a scroll view, so the person can read all of it.
      final message = find.textContaining('Payments already sent');
      final scroller = find.ancestor(
        of: message,
        matching: find.byType(Scrollable),
      );
      expect(scroller, findsOneWidget);
      await tester.drag(scroller, const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(
        tester.getRect(message).bottom,
        lessThanOrEqualTo(tester.getRect(scroller).bottom),
      );
    },
  );

  for (final (name, size) in [
    ('portrait', tabletPortrait),
    ('landscape', tabletLandscape),
  ]) {
    testWidgets('a tablet in $name keeps the wide patterns', (tester) async {
      surface(tester, size);
      await tester.pumpWidget(app(page()));

      // The search field is inline, with its list anchored under it.
      expect(
        find.descendant(
          of: find.byType(PaymentSearchField<String>),
          matching: find.byType(EditableText),
        ),
        findsOneWidget,
      );

      await openAndClose(tester, find.text('Confirm'), () {
        expect(find.byType(Dialog), findsOneWidget);
        expect(find.byType(BottomSheet), findsNothing);
      });
      await openAndClose(tester, find.byTooltip('More actions'), () {
        expect(find.text('Download PDF'), findsOneWidget);
        expect(find.byType(BottomSheet), findsNothing);
      });
      await openAndClose(tester, find.text('Report'), () {
        expect(find.byType(PaymentFocusView), findsOneWidget);
        expect(find.byType(BottomSheet), findsNothing);
      });
    });
  }
}
