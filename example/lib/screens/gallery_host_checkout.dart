part of 'gallery_screen.dart';

// D98 host adoption: two checkout layouts from compositions/host_checkout.dart
// share one host state, one set of callbacks and one product look. The
// gallery plays the host; nothing here talks to DemoCoordinator.

class _HostCheckoutDemo extends StatefulWidget {
  const _HostCheckoutDemo();
  @override
  State<_HostCheckoutDemo> createState() => _HostCheckoutDemoState();
}

class _HostCheckoutDemoState extends State<_HostCheckoutDemo> {
  static const _methods = [
    PaymentMethod(
      id: 'balance',
      label: 'Saldo Ruang Bayar',
      detail: 'Saldo Rp350.000',
      kind: PaymentMethodKind.balance,
    ),
    PaymentMethod(
      id: 'va',
      label: 'Virtual account (Bank Contoh)',
      detail: 'Bayar lewat transfer bank',
      kind: PaymentMethodKind.virtualAccount,
    ),
  ];

  String _method = 'balance';
  String _email = 'rina@contoh.id';
  bool _paying = false;

  CheckoutOrder get _order => CheckoutOrder(
    merchant: 'Ruang Bayar Akademi',
    merchantVerified: true, // Verified synthetic merchant fixture.
    reference: 'INV-2026-1103',
    quote: _quote(methodId: _method),
    methods: _methods,
    selectedMethodId: _method,
    balance: const Money.idr(350000),
    balanceState: BalanceState.sufficient,
    receiptEmail: _email,
    paying: _paying,
  );

  CheckoutActions _actions(BuildContext context) => CheckoutActions(
    onSelectMethod: (m) => setState(() => _method = m.id),
    onChangeMethod: () => _hostSays(
      context,
      'Host opens the method choice',
      'Host membuka pilihan metode',
    ),
    onReceiptEmailChanged: (v) => _email = v,
    onPay: () async {
      setState(() => _paying = true);
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() => _paying = false);
      if (context.mounted) {
        _hostSays(
          context,
          'Payment request received. No payment sent.',
          'Permintaan pembayaran diterima. Tidak ada pembayaran dikirim.',
        );
      }
    },
  );

  @override
  Widget build(BuildContext context) {
    final order = _order;
    // One product look around both layouts, as a host app or feature would.
    return ProductLooks(
      child: Builder(
        builder: (context) {
          final actions = _actions(context);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Entry(
                name: 'Host checkout · invoice · variants',
                child: InvoiceCheckout(order: order, actions: actions),
              ),
              _Entry(
                name: 'Host checkout · wallet review · variants',
                child: WalletReviewCheckout(order: order, actions: actions),
              ),
            ],
          );
        },
      ),
    );
  }
}
