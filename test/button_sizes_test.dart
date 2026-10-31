import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'package:flutter_ui_payment/src/foundation/tap_target.dart';
import 'button_guard_test.dart' show host;
import 'controls_test.dart' as controls;

void main() {
  for (final scale in [1.0, 2.0]) {
    for (final size in PaymentSize.values) {
      for (final width in PaymentWidth.values) {
        for (final variant in PaymentButtonVariant.values) {
          testWidgets('$size $width $variant $scale', (tester) async {
            tester.view.physicalSize = const Size(320, 800);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            await tester.pumpWidget(
              host(
                Align(
                  alignment: Alignment.topLeft,
                  child: PaymentButton(
                    label: 'Edit',
                    size: size,
                    width: width,
                    variant: variant,
                    icon: Icons.edit_outlined,
                    onPressed: () {},
                  ),
                ),
                scale,
              ),
            );
            final box = tester.getSize(find.byType(MinTapTarget));
            expect(box.width, greaterThanOrEqualTo(48));
            expect(box.height, greaterThanOrEqualTo(48));
            if (scale == 1) {
              final material = find.descendant(
                of: find.byType(PaymentButton),
                matching: find.byType(Material),
              );
              expect(tester.getSize(material).height, switch (size) {
                PaymentSize.small => 36,
                PaymentSize.medium => 48,
                PaymentSize.large => 56,
              });
            }
            expect(find.byType(AnimatedScale), findsNothing);
            expect(tester.takeException(), isNull);
          });
        }
      }
    }
  }
  testWidgets('small extends taps only within its 48 dp box', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(
        Column(
          children: [
            const SizedBox(height: 100),
            Align(
              alignment: Alignment.centerLeft,
              child: PaymentButton(
                label: 'Edit',
                size: PaymentSize.small,
                width: PaymentWidth.hug,
                onPressed: () {
                  taps++;
                },
              ),
            ),
          ],
        ),
        1,
      ),
    );
    final visual = tester.getRect(find.byType(FilledButton));
    final box = tester.getRect(find.byType(MinTapTarget));
    await tester.tapAt(Offset(visual.center.dx, visual.top - 4));
    await tester.pump();
    expect(taps, 1);
    await tester.tapAt(Offset(visual.center.dx, box.top - 4));
    await tester.pump();
    expect(taps, 1);
    expect(box.width, greaterThanOrEqualTo(112));
    expect(box.width, lessThan(800));
  });
  testWidgets('busy, autofocus, padding and reduced motion', (tester) async {
    for (final size in PaymentSize.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: PaymentButton(
                key: ValueKey(size),
                label: 'Save changes',
                size: size,
                busy: true,
                busyLabel: 'Saving changes',
                autofocus: true,
                icon: Icons.edit_outlined,
                onPressed: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final spinner = tester.widget<PaymentSpinner>(
        find.byType(PaymentSpinner),
      );
      expect(
        spinner.size,
        size == PaymentSize.small ? PaymentSize.small : PaymentSize.medium,
      );
      for (final e in find.byType(AnimatedOpacity).evaluate()) {
        expect((e.widget as AnimatedOpacity).duration, Duration.zero);
      }
      expect(FocusManager.instance.primaryFocus?.hasFocus, isTrue);
      final style = tester
          .widget<FilledButton>(find.byType(FilledButton))
          .style!;
      expect(style.padding?.resolve({}), switch (size) {
        PaymentSize.small => const EdgeInsets.symmetric(horizontal: 12),
        PaymentSize.medium => null,
        PaymentSize.large => const EdgeInsets.symmetric(horizontal: 24),
      });
    }
  });
  testWidgets('long hug label wraps at 200 percent', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      host(
        Align(
          alignment: Alignment.topLeft,
          child: PaymentButton(
            label: 'Change the payment method for this order',
            width: PaymentWidth.hug,
            onPressed: () {},
          ),
        ),
        2,
      ),
    );
    expect(
      tester
          .getSize(find.text('Change the payment method for this order'))
          .height,
      greaterThan(40),
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('small keyboard focus ring follows the visual', (tester) async {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    await tester.pumpWidget(
      host(
        PaymentButton(
          label: 'Edit',
          size: PaymentSize.small,
          width: PaymentWidth.hug,
          onPressed: () {},
        ),
        1,
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final paints = find.ancestor(
      of: find.byType(FilledButton),
      matching: find.byType(CustomPaint),
    );
    expect(tester.getSize(paints.first).height, 36);
  });
  for (final brightness in Brightness.values) {
    testWidgets('button contrast $brightness', (tester) async {
      for (final variant in PaymentButtonVariant.values) {
        await tester.pumpWidget(
          controls.host(
            PaymentButton(label: 'Save', variant: variant, onPressed: () {}),
            brightness: brightness,
          ),
        );
        final e = tester.element(find.byType(PaymentButton));
        final t = PaymentTheme.of(e);
        final fill = switch (variant) {
          PaymentButtonVariant.primary => t.accent,
          PaymentButtonVariant.destructive => t.danger.foreground,
          _ => t.surface,
        };
        final text = switch (variant) {
          PaymentButtonVariant.primary => t.onAccent,
          PaymentButtonVariant.destructive => t.surface,
          _ => t.accent,
        };
        expect(controls.contrast(text, fill), greaterThanOrEqualTo(4.5));
        if (variant == PaymentButtonVariant.secondary) {
          expect(
            controls.contrast(t.border, t.surface),
            greaterThanOrEqualTo(3),
          );
        }
      }
    });
  }
}
