part of 'gallery_screen.dart';

class _TabsSpecimen extends StatefulWidget {
  const _TabsSpecimen();
  @override
  State<_TabsSpecimen> createState() => _TabsSpecimenState();
}

class _TabsSpecimenState extends State<_TabsSpecimen> {
  int _selected = 0;
  @override
  Widget build(BuildContext context) => _Entry(
    name: 'PaymentTabs · variants',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final size in PaymentSize.values) ...[
          PaymentTabs(
            size: size,
            tabs: const [
              PaymentTab(label: 'Card'),
              PaymentTab(label: 'Bank transfer'),
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
                  child: const Text('Pay with your saved card.'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: PaymentTheme.of(context).spacing,
                  ),
                  child: const Text('Use your bank transfer reference.'),
                ),
              ],
            ),
        ],
        PaymentTabs(
          fitted: true,
          tabs: const [
            PaymentTab(label: 'Card'),
            PaymentTab(label: 'Bank transfer'),
            PaymentTab(label: 'Wallet'),
          ],
          selectedIndex: 0,
          onSelected: (_) {},
        ),
        PaymentTabs(
          tabs: const [
            PaymentTab(label: 'Card'),
            PaymentTab(
              label: 'Wallet',
              disabledReason: 'Not available for this merchant',
            ),
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
              label: 'Select all receipts',
            ),
            PaymentCheckbox(
              value: _email,
              onChanged: (v) => setState(() => _email = v),
              label: 'Email receipt',
              description: 'Send a copy to your saved email',
            ),
            PaymentCheckbox(
              value: _sms,
              onChanged: (v) => setState(() => _sms = v),
              label: 'SMS receipt',
            ),
            PaymentCheckbox(
              value: false,
              onChanged: (_) {},
              label: 'Accept the terms',
              errorText: 'Accept the terms to continue',
              required: true,
            ),
            const PaymentCheckbox(
              value: false,
              onChanged: null,
              label: 'Paper receipt',
              disabledReason: 'Not available for this merchant',
            ),
          ],
          'PaymentRadio' => [
            for (final method in ['Email', 'SMS'])
              PaymentRadio(
                value: method,
                groupValue: _receipt,
                onChanged: (v) => setState(() => _receipt = v),
                label: method,
                description: 'Send receipt by ${method.toLowerCase()}',
              ),
            for (final method in ['Email', 'SMS'])
              PaymentRadio(
                value: method,
                groupValue: null,
                onChanged: (_) {},
                label: method,
                errorText: 'Choose how to get your receipt',
              ),
            const PaymentRadio(
              value: 'Paper',
              groupValue: null,
              onChanged: null,
              label: 'Paper receipt',
              disabledReason: 'Not available for this merchant',
            ),
          ],
          _ => [
            PaymentSwitch(
              value: _email,
              onChanged: (v) => setState(() => _email = v),
              label: 'Email receipts',
              description: 'Send a copy after each payment',
            ),
            PaymentSwitch(
              value: _sms,
              onChanged: (v) => setState(() => _sms = v),
              label: 'SMS receipts',
            ),
            PaymentSwitch(
              value: false,
              onChanged: (_) {},
              label: 'Payment notifications',
              errorText: 'Allow notifications in settings',
            ),
            const PaymentSwitch(
              value: false,
              onChanged: null,
              label: 'Paper receipts',
              disabledReason: 'Not available for this merchant',
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
      children: [
        for (final size in PaymentSize.values)
          Padding(
            padding: EdgeInsets.only(bottom: PaymentTheme.of(context).spacing),
            child: PaymentCurrencyField(
              currency: 'IDR',
              size: size,
              label: size.name,
              onChanged: (_) {},
            ),
          ),
        PaymentCurrencyField(
          currency: 'IDR',
          description: 'Use your available balance',
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
