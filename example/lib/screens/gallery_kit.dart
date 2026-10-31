part of 'gallery_screen.dart';

// Gallery entries for the interaction, navigation, sheet, media, promotion
// and payment-extra components. Every control here does something real in
// the demo: actions open dialogs, sheets and snack bars; the video plays a
// bundled clip; promotion and history state is held by the demo as a host
// would hold it.

void _hostSays(BuildContext context, String en, String id) =>
    showPaymentToast(context, message: _t(context, en, id));

// ── Interaction ─────────────────────────────────────────────────────────────

class _ActionsDemo extends StatelessWidget {
  const _ActionsDemo();

  Future<void> _signOut(BuildContext context) async {
    final ok = await showPaymentConfirmDialog(
      context,
      title: _t(
        context,
        'Sign out of all devices?',
        'Keluar dari semua perangkat?',
      ),
      message: _t(
        context,
        'You will need to sign in again on every device. Payments already sent are not affected.',
        'Anda perlu masuk lagi di setiap perangkat. Pembayaran yang sudah dikirim tidak terpengaruh.',
      ),
      confirmLabel: _t(context, 'Sign out', 'Keluar'),
      destructive: true,
    );
    if (!context.mounted) return;
    showPaymentToast(
      context,
      tone: ok ? StatusTone.success : StatusTone.neutral,
      message: ok
          ? _t(context, 'Signed out (simulated)', 'Berhasil keluar (simulasi)')
          : _t(context, 'Nothing changed', 'Tidak ada perubahan'),
    );
  }

