part of 'gallery_screen.dart';

class _ContentSpecimen extends StatelessWidget {
  const _ContentSpecimen(this.name);
  final String name;
  @override
  Widget build(BuildContext context) {
    String t(String en, String id) => _t(context, en, id);
    final facts = [
      PaymentPropertyListItem(
        label: t('Method', 'Metode'),
        valueText: t('BCA virtual account', 'Virtual account BCA'),
      ),
      PaymentPropertyListItem(
        label: t('Amount', 'Jumlah'),
        value: const AmountText(Money.idr(102500)),
      ),
      PaymentPropertyListItem(
        label: t('Status', 'Status'),
        value: PaymentBadge(
          label: t('Paid', 'Dibayar'),
          tone: StatusTone.success,
        ),
      ),
      PaymentPropertyListItem(
        label: t('Reference', 'Referensi'),
        valueText: 'TRX-DEMO-42',
        reference: true,
        trailing: PaymentCopyButton(
          value: 'TRX-DEMO-42',
          onCopy: _copyGalleryValue,
          tooltip: t('Copy reference', 'Salin referensi'),
        ),
        caption: t(
          'Copy to quote it to support',
          'Salin untuk disebutkan ke bantuan',
        ),
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
                    label: t('Share', 'Bagikan'),
                    variant: PaymentButtonVariant.secondary,
                    onPressed: () {},
                  ),
                  PaymentButton(
                    label: t('Download', 'Unduh'),
                    variant: PaymentButtonVariant.secondary,
                    onPressed: () {},
                  ),
                  PaymentButton(
                    label: t('Report a problem', 'Laporkan masalah'),
                    variant: PaymentButtonVariant.quiet,
                    onPressed: () {},
                  ),
                ],
              ),
            PaymentButtonGroup(
              direction: Axis.vertical,
              children: [
                PaymentButton(
                  label: t('Check status', 'Cek status'),
                  onPressed: () {},
                ),
                PaymentButton(
                  label: t('Start new payment', 'Mulai pembayaran baru'),
                  variant: PaymentButtonVariant.secondary,
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
        'PaymentTaskList' => PaymentTaskList(
          items: [
            PaymentTaskListItem(
              title: t('Identity', 'Identitas'),
              status: PaymentTaskStatus.complete,
            ),
            PaymentTaskListItem(
              title: t('Documents', 'Dokumen'),
              status: PaymentTaskStatus.inProgress,
              subTasks: [
                const PaymentTaskListItem(
                  title: 'KTP',
                  status: PaymentTaskStatus.complete,
                ),
                PaymentTaskListItem(title: t('Selfie', 'Swafoto')),
              ],
            ),
            PaymentTaskListItem(
              title: t('Review', 'Tinjauan'),
              status: PaymentTaskStatus.blocked,
            ),
          ],
        ),
        'PaymentPropertyList' => Column(
          children: [
            PaymentPropertyList(
              title: t('Payment details', 'Rincian pembayaran'),
              items: facts,
            ),
            PaymentPropertyList(orientation: Axis.horizontal, items: facts),
          ],
        ),
        'PaymentTable' => PaymentTable(
          head: [
            PaymentTableHeaderCell(t('Method', 'Metode'), rowHeader: true),
            PaymentTableHeaderCell(t('Fee', 'Biaya'), numeric: true),
            PaymentTableHeaderCell(t('Arrives', 'Masuk')),
          ],
          rows: [
            for (final (method, fee, arrives) in [
              (
                t('Virtual account', 'Virtual account'),
                'Rp2.500',
                t('Within 10 min', 'Dalam 10 menit'),
              ),
              ('QRIS', 'Rp0', t('Instant', 'Instan')),
              (t('Card', 'Kartu'), 'Rp4.000', t('Instant', 'Instan')),
              (
                t('Wallet', 'Dompet digital'),
                'Rp1.500',
                t('Instant', 'Instan'),
              ),
            ])
              PaymentTableRow([
                PaymentTableCell(Text(method)),
                PaymentTableCell(Text(fee)),
                PaymentTableCell(Text(arrives)),
              ]),
          ],
          footer: PaymentTableRow([
            PaymentTableCell(Text(t('Total', 'Total'))),
            const PaymentTableCell(Text('Rp8.000')),
            PaymentTableCell(Text(t('Host computed', 'Dihitung host'))),
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
    String t(String en, String id) => _t(context, en, id);
    final paid = t('Paid', 'Dibayar');
    final pending = t('Pending', 'Tertunda');
    final settlement = t('Settlement', 'Penyelesaian');
    final columns = [
      PaymentDataColumn<int>(
        key: 'date',
        label: t('Date', 'Tanggal'),
        value: (r) => DateTime(2026, 10, r % 28 + 1),
        cell: PaymentCellType.date,
        sortable: true,
      ),
      PaymentDataColumn<int>(
        key: 'id',
        label: t('Reference', 'Referensi'),
        value: (r) => 'STL-DEMO-${r.toString().padLeft(4, '0')}',
        cell: PaymentCellType.id,
        pinned: true,
      ),
      PaymentDataColumn<int>(
        key: 'description',
        label: t('Description', 'Deskripsi'),
        value: (r) => '$settlement $r',
      ),
      PaymentDataColumn<int>(
        key: 'status',
        label: t('Status', 'Status'),
        value: (r) => r % 3 == 0 ? pending : paid,
        cell: PaymentCellType.status,
        statusMap: {paid: StatusTone.success, pending: StatusTone.warning},
      ),
      PaymentDataColumn<int>(
        key: 'amount',
        label: t('Amount', 'Jumlah'),
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
          label: t('Search settlements', 'Cari penyelesaian'),
          onChanged: (v) => setState(() => query = v),
        ),
        PaymentDataTable<int>(
          columns: columns,
          rows: List.generate(40, (i) => i + 1),
          rowKey: (r) => '$r',
          pagination: const PaymentPagination.local(pageSize: 10),
          selection: selected,
          onSelectionChanged: (v) => setState(() => selected = v),
          filter: (r, q) => 'STL-DEMO-$r $settlement $r'.toLowerCase().contains(
            q.toLowerCase(),
          ),
          filterQuery: query,
          batchActions: [
            PaymentButton(
              label: t('Download selected', 'Unduh yang dipilih'),
              variant: PaymentButtonVariant.secondary,
              onPressed: () {},
            ),
          ],
          rowActions: [
            PaymentRowAction<int>(
              id: 'view',
              label: t('View receipt', 'Lihat struk'),
              onPressed: (_) {},
            ),
            PaymentRowAction<int>(
              id: 'report',
              label: t('Report a problem', 'Laporkan masalah'),
              onPressed: (_) {},
            ),
            PaymentRowAction<int>(
              id: 'cancel',
              label: t('Cancel payout', 'Batalkan pencairan'),
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
            t('No settlements yet', 'Belum ada penyelesaian'),
            message: t(
              'Settlements appear after your first payout.',
              'Penyelesaian muncul setelah pencairan pertama Anda.',
            ),
            actionLabel: t('Set up payouts', 'Atur pencairan'),
            onAction: () {},
          ),
        ),
        PaymentDataTable<int>(
          columns: columns,
          rows: const [],
          rowKey: (r) => '$r',
          errorText: t('Statement didn’t load', 'Laporan gagal dimuat'),
          onRetry: () {},
        ),
      ],
    );
  }
}
