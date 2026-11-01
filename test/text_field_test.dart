import 'package:flutter/rendering.dart';
import 'content_host.dart' as phase4;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'first_line_test.dart' show host;

void main() {
  testWidgets('short floating label leaves detail in wrapping description', (
    t,
  ) async {
    await phase4.setSurface(t, const Size(320, 1000));
    const label = 'Reference';
    await t.pumpWidget(
      phase4.contentHost(
        const PaymentTextField(
          label: label,
          description:
              'Use the reference from the payment receipt when asking for help.',
        ),
        scale: 2,
      ),
    );
    final paragraph = t.renderObject<RenderParagraph>(find.text(label));
    expect(paragraph.didExceedMaxLines, isFalse);
    await t.tap(find.byType(EditableText));
    await t.enterText(find.byType(EditableText), 'demo');
    await t.pumpAndSettle();
    expect(
      t.renderObject<RenderParagraph>(find.text(label)).didExceedMaxLines,
      isFalse,
    );
    expect(
      t.getBottomLeft(find.text(label)).dy,
      lessThanOrEqualTo(t.getTopLeft(find.byType(EditableText)).dy),
    );
    expect(t.takeException(), isNull);
  });

  testWidgets('sizes keep 16px text and distinct padding', (tester) async {
    final heights = <double>[];
    for (final size in PaymentSize.values) {
      await tester.pumpWidget(
        host(PaymentTextField(label: 'Name', size: size), 1),
      );
      heights.add(tester.getSize(find.byType(InputDecorator)).height);
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).style.fontSize,
        16,
      );
    }
    debugPrint('Field heights: $heights');
    expect(heights[0], greaterThanOrEqualTo(48));
    expect(heights[1] - heights[0], 8);
    expect(heights[2] - heights[1], 8);
  });
  testWidgets('host errors hide on edit and return on a new attempt', (
    tester,
  ) async {
    String? error = 'Try another name';
    late StateSetter update;
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (_, set) {
            update = set;
            return PaymentTextField(label: 'Name', errorText: error);
          },
        ),
        1,
      ),
    );
    expect(find.text('Try another name'), findsOneWidget);
    expect(find.byIcon(PaymentIcons.danger), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'Ada');
    await tester.pump();
    expect(find.text('Try another name'), findsNothing);
    update(() => error = null);
    await tester.pump();
    update(() => error = 'Try another name');
    await tester.pump();
    expect(find.text('Try another name'), findsOneWidget);
  });
  testWidgets('validator and email traits work through Form', (tester) async {
    final key = GlobalKey<FormState>();
    await tester.pumpWidget(
      host(
        Form(
          key: key,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: PaymentTextField(
            label: 'Email',
            type: PaymentTextFieldType.email,
            validator: (v) => v!.contains('@') ? null : 'Include @',
          ),
        ),
        1,
      ),
    );
    expect(key.currentState!.validate(), false);
    await tester.pump();
    expect(find.byIcon(PaymentIcons.danger), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'ada@example.com');
    await tester.pump();
    expect(find.text('Include @'), findsNothing);
    final field = tester.widget<EditableText>(find.byType(EditableText));
    expect(field.keyboardType, TextInputType.emailAddress);
    expect(field.autocorrect, false);
  });
  testWidgets('search clear calls host and returns focus; host updates text', (
    tester,
  ) async {
    var query = 'kopi';
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (_, set) => PaymentTextField.search(
            query: query,
            onChanged: (v) => set(() => query = v),
          ),
        ),
        1,
      ),
    );
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pump();
    expect(query, '');
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      true,
    );
    expect(find.byTooltip('Clear search'), findsNothing);
  });
  testWidgets('hidden label stays on editable semantics', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        const PaymentTextField(
          label: 'Full name',
          hiddenElements: {PaymentFieldPart.label},
        ),
        1,
      ),
    );
    expect(
      tester.getSemantics(find.byType(EditableText)).label,
      contains('Full name'),
    );
    semantics.dispose();
  });
  for (final scale in [1.0, 2.0]) {
    testWidgets('text, currency, date and select share heights at $scale', (
      tester,
    ) async {
      double boxHeight() => tester
          .getSize(
            find
                .byWidgetPredicate(
                  (w) => w.runtimeType.toString() == '_BorderContainer',
                )
                .first,
          )
          .height;
      for (final size in PaymentSize.values) {
        final heights = <String, double>{};
        final fields = <String, Widget>{
          'text': PaymentTextField(label: 'Name', size: size),
          'currency': PaymentCurrencyField(
            currency: 'IDR',
            size: size,
            initialText: '102500',
            onChanged: (_) {},
          ),
          'date': PaymentDateField(
            label: 'Date',
            value: DateTime(2026, 10, 1),
            onChanged: (_) {},
            firstDate: DateTime(1900),
            lastDate: DateTime(2030),
            size: size,
          ),
          'select': PaymentSelect<int>(
            label: 'Province',
            options: const [PaymentSelectOption(value: 1, label: 'Bali')],
            value: 1,
            onChanged: (_) {},
            size: size,
          ),
          // An empty select with a long hint keeps one line (#65).
          'select hint': PaymentSelect<int>(
            label: 'Occupation',
            hint: 'Choose your occupation from the list',
            options: const [PaymentSelectOption(value: 1, label: 'Bali')],
            value: null,
            onChanged: (_) {},
            size: size,
          ),
        };
        for (final entry in fields.entries) {
          await tester.pumpWidget(host(entry.value, scale));
          heights[entry.key] = boxHeight();
        }
        expect(
          heights.values.toSet(),
          hasLength(1),
          reason: '$size at $scale: $heights',
        );
        if (scale == 1) {
          expect(heights['text'], switch (size) {
            PaymentSize.small => 48,
            PaymentSize.medium => 56,
            PaymentSize.large => 64,
          });
        }
      }
    });
  }
}
