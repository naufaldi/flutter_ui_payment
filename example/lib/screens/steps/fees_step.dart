import 'package:flutter/material.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import '../../coordinator/demo_coordinator.dart';
import '../../demo_strings.dart';

class FeesStep extends StatelessWidget {
  const FeesStep(this.c, {super.key});
  final DemoCoordinator c;
  @override
  Widget build(BuildContext context) {
    final s = DemoStrings.of(context);
    return PaymentFullPageView(
      title: s.feesTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: PaymentTheme.of(context).space(PaymentSpace.block),
        children: [
          Row(
            children: [
              Expanded(child: Text(s.feesNote)),
              PaymentTooltip(
                message: s.feesTooltip,
                child: PaymentIconButton(
                  icon: Icons.info_outline,
                  tooltip: s.feesTooltip,
                  onPressed: () {},
                ),
              ),
            ],
          ),
          PaymentTable(
            caption: s.feesTitle,
            head: const [
              PaymentTableHeaderCell('Method', rowHeader: true),
              PaymentTableHeaderCell('Fee', numeric: true),
              PaymentTableHeaderCell('Arrives'),
            ],
            rows: [
              for (final (method, fee, arrives) in [
                ('Virtual account', 2500, 'Within 10 min'),
                ('QRIS', 0, 'Instant'),
                ('Ruang Bayar balance', 0, 'Instant'),
                ('Card', 4000, 'Instant'),
              ])
                PaymentTableRow([
                  PaymentTableCell(Text(method)),
                  PaymentTableCell(AmountText(Money.idr(fee)), numeric: true),
                  PaymentTableCell(Text(arrives)),
                ]),
            ],
          ),
        ],
      ),
    );
  }
}
