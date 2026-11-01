part of 'gallery_screen.dart';

String _unavailable(BuildContext context) => _t(
  context,
  'Not available for this merchant',
  'Tidak tersedia untuk merchant ini',
);

class _TabsSpecimen extends StatefulWidget {
  const _TabsSpecimen();
  @override
  State<_TabsSpecimen> createState() => _TabsSpecimenState();
}

class _TabsSpecimenState extends State<_TabsSpecimen> {
  int _selected = 0;
  @override
  Widget build(BuildContext context) {
    final card = _t(context, 'Card', 'Kartu');
    final bankTransfer = _t(context, 'Bank transfer', 'Transfer bank');
    final wallet = _t(context, 'Wallet', 'Dompet digital');
    return _build(context, card, bankTransfer, wallet);
  }

  Widget _build(
    BuildContext context,
    String card,
    String bankTransfer,
    String wallet,
  ) => _Entry(
    name: 'PaymentTabs · variants',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final size in PaymentSize.values) ...[
          PaymentTabs(
            size: size,
            tabs: [
              PaymentTab(label: card),
              PaymentTab(label: bankTransfer),
            ],
            selectedIndex: _selected,
            onSelected: (i) => setState(() => _selected = i),
          ),
          if (size == PaymentSize.medium)
            PaymentTabPanels(
              selectedIndex: _selected,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: PaymentTheme.of(context).spacing,
                  ),
                  child: Text(
                    _t(
                      context,
                      'Pay with your saved card.',
                      'Bayar dengan kartu tersimpan Anda.',
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: PaymentTheme.of(context).spacing,
                  ),
                  child: Text(
                    _t(
                      context,
                      'Use your bank transfer reference.',
                      'Gunakan referensi transfer bank Anda.',
                    ),
                  ),
                ),
              ],
            ),
        ],
        PaymentTabs(
          fitted: true,
          tabs: [
            PaymentTab(label: card),
            PaymentTab(label: bankTransfer),
            PaymentTab(label: wallet),
          ],
          selectedIndex: 0,
          onSelected: (_) {},
        ),
        PaymentTabs(
          tabs: [
            PaymentTab(label: card),
            PaymentTab(label: wallet, disabledReason: _unavailable(context)),
          ],
          selectedIndex: 0,
          onSelected: (_) {},
        ),
      ],
    ),
  );
}

class _SelectionSpecimen extends StatefulWidget {
  const _SelectionSpecimen(this.kind);
  final String kind;
  @override
  State<_SelectionSpecimen> createState() => _SelectionSpecimenState();
}

