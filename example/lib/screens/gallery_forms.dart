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

const _provinces = [
  'Aceh',
  'Sumatera Utara',
  'Sumatera Barat',
  'Riau',
  'Jambi',
  'Sumatera Selatan',
  'Bengkulu',
  'Lampung',
  'Kepulauan Bangka Belitung',
  'Kepulauan Riau',
  'DKI Jakarta',
  'Jawa Barat',
  'Jawa Tengah',
  'DI Yogyakarta',
  'Jawa Timur',
  'Banten',
  'Bali',
  'Nusa Tenggara Barat',
  'Nusa Tenggara Timur',
  'Kalimantan Barat',
  'Kalimantan Tengah',
  'Kalimantan Selatan',
  'Kalimantan Timur',
  'Kalimantan Utara',
  'Sulawesi Utara',
  'Sulawesi Tengah',
  'Sulawesi Selatan',
  'Sulawesi Tenggara',
  'Gorontalo',
  'Sulawesi Barat',
  'Maluku',
  'Maluku Utara',
  'Papua',
  'Papua Barat',
  'Papua Selatan',
  'Papua Tengah',
  'Papua Pegunungan',
  'Papua Barat Daya',
];

class _SearchFieldSpecimen extends StatefulWidget {
  const _SearchFieldSpecimen();
  @override
  State<_SearchFieldSpecimen> createState() => _SearchFieldSpecimenState();
}

class _SearchFieldSpecimenState extends State<_SearchFieldSpecimen> {
  String? province;
  Set<String> banks = {'Bank Contoh', 'Bank Demo'};
  @override
  Widget build(BuildContext context) => _Entry(
    name: 'PaymentSearchField · variants',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: PaymentTheme.of(context).space(PaymentSpace.group),
      children: [
        PaymentSearchField<String>(
          key: const Key('search-province'),
          label: 'Province',
          options: [
            for (final p in _provinces) PaymentSearchOption(value: p, label: p),
          ],
          selected: province,
          onSelected: (v) => setState(() => province = v),
        ),
        PaymentSearchField<String>.multiple(
          label: 'Banks',
          options: [
            for (final p in ['Bank Contoh', 'Bank Demo', 'Bank Nusantara'])
              PaymentSearchOption(value: p, label: p),
          ],
          selected: banks,
          onSelectionChanged: (v) => setState(() => banks = v),
        ),
        PaymentSearchField<String>(
          label: 'Province',
          options: const [],
          selected: null,
          onSelected: (_) {},
          errorText: 'Choose a province',
        ),
        PaymentSearchField<String>(
          label: 'Remote search',
          options: const [],
          selected: null,
          onSelected: (_) {},
          onQueryChanged: (_) {},
          loading: true,
        ),
      ],
    ),
  );
}

class _DateRangeSpecimen extends StatefulWidget {
  const _DateRangeSpecimen();
  @override
  State<_DateRangeSpecimen> createState() => _DateRangeSpecimenState();
}

class _DateRangeSpecimenState extends State<_DateRangeSpecimen> {
  PaymentDateRange? value;
  PaymentDateGranularity granularity = PaymentDateGranularity.week;
  late final presets = [
    PaymentDatePreset(
      label: 'Last 7 days',
      start: DateTime(2026, 10, 25),
      end: DateTime(2026, 10, 31),
    ),
    PaymentDatePreset(
      label: 'Last 30 days',
      start: DateTime(2026, 10, 2),
      end: DateTime(2026, 10, 31),
    ),
    PaymentDatePreset(
      label: 'This month',
      start: DateTime(2026, 10),
      end: DateTime(2026, 10, 31),
    ),
  ];
  @override
  Widget build(BuildContext context) => _Entry(
    name: 'PaymentDateRangePicker · variants',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: PaymentTheme.of(context).space(PaymentSpace.group),
      children: [
        PaymentDateRangePicker(
          label: 'Date range',
          value: value,
          onChanged: (v) => setState(() => value = v),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          presets: presets,
        ),
        PaymentDateRangePicker(
          label: 'Payment history',
          value: PaymentDateRange(
            start: DateTime(2026, 10),
            end: DateTime(2026, 10, 31),
          ),
          onChanged: (_) {},
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          granularity: granularity,
          onGranularityChanged: (v) => setState(() => granularity = v),
        ),
        PaymentDateRangePicker(
          label: 'Recent payments',
          value: PaymentDateRange.fromPreset(presets[1]),
          onChanged: (_) {},
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          presets: presets,
        ),
        PaymentDateRangePicker(
          label: 'Date range',
          value: null,
          enabled: false,
          onChanged: (_) {},
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        ),
      ],
    ),
  );
}

class _ChipSpecimen extends StatelessWidget {
  const _ChipSpecimen();
  @override
  Widget build(BuildContext context) => _Entry(
    name: 'PaymentChip · variants',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: PaymentTheme.of(context).space(PaymentSpace.group),
      children: [
        PaymentChipList(
          children: [
            PaymentChip(label: 'Date', value: '1–31 Oct', onClose: () {}),
            PaymentChip(
              label: 'Method',
              values: const ['Transfer', 'QRIS', 'Card'],
              onDropdown: () {},
            ),
            PaymentChip(label: 'Add status', onAddSuggestion: () {}),
            const PaymentChip(label: 'Currency', value: 'IDR'),
          ],
        ),
        PromoCodeInput(
          status: PromoCodeStatus.applied,
          appliedCode: 'HEMAT10',
          onRemove: () {},
          onApply: (_) async {},
        ),
      ],
    ),
  );
}
