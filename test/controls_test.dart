import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'package:flutter_ui_payment/src/foundation/focus_ring.dart';

Widget host(
  Widget child, {
  bool reduceMotion = false,
  Brightness brightness = Brightness.light,
}) => MaterialApp(
  theme: ThemeData(brightness: brightness),
  locale: const Locale('en'),
  supportedLocales: const [Locale('en'), Locale('id')],
  localizationsDelegates: const [
    PaymentLocalizations.delegate,
    ...GlobalMaterialLocalizations.delegates,
  ],
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
    child: child!,
  ),
  home: Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [child]),
    ),
  ),
);

double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

Finder _ring() => find.byWidgetPredicate(
  (w) => w is CustomPaint && w.foregroundPainter is FocusRingPainter,
);

void main() {
  group('PaymentCheckbox', () {
    testWidgets('the whole row toggles and reads as one checked node', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      bool? changed;
      await tester.pumpWidget(
        host(
          PaymentCheckbox(
            value: false,
            onChanged: (v) => changed = v,
            label: 'Save this card',
            description: 'For your next payment',
          ),
        ),
      );

      expect(
        tester.getSemantics(find.byType(PaymentCheckbox)),
        matchesSemantics(
          label: 'Save this card\nFor your next payment',
          hasCheckedState: true,
          isChecked: false,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      // Tapping the label, not only the box, changes the value.
      await tester.tap(find.text('Save this card'));
      expect(changed, isTrue);
      expect(
        tester.getSize(find.byType(PaymentCheckbox)).height,
        greaterThanOrEqualTo(48),
      );
      handle.dispose();
    });

    testWidgets('disabled shows the reason and ignores taps', (tester) async {
      await tester.pumpWidget(
        host(
          const PaymentCheckbox(
            value: true,
            onChanged: null,
            label: 'Save this card',
            description: 'For your next payment',
            disabledReason: 'This card cannot be saved',
          ),
        ),
      );
      expect(find.text('This card cannot be saved'), findsOneWidget);
      expect(find.text('For your next payment'), findsNothing);
      final theme = PaymentTheme.of(
        tester.element(find.text('Save this card')),
      );
      expect(
        tester.widget<Text>(find.text('Save this card')).style!.color,
        theme.textSecondary,
      );
      await tester.tap(find.text('Save this card'));
    });

    testWidgets('keyboard focus rings the row, once', (tester) async {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );
      var value = false;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => PaymentCheckbox(
              value: value,
              onChanged: (v) => setState(() => value = v),
              label: 'Save this card',
            ),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(_ring(), findsOneWidget);
      // The painted checkbox takes no focus of its own, so one Tab is enough
      // and Space toggles the row.
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(value, isTrue);
    });
  });

  group('PaymentRadio', () {
    testWidgets('chooses its value and marks the selection in the group', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      String? chosen;
      await tester.pumpWidget(
        host(
          Column(
            children: [
              for (final v in ['card', 'bank'])
                PaymentRadio<String>(
                  value: v,
                  groupValue: 'card',
                  onChanged: (v) => chosen = v,
                  label: v,
                ),
            ],
          ),
        ),
      );

      expect(
        tester.getSemantics(find.byType(PaymentRadio<String>).first),
        isSemantics(
          label: 'card',
          isChecked: true,
          isInMutuallyExclusiveGroup: true,
        ),
      );
      expect(
        tester.getSemantics(find.byType(PaymentRadio<String>).last),
        isSemantics(label: 'bank', isChecked: false),
      );

      await tester.tap(find.text('card'));
      expect(chosen, isNull, reason: 'already selected');
      await tester.tap(find.text('bank'));
      expect(chosen, 'bank');
      handle.dispose();
    });

    testWidgets('the selected mark is a thicker ring, not only a color', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          Column(
            children: [
              for (final v in ['a', 'b'])
                PaymentRadio<String>(
                  value: v,
                  groupValue: 'a',
                  onChanged: (_) {},
                  label: v,
                ),
            ],
          ),
        ),
      );
      double ring(String label) {
        final box = tester.widget<Container>(
          find.descendant(
            of: find.widgetWithText(PaymentRadio<String>, label),
            matching: find.byWidgetPredicate(
              (w) =>
                  w is Container &&
                  w.decoration is BoxDecoration &&
                  (w.decoration! as BoxDecoration).shape == BoxShape.circle,
            ),
          ),
        );
        return ((box.decoration! as BoxDecoration).border! as Border).top.width;
      }

      expect(ring('a'), 6);
      expect(ring('b'), 1.5);
    });
  });

  group('PaymentSwitch', () {
    testWidgets('toggles from the row and reads as toggled', (tester) async {
      final handle = tester.ensureSemantics();
      bool? changed;
      await tester.pumpWidget(
        host(
          PaymentSwitch(
            value: true,
            onChanged: (v) => changed = v,
            label: 'Refund alerts',
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(PaymentSwitch)),
        isSemantics(
          label: 'Refund alerts',
          hasToggledState: true,
          isToggled: true,
        ),
      );
      await tester.tap(find.text('Refund alerts'));
      expect(changed, isFalse);
      handle.dispose();
    });

    testWidgets('on shows a check in the thumb', (tester) async {
      await tester.pumpWidget(
        host(
          PaymentSwitch(value: true, onChanged: (_) {}, label: 'Refund alerts'),
        ),
      );
      // The icon is painted into the thumb, not built as a widget.
      final thumb = tester.widget<Switch>(find.byType(Switch)).thumbIcon!;
      expect(thumb.resolve({WidgetState.selected})!.icon, Icons.check);
      expect(thumb.resolve({}), isNull);
    });
  });

  group('PaymentTabs', () {
    testWidgets('selects by index with 48 dp tabs', (tester) async {
      final handle = tester.ensureSemantics();
      int? picked;
      await tester.pumpWidget(
        host(
          PaymentTabs(
            labels: const ['All', 'Pending', 'Refunds'],
            selectedIndex: 0,
            onSelected: (i) => picked = i,
          ),
        ),
      );
      expect(
        tester.getSemantics(find.text('All')),
        isSemantics(label: 'All', isSelected: true, isButton: true),
      );
      expect(
        tester.getSemantics(find.text('Pending')),
        isSemantics(isSelected: false),
      );
      expect(
        tester.getSize(find.byType(PaymentTabs)).height,
        greaterThanOrEqualTo(48),
      );
      await tester.tap(find.text('Refunds'));
      expect(picked, 2);
      handle.dispose();
    });
  });

  group('PaymentSpinner', () {
    testWidgets('announces Loading and spins', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(const PaymentSpinner()));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('stands still with reduced motion', (tester) async {
      await tester.pumpWidget(host(const PaymentSpinner(), reduceMotion: true));
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byIcon(Icons.hourglass_top), findsOneWidget);
    });
  });

  testWidgets('PaymentDivider is a 1 px outline rule', (tester) async {
    await tester.pumpWidget(host(const PaymentDivider(height: 24)));
    final divider = tester.widget<Divider>(find.byType(Divider));
    final theme = PaymentTheme.of(tester.element(find.byType(Divider)));
    expect(divider.thickness, 1);
    expect(divider.color, theme.outline);
    expect(tester.getSize(find.byType(PaymentDivider)).height, 24);
  });

  testWidgets('PaymentTooltip shows its message on long press', (tester) async {
    await tester.pumpWidget(
      host(
        const PaymentTooltip(
          message: 'Paid on 30 Oct 2026, 14:05',
          child: Text('2d ago'),
        ),
      ),
    );
    await tester.longPress(find.text('2d ago'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Paid on 30 Oct 2026, 14:05'), findsOneWidget);
  });

  group('destructive PaymentButton', () {
    for (final brightness in Brightness.values) {
      testWidgets(
        'label reaches 4.5:1 on the danger fill (${brightness.name})',
        (tester) async {
          await tester.pumpWidget(
            host(
              PaymentButton(
                label: 'Remove card',
                onPressed: () {},
                variant: PaymentButtonVariant.destructive,
              ),
              brightness: brightness,
            ),
          );
          final theme = PaymentTheme.of(
            tester.element(find.text('Remove card')),
          );
          final style = tester
              .widget<FilledButton>(find.byType(FilledButton))
              .style!;
          final background = style.backgroundColor!.resolve({})!;
          final foreground = style.foregroundColor!.resolve({})!;
          expect(background, theme.danger.foreground);
          expect(contrast(foreground, background), greaterThanOrEqualTo(4.5));
        },
      );
    }

    testWidgets('busy spinner uses the label color', (tester) async {
      await tester.pumpWidget(
        host(
          PaymentButton(
            label: 'Remove card',
            onPressed: () {},
            busy: true,
            variant: PaymentButtonVariant.destructive,
          ),
        ),
      );
      final theme = PaymentTheme.of(tester.element(find.text('Remove card')));
      expect(
        tester.widget<PaymentSpinner>(find.byType(PaymentSpinner)).color,
        theme.surface,
      );
    });
  });
}