class _SelectionSpecimenState extends State<_SelectionSpecimen> {
  bool _email = true;
  bool _sms = false;
  String? _receipt;
  @override
  Widget build(BuildContext context) {
    String t(String en, String id) => _t(context, en, id);
    final kind = widget.kind;
    return _Entry(
      name: '$kind · variants',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: switch (kind) {
          'PaymentCheckbox' => [
            PaymentCheckbox(
              value: _email && _sms,
              indeterminate: _email != _sms,
              onChanged: (v) => setState(() {
                _email = v;
                _sms = v;
              }),
              label: t('Select all receipts', 'Pilih semua struk'),
            ),
            PaymentCheckbox(
              value: _email,
              onChanged: (v) => setState(() => _email = v),
              label: t('Email receipt', 'Struk lewat email'),
              description: t(
                'Send a copy to your saved email',
                'Kirim salinan ke email tersimpan Anda',
              ),
            ),
            PaymentCheckbox(
              value: _sms,
              onChanged: (v) => setState(() => _sms = v),
              label: t('SMS receipt', 'Struk lewat SMS'),
            ),
            PaymentCheckbox(
              value: false,
              onChanged: (_) {},
              label: t('Accept the terms', 'Setujui ketentuan'),
              errorText: t(
                'Accept the terms to continue',
                'Setujui ketentuan untuk melanjutkan',
              ),
              required: true,
            ),
            PaymentCheckbox(
              value: false,
              onChanged: null,
              label: t('Paper receipt', 'Struk kertas'),
              disabledReason: _unavailable(context),
            ),
          ],
          'PaymentRadio' => [
            for (final method in ['Email', 'SMS'])
              PaymentRadio(
                value: method,
                groupValue: _receipt,
                onChanged: (v) => setState(() => _receipt = v),
                label: method,
                description: t(
                  'Send receipt by ${method.toLowerCase()}',
                  'Kirim struk lewat ${method == 'SMS' ? 'SMS' : 'email'}',
                ),
              ),
            // A group error shows once, under the last option (#65).
            for (final method in ['Email', 'SMS'])
              PaymentRadio(
                value: method,
                groupValue: null,
                onChanged: (_) {},
                label: method,
                errorText: method == 'SMS'
                    ? t(
                        'Choose how to get your receipt',
                        'Pilih cara menerima struk',
                      )
                    : null,
              ),
            PaymentRadio(
              value: 'Paper',
              groupValue: null,
              onChanged: null,
              label: t('Paper receipt', 'Struk kertas'),
              disabledReason: _unavailable(context),
            ),
          ],
          _ => [
            PaymentSwitch(
              value: _email,
              onChanged: (v) => setState(() => _email = v),
              label: t('Email receipts', 'Struk lewat email'),
              description: t(
                'Send a copy after each payment',
                'Kirim salinan setiap selesai membayar',
              ),
            ),
            PaymentSwitch(
              value: _sms,
              onChanged: (v) => setState(() => _sms = v),
              label: t('SMS receipts', 'Struk lewat SMS'),
            ),
            PaymentSwitch(
              value: false,
              onChanged: (_) {},
              label: t('Payment notifications', 'Notifikasi pembayaran'),
              errorText: t(
                'Allow notifications in settings',
                'Izinkan notifikasi di pengaturan',
              ),
            ),
            PaymentSwitch(
              value: false,
              onChanged: null,
              label: t('Paper receipts', 'Struk kertas'),
              disabledReason: _unavailable(context),
            ),
          ],
        },
      ),
    );
  }
}

class _CurrencyFieldSpecimen extends StatelessWidget {
  const _CurrencyFieldSpecimen();
  @override
  Widget build(BuildContext context) => _Entry(
    name: 'PaymentCurrencyField · variants',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: PaymentTheme.of(context).space(PaymentSpace.group),
      children: [
        const _CurrencySwitch(),
        for (final size in PaymentSize.values)
          PaymentCurrencyField(
            currency: 'IDR',
            size: size,
            label: _sizeLabel(context, size),
            onChanged: (_) {},
          ),
        PaymentCurrencyField(
          currency: 'IDR',
          description: _t(
            context,
            'Use your available balance',
            'Gunakan saldo yang tersedia',
          ),
          minimum: const Money.idr(10000),
          onChanged: (_) {},
        ),
        PaymentCurrencyField(
          currency: 'USD',
          initialText: '5.00',
          padFractionDigits: true,
          onChanged: (_) {},
        ),
      ],
    ),
  );
}

class _TextFieldSpecimen extends StatefulWidget {
  const _TextFieldSpecimen();
  @override
  State<_TextFieldSpecimen> createState() => _TextFieldSpecimenState();
}

class _TextFieldSpecimenState extends State<_TextFieldSpecimen> {
  String query = 'kopi';
  @override
  Widget build(BuildContext context) {
    String t(String en, String id) => _t(context, en, id);
    return _build(context, t);
  }

