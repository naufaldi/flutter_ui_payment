part of 'gallery_screen.dart';

const _occupations = [
  PaymentSelectOption(value: 'employee', label: 'Employee'),
  PaymentSelectOption(value: 'entrepreneur', label: 'Entrepreneur'),
  PaymentSelectOption(value: 'student', label: 'Student'),
  PaymentSelectOption(value: 'civilServant', label: 'Civil servant'),
  PaymentSelectOption(value: 'homemaker', label: 'Homemaker'),
  PaymentSelectOption(value: 'freelancer', label: 'Freelancer'),
  PaymentSelectOption(value: 'retired', label: 'Retired'),
  PaymentSelectOption(
    value: 'other',
    label: 'Other',
    disabledReason: 'Not available for this account',
  ),
];

class _FormsSpecimen extends StatefulWidget {
  const _FormsSpecimen(this.name);
  final String name;
  @override
  State<_FormsSpecimen> createState() => _FormsSpecimenState();
}

class _FormsSpecimenState extends State<_FormsSpecimen> {
  String? occupation;
  Set<String> methods = {'Transfer', 'QRIS', 'Card'};
  DateTime? date;
  @override
  Widget build(BuildContext context) {
    final children = switch (widget.name) {
      'PaymentTextArea' => <Widget>[
        const PaymentTextArea(
          label: 'Describe the problem',
          maxLength: 300,
          description: 'Include the payment reference.',
        ),
        const PaymentTextArea(
          label: 'Description',
          errorText: 'Describe what happened',
        ),
        const PaymentTextArea(
          label: 'Notes',
          initialValue: 'Payment received',
          readOnly: true,
        ),
        const PaymentTextArea(label: 'Internal notes', enabled: false),
      ],
      'PaymentSelect' => <Widget>[
        PaymentSelect<String>(
          label: 'Occupation',
          hint: 'Choose your occupation',
          options: _occupations,
          value: occupation,
          onChanged: (v) => setState(() => occupation = v),
        ),
        PaymentSelect<String>(
          label: 'Occupation',
          options: _occupations,
          value: 'employee',
          onChanged: (_) {},
        ),
        PaymentSelect<String>(
          label: 'Occupation',
          options: _occupations,
          value: null,
          errorText: 'Choose your occupation',
          onChanged: (_) {},
        ),
        const PaymentSelect<String>(
          label: 'Occupation',
          options: _occupations,
          value: null,
          onChanged: null,
        ),
        PaymentSelect<String>.multiple(
          label: 'Payment methods',
          options: [
            for (final m in ['Transfer', 'QRIS', 'Card'])
              PaymentSelectOption(value: m, label: m),
          ],
          values: methods,
          onChanged: (v) => setState(() => methods = v),
        ),
      ],
      'PaymentDateField' => <Widget>[
        PaymentDateField(
          label: 'Date of birth',
          value: date,
          onChanged: (v) => setState(() => date = v),
          firstDate: DateTime(1900),
          lastDate: DateTime(2030),
        ),
        PaymentDateField(
          label: 'Date of birth',
          value: DateTime(1995, 8, 17),
          onChanged: (_) {},
          firstDate: DateTime(1900),
          lastDate: DateTime(2030),
        ),
        PaymentDateField(
          label: 'Date of birth',
          value: null,
          errorText: 'You must be 17 or older.',
          onChanged: (_) {},
          firstDate: DateTime(1900),
          lastDate: DateTime(2030),
        ),
        PaymentDateField(
          label: 'Date of birth',
          value: null,
          enabled: false,
          onChanged: (_) {},
          firstDate: DateTime(1900),
          lastDate: DateTime(2030),
        ),
      ],
      _ => <Widget>[
        PaymentFormFieldGroup(
          legend: 'Place and date of birth',
          children: [
            const PaymentTextField(label: 'Place of birth', required: true),
            PaymentDateField(
              label: 'Date of birth',
              value: date,
              onChanged: (v) => setState(() => date = v),
              firstDate: DateTime(1900),
              lastDate: DateTime(2030),
            ),
          ],
        ),
        const PaymentFormFieldGroup(
          legend: 'Card expiry',
          layout: Axis.horizontal,
          children: [
            PaymentTextField(label: 'Month', type: PaymentTextFieldType.number),
            PaymentTextField(label: 'Year', type: PaymentTextFieldType.number),
          ],
        ),
        const PaymentFormFieldGroup(
          legend: 'Disabled group',
          disabled: true,
          children: [
            PaymentTextField(label: 'Name'),
            PaymentTextArea(label: 'Notes'),
          ],
        ),
      ],
    };
    return _Entry(
      name: '${widget.name} · variants',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: PaymentTheme.of(context).space(PaymentSpace.group),
        children: children,
      ),
    );
  }
}

class _CurrencySwitch extends StatefulWidget {
  const _CurrencySwitch();
  @override
  State<_CurrencySwitch> createState() => _CurrencySwitchState();
}

class _CurrencySwitchState extends State<_CurrencySwitch> {
  String currency = 'IDR';
  @override
  Widget build(BuildContext context) => PaymentCurrencyField(
    currency: currency,
    currencies: const ['IDR', 'USD'],
    onCurrencyChanged: (v) => setState(() => currency = v),
    onChanged: (_) {},
  );
}
