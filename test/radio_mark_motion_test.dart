import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rakit_ui/rakit_ui.dart';
import 'package:rakit_ui/src/foundation/radio_mark.dart';

import 'helpers/reduced_motion.dart';

Widget host(Widget child, {bool reduceMotion = false, double textScale = 1}) =>
    MaterialApp(
      theme: ThemeData(),
      locale: const Locale('en'),
      supportedLocales: const [Locale('en'), Locale('id')],
      localizationsDelegates: const [
        PaymentLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations:
                reduceMotion || MediaQuery.disableAnimationsOf(context),
            textScaler: TextScaler.linear(textScale),
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      ),
    );

/// Three radio options; the host owns the selected value, like a real group.
class _RadioHarness extends StatefulWidget {
  const _RadioHarness();

  @override
  State<_RadioHarness> createState() => _RadioHarnessState();
}

class _RadioHarnessState extends State<_RadioHarness> {
  String? group = 'a';

  void pick(String value) => setState(() => group = value);

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final v in ['a', 'b', 'c'])
        PaymentRadio<String>(
          value: v,
          groupValue: group,
          onChanged: (v) => setState(() => group = v),
          label: v,
        ),
    ],
  );
}

class _PickerHarness extends StatefulWidget {
  const _PickerHarness();

  @override
  State<_PickerHarness> createState() => _PickerHarnessState();
}

class _PickerHarnessState extends State<_PickerHarness> {
  String selected = 'a';

  @override
  Widget build(BuildContext context) => PaymentMethodPicker(
    methods: const [
      PaymentMethod(id: 'a', label: 'Balance', kind: PaymentMethodKind.balance),
      PaymentMethod(id: 'b', label: 'Card', kind: PaymentMethodKind.card),
    ],
    selectedId: selected,
    onChanged: (method) => setState(() => selected = method.id),
  );
}

Finder _markAt(int index) => find.byType(RadioMark).at(index);

Border _ring(WidgetTester tester, int index) {
  final box = tester.widget<Container>(
    find.descendant(
      of: _markAt(index),
      matching: find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration! as BoxDecoration).shape == BoxShape.circle,
      ),
    ),
  );
  return (box.decoration! as BoxDecoration).border! as Border;
}

double _ringWidth(WidgetTester tester, int index) =>
    _ring(tester, index).top.width;

Color _ringColor(WidgetTester tester, int index) =>
    _ring(tester, index).top.color;

