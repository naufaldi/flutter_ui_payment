part of 'gallery_screen.dart';

class _BadgeSpecimen extends StatelessWidget {
  const _BadgeSpecimen();
  @override
  Widget build(BuildContext context) => _Entry(
    name: 'PaymentBadge · variants',
    child: Wrap(
      spacing: PaymentTheme.of(context).spacing,
      runSpacing: PaymentTheme.of(context).spacing,
      children: [
        PaymentBadge(
          tone: StatusTone.neutral,
          label: _t(context, 'Canceled', 'Dibatalkan'),
        ),
        PaymentBadge(
          tone: StatusTone.info,
          label: _t(context, 'In review', 'Ditinjau'),
        ),
        PaymentBadge(
          tone: StatusTone.success,
          label: _t(context, 'Paid', 'Dibayar'),
        ),
        PaymentBadge(
          tone: StatusTone.warning,
          label: _t(context, 'Pending', 'Tertunda'),
          icon: Icons.schedule,
        ),
        PaymentBadge(
          tone: StatusTone.danger,
          label: _t(context, 'Failed', 'Gagal'),
        ),
        PaymentBadge(
          tone: StatusTone.warning,
          label: _t(context, 'Not confirmed', 'Belum dikonfirmasi'),
          icon: Icons.help_outline,
        ),
        PaymentBadge.urgent(
          label: _t(context, 'Action required', 'Perlu tindakan'),
        ),
      ],
    ),
  );
}

class _BannerSpecimen extends StatelessWidget {
  const _BannerSpecimen();
  @override
  Widget build(BuildContext context) {
    final s = PaymentTheme.of(context).spacing;
    return _Entry(
      name: 'PaymentBanner · variants',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PaymentBanner(
            tone: StatusTone.info,
            title: _t(context, 'Review in progress', 'Sedang ditinjau'),
            message: _t(
              context,
              'We will show the outcome here.',
              'Hasilnya akan kami tampilkan di sini.',
            ),
          ),
          SizedBox(height: s),
          PaymentBanner(
            tone: StatusTone.success,
            title: _t(context, 'Payment received', 'Pembayaran diterima'),
          ),
          SizedBox(height: s),
          PaymentBanner(
            tone: StatusTone.warning,
            title: _t(context, 'Total changed', 'Total berubah'),
            message: _t(
              context,
              'Review the updated total before paying.',
              'Periksa total terbaru sebelum membayar.',
            ),
            actions: [
              PaymentButton(
                label: _t(context, 'Review total', 'Periksa total'),
                size: PaymentSize.small,
                width: PaymentWidth.hug,
                variant: PaymentButtonVariant.secondary,
                onPressed: () {},
              ),
            ],
          ),
          SizedBox(height: s),
          PaymentBanner(
            tone: StatusTone.danger,
            title: _t(context, 'Payment failed', 'Pembayaran gagal'),
            message: _t(
              context,
              'Your balance has not changed.',
              'Saldo Anda tidak berubah.',
            ),
            actions: [
              for (final (label, variant) in [
                (
                  _t(context, 'Try again', 'Coba lagi'),
                  PaymentButtonVariant.secondary,
                ),
                (
                  _t(context, 'Contact support', 'Hubungi bantuan'),
                  PaymentButtonVariant.quiet,
                ),
              ])
                PaymentButton(
                  label: label,
                  size: PaymentSize.small,
                  width: PaymentWidth.hug,
                  variant: variant,
                  onPressed: () {},
                ),
            ],
          ),
          SizedBox(height: s),
          PaymentBanner(
            tone: StatusTone.neutral,
            title: _t(context, 'Request canceled', 'Permintaan dibatalkan'),
          ),
        ],
      ),
    );
  }
}

class _ToastSpecimen extends StatefulWidget {
  const _ToastSpecimen();
  @override
  State<_ToastSpecimen> createState() => _ToastSpecimenState();
}

