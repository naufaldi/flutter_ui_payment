import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'package:flutter_ui_payment/src/foundation/focus_ring.dart';
import 'package:flutter_ui_payment/src/foundation/tap_target.dart';

final scheme = ColorScheme.fromSeed(seedColor: Colors.indigo);
final payment = PaymentTheme.fromColorScheme(scheme);

Widget app(Widget child, {PaymentButtonTheme? buttons, double scale = 1}) =>
    MaterialApp(
      theme: ThemeData(colorScheme: scheme, extensions: [payment, ?buttons]),
      localizationsDelegates: const [PaymentLocalizations.delegate],
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
          ),
          child: Scaffold(
            body: SingleChildScrollView(child: Column(children: [child])),
          ),
        ),
      ),
    );

ButtonStyle filled(WidgetTester tester, String label) => tester
    .widget<FilledButton>(
      find.ancestor(of: find.text(label), matching: find.byType(FilledButton)),
    )
    .style!;

void main() {
  testWidgets(
    'theme transitions preserve inherited defaults and ignore text paint',
    (tester) async {
      const empty = PaymentButtonTheme(style: PaymentButtonStyle());
      const custom = PaymentButtonTheme(
        style: PaymentButtonStyle(
          backgroundColor: Colors.deepPurple,
          borderRadius: BorderRadius.all(Radius.circular(24)),
          textStyle: TextStyle(inherit: false, fontSize: 18, color: Colors.red),
        ),
      );
      final originalTheme = ThemeData(
        colorScheme: scheme,
        extensions: [payment, empty],
      );
      final changedTheme = ThemeData(
        colorScheme: scheme,
        extensions: [payment, custom],
      );
      Widget transition(ThemeData from, ThemeData to, double t) => MaterialApp(
        theme: ThemeData.lerp(from, to, t),
        themeAnimationDuration: Duration.zero,
        home: Scaffold(
          body: PaymentButton(label: 'Transition', onPressed: () {}),
        ),
      );
      await tester.pumpWidget(transition(originalTheme, changedTheme, 0));
      final defaults = filled(tester, 'Transition');
      expect(defaults.backgroundColor!.resolve({}), payment.accent);
      expect(
        (defaults.shape!.resolve({})! as RoundedRectangleBorder).borderRadius,
        payment.controlBorderRadius,
      );
      await tester.pumpWidget(transition(originalTheme, changedTheme, 1));
      expect(
        filled(tester, 'Transition').backgroundColor!.resolve({}),
        Colors.deepPurple,
      );
      await tester.pumpWidget(transition(changedTheme, originalTheme, 1));
      expect(
        filled(tester, 'Transition').backgroundColor!.resolve({}),
        payment.accent,
      );
      expect(
        (filled(tester, 'Transition').shape!.resolve({})!
                as RoundedRectangleBorder)
            .borderRadius,
        payment.controlBorderRadius,
      );
      const typography = PaymentButtonTheme(
        style: PaymentButtonStyle(textStyle: TextStyle(fontSize: 18)),
      );
      final typographyTheme = originalTheme.copyWith(
        extensions: [payment, typography],
      );
      await tester.pumpWidget(transition(typographyTheme, changedTheme, 0.5));
      expect(tester.takeException(), isNull);
      expect(filled(tester, 'Transition').textStyle!.resolve({})!.fontSize, 18);
      expect(
        filled(tester, 'Transition').textStyle!.resolve({})!.color,
        isNot(Colors.red),
      );
    },
  );

  testWidgets('empty overrides preserve the default button appearance', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(PaymentButton(label: 'Save', onPressed: () {})),
    );
    final before = filled(tester, 'Save');
    await tester.pumpWidget(
      app(
        PaymentButton(
          label: 'Save',
          style: const PaymentButtonStyle(),
          onPressed: () {},
        ),
        buttons: const PaymentButtonTheme(),
      ),
    );
    final after = filled(tester, 'Save');
    expect(
      after.backgroundColor!.resolve({}),
      before.backgroundColor!.resolve({}),
    );
    expect(
      after.foregroundColor!.resolve({}),
      before.foregroundColor!.resolve({}),
    );
    expect(after.shape!.resolve({}), before.shape!.resolve({}));
    expect(after.textStyle!.resolve({}), before.textStyle!.resolve({}));
  });

  testWidgets('family scope changes buttons and preserves other extensions', (
    tester,
  ) async {
    const radius = BorderRadius.all(Radius.circular(28));
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) => Column(
            children: [
              PaymentButton(label: 'Outside', onPressed: () {}),
              Theme(
                data: Theme.of(context).copyWith(
                  extensions: [
                    ...Theme.of(context).extensions.values,
                    const PaymentButtonTheme(
                      style: PaymentButtonStyle(borderRadius: radius),
                      primary: PaymentButtonStyle(
                        backgroundColor: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
                child: Builder(
                  builder: (context) {
                    expect(PaymentTheme.of(context), same(payment));
                    return Column(
                      children: [
                        PaymentButton(label: 'Inside', onPressed: () {}),
                        PaymentButton(
                          label: 'Alternative',
                          variant: PaymentButtonVariant.secondary,
                          onPressed: () {},
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    expect(
      (filled(tester, 'Inside').shape!.resolve({})! as RoundedRectangleBorder)
          .borderRadius,
      radius,
    );
    expect(
      filled(tester, 'Inside').backgroundColor!.resolve({}),
      Colors.deepPurple,
    );
    expect(
      (filled(tester, 'Outside').shape!.resolve({})! as RoundedRectangleBorder)
          .borderRadius,
      payment.controlBorderRadius,
    );
    expect(
      tester
          .widget<OutlinedButton>(find.byType(OutlinedButton))
          .style!
          .foregroundColor!
          .resolve({}),
      payment.accent,
    );
  });

  testWidgets('instance overrides merge with shared and variant defaults', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        PaymentButton(
          label: 'Save',
          style: const PaymentButtonStyle(
            backgroundColor: Colors.deepPurple,
            textStyle: TextStyle(
              inherit: false,
              fontWeight: FontWeight.w700,
              color: Colors.red,
            ),
          ),
          onPressed: () {},
        ),
        buttons: const PaymentButtonTheme(
          style: PaymentButtonStyle(
            textStyle: TextStyle(fontFamily: 'HostFont', fontSize: 18),
          ),
          primary: PaymentButtonStyle(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
    final style = filled(tester, 'Save');
    expect(style.backgroundColor!.resolve({}), Colors.deepPurple);
    expect(style.foregroundColor!.resolve({}), Colors.white);
    final text = style.textStyle!.resolve({})!;
    expect(text.fontFamily, 'HostFont');
    expect(text.fontSize, 18);
    expect(text.fontWeight, FontWeight.w700);
    expect(text.color, isNot(Colors.red));
  });

  testWidgets('custom colors retain disabled, busy and focus behavior', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final completion = Completer<void>();
    var calls = 0;
    final focus = FocusNode();
    addTearDown(focus.dispose);
    const radius = BorderRadius.all(Radius.circular(24));
    const style = PaymentButtonStyle(
      backgroundColor: Colors.indigo,
      foregroundColor: Colors.white,
      borderRadius: radius,
    );
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    await tester.pumpWidget(
      app(
        Column(
          children: [
            PaymentButton(
              label: 'Save',
              busyLabel: 'Saving changes',
              icon: Icons.save,
              focusNode: focus,
              style: style,
              onPressed: () {
                calls++;
                return completion.future;
              },
            ),
            const PaymentButton(
              label: 'Disabled',
              busy: true,
              style: style,
              onPressed: null,
            ),
          ],
        ),
      ),
    );
    final disabled = filled(tester, 'Disabled');
    expect(
      disabled.backgroundColor!.resolve({WidgetState.disabled}),
      payment.surfaceMuted,
    );
    expect(
      disabled.foregroundColor!.resolve({WidgetState.disabled}),
      payment.disabled,
    );
    expect(
      IconTheme.of(tester.element(find.byIcon(Icons.save))).color,
      Colors.white,
    );
    focus.requestFocus();
    await tester.pump();
    final ring = tester.widget<CustomPaint>(
      find.byWidgetPredicate(
        (w) => w is CustomPaint && w.foregroundPainter is FocusRingPainter,
      ),
    );
    expect((ring.foregroundPainter! as FocusRingPainter).radius, radius);
    expect(
      (ring.foregroundPainter! as FocusRingPainter).color,
      payment.textPrimary,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.tap(find.text('Save'));
    expect(calls, 1);
    final save = find.widgetWithText(PaymentButton, 'Save');
    expect(tester.getSemantics(save).value, 'Saving changes');
    final spinner = tester.widget<PaymentSpinner>(
      find.descendant(of: save, matching: find.byType(PaymentSpinner)),
    );
    expect(spinner.color, Colors.white);
    final disabledSpinner = tester.widget<PaymentSpinner>(
      find.descendant(
        of: find.widgetWithText(PaymentButton, 'Disabled'),
        matching: find.byType(PaymentSpinner),
      ),
    );
    expect(disabledSpinner.color, payment.disabled);
    for (final fade in tester.widgetList<AnimatedOpacity>(
      find.byType(AnimatedOpacity),
    )) {
      expect(fade.duration, Duration.zero);
    }
    completion.complete();
    await tester.pump();
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets(
    'custom typography wraps at 200 percent with reachable 48dp targets',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        app(
          Column(
            children: [
              for (final width in PaymentWidth.values)
                PaymentButton(
                  label: 'Review your payment details',
                  width: width,
                  size: PaymentSize.small,
                  style: const PaymentButtonStyle(
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                    textStyle: TextStyle(fontSize: 18),
                  ),
                  onPressed: () {},
                ),
            ],
          ),
          scale: 2,
        ),
      );
      expect(tester.takeException(), isNull);
      for (final element in find.byType(MinTapTarget).evaluate()) {
        final size = tester.getSize(
          find.byElementPredicate((e) => identical(e, element)),
        );
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
      }
      for (final element
          in find.text('Review your payment details').evaluate()) {
        final paragraph = element.renderObject! as RenderParagraph;
        expect(paragraph.didExceedMaxLines, isFalse);
        expect(paragraph.size.height, greaterThan(40));
      }
    },
  );

  testWidgets('a hug secondary keeps its pill style inside kit button slots', (
    tester,
  ) async {
    const pill = PaymentButtonStyle(
      borderRadius: BorderRadius.all(Radius.circular(999)),
    );
    await tester.pumpWidget(
      app(
        Column(
          children: [
            PaymentButtonGroup(
              children: [
                PaymentButton(
                  label: 'Group pill',
                  variant: PaymentButtonVariant.secondary,
                  style: pill,
                  onPressed: () {},
                ),
              ],
            ),
            PaymentBanner(
              tone: StatusTone.info,
              title: 'Card expires soon',
              actions: [
                PaymentButton(
                  label: 'Banner pill',
                  width: PaymentWidth.hug,
                  variant: PaymentButtonVariant.secondary,
                  style: pill,
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
    for (final label in ['Group pill', 'Banner pill']) {
      final style = tester
          .widget<OutlinedButton>(
            find.ancestor(
              of: find.text(label),
              matching: find.byType(OutlinedButton),
            ),
          )
          .style!;
      expect(
        (style.shape!.resolve({})! as RoundedRectangleBorder).borderRadius,
        pill.borderRadius,
        reason: label,
      );
    }
  });
}