void main() {
  group('RadioMark selection motion (D127)', () {
    testWidgets(
      'eases the ring on selection, retargets mid-flight, state stays synchronous',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(host(const _RadioHarness()));

        // Before the change there is no handoff: the ring jumps straight to
        // its endpoint. Here it must be partway when checked mid-transition.
        await tester.tap(find.text('b'));
        await tester.pump();
        expect(
          tester.getSemantics(find.byType(PaymentRadio<String>).at(1)),
          isSemantics(label: 'b', isChecked: true),
          reason: 'checked state updates on the tap, not after the animation',
        );
        await tester.pump(const Duration(milliseconds: 75));
        final rising = _ringWidth(tester, 1);
        final falling = _ringWidth(tester, 0);
        expect(
          rising,
          inExclusiveRange(1.5, 6),
          reason: 'the selected mark is mid-handoff',
        );
        expect(
          falling,
          inExclusiveRange(1.5, 6),
          reason: 'the deselected mark is mid-handoff',
        );

        // Retarget before the first handoff lands.
        await tester.tap(find.text('c'));
        await tester.pump();
        expect(
          tester.getSemantics(find.byType(PaymentRadio<String>).at(2)),
          isSemantics(label: 'c', isChecked: true),
        );
        await tester.pump(const Duration(milliseconds: 75));
        final back = _ringWidth(tester, 1);
        expect(
          back,
          inExclusiveRange(1.5, 6),
          reason: 'the reversal is still in flight',
        );
        expect(
          back,
          lessThan(rising),
          reason: 'the ring falls from where it was, not from 6',
        );
        expect(_ringWidth(tester, 2), inExclusiveRange(1.5, 6));

        await tester.pumpAndSettle();
        expect(_ringWidth(tester, 0), 1.5);
        expect(_ringWidth(tester, 1), 1.5);
        expect(_ringWidth(tester, 2), 6);
        final theme = PaymentTheme.of(
          tester.element(find.byType(RadioMark).first),
        );
        expect(_ringColor(tester, 2), theme.accent);
        expect(_ringColor(tester, 0), theme.textSecondary);
        semantics.dispose();
      },
    );

    testWidgets('the method picker eases the same shared mark', (tester) async {
      await tester.pumpWidget(host(const _PickerHarness()));

      await tester.tap(find.text('Card'));
      final state = tester.state<_PickerHarnessState>(
        find.byType(_PickerHarness),
      );
      expect(
        state.selected,
        'b',
        reason: 'host selection updates on the tap, not after the animation',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 75));
      expect(_ringWidth(tester, 0), inExclusiveRange(1.5, 6));
      expect(_ringWidth(tester, 1), inExclusiveRange(1.5, 6));

      await tester.pumpAndSettle();
      expect(_ringWidth(tester, 0), 1.5);
      expect(_ringWidth(tester, 1), 6);
    });

    for (final setup in ReducedMotion.values) {
      testWidgets('is instant under ${setup.name} (B9)', (tester) async {
        await tester.pumpWidget(
          setup.apply(tester, host(const _RadioHarness())),
        );
        final state = tester.state<_RadioHarnessState>(
          find.byType(_RadioHarness),
        );
        await expectStill(tester, () => state.pick('b'));
        expect(_ringWidth(tester, 0), 1.5);
        expect(_ringWidth(tester, 1), 6);
      });
    }

    testWidgets('ends mid-flight when iOS Reduce Motion turns on', (
      tester,
    ) async {
      await tester.pumpWidget(host(const _RadioHarness()));
      final state = tester.state<_RadioHarnessState>(
        find.byType(_RadioHarness),
      );
      state.pick('b');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.hasRunningAnimations, isTrue);
      expect(_ringWidth(tester, 1), inExclusiveRange(1.5, 6));

      // Nothing above the mark rebuilds: reduceMotion isn't in
      // MediaQueryData, so the mark has to notice the change itself.
      await expectStill(tester, () {
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(
              reduceMotion: true,
              autoPlayVideos: true,
              autoPlayAnimatedImages: true,
            );
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
      });
      expect(_ringWidth(tester, 1), 6);
      expect(_ringWidth(tester, 0), 1.5);
    });

    testWidgets('ends mid-flight when MediaQuery disableAnimations turns on', (
      tester,
    ) async {
      await tester.pumpWidget(host(const _RadioHarness()));
      final state = tester.state<_RadioHarnessState>(
        find.byType(_RadioHarness),
      );
      state.pick('b');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.hasRunningAnimations, isTrue);
      expect(_ringWidth(tester, 1), inExclusiveRange(1.5, 6));

      await tester.pumpWidget(host(const _RadioHarness(), reduceMotion: true));
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
      expect(_ringWidth(tester, 1), 6);
      expect(_ringWidth(tester, 0), 1.5);
    });

    testWidgets(
      'keeps the 48 dp row and the fixed 20 dp mark at 320 dp, 200% text',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(host(const _PickerHarness(), textScale: 2));
        expect(tester.takeException(), isNull);
        for (final label in ['Balance', 'Card']) {
          final row = find
              .ancestor(of: find.text(label), matching: find.byType(InkWell))
              .first;
          expect(
            tester.getSize(row).height,
            greaterThanOrEqualTo(48),
            reason: '$label row keeps its 48 dp target',
          );
        }
        expect(
          tester.getSize(find.byType(RadioMark).first),
          const Size(20, 20),
        );
      },
    );

    // Last: sendKeyEvent leaves the platform in keyboard highlight mode,
    // which would make earlier tests' taps read as keyboard-driven.
    testWidgets('keyboard selection lands at once', (tester) async {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );
      await tester.pumpWidget(host(const _RadioHarness()));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      final state = tester.state<_RadioHarnessState>(
        find.byType(_RadioHarness),
      );
      expect(state.group, 'b');
      expect(_ringWidth(tester, 1), 6);
      expect(_ringWidth(tester, 0), 1.5);
    });
  });
}
