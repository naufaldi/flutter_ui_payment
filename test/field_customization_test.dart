import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rakit_ui/rakit_ui.dart';

final scheme = ColorScheme.fromSeed(seedColor: Colors.indigo);
final payment = PaymentTheme.fromColorScheme(scheme);
PaymentType typeOf(WidgetTester t) =>
    PaymentType.of(t.element(find.byType(Scaffold).first));
const rounded = BorderRadius.all(Radius.circular(20));

Widget app(
  Widget child, {
  List<ThemeExtension<dynamic>> extensions = const [],
  double scale = 1,
  Size? size,
}) => MaterialApp(
  theme: ThemeData(colorScheme: scheme, extensions: [payment, ...extensions]),
  localizationsDelegates: const [PaymentLocalizations.delegate],
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: true),
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [child],
          ),
        ),
      ),
    ),
  ),
);

InputDecoration decorationOf(WidgetTester tester, Finder field) => tester
    .widget<InputDecorator>(
      find.descendant(of: field, matching: find.byType(InputDecorator)).first,
    )
    .decoration;

OutlineInputBorder outline(InputBorder? border) =>
    border! as OutlineInputBorder;

TextStyle editableStyle(WidgetTester tester, Finder field) => tester
    .widget<EditableText>(
      find.descendant(of: field, matching: find.byType(EditableText)),
    )
    .style;

Widget fields({bool enabled = true}) => Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    PaymentTextField(
      key: const Key('text'),
      label: 'Full name',
      enabled: enabled,
      initialValue: 'Rina',
    ),
    PaymentSelect<String>(
      key: const Key('select'),
      label: 'Occupation',
      options: const [
        PaymentSelectOption(value: 'employee', label: 'Employee'),
        PaymentSelectOption(value: 'student', label: 'Student'),
      ],
      value: 'employee',
      onChanged: enabled ? (_) {} : null,
    ),
    PaymentDateField(
      key: const Key('date'),
      label: 'Date of birth',
      value: DateTime(1990, 4, 12),
      onChanged: (_) {},
      firstDate: DateTime(1900),
      lastDate: DateTime(2030),
      enabled: enabled,
    ),
    PaymentCurrencyField(
      key: const Key('currency'),
      currency: 'IDR',
      onChanged: (_) {},
    ),
  ],
);

