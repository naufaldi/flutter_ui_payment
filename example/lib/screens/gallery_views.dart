part of 'gallery_screen.dart';

class _ViewSpecimen extends StatefulWidget {
  const _ViewSpecimen(this.name);
  final String name;
  @override
  State<_ViewSpecimen> createState() => _ViewSpecimenState();
}

class _ViewSpecimenState extends State<_ViewSpecimen> {
  int state = 0;
  bool refunds = true;
  bool promos = false;
  String method = 'bank', language = 'en';
  PaymentButton button(
    String label, {
    PaymentButtonVariant variant = PaymentButtonVariant.secondary,
  }) => PaymentButton(
    label: label,
    variant: variant,
    onPressed: () => _galleryFeedback(context, label, label),
  );
  Widget property({
    bool pending = false,
    bool empty = false,
    bool error = false,
    bool horizontal = false,
  }) => PaymentDetailPagePropertyList(
    title: _t(context, 'Payment details', 'Rincian pembayaran'),
    pending: pending,
    orientation: horizontal ? Axis.horizontal : Axis.vertical,
    errorText: error
        ? _t(context, 'Details didn’t load', 'Rincian gagal dimuat')
        : null,
    onRetry: () {},
    onCreate: empty ? () {} : null,
    emptyMessage: PaymentEmptyMessage(
      _t(context, 'No details yet', 'Belum ada rincian'),
      message: _t(
        context,
        'Add a payment detail to get started.',
        'Tambahkan rincian pembayaran untuk memulai.',
      ),
    ),
    items: empty
        ? const []
        : [
            PaymentDetailProperty(
              label: _t(context, 'Amount', 'Jumlah'),
              values: [
                PaymentDetailValue(
                  PaymentLocalizations.of(
                    context,
                  ).moneyFormat.format(const Money.idr(102500)),
                  subText: _t(context, 'Including fee', 'Termasuk biaya'),
                ),
              ],
            ),
            PaymentDetailProperty(
              label: _t(context, 'Merchant', 'Merchant'),
              values: [
                PaymentDetailValue.link(
                  PaymentLink(label: 'Toko Contoh', onPressed: () {}),
                ),
              ],
            ),
          ],
  );
  Widget attempts({
    bool pending = false,
    bool empty = false,
    bool error = false,
  }) => PaymentDetailPageTable<int>(
    title: _t(context, 'Attempts', 'Percobaan'),
    pending: pending,
    errorText: error
        ? _t(context, 'Attempts didn’t load', 'Percobaan gagal dimuat')
        : null,
    onRetry: () {},
    columns: [
      PaymentDataColumn<int>(
        key: 'time',
        label: _t(context, 'Time', 'Waktu'),
        value: (r) => DateTime(2026, 10, 1, 10, r),
        cell: PaymentCellType.date,
      ),
      PaymentDataColumn<int>(
        key: 'method',
        label: _t(context, 'Method', 'Metode'),
        value: (r) => _t(context, 'BCA virtual account', 'Virtual account BCA'),
        pinned: true,
      ),
      PaymentDataColumn<int>(
        key: 'status',
        label: _t(context, 'Status', 'Status'),
        value: (r) => r == 3
            ? _t(context, 'Paid', 'Dibayar')
            : _t(context, 'Pending', 'Tertunda'),
        cell: PaymentCellType.status,
        statusMap: {
          _t(context, 'Paid', 'Dibayar'): StatusTone.success,
          _t(context, 'Pending', 'Tertunda'): StatusTone.warning,
        },
      ),
      PaymentDataColumn<int>(
        key: 'amount',
        label: _t(context, 'Amount', 'Jumlah'),
        value: (r) => const Money.idr(102500),
        cell: PaymentCellType.currency,
      ),
    ],
    rows: empty ? const [] : const [1, 2, 3],
    rowKey: (r) => '$r',
    rowActions: [
      PaymentRowAction<int>(
        id: 'view',
        label: _t(context, 'View attempt', 'Lihat percobaan'),
        onPressed: (_) {},
      ),
    ],
  );
  @override
  Widget build(BuildContext context) {
    final facts = [
      PaymentPropertyListItem(
        label: _t(context, 'Items', 'Barang'),
        valueText: _t(context, '2 items', '2 barang'),
      ),
      PaymentPropertyListItem(
        label: _t(context, 'Subtotal', 'Subtotal'),
        valueText: 'Rp100.000',
      ),
      PaymentPropertyListItem(
        label: _t(context, 'Fee', 'Biaya'),
        valueText: 'Rp2.500',
      ),
      PaymentPropertyListItem(
        label: _t(context, 'Total', 'Total'),
        valueText: 'Rp102.500',
        emphasis: true,
      ),
    ];
    final view = switch (widget.name) {
      'PaymentContextView' => PaymentContextView(
        title: _t(context, 'Order context', 'Konteks pesanan'),
        description: _t(
          context,
          'Toko Contoh · Order DEMO-42',
          'Toko Contoh · Pesanan DEMO-42',
        ),
        brand: const PaymentIcon(Icons.storefront_outlined),
        externalLink: PaymentLink(
          label: _t(context, 'Merchant help', 'Bantuan merchant'),
          external: true,
          onPressed: () {},
        ),
        // Close and cancel are quiet everywhere (#49-3).
        secondaryAction: button(
          _t(context, 'Close', 'Tutup'),
          variant: PaymentButtonVariant.quiet,
        ),
        primaryAction: button(
          _t(context, 'Continue to payment', 'Lanjut ke pembayaran'),
          variant: PaymentButtonVariant.primary,
        ),
        // The order ID is a reference row with a copy action, not a
        // separate button (D57).
        child: PaymentPropertyList(
          items: [
            PaymentPropertyListItem(
              label: _t(context, 'Order ID', 'ID pesanan'),
              valueText: 'DEMO-42',
              reference: true,
              trailing: PaymentCopyButton(
                value: 'DEMO-42',
                tooltip: _t(context, 'Copy order ID', 'Salin ID pesanan'),
                onCopy: (_) async => true,
              ),
            ),
            ...facts,
          ],
        ),
      ),
      // The header keeps navigation; the operation pins to the footer
      // (D59a, D62, Q3).
      'PaymentFullPageView' => PaymentFullPageView(
        title: _t(context, 'Transactions', 'Transaksi'),
        pageLink: PaymentLink(
          label: _t(context, 'Fees', 'Biaya'),
          onPressed: () =>
              _galleryFeedback(context, 'Fees opened', 'Biaya dibuka'),
        ),
        primaryAction: button(
          _t(context, 'Download statement', 'Unduh laporan'),
          variant: PaymentButtonVariant.primary,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: PaymentTheme.of(context).space(PaymentSpace.block),
          children: [
            PaymentTabs(
              tabs: [
                PaymentTab(label: _t(context, 'All', 'Semua')),
                PaymentTab(label: _t(context, 'In progress', 'Diproses')),
                PaymentTab(label: _t(context, 'Refunds', 'Refund')),
              ],
              selectedIndex: state,
              onSelected: (v) => setState(() => state = v),
            ),
            PaymentPropertyList(items: facts),
          ],
        ),
      ),
      'PaymentFocusView' => PaymentFocusView(
        title: _t(context, 'Report a problem', 'Laporkan masalah'),
        secondaryAction: button(
          _t(context, 'Cancel', 'Batal'),
          variant: PaymentButtonVariant.quiet,
        ),
        primaryAction: button(
          _t(context, 'Send', 'Kirim'),
          variant: PaymentButtonVariant.primary,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: PaymentTheme.of(context).space(PaymentSpace.block),
          children: [
            PaymentTextArea(
              label: _t(context, 'What went wrong?', 'Apa yang salah?'),
            ),
            PaymentButton(
              label: _t(
                context,
                'Open report a problem',
                'Buka laporkan masalah',
              ),
              variant: PaymentButtonVariant.secondary,
              onPressed: () => showPaymentFocusView<void>(
                context,
                builder: (_) => PaymentFocusView(
                  title: _t(context, 'Report a problem', 'Laporkan masalah'),
                  confirmClose: PaymentConfirmClose(
                    title: _t(context, 'Discard report?', 'Buang laporan?'),
                    message: _t(
                      context,
                      'Your changes will be lost.',
                      'Perubahan Anda akan hilang.',
                    ),
                    exitLabel: _t(context, 'Discard', 'Buang'),
                  ),
                  child: PaymentTextArea(
                    label: _t(context, 'What went wrong?', 'Apa yang salah?'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      'PaymentSettingsView' => PaymentSettingsView(
        title: _t(context, 'Payment settings', 'Pengaturan pembayaran'),
        statusMessage: _t(context, 'Saved', 'Tersimpan'),
        statusTone: StatusTone.success,
        onSave: () async {
          await Future<void>.delayed(const Duration(milliseconds: 600));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: PaymentTheme.of(context).space(PaymentSpace.block),
          children: [
            PaymentFormFieldGroup(
              legend: _t(context, 'Notifications', 'Notifikasi'),
              children: [
                PaymentSwitch(
                  label: _t(
                    context,
                    'Refund notifications',
                    'Notifikasi refund',
                  ),
                  value: refunds,
                  onChanged: (v) => setState(() => refunds = v),
                ),
                PaymentSwitch(
                  label: _t(context, 'Promotions', 'Promosi'),
                  value: promos,
                  onChanged: (v) => setState(() => promos = v),
                ),
              ],
            ),
            PaymentFormFieldGroup(
              legend: _t(context, 'Default method', 'Metode utama'),
              children: [
                for (final value in ['bank', 'wallet'])
                  PaymentRadio<String>(
                    value: value,
                    groupValue: method,
                    onChanged: (v) => setState(() => method = v),
                    label: value == 'bank'
                        ? _t(
                            context,
                            'BCA virtual account',
                            'Virtual account BCA',
                          )
                        : _t(context, 'Wallet', 'Dompet digital'),
                  ),
              ],
            ),
            PaymentFormFieldGroup(
              legend: _t(context, 'Language', 'Bahasa'),
              children: [
                PaymentSelect<String>(
                  label: _t(context, 'Statement language', 'Bahasa laporan'),
                  options: const [
                    PaymentSelectOption(value: 'en', label: 'English'),
                    PaymentSelectOption(value: 'id', label: 'Bahasa Indonesia'),
                  ],
                  value: language,
                  onChanged: (v) => setState(() => language = v),
                ),
              ],
            ),
          ],
        ),
      ),
      // Account linking (D61): both tiles, what the app can and can never
      // do, one legal sentence and a pinned Continue / quiet Cancel.
      'PaymentSignInView' => PaymentSignInView(
        requesterBrand: const PaymentIcon(Icons.school_outlined),
        brand: const PaymentIcon(Icons.account_balance_wallet_outlined),
        title: _t(
          context,
          'Sign in with Ruang Bayar',
          'Masuk dengan Ruang Bayar',
        ),
        description: _t(
          context,
          'To pay and see your payments in Toko Belajar.',
          'Untuk membayar dan melihat pembayaran Anda di Toko Belajar.',
        ),
        canDo: [
          _t(
            context,
            'See your name and account number',
            'Melihat nama dan nomor akun Anda',
          ),
          _t(
            context,
            'Request payments, always with your confirmation',
            'Meminta pembayaran, selalu dengan konfirmasi Anda',
          ),
        ],
        cannotDo: [
          _t(context, 'See your PIN or balance', 'Melihat PIN atau saldo Anda'),
        ],
        legalNotice: _t(
          context,
          'By continuing you agree to Ruang Bayar’s {0} and {1}.',
          'Dengan melanjutkan, Anda menyetujui {0} dan {1} Ruang Bayar.',
        ),
        legalLinks: [
          PaymentLink(
            label: _t(context, 'Terms', 'Ketentuan'),
            external: true,
            onPressed: () {},
          ),
          PaymentLink(
            label: _t(context, 'Privacy', 'Privasi'),
            external: true,
            onPressed: () {},
          ),
        ],
        primaryAction: button(
          _t(context, 'Continue', 'Lanjutkan'),
          variant: PaymentButtonVariant.primary,
        ),
        secondaryAction: button(
          _t(context, 'Cancel', 'Batal'),
          variant: PaymentButtonVariant.quiet,
        ),
        errorText: state == 1
            ? _t(
                context,
                'Sign-in was canceled. Try again.',
                'Masuk dibatalkan. Coba lagi.',
              )
            : null,
      ),
      'PaymentOnboardingView' => PaymentOnboardingView(
        title: _t(context, 'Verify your identity', 'Verifikasi identitas Anda'),
        tasks: [
          PaymentTaskListItem(
            title: _t(context, 'Identity', 'Identitas'),
            status: PaymentTaskStatus.complete,
          ),
          PaymentTaskListItem(
            title: _t(context, 'Documents', 'Dokumen'),
            status: PaymentTaskStatus.inProgress,
            subTasks: [
              const PaymentTaskListItem(
                title: 'KTP',
                status: PaymentTaskStatus.complete,
              ),
              PaymentTaskListItem(title: _t(context, 'Selfie', 'Swafoto')),
            ],
          ),
          PaymentTaskListItem(title: _t(context, 'Review', 'Tinjauan')),
        ],
        pending: state == 1,
        error: state == 2
            ? PaymentBanner(
                tone: StatusTone.warning,
                title: _t(
                  context,
                  'Documents need attention',
                  'Dokumen perlu diperiksa',
                ),
              )
            : null,
        completed: state == 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: PaymentTheme.of(context).space(PaymentSpace.block),
          children: [
            Text(
              _t(
                context,
                'Add your identity documents to get started.',
                'Tambahkan dokumen identitas untuk memulai.',
              ),
            ),
            button(
              _t(context, 'Continue', 'Lanjutkan'),
              variant: PaymentButtonVariant.primary,
            ),
          ],
        ),
      ),
      'PaymentDetailPage' => PaymentDetailPage(
        title: _t(
          context,
          '${PaymentLocalizations.of(context).moneyFormat.format(const Money.idr(102500))} to Toko Contoh',
          '${PaymentLocalizations.of(context).moneyFormat.format(const Money.idr(102500))} ke Toko Contoh',
        ),
        description: _t(
          context,
          'Paid with BCA virtual account · 1 Oct 2026',
          'Dibayar dengan virtual account BCA · 1 Okt 2026',
        ),
        breadcrumbs: [
          PaymentBreadcrumb(
            label: _t(context, 'Transactions', 'Transaksi'),
            onPressed: () {},
          ),
        ],
        // The priority action pins to the footer; the header keeps the
        // rarer actions, behind ⋮ on phones (D59a, D62).
        primaryAction: button(
          _t(context, 'View receipt', 'Lihat struk'),
          variant: PaymentButtonVariant.primary,
        ),
        secondaryAction: button(
          _t(context, 'Report a problem', 'Laporkan masalah'),
          variant: PaymentButtonVariant.quiet,
        ),
        actions: [
          button(_t(context, 'Download PDF', 'Unduh PDF')),
          button(
            _t(context, 'Request refund', 'Ajukan refund'),
            variant: PaymentButtonVariant.destructive,
          ),
        ],
        primary: [property(), attempts()],
        secondary: [
          PaymentDetailPagePropertyList(
            title: _t(context, 'Merchant', 'Merchant'),
            pending: false,
            items: [
              PaymentDetailProperty(
                label: _t(context, 'Name', 'Nama'),
                values: [const PaymentDetailValue('Toko Contoh')],
              ),
              PaymentDetailProperty(
                label: _t(context, 'Support', 'Bantuan'),
                values: [
                  PaymentDetailValue.link(
                    PaymentLink(
                      label: _t(context, 'Help centre', 'Pusat bantuan'),
                      external: true,
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      'PaymentOverviewPage' => PaymentFullPageView(
        title: _t(context, 'Spending', 'Pengeluaran'),
        child: PaymentOverviewPage(
          primary: [
            ChartModule(
              title: _t(context, 'This month', 'Bulan ini'),
              state: ChartState.ready,
              // The headline is the chart's own total, never "—" beside
              // data (#66).
              headline: const Money.idr(2010000),
              headlineCaption: _t(context, '1–29 Oct', '1–29 Okt'),
              chart: SizedBox(
                height: 240,
                child: PaymentBarChart(
                  points: _chartFixture('typical', _t(context, 'Oct', 'Okt')),
                ),
              ),
            ),
            PaymentPageModule(
              title: _t(context, 'Recent transactions', 'Transaksi terbaru'),
              child: PaymentPropertyList(
                items: [
                  const PaymentPropertyListItem(
                    label: 'Toko Contoh',
                    valueText: 'Rp102.500',
                  ),
                  PaymentPropertyListItem(
                    label: _t(context, 'Groceries', 'Belanja harian'),
                    valueText: 'Rp75.000',
                  ),
                  PaymentPropertyListItem(
                    label: _t(context, 'Coffee', 'Kopi'),
                    valueText: 'Rp25.000',
                  ),
                ],
              ),
            ),
          ],
          secondary: [
            PaymentPageModule(
              title: _t(context, 'Balance', 'Saldo'),
              child: PaymentPropertyList(
                items: [
                  PaymentPropertyListItem(
                    label: _t(context, 'Available', 'Tersedia'),
                    valueText: 'Rp500.000',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      'PaymentDetailPagePropertyList' => Column(
        children: [
          property(),
          property(horizontal: true),
          property(pending: true),
          property(empty: true),
          property(error: true),
        ],
      ),
      'PaymentDetailPageTable' => Column(
        children: [
          attempts(),
          attempts(pending: true),
          attempts(empty: true),
          attempts(error: true),
        ],
      ),
      _ => const SizedBox.shrink(),
    };
    return _Entry(
      name: '${widget.name} · variants',
      states:
          widget.name == 'PaymentSignInView' ||
              widget.name == 'PaymentOnboardingView'
          ? Wrap(
              children: [
                for (
                  var i = 0;
                  i < (widget.name == 'PaymentSignInView' ? 2 : 4);
                  i++
                )
                  TextButton(
                    onPressed: () => setState(() => state = i),
                    child: Text(
                      [
                        'Ready',
                        _t(context, 'Pending', 'Tertunda'),
                        'Error',
                        'Complete',
                      ][i],
                    ),
                  ),
              ],
            )
          : null,
      child:
          widget.name == 'PaymentDetailPagePropertyList' ||
              widget.name == 'PaymentDetailPageTable'
          ? view
          : SizedBox(
              height:
                  widget.name.startsWith('PaymentDetailPage') ||
                      widget.name == 'PaymentOverviewPage'
                  ? 640
                  : 560,
              child: view,
            ),
    );
  }
}
