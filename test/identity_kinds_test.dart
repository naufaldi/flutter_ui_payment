import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'first_line_test.dart' show host;

void main() {
  testWidgets('search validates, focuses, groups and submits a host value', (
    t,
  ) async {
    Map<String, String>? result;
    await t.pumpWidget(
      host(
        IdentityForm(
          fields: [
            const IdentityFieldSpec(
              key: 'name',
              label: 'Name',
              group: 'Personal details',
            ),
            IdentityFieldSpec(
              key: 'province',
              label: 'Province',
              group: 'Personal details',
              kind: IdentityFieldKind.search,
              options: const [
                PaymentSelectOption(value: 'jawa-barat', label: 'Jawa Barat'),
              ],
              validator: (v) => v.isEmpty ? 'Choose province' : null,
            ),
          ],
          onSubmit: (v) => result = v,
        ),
        1,
      ),
    );
    expect(find.byType(PaymentFormFieldGroup), findsOneWidget);
    await t.tap(find.text('Continue'));
    await t.pumpAndSettle();
    expect(find.text('Choose province'), findsOneWidget);
    final editor = find.descendant(
      of: find.byType(PaymentSearchField<String>),
      matching: find.byType(EditableText),
    );
    expect(t.widget<EditableText>(editor).focusNode.hasFocus, isTrue);
    await t.enterText(editor, 'Jawa B');
    await t.pumpAndSettle();
    await t.tap(find.text('Jawa Barat'));
    await t.pumpAndSettle();
    await t.tap(find.text('Continue'));
    await t.pumpAndSettle();
    expect(result?['province'], 'jawa-barat');
    await t.pumpWidget(
      host(
        VerificationReview(
          fields: const [
            IdentityFieldSpec(
              key: 'province',
              label: 'Province',
              kind: IdentityFieldKind.search,
              options: [
                PaymentSelectOption(value: 'jawa-barat', label: 'Jawa Barat'),
              ],
            ),
          ],
          values: result!,
          documents: const [],
          onSubmit: () async {},
        ),
        1,
      ),
    );
    expect(find.text('Jawa Barat'), findsOneWidget);
  });

  testWidgets('identity submits date as ISO and choice as host value', (
    tester,
  ) async {
    Map<String, String>? result;
    await tester.pumpWidget(
      host(
        IdentityForm(
          fields: [
            const IdentityFieldSpec(key: 'name', label: 'Name'),
            IdentityFieldSpec(
              key: 'dob',
              label: 'Date of birth',
              kind: IdentityFieldKind.date,
              firstDate: DateTime(1900),
              lastDate: DateTime(2030),
            ),
            IdentityFieldSpec(
              key: 'occupation',
              label: 'Occupation',
              kind: IdentityFieldKind.choice,
              options: const [
                PaymentSelectOption(value: 'employee', label: 'Employee'),
              ],
              validator: (v) => v.isEmpty ? 'Choose occupation' : null,
            ),
          ],
          onSubmit: (v) => result = v,
        ),
        1,
      ),
    );
    await tester.enterText(find.byType(TextFormField).at(0), 'Sari');
    await tester.enterText(find.byType(TextFormField).at(1), '17081995');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.tap(
      find
          .ancestor(of: find.text('Occupation'), matching: find.byType(InkWell))
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Employee'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(result, {
      'name': 'Sari',
      'dob': '1995-08-17',
      'occupation': 'employee',
    });
  });
  testWidgets('currency switch reports choice and reparses on host update', (
    tester,
  ) async {
    String? selected;
    AmountParseResult? result;
    Widget field(String currency) => host(
      PaymentCurrencyField(
        currency: currency,
        currencies: const ['IDR', 'USD'],
        initialText: '5000',
        onCurrencyChanged: (v) => selected = v,
        onChanged: (v) => result = v,
      ),
      1,
    );
    await tester.pumpWidget(field('IDR'));
    await tester.tap(
      find
          .ancestor(of: find.text('Currency'), matching: find.byType(InkWell))
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('USD · \$'));
    await tester.pumpAndSettle();
    expect(selected, 'USD');
    await tester.pumpWidget(field('USD'));
    await tester.pump();
    expect(result?.money?.currency, 'USD');
  });
}