  @override
  Widget build(BuildContext context) {
    String t(String en, String id) => _t(context, en, id);
    return _Entry(
      name: 'ActionTile · ActionMenu · showPaymentConfirmDialog',
      child: PaymentSection(
        title: t('Account', 'Akun'),
        trailing: ActionMenu(
          entries: [
            ActionMenuEntry(
              label: t('Copy account ID', 'Salin ID akun'),
              icon: Icons.copy_rounded,
              onSelected: () => _hostSays(context, 'Copied', 'Disalin'),
            ),
            ActionMenuEntry(
              label: t('Export history', 'Ekspor riwayat'),
              icon: Icons.download_outlined,
              onSelected: null,
            ),
            ActionMenuEntry(
              label: t('Sign out everywhere', 'Keluar dari semua perangkat'),
              icon: Icons.logout,
              destructive: true,
              onSelected: () => _signOut(context),
            ),
          ],
        ),
        child: ActionTileGroup(
          children: [
            ActionTile(
              icon: Icons.receipt_long_outlined,
              title: t('Transaction history', 'Riwayat transaksi'),
              subtitle: t('Last 90 days', '90 hari terakhir'),
              onTap: () => _hostSays(
                context,
                'Host opens history',
                'Host membuka riwayat',
              ),
            ),
            ActionTile(
              icon: Icons.pin_outlined,
              title: t('Change PIN', 'Ubah PIN'),
              disabledReason: t(
                'Managed by your bank app',
                'Dikelola di aplikasi bank Anda',
              ),
            ),
            ActionTile(
              icon: Icons.logout,
              title: t(
                'Sign out of all devices',
                'Keluar dari semua perangkat',
              ),
              destructive: true,
              onTap: () => _signOut(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpandableDemo extends StatefulWidget {
  const _ExpandableDemo();
  @override
  State<_ExpandableDemo> createState() => _ExpandableDemoState();
}

class _ExpandableDemoState extends State<_ExpandableDemo> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    String t(String en, String id) => _t(context, en, id);
    return _Entry(
      name: 'ExpandableSection',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExpandableSection(
            leading: Icons.help_outline,
            title: t(
              'How long does a transfer take?',
              'Berapa lama transfer diproses?',
            ),
            child: Text(
              t(
                'Most bank transfers are confirmed within minutes. Some banks take until the next business day; the status updates when your bank reports it.',
                'Sebagian besar transfer terkonfirmasi dalam hitungan menit. Beberapa bank butuh sampai hari kerja berikutnya; status diperbarui saat bank melapor.',
              ),
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              t('Controlled: open from outside', 'Terkontrol: buka dari luar'),
            ),
            value: _open,
            onChanged: (v) => setState(() => _open = v),
          ),
          ExpandableSection(
            leading: Icons.shield_outlined,
            title: t('Buyer protection', 'Perlindungan pembeli'),
            subtitle: t('Provided by the merchant', 'Disediakan merchant'),
            expanded: _open,
            onExpandedChanged: (v) => setState(() => _open = v),
            child: Text(
              t(
                'Refunds are requested from the merchant and appear as a separate refund on the original payment.',
                'Refund diajukan ke merchant dan tampil sebagai refund terpisah pada pembayaran asal.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _LoadState { loading, ready, empty, error }

class _StatesDemo extends StatefulWidget {
  const _StatesDemo();
  @override
  State<_StatesDemo> createState() => _StatesDemoState();
}

class _StatesDemoState extends State<_StatesDemo> {
  _LoadState _state = _LoadState.loading;

  Future<void> _retry() async {
    setState(() => _state = _LoadState.loading);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (mounted) setState(() => _state = _LoadState.ready);
  }

  @override
  Widget build(BuildContext context) {
    String t(String en, String id) => _t(context, en, id);
    return _Entry(
      name: 'LoadingSkeleton · StateMessage',
      states: _StatePicker(
        values: _LoadState.values,
        selected: _state,
        onSelected: (v) => setState(() => _state = v),
        label: (v) => v.name,
      ),
      child: PaymentSection(
        title: t('Saved billers', 'Tagihan tersimpan'),
        child: switch (_state) {
          _LoadState.loading => const LoadingSkeleton(),
          _LoadState.empty => StateMessage(
            icon: Icons.bookmark_border,
            title: t('No saved billers', 'Belum ada tagihan tersimpan'),
            message: t(
              'Save a biller after paying to find it here.',
              'Simpan tagihan setelah membayar agar muncul di sini.',
            ),
          ),
          _LoadState.error => StateMessage(
            icon: Icons.cloud_off_outlined,
            tone: StatusTone.danger,
            title: t('Couldn’t load billers', 'Tagihan gagal dimuat'),
            message: t('Check your connection.', 'Periksa koneksi Anda.'),
            actionLabel: t('Try again', 'Coba lagi'),
            onAction: _retry,
          ),
          _LoadState.ready => ActionTileGroup(
            children: [
              ActionTile(
                icon: Icons.bolt_outlined,
                title: t(
                  'Electricity · 5123 •••• 8890',
                  'Listrik · 5123 •••• 8890',
                ),
                onTap: () => _hostSays(
                  context,
                  'Host opens biller',
                  'Host membuka tagihan',
                ),
              ),
              ActionTile(
                icon: Icons.water_drop_outlined,
                title: t('Water · PDAM Contoh', 'Air · PDAM Contoh'),
                onTap: () => _hostSays(
                  context,
                  'Host opens biller',
                  'Host membuka tagihan',
                ),
              ),
            ],
          ),
        },
      ),
    );
  }
}

// ── Navigation ──────────────────────────────────────────────────────────────

class _NavigationDemo extends StatefulWidget {
  const _NavigationDemo();
  @override
  State<_NavigationDemo> createState() => _NavigationDemoState();
}

class _NavigationDemoState extends State<_NavigationDemo> {
  String _selected = 'home';

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    String t(String en, String id) => _t(context, en, id);
    return _Entry(
      name: 'NavSidebar · AdaptiveNavShell',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PaymentBanner(
            tone: StatusTone.info,
            title: t(
              'This gallery runs inside AdaptiveNavShell',
              'Galeri ini memakai AdaptiveNavShell',
            ),
            message: t(
              'Narrower than 720 dp: the menu button opens a drawer (scrim, Back or Escape closes it and focus returns to the button). Wider: the same items sit in a permanent sidebar.',
              'Di bawah 720 dp: tombol menu membuka drawer (scrim, Back atau Escape menutupnya dan fokus kembali ke tombol). Lebih lebar: item yang sama tampil di sidebar tetap.',
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 340,
            decoration: BoxDecoration(
              border: Border.all(color: theme.outline),
              borderRadius: theme.borderRadius,
            ),
            clipBehavior: Clip.antiAlias,
            child: NavSidebar(
              selectedId: _selected,
              onSelected: (item) => setState(() => _selected = item.id),
              header: const MerchantHeader(name: 'Ruang Bayar', verified: true),
              sections: [
                PaymentNavSection(
                  items: [
                    PaymentNavItem(
                      id: 'home',
                      label: t('Home', 'Beranda'),
                      icon: Icons.home_outlined,
                      selectedIcon: Icons.home,
                    ),
                    PaymentNavItem(
                      id: 'pay',
                      label: t('Pay bills', 'Bayar tagihan'),
                      icon: Icons.receipt_outlined,
                    ),
                    PaymentNavItem(
                      id: 'history',
                      label: t('History', 'Riwayat'),
                      icon: Icons.history,
                      badge: '2',
                    ),
                  ],
                ),
                PaymentNavSection(
                  title: t('Account', 'Akun'),
                  items: [
                    PaymentNavItem(
                      id: 'kyc',
                      label: t('Verification', 'Verifikasi'),
                      icon: Icons.badge_outlined,
                    ),
                    PaymentNavItem(
                      id: 'limits',
                      label: t('Limits', 'Limit'),
                      icon: Icons.speed,
                      enabled: false,
                      disabledReason: t('Verify first', 'Verifikasi dulu'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sheets ──────────────────────────────────────────────────────────────────

class _SheetsDemo extends StatelessWidget {
  const _SheetsDemo();

  Future<void> _filters(BuildContext context) async {
    String t(String en, String id) => _t(context, en, id);
    final picked = await showPaymentSheet<String>(
      context: context,
      builder: (context) {
        var range = '30';
        return StatefulBuilder(
          builder: (context, setSheet) => PaymentSheet(
            header: PaymentSheetHeader(
              title: t('Filter history', 'Filter riwayat'),
              onClose: () => Navigator.pop(context),
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    for (final d in const ['7', '30', '90'])
                      ChoiceChip(
                        label: Text(t('$d days', '$d hari')),
                        selected: range == d,
                        onSelected: (_) => setSheet(() => range = d),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    labelText: t('Merchant name', 'Nama merchant'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            footer: PaymentButton(
              label: t('Show results', 'Tampilkan hasil'),
              onPressed: () => Navigator.pop(context, range),
            ),
          ),
        );
      },
    );
    if (picked != null && context.mounted) {
      _hostSays(context, 'Filter: $picked days', 'Filter: $picked hari');
    }
  }

  Future<void> _pendingOptions(BuildContext context) async {
    String t(String en, String id) => _t(context, en, id);
    Future<void> confirmCancel(BuildContext sheet) async {
      final ok = await showPaymentConfirmDialog(
        sheet,
        title: t('Request cancellation?', 'Minta pembatalan?'),
        message: t(
          'The merchant decides. Until they confirm, the payment stays pending and may still complete.',
          'Merchant yang memutuskan. Sampai dikonfirmasi, pembayaran tetap menunggu dan masih bisa selesai.',
        ),
        confirmLabel: t('Send request', 'Kirim permintaan'),
        cancelLabel: t('Keep payment', 'Tetap bayar'),
        destructive: true,
      );
      if (ok && sheet.mounted) {
        Navigator.pop(sheet);
        if (context.mounted) {
          _hostSays(
            context,
            'Request sent. Status: pending until the merchant confirms.',
            'Permintaan terkirim. Status: menunggu konfirmasi merchant.',
          );
        }
      }
    }

    await showPaymentSheet<void>(
      context: context,
      builder: (sheet) => PaymentSheet(
        header: PaymentSheetHeader(
          title: t('Pending payment', 'Pembayaran menunggu'),
          subtitle: 'att-7Q2-0091',
          onClose: () => Navigator.pop(sheet),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const InfoRow(label: 'Total', value: AmountText(Money.idr(104000))),
            const SizedBox(height: 8),
            PaymentBanner(
              tone: StatusTone.info,
              title: t(
                'Closing this panel does not cancel the payment',
                'Menutup panel ini tidak membatalkan pembayaran',
              ),
            ),
          ],
        ),
        footer: PaymentButton(
          label: t('Request cancellation', 'Minta pembatalan'),
          variant: PaymentButtonVariant.secondary,
          // Not async on purpose: PaymentButton shows a spinner while a
          // returned Future runs, and asking a question is not host work.
          onPressed: () => unawaited(confirmCancel(sheet)),
        ),
      ),
    );
  }

  Future<void> _details(BuildContext context) {
    String t(String en, String id) => _t(context, en, id);
    return showPaymentSideSheet<void>(
      context: context,
      builder: (panel) => PaymentSheet(
        header: PaymentSheetHeader(
          title: t('Order details', 'Detail pesanan'),
          onClose: () => Navigator.pop(panel),
        ),
        body: Column(
          children: [
            const MerchantHeader(
              name: 'Ruang Bayar Akademi',
              orderReference: 'RB-2026-1030-118',
              verified: true,
            ),
            const SizedBox(height: 16),
            const InfoRow(
              label: 'Paket Belajar',
              value: AmountText(Money.idr(100000)),
            ),
            InfoRow(
              label: t('Service fee', 'Biaya layanan'),
              value: const AmountText(Money.idr(2500)),
            ),
            const Divider(),
            const InfoRow(
              label: 'Total',
              emphasis: true,
              value: AmountText(
                Money.idr(102500),
                variant: AmountTextVariant.display,
              ),
            ),
          ],
        ),
        footer: PaymentButton(
          label: t('Close', 'Tutup'),
          variant: PaymentButtonVariant.secondary,
          onPressed: () => Navigator.pop(panel),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String t(String en, String id) => _t(context, en, id);
    return _Entry(
      name: 'PaymentSheet · showPaymentSheet · showPaymentSideSheet',
      child: ActionTileGroup(
        children: [
          ActionTile(
            icon: Icons.filter_list,
            title: t('Bottom sheet with form', 'Bottom sheet dengan form'),
            subtitle: t(
              'Keyboard pushes the footer up',
              'Keyboard mendorong footer ke atas',
            ),
            onTap: () => _filters(context),
          ),
          ActionTile(
            icon: Icons.pending_outlined,
            title: t(
              'Close vs. cancel payment',
              'Tutup vs. batalkan pembayaran',
            ),
            subtitle: t(
              'Destructive action behind confirmation',
              'Aksi destruktif dengan konfirmasi',
            ),
            onTap: () => _pendingOptions(context),
          ),
          ActionTile(
            icon: Icons.vertical_split_outlined,
            title: t('Side panel', 'Panel samping'),
            subtitle: t(
              'Slides from the end edge; Escape closes',
              'Muncul dari sisi kanan; Escape menutup',
            ),
            onTap: () => _details(context),
          ),
        ],
      ),
    );
  }
}

// ── Video ───────────────────────────────────────────────────────────────────

class _VideoDemo extends StatefulWidget {
  const _VideoDemo();
  @override
  State<_VideoDemo> createState() => _VideoDemoState();
}

class _VideoDemoState extends State<_VideoDemo> {
  late final _playable = VideoPlayerAdapter.asset(
    'assets/video/ruang_bayar_demo.mp4',
  );
  late final _broken = VideoPlayerAdapter.asset('assets/video/missing.mp4');
  String _video = 'bundled';
  final _loading = _StalledVideo();

  @override
  void dispose() {
    _playable.dispose();
    _broken.dispose();
    _loading.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String t(String en, String id) => _t(context, en, id);
    return _Entry(
      name: 'PaymentVideoPlayer + video_player adapter',
      states: _StatePicker(
        values: const ['bundled', 'missing', 'loading'],
        selected: _video,
        onSelected: (v) => setState(() => _video = v),
        label: (v) => switch (v) {
          'missing' => t('Missing file', 'File hilang'),
          'loading' => t('Loading', 'Memuat'),
          _ => t('Bundled clip', 'Klip bawaan'),
        },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PaymentVideoPlayer(
            key: ValueKey(_video),
            controller: switch (_video) {
              'missing' => _broken,
              'loading' => _loading,
              _ => _playable,
            },
            title: t(
              'How to pay with a virtual account (demo clip)',
              'Cara bayar virtual account (klip demo)',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t(
              'Real playback of an 8 s synthetic clip bundled with the example. No autoplay; it pauses when you switch tabs, leave the app or scroll it away with the section.',
              'Pemutaran nyata klip sintetis 8 detik yang dibundel. Tidak autoplay; berhenti saat pindah tab, keluar aplikasi, atau pindah bagian.',
            ),
            textScaler: devScaler(context),
            style: devMono(PaymentTheme.of(context).textSecondary),
          ),
        ],
      ),
    );
  }
}

// ── Promotions ──────────────────────────────────────────────────────────────

class _PromoDemo extends StatefulWidget {
  const _PromoDemo();
  @override
  State<_PromoDemo> createState() => _PromoDemoState();
}

class _PromoDemoState extends State<_PromoDemo> {
  PromoSlotState _slot = PromoSlotState.ready;
  bool _bannerDismissed = false;

  @override
  Widget build(BuildContext context) {
    String t(String en, String id) => _t(context, en, id);
    final sponsored = PromoContent(
      id: 'promo-1',
      kind: PromoKind.sponsored,
      advertiser: 'Bank Contoh',
      title: t('Cashback 10% on bill payments', 'Cashback 10% bayar tagihan'),
      message: t(
        'Pay electricity or water bills with Bank Contoh VA.',
        'Bayar listrik atau air dengan VA Bank Contoh.',
      ),
      terms: t(
        'Until 31 Dec 2026 · max Rp20,000',
        'Sampai 31 Des 2026 · maks Rp20.000',
      ),
      ctaLabel: t('See offer', 'Lihat penawaran'),
      icon: Icons.savings_outlined,
    );
    final own = PromoContent(
      id: 'promo-2',
      kind: PromoKind.promotion,
      title: t(
        'Invite a friend, both get Rp10,000',
        'Ajak teman, sama-sama dapat Rp10.000',
      ),
      ctaLabel: t('Invite', 'Ajak'),
      icon: Icons.card_giftcard,
    );
    void cta(PromoContent c) => _hostSays(
      context,
      'Host opens "${c.title}"',
      'Host membuka "${c.title}"',
    );
    return _Entry(
      name: 'PromoCard · PromoSlot',
      states: _StatePicker(
        values: PromoSlotState.values,
        selected: _slot,
        onSelected: (v) => setState(() => _slot = v),
        label: (v) => v.name,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PromoSlot(
            state: _slot,
            content: sponsored,
            collapseWhenEmpty: false,
            onAction: cta,
            onRetry: () => setState(() => _slot = PromoSlotState.ready),
            onAbout: (c) => showPaymentConfirmDialog(
              context,
              title: t('Why you see this', 'Kenapa Anda melihat ini'),
              message: t(
                'Bank Contoh paid for this placement. It is shown to everyone in the bill payment section and does not use your transaction data.',
                'Bank Contoh membayar penempatan ini. Ditampilkan ke semua orang di bagian tagihan dan tidak memakai data transaksi Anda.',
              ),
              confirmLabel: t('OK', 'Oke'),
            ),
          ),
          const SizedBox(height: 16),
          if (_bannerDismissed)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () => setState(() => _bannerDismissed = false),
                icon: const Icon(Icons.undo),
                label: Text(
                  t('Banner dismissed. Restore', 'Banner ditutup. Pulihkan'),
                ),
              ),
            )
          else
            PromoCard(
              content: own,
              layout: PromoLayout.banner,
              onAction: () => cta(own),
              onDismiss: () {
                setState(() => _bannerDismissed = true);
                showPaymentToast(
                  context,
                  message: t('Promo hidden', 'Promo disembunyikan'),
                  actionLabel: t('Undo', 'Urungkan'),
                  onAction: () => setState(() => _bannerDismissed = false),
                );
              },
            ),
        ],
      ),
    );
  }
}

// ── Payment extras ──────────────────────────────────────────────────────────

class _MerchantStepsDemo extends StatefulWidget {
  const _MerchantStepsDemo();
  @override
  State<_MerchantStepsDemo> createState() => _MerchantStepsDemoState();
}

class _MerchantStepsDemoState extends State<_MerchantStepsDemo> {
  int _step = 1;

  @override
  Widget build(BuildContext context) {
    String t(String en, String id) => _t(context, en, id);
    final steps = [
      t('Verify', 'Verifikasi'),
      'Checkout',
      t('Authorize', 'Otorisasi'),
      t('Done', 'Selesai'),
    ];
    return _Entry(
      name: 'MerchantHeader · PaymentStepIndicator',
      states: _StatePicker(
        values: const [0, 1, 2, 3],
        selected: _step,
        onSelected: (v) => setState(() => _step = v),
        label: (v) => steps[v],
      ),
      child: PaymentSection(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MerchantHeader(
              name: 'Ruang Bayar Akademi',
              category: t('Education', 'Pendidikan'),
              orderReference: 'RB-2026-1030-118',
              verified: true,
            ),
            const SizedBox(height: 16),
            PaymentStepIndicator(steps: steps, current: _step),
          ],
        ),
      ),
    );
  }
}

class _BalanceDemo extends StatefulWidget {
  const _BalanceDemo();
  @override
  State<_BalanceDemo> createState() => _BalanceDemoState();
}

class _BalanceDemoState extends State<_BalanceDemo> {
  BalanceState _state = BalanceState.insufficient;

  @override
  Widget build(BuildContext context) {
    String t(String en, String id) => _t(context, en, id);
    return _Entry(
      name: 'BalanceCard',
      states: _StatePicker(
        values: BalanceState.values,
        selected: _state,
        onSelected: (v) => setState(() => _state = v),
        label: (v) => v.name,
      ),
      child: BalanceCard(
        state: _state,
        balance: _state == BalanceState.insufficient
            ? const Money.idr(80000)
            : const Money.idr(350000),
        shortfall: const Money.idr(22500),
        limitUsed: const Money.idr(4600000),
        limitTotal: const Money.idr(5000000),
        action: TextButton(
          onPressed: () =>
              _hostSays(context, 'Host opens top up', 'Host membuka isi saldo'),
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          child: Text(t('Top up', 'Isi saldo')),
        ),
      ),
    );
  }
}

class _PromoCodeDemo extends StatefulWidget {
  const _PromoCodeDemo();
  @override
  State<_PromoCodeDemo> createState() => _PromoCodeDemoState();
}

class _PromoCodeDemoState extends State<_PromoCodeDemo> {
  PromoCodeStatus _status = PromoCodeStatus.idle;
  String? _code;
  String? _message;

  /// Simulated host check: only HEMAT10 is valid.
  Future<void> _apply(String code) async {
    setState(() => _status = PromoCodeStatus.checking);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      _code = code;
      if (code == 'HEMAT10') {
        _status = PromoCodeStatus.applied;
        _message = null;
      } else {
        _status = PromoCodeStatus.rejected;
        _message = _t(
          context,
          'This code isn’t valid. Try HEMAT10.',
          'Kode ini tidak berlaku. Coba HEMAT10.',
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final applied = _status == PromoCodeStatus.applied;
    const discount = Money.idr(-10000);
    final quote = PaymentQuote(
      id: 'Q-PROMO',
      revision: applied ? 2 : 1,
      lines: [
        const QuoteLine(label: 'Paket Belajar', amount: Money.idr(100000)),
        QuoteLine(
          label: _t(context, 'Service fee', 'Biaya layanan'),
          amount: const Money.idr(2500),
          kind: QuoteLineKind.fee,
        ),
        if (applied)
          const QuoteLine(
            label: 'HEMAT10',
            amount: discount,
            kind: QuoteLineKind.discount,
          ),
      ],
      total: Money.idr(applied ? 92500 : 102500),
      expiresAt: _now.add(const Duration(minutes: 10)),
    );
    return _Entry(
      name: 'PromoCodeInput → host re-quote → PaymentSummary',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PromoCodeInput(
            status: _status,
            appliedCode: _code,
            discount: discount,
            message: _message,
            onApply: _apply,
            onRemove: () => setState(() => _status = PromoCodeStatus.idle),
          ),
          const SizedBox(height: 12),
          PaymentSummary(quote: quote),
        ],
      ),
    );
  }
}

class _ActionBarDemo extends StatefulWidget {
  const _ActionBarDemo();
  @override
  State<_ActionBarDemo> createState() => _ActionBarDemoState();
}

class _ActionBarDemoState extends State<_ActionBarDemo> {
  bool _updating = false;

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    String t(String en, String id) => _t(context, en, id);
    return _Entry(
      name: 'PaymentActionBar',
      states: _StatePicker(
        values: const [false, true],
        selected: _updating,
        onSelected: (v) => setState(() => _updating = v),
        label: (v) => v ? t('Re-quoting', 'Memperbarui') : t('Ready', 'Siap'),
      ),
      child: ClipRRect(
        borderRadius: theme.borderRadius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: theme.outline),
            borderRadius: theme.borderRadius,
          ),
          child: PaymentActionBar(
            total: const Money.idr(102500),
            updating: _updating,
            action: PaymentButton(
              label: t('Review & pay', 'Tinjau & bayar'),
              onPressed: _updating
                  ? null
                  : () => _hostSays(
                      context,
                      'Host opens review',
                      'Host membuka tinjauan',
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Transaction history ─────────────────────────────────────────────────────

final _records = [
  TransactionRecord(
    id: 't1',
    title: 'Paket Belajar · 1 bulan',
    merchant: 'Ruang Bayar Akademi',
    amount: const Money.idr(102500),
    createdAt: _now.subtract(const Duration(minutes: 12)),
    status: null,
    methodLabel: 'Saldo Ruang Bayar',
    reference: 'att-mvux8evr-1',
  ),
  TransactionRecord(
    id: 't2',
    title: 'Token listrik 100.000',
    merchant: 'PLN Contoh',
    amount: const Money.idr(101500),
    createdAt: _now.subtract(const Duration(hours: 3)),
    status: PaymentStatus.pending,
    methodLabel: 'Virtual account Bank Contoh',
    reference: 'VA-88081234567890',
  ),
  TransactionRecord(
    id: 't3',
    title: 'Pulsa 50.000',
    merchant: 'Operator Contoh',
    amount: const Money.idr(51000),
    createdAt: _now.subtract(const Duration(days: 1)),
    status: PaymentStatus.succeeded,
    methodLabel: 'Saldo Ruang Bayar',
    reference: 'TRX-20261029-4410',
  ),
  TransactionRecord(
    id: 't4',
    title: 'Langganan kelas desain dengan nama paket yang sangat panjang',
    merchant: 'Ruang Bayar Akademi',
    amount: const Money.idr(250000),
    createdAt: _now.subtract(const Duration(days: 3)),
    status: PaymentStatus.succeeded,
    methodLabel: 'Saldo Ruang Bayar',
    reference: 'TRX-20261027-0042',
    refund: RefundInfo(
      status: RefundStatus.partial,
      amount: const Money.idr(100000),
      updatedAt: _now.subtract(const Duration(days: 1)),
    ),
  ),
  TransactionRecord(
    id: 't5',
    title: 'Air PDAM Oktober',
    merchant: 'PDAM Contoh',
    amount: const Money.idr(87300),
    createdAt: _now.subtract(const Duration(days: 6)),
    status: PaymentStatus.failed,
    methodLabel: 'Saldo Ruang Bayar',
    reference: 'TRX-20261024-7781',
  ),
  TransactionRecord(
    id: 't6',
    title: 'Paket data 10 GB',
    merchant: 'Operator Contoh',
    amount: const Money.idr(65000),
    createdAt: _now.subtract(const Duration(days: 9)),
    status: PaymentStatus.expired,
    methodLabel: 'Virtual account Bank Contoh',
  ),
];

enum _HistorySource { ready, loading, error, empty }

class _HistoryDemo extends StatefulWidget {
  const _HistoryDemo();
  @override
  State<_HistoryDemo> createState() => _HistoryDemoState();
}

class _HistoryDemoState extends State<_HistoryDemo> {
  _HistorySource _source = _HistorySource.ready;
  String _query = '';
  TransactionFilter _filter = TransactionFilter.all;

  Future<void> _open(TransactionRecord r) {
    String t(String en, String id) => _t(context, en, id);
    final wide = MediaQuery.sizeOf(context).width >= 720;
    final actions = <Widget>[
      if (r.status == null || !(r.status!.isTerminal))
        PaymentButton(
          label: t('Check status', 'Cek status'),
          onPressed: () => Future.delayed(const Duration(milliseconds: 600)),
        ),
      if (r.status == PaymentStatus.succeeded)
        PaymentButton(
          label: t('View receipt', 'Lihat struk'),
          variant: PaymentButtonVariant.secondary,
          onPressed: () =>
              _hostSays(context, 'Host opens receipt', 'Host membuka struk'),
        ),
    ];
    Widget sheet(BuildContext context) => PaymentSheet(
      header: PaymentSheetHeader(
        title: t('Transaction', 'Transaksi'),
        onClose: () => Navigator.pop(context),
      ),
      body: TransactionDetail(record: r, actions: actions),
    );
    return wide
        ? showPaymentSideSheet<void>(context: context, builder: sheet)
        : showPaymentSheet<void>(context: context, builder: sheet);
  }

  @override
  Widget build(BuildContext context) {
    final records = switch (_source) {
      _HistorySource.empty => const <TransactionRecord>[],
      _ => TransactionRecord.where(_records, query: _query, filter: _filter),
    };
    return _Entry(
      name: 'TransactionHistory · TransactionListItem · TransactionDetail',
      states: _StatePicker(
        values: _HistorySource.values,
        selected: _source,
        onSelected: (v) => setState(() => _source = v),
        label: (v) => v.name,
      ),
      child: TransactionHistory(
        records: records,
        query: _query,
        filter: _filter,
        loading: _source == _HistorySource.loading,
        error: _source == _HistorySource.error
            ? _t(
                context,
                'The server didn’t respond.',
                'Server tidak merespons.',
              )
            : null,
        onRetry: () => setState(() => _source = _HistorySource.ready),
        onQueryChanged: (q) => setState(() => _query = q),
        onFilterChanged: (f) => setState(() => _filter = f),
        onOpen: _open,
      ),
    );
  }
}

// ── Controls ────────────────────────────────────────────────────────────────

class _ButtonsDemo extends StatelessWidget {
  const _ButtonsDemo();
  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    Widget caption(String label) => Text(
      label,
      textScaler: devScaler(context),
      style: devMono(theme.textSecondary),
    );
    return _Entry(
      name: 'PaymentButton · variants',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          caption(
            _t(
              context,
              'Documentation specimen: the one-primary rule is waived here.',
              'Spesimen dokumentasi: aturan satu aksi utama dikecualikan di sini.',
            ),
          ),
          for (final variant in PaymentButtonVariant.values) ...[
            caption(variant.name),
            Wrap(
              spacing: theme.spacing,
              runSpacing: theme.spacing,
              children: [
                PaymentButton(
                  label: variant == PaymentButtonVariant.destructive
                      ? _t(context, 'Remove card', 'Hapus kartu')
                      : _t(context, 'Save changes', 'Simpan perubahan'),
                  variant: variant,
                  width: PaymentWidth.hug,
                  icon: variant == PaymentButtonVariant.destructive
                      ? Icons.delete_outline
                      : null,
                  onPressed: () => _hostSays(
                    context,
                    'Changes saved (simulated)',
                    'Perubahan disimpan (simulasi)',
                  ),
                ),
                PaymentButton(
                  label: _t(context, 'Unavailable', 'Tidak tersedia'),
                  variant: variant,
                  width: PaymentWidth.hug,
                  onPressed: null,
                ),
              ],
            ),
          ],
          caption(_t(context, 'Busy', 'Memproses')),
          Wrap(
            spacing: theme.spacing,
            runSpacing: theme.spacing,
            children: [
              for (final variant in [
                PaymentButtonVariant.primary,
                PaymentButtonVariant.destructive,
              ])
                PaymentButton(
                  label: _t(context, 'Saving changes', 'Menyimpan perubahan'),
                  variant: variant,
                  width: PaymentWidth.hug,
                  busy: true,
                  onPressed: () {},
                ),
            ],
          ),
          caption(_t(context, 'Sizes', 'Ukuran')),
          for (final size in PaymentSize.values)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: PaymentButton(
                key: size == PaymentSize.medium
                    ? const ValueKey('button-specimen-focus')
                    : null,
                label: _t(context, 'Edit', 'Ubah'),
                size: size,
                width: PaymentWidth.hug,
                variant: PaymentButtonVariant.secondary,
                onPressed: () => _hostSays(
                  context,
                  'Host opens editor',
                  'Host membuka editor',
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: Text(
                  _t(context, 'Saved cards', 'Kartu tersimpan'),
                  style: PaymentType.of(context).heading,
                ),
              ),
              PaymentButton(
                label: _t(context, 'Add card', 'Tambah kartu'),
                size: PaymentSize.small,
                width: PaymentWidth.hug,
                variant: PaymentButtonVariant.secondary,
                onPressed: () => _hostSays(
                  context,
                  'Host opens card form',
                  'Host membuka formulir kartu',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AmountTextVariantsDemo extends StatelessWidget {
  const _AmountTextVariantsDemo();
  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    return _Entry(
      name: 'AmountText · variants',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final variant in AmountTextVariant.values)
            Padding(
              padding: EdgeInsets.symmetric(vertical: theme.spacing),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      variant.name,
                      textScaler: devScaler(context),
                      style: devMono(theme.textSecondary),
                    ),
                  ),
                  Flexible(
                    child: AmountText(
                      const Money.idr(102500),
                      variant: variant,
                    ),
                  ),
                ],
              ),
            ),
          InfoRow(
            label: _t(context, 'Total', 'Total'),
            emphasis: true,
            value: const AmountText(
              Money.idr(102500),
              variant: AmountTextVariant.total,
            ),
          ),
          InfoRow(
            label: _t(context, 'Muted', 'Redup'),
            value: AmountText(
              const Money.idr(102500),
              style: TextStyle(color: theme.textSecondary),
            ),
          ),
          InfoRow(
            label: _t(context, 'Struck', 'Dicoret'),
            value: const AmountText(
              Money.idr(102500),
              style: TextStyle(decoration: TextDecoration.lineThrough),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoicesDemo extends StatefulWidget {
  const _ChoicesDemo();

  @override
  State<_ChoicesDemo> createState() => _ChoicesDemoState();
}

class _ChoicesDemoState extends State<_ChoicesDemo> {
  bool _save = true;
  String _receipt = 'email';
  bool _alerts = true;

  @override
  Widget build(BuildContext context) {
    String t(String en, String id) => _t(context, en, id);
    return _Entry(
      name: 'PaymentCheckbox · PaymentRadio · PaymentSwitch',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PaymentCheckbox(
            value: _save,
            onChanged: (v) => setState(() => _save = v),
            label: t('Save this card for next time', 'Simpan kartu ini'),
            description: t(
              'Stored by your payment provider',
              'Disimpan oleh penyedia pembayaran',
            ),
          ),
          PaymentCheckbox(
            value: false,
            onChanged: null,
            label: t('Use as default card', 'Jadikan kartu utama'),
            disabledReason: t(
              'Save the card first',
              'Simpan kartu terlebih dahulu',
            ),
          ),
          const PaymentDivider(height: 24),
          PaymentSection(
            title: t('Send receipt by', 'Kirim struk lewat'),
            child: Column(
              children: [
                for (final (value, en, id) in [
                  ('email', 'Email', 'Email'),
                  ('sms', 'SMS', 'SMS'),
                  ('none', "Don't send", 'Jangan kirim'),
                ])
                  PaymentRadio<String>(
                    value: value,
                    groupValue: _receipt,
                    onChanged: (v) => setState(() => _receipt = v),
                    label: t(en, id),
                  ),
              ],
            ),
          ),
          const PaymentDivider(height: 24),
          PaymentSwitch(
            value: _alerts,
            onChanged: (v) => setState(() => _alerts = v),
            label: t('Refund alerts', 'Notifikasi refund'),
            description: t(
              'A notification when a refund settles',
              'Notifikasi saat refund selesai',
            ),
          ),
          PaymentSwitch(
            value: false,
            onChanged: null,
            label: t('Weekly summary', 'Ringkasan mingguan'),
            disabledReason: t(
              'Turn on notifications in Settings',
              'Aktifkan notifikasi di Pengaturan',
            ),
          ),
        ],
      ),
    );
  }
}

class _TabsDemo extends StatefulWidget {
  const _TabsDemo();

  @override
  State<_TabsDemo> createState() => _TabsDemoState();
}

class _TabsDemoState extends State<_TabsDemo> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    String t(String en, String id) => _t(context, en, id);
    final theme = PaymentTheme.of(context);
    final text = Theme.of(context).textTheme.bodyLarge;
    final bodies = [
      t(
        'Pay from your card. The total is charged once you confirm.',
        'Bayar dengan kartu. Total ditagih setelah Anda konfirmasi.',
      ),
      t(
        'Transfer to a virtual account number. It expires in 24 hours.',
        'Transfer ke nomor virtual account. Berlaku 24 jam.',
      ),
    ];
    return _Entry(
      name: 'PaymentTabs · PaymentTooltip · PaymentSpinner · PaymentDivider',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PaymentTabs(
            labels: [t('Card', 'Kartu'), t('Bank transfer', 'Transfer bank')],
            selectedIndex: _tab,
            onSelected: (i) => setState(() => _tab = i),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: theme.spacing * 1.5),
            child: Text(bodies[_tab], style: text),
          ),
          const PaymentDivider(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  t('Paid 2 days ago', 'Dibayar 2 hari lalu'),
                  style: text,
                ),
              ),
              PaymentTooltip(
                message: t(
                  'Paid on 29 Oct 2026, 14:05',
                  'Dibayar 29 Okt 2026, 14.05',
                ),
                child: IconButton(
                  icon: const Icon(Icons.info_outline),
                  color: theme.textSecondary,
                  onPressed: () {},
                ),
              ),
            ],
          ),
          const PaymentDivider(height: 24),
          Row(
            children: [
              const PaymentSpinner(),
              SizedBox(width: theme.spacing * 1.5),
              Expanded(
                child: Text(
                  t('Checking payment status', 'Memeriksa status pembayaran'),
                  style: text?.copyWith(color: theme.textSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StalledVideo extends PaymentVideoController {
  @override
  Future<void> initialize() async {
    value = const VideoPlaybackValue(phase: VideoPhase.loading);
  }

  @override
  Future<void> play() async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> seekTo(Duration position) async {}
  @override
  Future<void> setMuted(bool muted) async {}
  @override
  Future<void> retry() async {}
  @override
  Widget buildSurface(BuildContext context) => const SizedBox.shrink();
}
