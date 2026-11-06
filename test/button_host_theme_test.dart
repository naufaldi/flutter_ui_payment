import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rakit_ui/rakit_ui.dart';
import 'package:rakit_ui/src/foundation/tap_target.dart';

// A host app whose Material button themes would resize every button (#277).
const hostileStyle = ButtonStyle(
  fixedSize: WidgetStatePropertyAll(Size(300, 72)),
  maximumSize: WidgetStatePropertyAll(Size(120, 40)),
  padding: WidgetStatePropertyAll(EdgeInsets.all(40)),
);

Widget hostApp(Widget child, {double scale = 1}) => MaterialApp(
  theme: ThemeData(
    filledButtonTheme: const FilledButtonThemeData(style: hostileStyle),
    outlinedButtonTheme: const OutlinedButtonThemeData(style: hostileStyle),
    textButtonTheme: const TextButtonThemeData(style: hostileStyle),
  ),
  localizationsDelegates: const [PaymentLocalizations.delegate],
  home: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(scale)),
    child: Scaffold(
      body: Align(alignment: Alignment.topLeft, child: child),
    ),
  ),
);

Size drawn(WidgetTester t) => t.getSize(
  find.descendant(
    of: find.byType(PaymentButton),
    matching: find.byType(Material),
  ),
);

void main() {
  testWidgets('a host button theme cannot resize the kit button scale', (
    t,
  ) async {
    t.view.physicalSize = const Size(360, 800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    for (final variant in PaymentButtonVariant.values) {
      for (final (size, height) in [
        (PaymentSize.small, 36.0),
        (PaymentSize.medium, 48.0),
        (PaymentSize.large, 56.0),
      ]) {
        await t.pumpWidget(
          hostApp(
            PaymentButton(
              label: 'Pay',
              variant: variant,
              size: size,
              width: PaymentWidth.hug,
              onPressed: () {},
            ),
          ),
        );
        expect(drawn(t).height, height, reason: '$variant $size');
        // The label keeps the kit inset, not the host's 40 dp padding.
        expect(drawn(t).width, lessThan(150), reason: '$variant $size');
        final target = t.getSize(find.byType(MinTapTarget));
        expect(target.height, greaterThanOrEqualTo(48));
        expect(target.width, greaterThanOrEqualTo(48));
      }
    }
  });

  testWidgets('under a host theme a long label still grows at 200% text', (
    t,
  ) async {
    t.view.physicalSize = const Size(320, 800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      hostApp(
        SizedBox(
          width: 320,
          child: PaymentButton(
            label: 'Confirm the transfer to the savings account',
            onPressed: () {},
          ),
        ),
        scale: 2,
      ),
    );
    // A host maximum size of 40 dp would clip the wrapped label.
    expect(drawn(t).height, greaterThan(48));
    expect(t.takeException(), isNull);
  });
}
