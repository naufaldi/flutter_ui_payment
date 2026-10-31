import 'package:flutter/material.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import '../../coordinator/demo_coordinator.dart';
import '../../demo_strings.dart';

class OrderContext extends StatelessWidget {
  const OrderContext(this.c, {super.key});
  final DemoCoordinator c;
  @override
  Widget build(BuildContext context) {
    final s = DemoStrings.of(context);
    return PaymentContextView(
      title: s.orderContext,
      description: '${s.productTitle} · Order DEMO-42',
      brand: const PaymentIcon(Icons.storefront_outlined),
      externalLink: PaymentLink(
        label: s.merchantHelp,
        external: true,
        onPressed: () => showPaymentToast(context, message: s.supportOpened),
      ),
      child: PaymentPropertyList(
        items: [
          PaymentPropertyListItem(label: 'Item', valueText: s.productTitle),
          const PaymentPropertyListItem(
            label: 'Merchant',
            valueText: 'Ruang Bayar Akademi',
          ),
          const PaymentPropertyListItem(label: 'Order', valueText: 'DEMO-42'),
          if (c.quote != null)
            PaymentPropertyListItem(
              label: 'Total',
              value: AmountText(c.quote!.total),
              emphasis: true,
            ),
        ],
      ),
    );
  }
}
