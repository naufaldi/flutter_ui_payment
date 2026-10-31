part of 'gallery_screen.dart';

class _BadgeSpecimen extends StatelessWidget {
  const _BadgeSpecimen();
  @override
  Widget build(BuildContext context) => _Entry(
    name: 'PaymentBadge · variants',
    child: Wrap(
      spacing: PaymentTheme.of(context).spacing,
      runSpacing: PaymentTheme.of(context).spacing,
      children: const [
        PaymentBadge(tone: StatusTone.neutral, label: 'Canceled'),
        PaymentBadge(tone: StatusTone.info, label: 'In review'),
        PaymentBadge(tone: StatusTone.success, label: 'Paid'),
        PaymentBadge(
          tone: StatusTone.warning,
          label: 'Pending',
          icon: Icons.schedule,
        ),
        PaymentBadge(tone: StatusTone.danger, label: 'Failed'),
        PaymentBadge(
          tone: StatusTone.warning,
          label: 'Not confirmed',
          icon: Icons.help_outline,
        ),
        PaymentBadge.urgent(label: 'Action required'),
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
          const PaymentBanner(
            tone: StatusTone.info,
            title: 'Review in progress',
            message: 'We will show the outcome here.',
          ),
          SizedBox(height: s),
          const PaymentBanner(
            tone: StatusTone.success,
            title: 'Payment received',
          ),
          SizedBox(height: s),
          PaymentBanner(
            tone: StatusTone.warning,
            title: 'Total changed',
            message: 'Review the updated total before paying.',
            actions: [
              PaymentButton(
                label: 'Review total',
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
            title: 'Payment failed',
            message: 'Your balance has not changed.',
            actions: [
              for (final (label, variant) in [
                ('Try again', PaymentButtonVariant.secondary),
                ('Contact support', PaymentButtonVariant.quiet),
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
          const PaymentBanner(
            tone: StatusTone.neutral,
            title: 'Request canceled',
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
          ('Neutral', 'Promo hidden', StatusTone.neutral),
          ('Success', 'Reference copied', StatusTone.success),
          (
            'Warning',
            'Share canceled. Your receipt is still here.',
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
          label: 'With undo',
          size: PaymentSize.small,
          width: PaymentWidth.hug,
          variant: PaymentButtonVariant.secondary,
          onPressed: () => _toast = showPaymentToast(
            context,
            message: 'Promo hidden',
            actionLabel: 'Undo',
            onAction: () {},
          ),
        ),
        PaymentButton(
          label: 'Pending',
          size: PaymentSize.small,
          width: PaymentWidth.hug,
          variant: PaymentButtonVariant.secondary,
          onPressed: () {
            _work?.cancel();
            _toast = showPaymentToast(
              context,
              message: 'Refreshing balance…',
              pending: true,
            );
            final toast = _toast!;
            _work = Timer(
              const Duration(milliseconds: 1200),
              () => toast.update('Balance updated', tone: StatusTone.success),
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
                Text(size.name),
              ],
            ),
          ),
        Wrap(
          spacing: PaymentTheme.of(context).spacing,
          runSpacing: PaymentTheme.of(context).spacing,
          children: [
            for (final (label, ms) in [
              ('Start a fast wait (100 ms)', 100),
              ('Start a slow wait (2 s)', 2000),
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
            const Expanded(child: Text('Paid 2 days ago')),
            PaymentTooltip(
              key: const Key('tooltip-label'),
              type: PaymentTooltipType.label,
              message: 'Payment time: 29 Oct 2026, 14:05',
              child: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.info_outline),
              ),
            ),
          ],
        ),
        const PaymentTooltip(
          key: Key('tooltip-description'),
          placement: PaymentTooltipPlacement.top,
          message: 'Paid on 29 Oct 2026, 14:05',
          child: Text('2d ago'),
        ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: PaymentTooltip(
            key: const Key('tooltip-flip'),
            placement: PaymentTooltipPlacement.end,
            message: 'Flips to the start when there is no room',
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
