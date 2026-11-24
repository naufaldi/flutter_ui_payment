import 'dart:ui' show BoxHeightStyle;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:rakit_ui/rakit_ui.dart';

import 'helpers/toast.dart';

void main() {
  late BuildContext context;
  Future<void> mount(WidgetTester tester, TextDirection direction) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          brightness: direction == TextDirection.ltr
              ? Brightness.light
              : Brightness.dark,
          snackBarTheme: const SnackBarThemeData(showCloseIcon: true),
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: Directionality(textDirection: direction, child: child!),
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

  for (final direction in TextDirection.values) {
    testWidgets('B4: at 320 dp and 200% the person reads the whole toast and '
        'can reach Undo and close (${direction.name})', (tester) async {
      await mount(tester, direction);
      var undone = 0;
      final toast = showPaymentToast(
        context,
        message: 'Payment of 120 sent to Alex',
        actionLabel: 'Undo',
        onAction: () => undone++,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);

      final surface = toastSurface(context);
      final material = tester.widget<Material>(surface);
      expect(material.clipBehavior, Clip.hardEdge);
      expect(material.elevation, 0);
      final pill = tester.getRect(surface);
      final message = find.text('Payment of 120 sent to Alex');
      final text = tester.getRect(message);
      final undoButton = find.widgetWithText(TextButton, 'Undo');
      final closeButton = find.byKey(StandardComponentType.closeButton.key);
      expect(undoButton.hitTestable(), findsOneWidget);
      expect(closeButton.hitTestable(), findsOneWidget);
      expect(
        tester.getSemantics(closeButton).getSemanticsData().tooltip,
        MaterialLocalizations.of(context).closeButtonTooltip,
      );
      final action = tester.getRect(undoButton);
      final close = tester.getRect(closeButton);
      final screen = Offset.zero & tester.view.physicalSize;
      for (final rect in [text, action, close]) {
        expect(pill.intersect(rect), rect, reason: '$rect inside $pill');
      }
      expect(screen.intersect(pill), pill);
      // D88: use the rendered first line, not the center of the whole message.
      final firstLine = tester
          .renderObject<RenderParagraph>(message)
          .getBoxesForSelection(
            const TextSelection(baseOffset: 0, extentOffset: 1),
            boxHeightStyle: BoxHeightStyle.max,
          )
          .single
          .toRect();
      expect(text.height, greaterThan(firstLine.height));
      final closeIcon = find.descendant(
        of: closeButton,
        matching: find.byIcon(Icons.close),
      );
      expect(
        tester.getCenter(closeIcon).dy,
        closeTo(text.top + firstLine.center.dy, 2),
      );

      // The action sits on its own line under the message, on the end edge.
      expect(action.top, greaterThanOrEqualTo(text.bottom));
      final ltr = direction == TextDirection.ltr;
      expect(
        ltr ? action.right : action.left,
        closeTo(ltr ? close.left : close.right, 13),
      );
      for (final target in [action, close]) {
        expect(target.width, greaterThanOrEqualTo(48));
        expect(target.height, greaterThanOrEqualTo(48));
      }

      await tester.tap(undoButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(undone, 1);
      expect(find.byType(SnackBar), findsNothing);
      await toast.closed;
    });
  }
}