void main() {
  testWidgets(
    'small input type keeps long currency digits inside the viewport',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        app(
          extensions: const [
            PaymentFieldTheme(textStyle: TextStyle(fontSize: 12, height: 1)),
          ],
          PaymentCurrencyField(
            currency: 'IDR',
            size: PaymentSize.small,
            initialText: '123456789012345678901234567890',
            onChanged: (_) {},
          ),
        ),
      );
      final editable = tester
          .state<EditableTextState>(find.byType(EditableText))
          .renderEditable;
      final glyph = editable
          .getBoxesForSelection(
            const TextSelection(baseOffset: 0, extentOffset: 1),
          )
          .single;
      expect(glyph.top, greaterThanOrEqualTo(0));
      expect(glyph.bottom, lessThanOrEqualTo(editable.size.height));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('disabled currency uses disabled fill from the field group', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        extensions: const [PaymentFieldTheme(fillColor: Colors.amber)],
        PaymentFormFieldGroup(
          legend: 'Payment',
          disabled: true,
          children: [PaymentCurrencyField(currency: 'IDR', onChanged: (_) {})],
        ),
      ),
    );
    final decoration = decorationOf(tester, find.byType(PaymentCurrencyField));
    expect(decoration.enabled, isFalse);
    expect(decoration.fillColor, payment.surfaceMuted);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).readOnly,
      isTrue,
    );
  });

  testWidgets('no or empty field theme keeps the default field look', (
    tester,
  ) async {
    for (final extensions in [
      const <ThemeExtension<dynamic>>[],
      const [PaymentFieldTheme()],
    ]) {
      await tester.pumpWidget(app(fields(), extensions: extensions));
      for (final key in ['text', 'select', 'date', 'currency']) {
        final d = decorationOf(tester, find.byKey(Key(key)));
        expect(d.filled, isNot(isTrue), reason: key);
        expect(outline(d.enabledBorder).borderSide.color, payment.border);
        expect(
          outline(d.enabledBorder).borderRadius,
          payment.controlBorderRadius,
        );
        expect(outline(d.focusedBorder).borderSide.color, payment.accent);
        expect(outline(d.focusedBorder).borderSide.width, 2);
      }
      final input = typeOf(tester).input;
      final style = editableStyle(tester, find.byKey(const Key('text')));
      expect(
        (style.fontSize, style.height, style.fontWeight, style.color),
        (input.fontSize, input.height, input.fontWeight, payment.textPrimary),
      );
      expect(
        tester.getSize(find.byKey(const Key('text'))).height,
        greaterThanOrEqualTo(56),
      );
    }
  });

  testWidgets(
    'a scoped field theme rounds and fills fields only, keeping other extensions',
    (tester) async {
      const buttons = PaymentButtonTheme();
      late BuildContext scoped;
      await tester.pumpWidget(
        app(
          extensions: const [buttons],
          Builder(
            builder: (context) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Theme(
                  data: Theme.of(context).copyWith(
                    extensions: [
                      ...Theme.of(context).extensions.values,
                      PaymentFieldTheme(
                        fillColor: PaymentTheme.of(context).surfaceMuted,
                        borderColor: PaymentTheme.of(context).textSecondary,
                        borderRadius: rounded,
                        textStyle: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  child: Builder(
                    builder: (context) {
                      scoped = context;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          fields(),
                          PaymentButton(label: 'Pay', onPressed: () {}),
                        ],
                      );
                    },
                  ),
                ),
                const PaymentTextField(key: Key('outside'), label: 'Outside'),
              ],
            ),
          ),
        ),
      );
      expect(Theme.of(scoped).extension<PaymentButtonTheme>(), buttons);
      expect(Theme.of(scoped).extension<PaymentTheme>(), payment);
      for (final key in ['text', 'select', 'date', 'currency']) {
        final d = decorationOf(tester, find.byKey(Key(key)));
        expect(d.filled, isTrue, reason: key);
        expect(d.fillColor, payment.surfaceMuted, reason: key);
        expect(outline(d.enabledBorder).borderRadius, rounded, reason: key);
        expect(
          outline(d.enabledBorder).borderSide.color,
          payment.textSecondary,
        );
        expect(outline(d.focusedBorder).borderRadius, rounded, reason: key);
      }
      expect(
        editableStyle(tester, find.byKey(const Key('text'))).fontWeight,
        FontWeight.w600,
      );
      final selectValue = tester.widget<Text>(find.text('Employee'));
      expect(selectValue.style!.fontWeight, FontWeight.w600);
      // The amount keeps its role.
      expect(
        editableStyle(tester, find.byKey(const Key('currency'))).fontSize,
        typeOf(tester).amountLarge.fontSize,
      );
      // Buttons and fields outside the scope are unchanged.
      final button = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Pay'),
          matching: find.byType(FilledButton),
        ),
      );
      expect(
        (button.style!.shape!.resolve({})! as RoundedRectangleBorder)
            .borderRadius,
        payment.controlBorderRadius,
      );
      final outside = decorationOf(tester, find.byKey(const Key('outside')));
      expect(outside.filled, isNot(isTrue));
      expect(
        outline(outside.enabledBorder).borderRadius,
        payment.controlBorderRadius,
      );
    },
  );

  testWidgets(
    'themed fields keep focus, error, disabled and read-only states',
    (tester) async {
      const theme = PaymentFieldTheme(
        fillColor: Colors.amber,
        borderColor: Colors.teal,
        borderRadius: rounded,
      );
      String? picked;
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        app(
          extensions: const [theme],
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PaymentTextField(
                key: const Key('name'),
                label: 'Name',
                controller: controller,
                errorText: 'Enter your name',
              ),
              const PaymentTextField(
                key: Key('readonly'),
                label: 'Reference',
                initialValue: 'INV-1',
                readOnly: true,
              ),
              const PaymentTextField(
                key: Key('disabled'),
                label: 'Locked',
                enabled: false,
              ),
              PaymentSelect<String>(
                key: const Key('select'),
                label: 'Occupation',
                options: const [
                  PaymentSelectOption(value: 'employee', label: 'Employee'),
                  PaymentSelectOption(value: 'student', label: 'Student'),
                ],
                value: null,
                onChanged: (v) => picked = v,
              ),
            ],
          ),
        ),
      );
      final name = decorationOf(tester, find.byKey(const Key('name')));
      expect(
        outline(name.errorBorder).borderSide.color,
        payment.danger.foreground,
      );
      expect(outline(name.focusedBorder).borderSide.color, payment.accent);
      expect(outline(name.focusedBorder).borderSide.width, 2);
      expect(find.text('Enter your name'), findsOneWidget);

      final disabled = decorationOf(tester, find.byKey(const Key('disabled')));
      expect(disabled.fillColor, payment.surfaceMuted);
      expect(
        outline(disabled.disabledBorder).borderSide.color,
        payment.disabled,
      );

      final readOnly = decorationOf(tester, find.byKey(const Key('readonly')));
      expect(readOnly.fillColor, Colors.amber);
      expect(readOnly.enabled, isTrue);

      // The person can still type and pick.
      await tester.enterText(find.byKey(const Key('name')), 'Rina');
      expect(controller.text, 'Rina');
      await tester.tap(find.byKey(const Key('select')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Student'));
      await tester.pumpAndSettle();
      expect(picked, 'student');
    },
  );

  testWidgets(
    'custom field type fits 320 dp at 200% with 48 dp targets and role labels',
    (tester) async {
      tester.view.physicalSize = const Size(320, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        app(
          scale: 2,
          extensions: const [
            PaymentFieldTheme(
              borderRadius: rounded,
              textStyle: TextStyle(
                inherit: false,
                fontSize: 12,
                height: 1.2,
                fontWeight: FontWeight.w600,
                color: Colors.red,
                backgroundColor: Colors.yellow,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PaymentTextField(
                key: Key('small'),
                label: 'Account holder name as printed on the card',
                initialValue: 'Rina Kartika Wulandari',
                description: 'Use the name your bank shows',
                errorText: 'Name does not match the account',
                size: PaymentSize.small,
              ),
              PaymentSelect<String>(
                key: const Key('select'),
                label: 'Occupation',
                options: const [
                  PaymentSelectOption(value: 'employee', label: 'Employee'),
                ],
                value: 'employee',
                onChanged: (_) {},
                size: PaymentSize.small,
              ),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final style = editableStyle(tester, find.byKey(const Key('small')));
      expect(style.fontSize, 12);
      expect(style.fontWeight, FontWeight.w600);
      expect(style.color, payment.textPrimary);
      expect(style.backgroundColor, isNull);
      expect(style.decoration, isNot(TextDecoration.underline));
      for (final key in ['small', 'select']) {
        final box = find
            .descendant(
              of: find.byKey(Key(key)),
              matching: find.byType(InputDecorator),
            )
            .first;
        expect(tester.getSize(box).height, greaterThanOrEqualTo(48));
      }
      // Label, helper and error keep their roles.
      final label = tester.widget<Text>(
        find.text('Account holder name as printed on the card'),
      );
      expect(label.style!.fontSize, typeOf(tester).label.fontSize);
      final error = tester.widget<Text>(
        find.text('Name does not match the account'),
      );
      expect(error.style!.fontSize, typeOf(tester).caption.fontSize);
      expect(error.style!.color, payment.danger.foreground);
    },
  );

  testWidgets('field themes interpolate without fabricated defaults', (
    tester,
  ) async {
    const a = PaymentFieldTheme(
      fillColor: Colors.white,
      textStyle: TextStyle(inherit: false, fontSize: 12, color: Colors.red),
    );
    const b = PaymentFieldTheme(
      fillColor: Colors.black,
      borderRadius: rounded,
      textStyle: TextStyle(fontSize: 20),
    );
    final early = a.lerp(b, .25);
    expect(early.fillColor, Color.lerp(Colors.white, Colors.black, .25));
    expect(early.borderRadius, isNull);
    expect(early.borderColor, isNull);
    expect(early.textStyle!.fontSize, 14);
    expect(early.textStyle!.inherit, isTrue);
    expect(early.textStyle!.color, isNull);
    final later = a.lerp(b, .75);
    expect(later.borderRadius, rounded);
    expect(
      a.lerp(const PaymentFieldTheme(), .4).textStyle!.fontSize,
      12,
      reason: 'one-sided typography holds until the midpoint',
    );
    expect(a.lerp(const PaymentFieldTheme(), .6).textStyle, isNull);
    expect(a.copyWith(borderColor: Colors.teal).fillColor, Colors.white);
    expect(
      const PaymentFieldTheme(borderRadius: rounded),
      const PaymentFieldTheme(borderRadius: rounded),
    );
    expect(
      const PaymentFieldTheme(borderRadius: rounded).hashCode,
      const PaymentFieldTheme(borderRadius: rounded).hashCode,
    );

    // A live theme transition from no override renders the default first.
    final from = ThemeData(
      colorScheme: scheme,
      extensions: [payment, const PaymentFieldTheme()],
    );
    final to = ThemeData(colorScheme: scheme, extensions: [payment, a]);
    Widget at(double t) => MaterialApp(
      theme: ThemeData.lerp(from, to, t),
      themeAnimationDuration: Duration.zero,
      localizationsDelegates: const [PaymentLocalizations.delegate],
      home: const Scaffold(body: PaymentTextField(label: 'Name')),
    );
    await tester.pumpWidget(at(.3));
    final d = decorationOf(tester, find.byType(PaymentTextField));
    expect(d.filled, isNot(isTrue));
    expect(d.fillColor, isNot(Colors.white));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(at(.7));
    expect(tester.takeException(), isNull);
    expect(editableStyle(tester, find.byType(PaymentTextField)).fontSize, 12);
  });
}
