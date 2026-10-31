import 'dart:ui' show Tristate, SemanticsValidationResult;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'first_line_test.dart' show host;

void main() {
  testWidgets('switch label centers with its mark and retains a tap target', (
    t,
  ) async {
    await t.pumpWidget(
      host(
        PaymentSwitch(label: 'Promotions', value: true, onChanged: (_) {}),
        1,
      ),
    );
    expect(
      (t.getCenter(find.text('Promotions')).dy -
              t.getCenter(find.byType(Switch)).dy)
          .abs(),
      lessThanOrEqualTo(1),
    );
    expect(
      t.getSize(find.byType(PaymentSwitch)).height,
      greaterThanOrEqualTo(48),
    );
  });

  testWidgets('indeterminate checkbox reports true and paints a dash', (
    tester,
  ) async {
    final values = <bool>[];
    await tester.pumpWidget(
      host(
        PaymentCheckbox(
          value: false,
          indeterminate: true,
          onChanged: values.add,
          label: 'Select all',
        ),
        1,
      ),
    );
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isNull);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).tristate, isTrue);
    await tester.tap(find.text('Select all'));
    expect(values, [true]);
  });
  for (final kind in ['checkbox', 'radio', 'switch']) {
    Widget control({Set<PaymentFieldPart> hidden = const {}}) => switch (kind) {
      'checkbox' => PaymentCheckbox(
        value: false,
        onChanged: (_) {},
        label: 'Consent',
        description: 'Required to proceed',
        errorText: 'Accept the terms',
        required: true,
        hiddenElements: hidden,
      ),
      'radio' => PaymentRadio(
        value: 'email',
        groupValue: null,
        onChanged: (_) {},
        label: 'Consent',
        description: 'Required to proceed',
        errorText: 'Accept the terms',
        required: true,
        hiddenElements: hidden,
      ),
      _ => PaymentSwitch(
        value: false,
        onChanged: (_) {},
        label: 'Consent',
        description: 'Required to proceed',
        errorText: 'Accept the terms',
        required: true,
        hiddenElements: hidden,
      ),
    };
    testWidgets('$kind errors and required semantics', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(host(control(), 1));
      expect(find.byIcon(PaymentIcons.danger), findsOneWidget);
      expect(find.text('Accept the terms'), findsOneWidget);
      final node = tester.getSemantics(
        find.bySemanticsLabel(RegExp('Consent')).first,
      );
      expect(node.flagsCollection.isRequired, Tristate.isTrue);
      expect(
        node.getSemanticsData().validationResult,
        SemanticsValidationResult.invalid,
      );
      expect(node.label, contains('Accept the terms'));
      semantics.dispose();
    });
    testWidgets('$kind hidden text remains spoken', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        host(control(hidden: PaymentFieldPart.values.toSet()), 1),
      );
      expect(find.text('Consent'), findsNothing);
      expect(find.text('Accept the terms'), findsNothing);
      expect(
        find.bySemanticsLabel(
          RegExp(
            'Consent.*Required to proceed.*Accept the terms',
            dotAll: true,
          ),
        ),
        findsOneWidget,
      );
      semantics.dispose();
    });
  }
}
