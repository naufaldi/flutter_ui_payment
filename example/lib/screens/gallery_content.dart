part of 'gallery_screen.dart';

class _ContentSpecimen extends StatelessWidget {
  const _ContentSpecimen(this.name);
  final String name;
  @override
  Widget build(BuildContext context) {
    const facts = [
      PaymentPropertyListItem(
        label: 'Method',
        valueText: 'BCA virtual account',
      ),
      PaymentPropertyListItem(label: 'Amount', valueText: 'Rp102.500'),
      PaymentPropertyListItem(
        label: 'Status',
        value: PaymentBadge(label: 'Paid', tone: StatusTone.success),
      ),
      PaymentPropertyListItem(
        label: 'Reference',
        value: PaymentCode('TRX-DEMO-42'),
        caption: 'Copy to quote it to support',
      ),
    ];
    return _Entry(
      name: '$name · variants',
      child: switch (name) {
        'PaymentPropertyList' => const Column(
          children: [
            PaymentPropertyList(title: 'Payment details', items: facts),
            PaymentPropertyList(orientation: Axis.horizontal, items: facts),
          ],
        ),
        'PaymentTable' => const PaymentTable(
          head: [
            PaymentTableHeaderCell('Method', rowHeader: true),
            PaymentTableHeaderCell('Fee', numeric: true),
            PaymentTableHeaderCell('Arrives'),
          ],
          rows: [
            PaymentTableRow([
              PaymentTableCell(Text('Virtual account')),
              PaymentTableCell(Text('Rp2.500')),
              PaymentTableCell(Text('Within 10 min')),
            ]),
            PaymentTableRow([
              PaymentTableCell(Text('QRIS')),
              PaymentTableCell(Text('Rp0')),
              PaymentTableCell(Text('Instant')),
            ]),
            PaymentTableRow([
              PaymentTableCell(Text('Card')),
              PaymentTableCell(Text('Rp4.000')),
              PaymentTableCell(Text('Instant')),
            ]),
            PaymentTableRow([
              PaymentTableCell(Text('Wallet')),
              PaymentTableCell(Text('Rp1.500')),
              PaymentTableCell(Text('Instant')),
            ]),
          ],
          footer: PaymentTableRow([
            PaymentTableCell(Text('Total')),
            PaymentTableCell(Text('Rp8.000')),
            PaymentTableCell(Text('Host computed')),
          ]),
        ),
        _ => const LoadingSkeleton.table(rows: 3, columns: 3),
      },
    );
  }
}
