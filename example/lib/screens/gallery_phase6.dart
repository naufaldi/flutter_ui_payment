part of 'gallery_screen.dart';

class _KitSpecimen extends StatefulWidget {
  const _KitSpecimen(this.kind);
  final String kind;
  @override
  State<_KitSpecimen> createState() => _KitSpecimenState();
}

class _KitSpecimenState extends State<_KitSpecimen> {
  final _video = _StalledVideo();
  String _selected = 'payments';
  @override
  void dispose() {
    _video.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = PaymentTheme.of(context);
    final space = t.space(PaymentSpace.block);
    PaymentButton action(
      String label, {
      VoidCallback? onPressed,
      bool primary = false,
    }) => PaymentButton(
      label: label,
      variant: primary
          ? PaymentButtonVariant.primary
          : PaymentButtonVariant.secondary,
      onPressed: onPressed,
    );
    final now = DateTime(2026, 11, 1, 12);
    String tr(String en, String id) => _t(context, en, id);
    final l10n = PaymentLocalizations.of(context);
    final pay = l10n.payAmount(
      l10n.moneyFormat.format(const Money.idr(102500)),
    );
    // One name for the action on the button and in its confirmation.
    final removeCard = tr('Remove card', 'Hapus kartu');
    final (caption, children) = switch (widget.kind) {
      'dialog' => (
        'showPaymentConfirmDialog · variants',
        <Widget>[
          Text(
            tr(
              'Confirm the named consequence before removing a saved card.',
              'Konfirmasi akibatnya sebelum menghapus kartu tersimpan.',
            ),
          ),
          PaymentButton(
            key: const Key('phase6-dialog-open'),
            label: removeCard,
            variant: PaymentButtonVariant.destructive,
            onPressed: () => showPaymentConfirmDialog(
              context,
              title: tr('Remove card?', 'Hapus kartu?'),
              message: tr(
                'You can add this demo card again later.',
                'Anda bisa menambahkan kartu demo ini lagi nanti.',
              ),
              confirmLabel: removeCard,
              cancelLabel: tr('Cancel', 'Batal'),
              destructive: true,
            ),
          ),
        ],
      ),
      'sheets' => (
        'PaymentSheet · variants',
        <Widget>[
          SizedBox(
            height: 420,
            child: PaymentSheet(
              header: PaymentSheetHeader(
                title: tr('Payment options', 'Opsi pembayaran'),
              ),
              body: Text(
                tr(
                  'Choose a method for this demo payment.',
                  'Pilih metode untuk pembayaran demo ini.',
                ),
              ),
              // The sheet's completion action is its one primary; the
              // trigger that opens a sheet stays secondary (D54).
              footer: action(
                tr('Done', 'Selesai'),
                onPressed: () {},
                primary: true,
              ),
            ),
          ),
          action(
            tr('Open sheet', 'Buka sheet'),
            onPressed: () => showPaymentSheet<void>(
              context: context,
              builder: (_) => PaymentSheet(
                header: PaymentSheetHeader(
                  title: tr('Demo sheet', 'Sheet demo'),
                ),
                body: Text(
                  tr(
                    'Supporting payment information.',
                    'Informasi pendukung pembayaran.',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      'section' => (
        'PaymentSection · variants',
        <Widget>[
          PaymentSection(
            title: tr('Payment method', 'Metode pembayaran'),
            trailing: PaymentLink(
              label: tr('Change', 'Ganti'),
              onPressed: () {},
            ),
            child: Text(tr('QRIS · Instant', 'QRIS · Instan')),
          ),
          PaymentSection(
            child: Text(tr('Fees include VAT.', 'Biaya sudah termasuk PPN.')),
          ),
        ],
      ),
      'navigation' => (
        'AdaptiveNavShell · variants',
        <Widget>[
          SizedBox(
            width: 280,
            height: 340,
            child: NavSidebar(
              selectedId: _selected,
              onSelected: (item) => setState(() => _selected = item.id),
              sections: [
                PaymentNavSection(
                  title: tr('Payments', 'Pembayaran'),
                  items: [
                    PaymentNavItem(
                      id: 'payments',
                      label: tr('Transactions', 'Transaksi'),
                      icon: Icons.receipt_long_outlined,
                    ),
                  ],
                ),
                PaymentNavSection(
                  title: tr('Account', 'Akun'),
                  items: [
                    PaymentNavItem(
                      id: 'settings',
                      label: tr('Settings', 'Pengaturan'),
                      icon: Icons.settings_outlined,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      'step_indicator' => (
        'PaymentStepIndicator · variants',
        <Widget>[
          for (var i = 0; i < 3; i++)
            PaymentStepIndicator(
              steps: [
                tr('Order', 'Pesanan'),
                tr('Review', 'Tinjau'),
                tr('Pay', 'Bayar'),
              ],
              current: i,
            ),
        ],
      ),
      'info_row' => (
        'InfoRow · variants',
        <Widget>[
          InfoRow(label: tr('Method', 'Metode'), valueText: 'QRIS'),
          InfoRow(
            label: tr('Total', 'Total'),
            value: const AmountText(Money.idr(102500)),
            emphasis: true,
          ),
          InfoRow(
            label: tr('Fee', 'Biaya'),
            valueText: 'Rp2.500',
            caption: tr('Includes VAT', 'Termasuk PPN'),
          ),
          InfoRow(
            label: tr('Reference', 'Referensi'),
            valueText: 'TRX-DEMO-0042',
            trailing: const PaymentCopyButton(
              value: 'TRX-DEMO-0042',
              onCopy: _copyGalleryValue,
            ),
          ),
          InfoRow(
            label: tr('Order', 'Pesanan'),
            value: const MiddleEllipsisText(
              'DEMO-ORDER-2026-VERY-LONG-REFERENCE-0042',
            ),
          ),
        ],
      ),
      'countdown' => (
        'CountdownText · variants',
        <Widget>[
          for (final minutes in [90, 7, 0])
            CountdownText(
              expiresAt: now.add(Duration(minutes: minutes)),
              clock: () => now,
            ),
        ],
      ),
      'privacy_mask' => (
        'PrivacyMask · variants',
        <Widget>[
          for (final obscured in [false, true])
            PrivacyMask(
              obscured: obscured,
              child: PaymentPropertyList(
                items: [
                  PaymentPropertyListItem(
                    label: tr('Virtual account', 'Virtual account'),
                    valueText: 'DEMO-VA-0042',
                  ),
                ],
              ),
            ),
        ],
      ),
      'action_bar' => (
        'PaymentActionBar · variants',
        <Widget>[
          PaymentActionBar(
            total: const Money.idr(102500),
            action: action(pay, onPressed: () {}, primary: true),
          ),
          PaymentActionBar(
            total: const Money.idr(102500),
            updating: true,
            action: action(l10n.updatingTotal, primary: true),
          ),
          Text(
            tr(
              'Choose a payment method to continue.',
              'Pilih metode pembayaran untuk melanjutkan.',
            ),
          ),
          PaymentActionBar(
            total: const Money.idr(102500),
            action: action(pay, primary: true),
          ),
        ],
      ),
      'media' => (
        'PaymentVideoPlayer · variants',
        <Widget>[
          PaymentVideoPlayer(
            controller: _video,
            title: tr(
              'How to pay (demo, loading only)',
              'Cara membayar (demo, hanya memuat)',
            ),
          ),
        ],
      ),
      'status_header' => (
        'StatusHeader · variants',
        <Widget>[
          StatusHeader(
            tone: StatusTone.success,
            icon: PaymentIcons.success,
            title: tr('Paid', 'Dibayar'),
          ),
          StatusHeader(
            tone: StatusTone.warning,
            icon: Icons.schedule,
            title: tr('Pending', 'Tertunda'),
          ),
          StatusHeader(
            tone: StatusTone.danger,
            icon: Icons.error_outline,
            title: tr('Failed', 'Gagal'),
          ),
          StatusHeader(
            tone: StatusTone.neutral,
            icon: Icons.help_outline,
            title: tr('Not confirmed', 'Belum dikonfirmasi'),
            hatched: true,
          ),
        ],
      ),
      'loading_skeleton' => (
        'LoadingSkeleton · variants',
        <Widget>[
          const LoadingSkeleton(rows: 2),
          const LoadingSkeleton(rows: 2, leading: false),
          const LoadingSkeleton.table(rows: 2),
        ],
      ),
      'state_message' => (
        'StateMessage · PaymentEmptyMessage · variants',
        <Widget>[
          StateMessage(
            icon: Icons.receipt_long_outlined,
            title: tr('No transactions yet', 'Belum ada transaksi'),
            message: tr(
              'Your first payment will appear here.',
              'Pembayaran pertama Anda akan muncul di sini.',
            ),
            actionLabel: tr('Make a payment', 'Lakukan pembayaran'),
            onAction: () {},
          ),
          StateMessage(
            icon: Icons.warning_amber,
            title: tr('Spending did not load', 'Pengeluaran gagal dimuat'),
            message: tr(
              'Payments are still available.',
              'Pembayaran tetap bisa dilakukan.',
            ),
            tone: StatusTone.warning,
            actionLabel: tr('Retry', 'Coba lagi'),
            onAction: () {},
          ),
          StateMessage(
            icon: Icons.error_outline,
            title: tr('Transactions did not load', 'Transaksi gagal dimuat'),
            message: tr(
              'Retry to see your payment history.',
              'Coba lagi untuk melihat riwayat pembayaran.',
            ),
            tone: StatusTone.danger,
            actionLabel: tr('Retry', 'Coba lagi'),
            onAction: () {},
          ),
          PaymentDetailPagePropertyList(
            title: tr('No matches', 'Tidak ada yang cocok'),
            pending: false,
            emptyMessage: PaymentEmptyMessage(
              tr(
                'No matching settlements',
                'Tidak ada penyelesaian yang cocok',
              ),
              message: tr(
                'Clear the search to see all records.',
                'Hapus pencarian untuk melihat semua catatan.',
              ),
              actionLabel: tr('Clear search', 'Hapus pencarian'),
              onAction: () {},
            ),
          ),
        ],
      ),
      'chart_module' => (
        'ChartModule · variants',
        <Widget>[
          for (final state in [
            ChartState.ready,
            ChartState.loading,
            ChartState.empty,
            ChartState.error,
          ])
            ChartModule(
              title:
                  '${tr('Weekly spending', 'Pengeluaran mingguan')} · ${switch (state) {
                    ChartState.ready => tr('ready', 'siap'),
                    ChartState.loading => tr('loading', 'memuat'),
                    ChartState.empty => tr('empty', 'kosong'),
                    ChartState.error => tr('error', 'galat'),
                  }}',
              state: state,
              height: 200,
              headline: state == ChartState.ready
                  ? const Money.idr(102500)
                  : null,
              chart: state == ChartState.ready
                  ? PaymentBarChart(
                      points: [
                        ChartPoint(
                          label: tr('W1', 'M1'),
                          value: const Money.idr(25000),
                        ),
                        ChartPoint(
                          label: tr('W2', 'M2'),
                          value: const Money.idr(77500),
                        ),
                      ],
                    )
                  : null,
              onRetry: () {},
            ),
        ],
      ),
      _ => throw ArgumentError.value(
        widget.kind,
        'kind',
        'Unknown kit specimen',
      ),
    };
    return _Entry(
      name: caption,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: space,
        children: children,
      ),
    );
  }
}
