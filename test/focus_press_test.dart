import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'helpers/reduced_motion.dart';
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
    data: MediaQuery.of(context).copyWith(
      disableAnimations:
          reduceMotion || MediaQuery.of(context).disableAnimations,
    ),
    child: child!,
  ),
  home: Scaffold(
    body: Padding(padding: const EdgeInsets.all(16), child: child),
  ),
);

final _instructions = VirtualAccountInstructions(
  providerLabel: 'Bank Contoh',
  accountNumber: '8808 0012 3456 7890',
  amount: const Money.idr(104000),
  // Already elapsed, so no countdown timer runs.
  expiresAt: DateTime(2026, 1, 1),
);

Widget _copyButton({bool reduceMotion = false}) => host(
  PaymentInstructions(
    instructions: _instructions,
    clock: () => DateTime(2026, 1, 2),
    onCopyNumber: (_) async => true,
  ),
  reduceMotion: reduceMotion,
);

Finder _ring() => find.byWidgetPredicate(
  (w) => w is CustomPaint && w.foregroundPainter is FocusRingPainter,
);

double _copyScale(WidgetTester tester) => tester
    .widget<AnimatedScale>(
      // The icon becomes a check once copied, so find the button itself.
      find.ancestor(
        of: find.byType(IconButton),
        matching: find.byType(AnimatedScale),
      ),
    )
    .scale;

void main() {
  for (final horizontal in [true, false]) {
    testWidgets('press releases past slop, horizontal=$horizontal', (t) async {
      t.view.physicalSize = const Size(320, 600);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      var calls = 0;
      await t.pumpWidget(
        host(
          SizedBox(
            height: 200,
            child: ListView(
              scrollDirection: horizontal ? Axis.horizontal : Axis.vertical,
              children: [
                if (horizontal)
                  PaymentChip(label: 'Chip', onDropdown: () => calls++)
                else
                  PaymentCopyButton(
                    value: '123',
                    onCopy: (_) async {
                      calls++;
                      return true;
                    },
                  ),
                const SizedBox(width: 1000, height: 1000),
              ],
            ),
          ),
        ),
      );
      final control = find.byType(horizontal ? PaymentChip : PaymentCopyButton);
      final scale = find
          .descendant(of: control, matching: find.byType(AnimatedScale))
          .first;
      final gesture = await t.startGesture(t.getCenter(control));
      await t.pump();
      expect(t.widget<AnimatedScale>(scale).scale, .96);
      final delta = horizontal
          ? const Offset(-(kTouchSlop + 2), 0)
          : const Offset(0, -(kTouchSlop + 2));
      await gesture.moveBy(delta);
      await t.pump();
      expect(t.widget<AnimatedScale>(scale).scale, 1);
      await gesture.moveBy(delta);
      await t.pump();
      expect(t.widget<AnimatedScale>(scale).scale, 1);
      await gesture.up();
      await t.pumpAndSettle();
      expect(calls, 0);
    });
  }
  testWidgets('150 ms hold keeps press feedback until release', (t) async {
    await t.pumpWidget(_copyButton());
    final gesture = await t.startGesture(t.getCenter(find.byType(IconButton)));
    await t.pump(const Duration(milliseconds: 150));
    expect(_copyScale(t), .96);
    await gesture.up();
    await t.pumpAndSettle();
    expect(_copyScale(t), 1);
  });
  testWidgets('disabled tab never shrinks', (t) async {
    await t.pumpWidget(
      host(
        PaymentTabs(
          tabs: const [
            PaymentTab(label: 'Disabled', disabledReason: 'Unavailable'),
          ],
          selectedIndex: 0,
          onSelected: (_) {},
        ),
      ),
    );
    final gesture = await t.startGesture(t.getCenter(find.text('Disabled')));
    await t.pump();
    expect(t.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
    await gesture.up();
    await t.pumpAndSettle();
  });
  for (final setup in ReducedMotion.values) {
    testWidgets('chip stays full size and still (${setup.name})', (t) async {
      await t.pumpWidget(
        host(setup.apply(t, PaymentChip(label: 'Chip', onDropdown: () {}))),
      );
      await t.pumpAndSettle();
      // Drive the kit listener directly: Material ink is a D67 exception.
      final listener = t.widget<Listener>(
        find
            .descendant(
              of: find.byType(PaymentPressScale),
              matching: find.byType(Listener),
            )
            .first,
      );
      await expectStill(
        t,
        () => listener.onPointerDown!(const PointerDownEvent(pointer: 1)),
      );
      expect(t.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
      await expectStill(
        t,
        () => listener.onPointerCancel!(const PointerCancelEvent(pointer: 1)),
      );
    });
  }
  void useStrategy(FocusHighlightStrategy strategy) {
    FocusManager.instance.highlightStrategy = strategy;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
  }

  for (final brightness in Brightness.values) {
    testWidgets('keyboard focus draws a neutral ring (${brightness.name})', (
      tester,
    ) async {
      useStrategy(FocusHighlightStrategy.alwaysTraditional);
      await tester.pumpWidget(
        host(
          PaymentButton(label: 'Pay', onPressed: () {}),
          brightness: brightness,
        ),
      );
      final before = tester.getRect(find.byType(FilledButton));
      expect(_ring(), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      expect(_ring(), findsOneWidget);
      final painter =
          tester.widget<CustomPaint>(_ring()).foregroundPainter!
              as FocusRingPainter;
      final theme = PaymentTheme.of(tester.element(find.byType(PaymentButton)));
      expect(painter.color, theme.textPrimary);
      expect(painter.color, isNot(theme.accent));
      // The ring is painted, not laid out: the button does not move.
      expect(tester.getRect(find.byType(FilledButton)), before);
    });
  }

  testWidgets('touch focus draws no ring', (tester) async {
    useStrategy(FocusHighlightStrategy.alwaysTouch);
    await tester.pumpWidget(
      host(PaymentButton(label: 'Pay', onPressed: () {})),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(Focus.of(tester.element(find.text('Pay'))).hasPrimaryFocus, isTrue);
    expect(_ring(), findsNothing);
  });

  testWidgets('a compact control scales to 0.96 while pressed', (tester) async {
    await tester.pumpWidget(_copyButton());
    expect(_copyScale(tester), 1);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byIcon(PaymentIcons.copy)),
    );
    await tester.pump();
    expect(_copyScale(tester), 0.96);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(_copyScale(tester), 1);
  });

  testWidgets('reduced motion keeps a pressed control at full size', (
    tester,
  ) async {
    await tester.pumpWidget(_copyButton(reduceMotion: true));

    final gesture = await tester.startGesture(
      tester.getCenter(find.byIcon(PaymentIcons.copy)),
    );
    await tester.pump();
    expect(_copyScale(tester), 1);

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('a full-width PaymentButton never scales', (tester) async {
    await tester.pumpWidget(
      host(PaymentButton(label: 'Pay', onPressed: () {})),
    );

    expect(
      find.ancestor(
        of: find.byType(FilledButton),
        matching: find.byType(AnimatedScale),
      ),
      findsNothing,
    );
  });
}