class _ToastSpecimenState extends State<_ToastSpecimen> {
  PaymentToastController? _toast;
  Timer? _work;
  @override
  void dispose() {
    _work?.cancel();
    _toast?.dismiss();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _Entry(
    name: 'showPaymentToast · variants',
    child: Wrap(
      spacing: PaymentTheme.of(context).spacing,
      runSpacing: PaymentTheme.of(context).spacing,
      children: [
        for (final (label, message, tone) in [
          (
            _t(context, 'Neutral', 'Netral'),
            _t(context, 'Promo hidden', 'Promo disembunyikan'),
            StatusTone.neutral,
          ),
          (
            _t(context, 'Success', 'Berhasil'),
            _t(context, 'Reference copied', 'Referensi disalin'),
            StatusTone.success,
          ),
          (
            _t(context, 'Warning', 'Peringatan'),
            _t(
              context,
              'Share canceled. Your receipt is still here.',
              'Berbagi dibatalkan. Struk Anda masih di sini.',
            ),
            StatusTone.warning,
          ),
        ])
          PaymentButton(
            label: label,
            size: PaymentSize.small,
            width: PaymentWidth.hug,
            variant: PaymentButtonVariant.secondary,
            onPressed: () => _toast = showPaymentToast(
              context,
              message: message,
              tone: tone,
            ),
          ),
        PaymentButton(
          label: _t(context, 'With undo', 'Dengan urungkan'),
          size: PaymentSize.small,
          width: PaymentWidth.hug,
          variant: PaymentButtonVariant.secondary,
          onPressed: () => _toast = showPaymentToast(
            context,
            message: _t(context, 'Promo hidden', 'Promo disembunyikan'),
            actionLabel: _t(context, 'Undo', 'Urungkan'),
            onAction: () {},
          ),
        ),
        PaymentButton(
          key: const Key('toast-pending'),
          label: _t(context, 'Pending', 'Tertunda'),
          size: PaymentSize.small,
          width: PaymentWidth.hug,
          variant: PaymentButtonVariant.secondary,
          onPressed: () {
            _work?.cancel();
            _toast = showPaymentToast(
              context,
              message: _t(context, 'Refreshing balance…', 'Memperbarui saldo…'),
              pending: true,
            );
            final toast = _toast!;
            final updated = _t(context, 'Balance updated', 'Saldo diperbarui');
            _work = Timer(
              const Duration(milliseconds: 1200),
              () => toast.update(updated, tone: StatusTone.success),
            );
          },
        ),
      ],
    ),
  );
}

class _SpinnerSpecimen extends StatefulWidget {
  const _SpinnerSpecimen();
  @override
  State<_SpinnerSpecimen> createState() => _SpinnerSpecimenState();
}

class _SpinnerSpecimenState extends State<_SpinnerSpecimen> {
  bool _waiting = false;
  int _generation = 0;
  Timer? _timer;
  void _wait(int ms) {
    _timer?.cancel();
    setState(() {
      _waiting = true;
      _generation++;
    });
    _timer = Timer(Duration(milliseconds: ms), () {
      if (mounted) setState(() => _waiting = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _Entry(
    name: 'PaymentSpinner · variants',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final size in PaymentSize.values)
          Padding(
            padding: EdgeInsets.only(bottom: PaymentTheme.of(context).spacing),
            child: Row(
              children: [
                PaymentSpinner(size: size),
                SizedBox(width: PaymentTheme.of(context).spacing),
                Text(_sizeLabel(context, size)),
              ],
            ),
          ),
        Wrap(
          spacing: PaymentTheme.of(context).spacing,
          runSpacing: PaymentTheme.of(context).spacing,
          children: [
            for (final (label, ms) in [
              (
                _t(
                  context,
                  'Start a fast wait (100 ms)',
                  'Mulai tunggu singkat (100 md)',
                ),
                100,
              ),
              (
                _t(
                  context,
                  'Start a slow wait (2 s)',
                  'Mulai tunggu lama (2 dtk)',
                ),
                2000,
              ),
            ])
              PaymentButton(
                label: label,
                variant: PaymentButtonVariant.secondary,
                size: PaymentSize.small,
                width: PaymentWidth.hug,
                onPressed: () => _wait(ms),
              ),
          ],
        ),
        if (_waiting)
          PaymentSpinner(
            key: ValueKey(_generation),
            delay: const Duration(milliseconds: 300),
          ),
      ],
    ),
  );
}

class _TooltipSpecimen extends StatelessWidget {
  const _TooltipSpecimen();
  @override
  Widget build(BuildContext context) => _Entry(
    name: 'PaymentTooltip · variants',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _t(context, 'Paid 2 days ago', 'Dibayar 2 hari lalu'),
              ),
            ),
            PaymentTooltip(
              key: const Key('tooltip-label'),
              type: PaymentTooltipType.label,
              message: _t(
                context,
                'Payment time: 29 Oct 2026, 14:05',
                'Waktu pembayaran: 29 Okt 2026, 14.05',
              ),
              child: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.info_outline),
              ),
            ),
          ],
        ),
        PaymentTooltip(
          key: const Key('tooltip-description'),
          placement: PaymentTooltipPlacement.top,
          message: _t(
            context,
            'Paid on 29 Oct 2026, 14:05',
            'Dibayar 29 Okt 2026, 14.05',
          ),
          child: Text(_t(context, '2d ago', '2 hr lalu')),
        ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: PaymentTooltip(
            key: const Key('tooltip-flip'),
            placement: PaymentTooltipPlacement.end,
            message: _t(
              context,
              'Flips to the start when there is no room',
              'Pindah ke awal jika tidak ada ruang',
            ),
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.info_outline),
            ),
          ),
        ),
      ],
    ),
  );
}
