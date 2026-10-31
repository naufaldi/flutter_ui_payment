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
        'PaymentDataTable' => _SettlementSpecimen(),
        'PaymentButtonGroup' => Column(
          spacing: 16,
          children: [
            for (final collapse in PaymentButtonGroupCollapse.values)
              PaymentButtonGroup(
                collapse: collapse,
                children: [
                  PaymentButton(
                    label: 'Share',
                    variant: PaymentButtonVariant.secondary,
                    onPressed: () {},
                  ),
                  PaymentButton(
                    label: 'Download',
                    variant: PaymentButtonVariant.secondary,
                    onPressed: () {},
                  ),
                  PaymentButton(
                    label: 'Report a problem',
                    variant: PaymentButtonVariant.quiet,
                    onPressed: () {},
                  ),
                ],
              ),
            PaymentButtonGroup(
              direction: Axis.vertical,
              children: [
                PaymentButton(label: 'Check status', onPressed: () {}),
                PaymentButton(
                  label: 'Start new payment',
                  variant: PaymentButtonVariant.secondary,
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
        'PaymentTaskList' => const PaymentTaskList(
          items: [
            PaymentTaskListItem(
              title: 'Identity',
              status: PaymentTaskStatus.complete,
            ),
            PaymentTaskListItem(
              title: 'Documents',
              status: PaymentTaskStatus.inProgress,
              subTasks: [
                PaymentTaskListItem(
                  title: 'KTP',
                  status: PaymentTaskStatus.complete,
                ),
                PaymentTaskListItem(title: 'Selfie'),
              ],
            ),
            PaymentTaskListItem(
              title: 'Review',
              status: PaymentTaskStatus.blocked,
            ),
          ],
        ),
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

class _SettlementSpecimen extends StatefulWidget {
  @override
  State<_SettlementSpecimen> createState() => _SettlementSpecimenState();
}

class _SettlementSpecimenState extends State<_SettlementSpecimen> {
  Set<String> selected = {};
  String query = '';
  @override
  Widget build(BuildContext context) {
    final columns = [
      PaymentDataColumn<int>(
        key: 'date',
        label: 'Date',
        value: (r) => DateTime(2026, 10, r % 28 + 1),
        cell: PaymentCellType.date,
        sortable: true,
      ),
      PaymentDataColumn<int>(
        key: 'id',
        label: 'Reference',
        value: (r) => 'STL-DEMO-${r.toString().padLeft(4, '0')}',
        cell: PaymentCellType.id,
        pinned: true,
      ),
      PaymentDataColumn<int>(
        key: 'description',
        label: 'Description',
        value: (r) => 'Settlement $r',
      ),
      PaymentDataColumn<int>(
        key: 'status',
        label: 'Status',
        value: (r) => r % 3 == 0 ? 'Pending' : 'Paid',
        cell: PaymentCellType.status,
        statusMap: {'Paid': StatusTone.success, 'Pending': StatusTone.warning},
      ),
      PaymentDataColumn<int>(
        key: 'amount',
        label: 'Amount',
        value: (r) => Money.idr(r * 2500),
        cell: PaymentCellType.currency,
        sortable: true,
      ),
    ];
    return Column(
      spacing: 16,
      children: [
        PaymentTextField.search(
          query: query,
          label: 'Search settlements',
          onChanged: (v) => setState(() => query = v),
        ),
        PaymentDataTable<int>(
          columns: columns,
          rows: List.generate(40, (i) => i + 1),
          rowKey: (r) => '$r',
          pagination: const PaymentPagination.local(pageSize: 10),
          selection: selected,
          onSelectionChanged: (v) => setState(() => selected = v),
          filter: (r, q) => 'STL-DEMO-$r Settlement $r'.toLowerCase().contains(
            q.toLowerCase(),
          ),
          filterQuery: query,
          batchActions: [
            PaymentButton(
              label: 'Download selected',
              variant: PaymentButtonVariant.secondary,
              onPressed: () {},
            ),
          ],
          rowActions: [
            PaymentRowAction<int>(
              id: 'view',
              label: 'View receipt',
              onPressed: (_) {},
            ),
            PaymentRowAction<int>(
              id: 'report',
              label: 'Report a problem',
              onPressed: (_) {},
            ),
            PaymentRowAction<int>(
              id: 'cancel',
              label: 'Cancel payout',
              destructive: true,
              onPressed: (_) {},
            ),
          ],
        ),
        PaymentDataTable<int>(
          columns: columns,
          rows: const [],
          rowKey: (r) => '$r',
          pending: true,
        ),
        PaymentDataTable<int>(
          columns: columns,
          rows: const [],
          rowKey: (r) => '$r',
          emptyMessage: PaymentEmptyMessage(
            'No settlements yet',
            message: 'Settlements appear after your first payout.',
            actionLabel: 'Set up payouts',
            onAction: () {},
          ),
        ),
        PaymentDataTable<int>(
          columns: columns,
          rows: const [],
          rowKey: (r) => '$r',
          errorText: 'Statement didn’t load',
          onRetry: () {},
        ),
      ],
    );
  }
}
