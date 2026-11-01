part of 'gallery_screen.dart';

List<PaymentSelectOption<String>> _occupations(BuildContext context) {
  String t(String en, String id) => _t(context, en, id);
  return [
    PaymentSelectOption(value: 'employee', label: t('Employee', 'Karyawan')),
    PaymentSelectOption(
      value: 'entrepreneur',
      label: t('Entrepreneur', 'Wiraswasta'),
    ),
    PaymentSelectOption(value: 'student', label: t('Student', 'Pelajar')),
    PaymentSelectOption(
      value: 'civilServant',
      label: t('Civil servant', 'Pegawai negeri'),
    ),
    PaymentSelectOption(
      value: 'homemaker',
      label: t('Homemaker', 'Ibu rumah tangga'),
    ),
    PaymentSelectOption(
      value: 'freelancer',
      label: t('Freelancer', 'Pekerja lepas'),
    ),
    PaymentSelectOption(value: 'retired', label: t('Retired', 'Pensiunan')),
    PaymentSelectOption(
      value: 'other',
      label: t('Other', 'Lainnya'),
      disabledReason: t(
        'Not available for this account',
        'Tidak tersedia untuk akun ini',
      ),
    ),
  ];
}

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
  DateTime? transferDate;
  @override
  Widget build(BuildContext context) {
    String t(String en, String id) => _t(context, en, id);
    final occupations = _occupations(context);
    final occupationLabel = t('Occupation', 'Pekerjaan');
    final dateOfBirth = t('Date of birth', 'Tanggal lahir');
    // Past dates end today (D51); a date of birth spans decades, so its
    // picker is the wheel (D52a, Q2).
    final today = DateUtils.dateOnly(DateTime.now());
    final children = switch (widget.name) {
      'PaymentTextArea' => <Widget>[
        PaymentTextArea(
          label: t('Describe the problem', 'Jelaskan masalahnya'),
          maxLength: 300,
          description: t(
            'Include the payment reference.',
            'Sertakan referensi pembayaran.',
          ),
        ),
        PaymentTextArea(
          label: t('Description', 'Deskripsi'),
          errorText: t('Describe what happened', 'Jelaskan apa yang terjadi'),
        ),
        PaymentTextArea(
          label: t('Notes', 'Catatan'),
          initialValue: t('Payment received', 'Pembayaran diterima'),
          readOnly: true,
        ),
        PaymentTextArea(
          label: t('Internal notes', 'Catatan internal'),
          enabled: false,
        ),
      ],
      'PaymentSelect' => <Widget>[
        PaymentSelect<String>(
          label: occupationLabel,
          hint: t('Choose your occupation', 'Pilih pekerjaan Anda'),
          options: occupations,
          value: occupation,
          onChanged: (v) => setState(() => occupation = v),
        ),
        PaymentSelect<String>(
          label: occupationLabel,
          options: occupations,
          value: 'employee',
          onChanged: (_) {},
        ),
        PaymentSelect<String>(
          label: occupationLabel,
          options: occupations,
          value: null,
          errorText: t('Choose your occupation', 'Pilih pekerjaan Anda'),
          onChanged: (_) {},
        ),
        PaymentSelect<String>(
          label: occupationLabel,
          options: occupations,
          value: null,
          onChanged: null,
        ),
        PaymentSelect<String>.multiple(
          label: t('Payment methods', 'Metode pembayaran'),
          options: [
            for (final (m, label) in [
              ('Transfer', 'Transfer'),
              ('QRIS', 'QRIS'),
              ('Card', t('Card', 'Kartu')),
            ])
              PaymentSelectOption(value: m, label: label),
          ],
          values: methods,
          onChanged: (v) => setState(() => methods = v),
        ),
      ],
      'PaymentDateField' => <Widget>[
        PaymentDateField(
          key: const Key('date-dob'),
          label: dateOfBirth,
          value: date,
          onChanged: (v) => setState(() => date = v),
          firstDate: DateTime(1900),
          lastDate: today,
        ),
        PaymentDateField(
          key: const Key('date-dob-filled'),
          label: dateOfBirth,
          value: DateTime(1995, 8, 17),
          onChanged: (_) {},
          firstDate: DateTime(1900),
          lastDate: today,
        ),
        PaymentDateField(
          label: dateOfBirth,
          value: null,
          errorText: t('You must be 17 or older.', 'Usia minimal 17 tahun.'),
          onChanged: (_) {},
          firstDate: DateTime(1900),
          lastDate: today,
        ),
        PaymentDateField(
          label: dateOfBirth,
          value: null,
          enabled: false,
          onChanged: (_) {},
          firstDate: DateTime(1900),
          lastDate: today,
        ),
        // A near date: the calendar (D52a).
        PaymentDateField(
          key: const Key('date-transfer'),
          label: t('Transfer date', 'Tanggal transfer'),
          value: transferDate,
          onChanged: (v) => setState(() => transferDate = v),
          firstDate: today,
          lastDate: today.add(const Duration(days: 90)),
        ),
      ],
      _ => <Widget>[
        PaymentFormFieldGroup(
          legend: t('Place and date of birth', 'Tempat dan tanggal lahir'),
          children: [
            PaymentTextField(
              label: t('Place of birth', 'Tempat lahir'),
              required: true,
            ),
            PaymentDateField(
              label: dateOfBirth,
              value: date,
              onChanged: (v) => setState(() => date = v),
              firstDate: DateTime(1900),
              lastDate: today,
            ),
          ],
        ),
        PaymentFormFieldGroup(
          legend: t('Card expiry', 'Masa berlaku kartu'),
          layout: Axis.horizontal,
          children: [
            PaymentTextField(
              label: t('Month', 'Bulan'),
              type: PaymentTextFieldType.number,
            ),
            PaymentTextField(
              label: t('Year', 'Tahun'),
              type: PaymentTextFieldType.number,
            ),
          ],
        ),
        PaymentFormFieldGroup(
          legend: t('Disabled group', 'Grup nonaktif'),
          disabled: true,
          children: [
            PaymentTextField(label: t('Name', 'Nama')),
            PaymentTextArea(label: t('Notes', 'Catatan')),
          ],
        ),
      ],
    };
    return _Entry(
      name: '${widget.name} · variants',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        // Field groups sit a section apart (#65); single fields a group.
        spacing: PaymentTheme.of(context).space(
          widget.name == 'PaymentFormFieldGroup'
              ? PaymentSpace.section
              : PaymentSpace.group,
        ),
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
          label: _t(context, 'Province', 'Provinsi'),
          options: [
            for (final p in _provinces) PaymentSearchOption(value: p, label: p),
          ],
          selected: province,
          onSelected: (v) => setState(() => province = v),
        ),
        PaymentSearchField<String>.multiple(
          label: _t(context, 'Banks', 'Bank'),
          options: [
            for (final p in ['Bank Contoh', 'Bank Demo', 'Bank Nusantara'])
              PaymentSearchOption(value: p, label: p),
          ],
          selected: banks,
          onSelectionChanged: (v) => setState(() => banks = v),
        ),
        PaymentSearchField<String>(
          label: _t(context, 'Province', 'Provinsi'),
          options: const [],
          selected: null,
          onSelected: (_) {},
          errorText: _t(context, 'Choose a province', 'Pilih provinsi'),
        ),
        PaymentSearchField<String>(
          label: _t(context, 'Remote search', 'Pencarian jarak jauh'),
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
  List<PaymentDatePreset> _presets(BuildContext context) => [
    PaymentDatePreset(
      label: _t(context, 'Last 7 days', '7 hari terakhir'),
      start: DateTime(2026, 10, 25),
      end: DateTime(2026, 10, 31),
    ),
    PaymentDatePreset(
      label: _t(context, 'Last 30 days', '30 hari terakhir'),
      start: DateTime(2026, 10, 2),
      end: DateTime(2026, 10, 31),
    ),
    PaymentDatePreset(
      label: _t(context, 'This month', 'Bulan ini'),
      start: DateTime(2026, 10),
      end: DateTime(2026, 10, 31),
    ),
  ];
  @override
  Widget build(BuildContext context) {
    final presets = _presets(context);
    return _build(context, presets);
  }

  Widget _build(BuildContext context, List<PaymentDatePreset> presets) =>
      _Entry(
        name: 'PaymentDateRangePicker · variants',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: PaymentTheme.of(context).space(PaymentSpace.group),
          children: [
            PaymentDateRangePicker(
              key: const Key('range-presets'),
              label: _t(context, 'Date range', 'Rentang tanggal'),
              value: value,
              onChanged: (v) => setState(() => value = v),
              firstDate: DateTime(2020),
              lastDate: DateUtils.dateOnly(DateTime.now()),
              presets: presets,
            ),
            PaymentDateRangePicker(
              key: const Key('range-history'),
              label: _t(context, 'Payment history', 'Riwayat pembayaran'),
              value: PaymentDateRange(
                start: DateTime(2026, 10),
                end: DateTime(2026, 10, 31),
              ),
              onChanged: (_) {},
              firstDate: DateTime(2020),
              lastDate: DateUtils.dateOnly(DateTime.now()),
              granularity: granularity,
              onGranularityChanged: (v) => setState(() => granularity = v),
            ),
            PaymentDateRangePicker(
              label: _t(context, 'Recent payments', 'Pembayaran terbaru'),
              value: PaymentDateRange.fromPreset(presets[1]),
              onChanged: (_) {},
              firstDate: DateTime(2020),
              lastDate: DateUtils.dateOnly(DateTime.now()),
              presets: presets,
            ),
            PaymentDateRangePicker(
              label: _t(context, 'Date range', 'Rentang tanggal'),
              value: null,
              enabled: false,
              onChanged: (_) {},
              firstDate: DateTime(2020),
              lastDate: DateUtils.dateOnly(DateTime.now()),
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
            PaymentChip(
              label: _t(context, 'Date', 'Tanggal'),
              value: PaymentLocalizations.of(
                context,
              ).formatDateRange(DateTime(2026, 10), DateTime(2026, 10, 31)),
              onClose: () {},
            ),
            PaymentChip(
              label: _t(context, 'Method', 'Metode'),
              values: ['Transfer', 'QRIS', _t(context, 'Card', 'Kartu')],
              onDropdown: () {},
            ),
            PaymentChip(
              label: _t(context, 'Add status', 'Tambah status'),
              onAddSuggestion: () {},
            ),
            PaymentChip(
              label: _t(context, 'Currency', 'Mata uang'),
              value: 'IDR',
            ),
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
