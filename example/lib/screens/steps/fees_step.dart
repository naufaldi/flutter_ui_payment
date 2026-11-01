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
              // The info button toggles its hint on tap (D49).
              PaymentTooltip(
                message: s.feesTooltip,
                trigger: (toggle, focusNode) => PaymentIconButton(
                  key: const Key('fees-info'),
                  icon: Icons.info_outline,
                  tooltip: s.feesInfo,
                  focusNode: focusNode,
                  onPressed: toggle,
                ),
              ),
            ],
          ),
          PaymentTable(
            caption: s.feesTitle,
            head: [
              PaymentTableHeaderCell(s.columnMethod, rowHeader: true),
              PaymentTableHeaderCell(s.columnFee, numeric: true),
              PaymentTableHeaderCell(s.columnArrives),
            ],
            rows: [
              for (final (method, fee, arrives) in [
                (s.methodVirtualAccount, 2500, s.arrivesWithin10),
                ('QRIS', 0, s.arrivesInstant),
                (s.methodBalance, 0, s.arrivesInstant),
                (s.methodCard, 4000, s.arrivesInstant),
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