  Widget _build(
    BuildContext context,
    String Function(String, String) t,
  ) => _Entry(
    name: 'PaymentTextField · variants',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: PaymentTheme.of(context).space(PaymentSpace.group),
      children: [
        for (final size in PaymentSize.values)
          PaymentTextField(label: t('Full name', 'Nama lengkap'), size: size),
        PaymentTextField(
          label: t('Email for receipt', 'Email untuk struk'),
          type: PaymentTextFieldType.email,
          description: t('We send the receipt here.', 'Struk dikirim ke sini.'),
        ),
        PaymentTextField(
          label: t('Phone number', 'Nomor ponsel'),
          type: PaymentTextFieldType.tel,
          required: true,
          errorText: t('Enter a phone number', 'Masukkan nomor ponsel'),
        ),
        PaymentTextField(
          label: t('Promo code', 'Kode promo'),
          reference: true,
          initialValue: 'HEMAT10',
        ),
        PaymentTextField(
          label: t('Order ID', 'ID pesanan'),
          readOnly: true,
          initialValue: 'ORD-2026-0042',
        ),
        PaymentTextField(
          label: t('Company name', 'Nama perusahaan'),
          enabled: false,
        ),
        PaymentTextField.search(
          query: query,
          onChanged: (v) => setState(() => query = v),
        ),
      ],
    ),
  );
}

class _ActionSpecimen extends StatelessWidget {
  const _ActionSpecimen(this.kind);
  final String kind;
  @override
  Widget build(BuildContext context) => _Entry(
    name: '$kind · variants',
    child: switch (kind) {
      'PaymentIconButton' => Wrap(
        children: [
          PaymentIconButton(
            icon: PaymentIcons.close,
            tooltip: _t(context, 'Close', 'Tutup'),
            onPressed: () {},
          ),
          PaymentIconButton(
            icon: Icons.more_vert,
            tooltip: _t(context, 'More actions', 'Tindakan lain'),
            onPressed: () {},
          ),
          PaymentIconButton(
            icon: PaymentIcons.copy,
            tooltip: _t(context, 'Copy', 'Salin'),
            variant: PaymentIconButtonVariant.accent,
            onPressed: () {},
          ),
          PaymentIconButton(
            icon: PaymentIcons.close,
            tooltip: _t(context, 'Disabled close', 'Tutup nonaktif'),
            onPressed: null,
          ),
          PaymentIconButton(
            key: const Key('icon-button-focus'),
            icon: PaymentIcons.close,
            tooltip: _t(context, 'Focused close', 'Tutup terfokus'),
            onPressed: () {},
          ),
        ],
      ),
      'PaymentLink' => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PaymentLink(label: _t(context, 'Edit', 'Ubah'), onPressed: () {}),
          PaymentLink(
            label: _t(
              context,
              'Read the privacy policy',
              'Baca kebijakan privasi',
            ),
            external: true,
            onPressed: () {},
          ),
          PaymentLink(
            label: _t(context, 'Why this?', 'Kenapa ini?'),
            variant: PaymentLinkVariant.secondary,
            onPressed: () {},
          ),
          PaymentLink(label: _t(context, 'Edit', 'Ubah'), onPressed: null),
          PaymentLink(
            label: _t(
              context,
              'View payment instructions for virtual account',
              'Lihat petunjuk pembayaran virtual account',
            ),
            onPressed: () {},
          ),
          // States old → new and has no dismiss while paying (D48).
          PaymentBanner(
            tone: StatusTone.warning,
            title: _t(context, 'Total changed', 'Total berubah'),
            message: PaymentLocalizations.of(context).totalChangedMessage(
              PaymentLocalizations.of(
                context,
              ).moneyFormat.format(const Money.idr(102500)),
              PaymentLocalizations.of(
                context,
              ).moneyFormat.format(const Money.idr(104000)),
            ),
            actions: [
              PaymentLink(
                label: _t(context, 'Review total', 'Periksa total'),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
      _ => Column(
        children: [
          const Row(
            children: [
              Expanded(child: Text('8808 1234 5678 9012')),
              PaymentCopyButton(
                value: '8808 1234 5678 9012',
                onCopy: _copyGalleryValue,
              ),
            ],
          ),
          Row(
            children: [
              const Expanded(child: Text('TRX-DEMO-42')),
              PaymentCopyButton(
                key: const Key('copy-failed'),
                value: 'TRX-DEMO-42',
                onCopy: (_) async => false,
              ),
            ],
          ),
        ],
      ),
    },
  );
}
