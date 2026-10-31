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
    final (caption, children) = switch (widget.kind) {
      'dialog' => (
        'showPaymentConfirmDialog · variants',
        <Widget>[
          const Text(
            'Confirm the named consequence before removing a saved card.',
          ),
          PaymentButton(
            key: const Key('phase6-dialog-open'),
            label: 'Remove card',
            variant: PaymentButtonVariant.destructive,
            onPressed: () => showPaymentConfirmDialog(
              context,
              title: 'Remove card?',
              message: 'You can add this demo card again later.',
              confirmLabel: 'Remove card',
              cancelLabel: 'Cancel',
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
              header: const PaymentSheetHeader(title: 'Payment options'),
              body: const Text('Choose a method for this demo payment.'),
              footer: action('Done', onPressed: () {}),
            ),
          ),
          action(
            'Open sheet',
            onPressed: () => showPaymentSheet<void>(
              context: context,
              builder: (_) => const PaymentSheet(
                header: PaymentSheetHeader(title: 'Demo sheet'),
                body: Text('Supporting payment information.'),
              ),
            ),
          ),
        ],
      ),
      'section' => (
        'PaymentSection · variants',
        <Widget>[
          PaymentSection(
            title: 'Payment method',
            trailing: PaymentLink(label: 'Change', onPressed: () {}),
            child: const Text('QRIS · Instant'),
          ),
          const PaymentSection(child: Text('Fees include VAT.')),
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
              sections: const [
                PaymentNavSection(
                  title: 'Payments',
                  items: [
                    PaymentNavItem(
                      id: 'payments',
                      label: 'Transactions',
                      icon: Icons.receipt_long_outlined,
                    ),
                  ],
                ),
                PaymentNavSection(
                  title: 'Account',
                  items: [
                    PaymentNavItem(
                      id: 'settings',
                      label: 'Settings',
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
              steps: const ['Order', 'Review', 'Pay'],
              current: i,
            ),
        ],
      ),
      'info_row' => (
        'InfoRow · variants',
        <Widget>[
          const InfoRow(label: 'Method', valueText: 'QRIS'),
          const InfoRow(
            label: 'Total',
            value: AmountText(Money.idr(102500)),
            emphasis: true,
          ),
          const InfoRow(
            label: 'Fee',
            valueText: 'Rp2.500',
            caption: 'Includes VAT',
          ),
          const InfoRow(
            label: 'Reference',
            valueText: 'TRX-DEMO-0042',
            trailing: PaymentCopyButton(
              value: 'TRX-DEMO-0042',
              onCopy: _copyGalleryValue,
            ),
          ),
          const InfoRow(
            label: 'Order',
            value: MiddleEllipsisText(
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
              child: const PaymentPropertyList(
                items: [
                  PaymentPropertyListItem(
                    label: 'Virtual account',
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
            action: action('Pay Rp102.500', onPressed: () {}, primary: true),
          ),
          PaymentActionBar(
            total: const Money.idr(102500),
            updating: true,
            action: action('Updating total', primary: true),
          ),
          const Text('Choose a payment method to continue.'),
          PaymentActionBar(
            total: const Money.idr(102500),
            action: action('Pay Rp102.500', primary: true),
          ),
        ],
      ),
      'media' => (
        'PaymentVideoPlayer · variants',
        <Widget>[
          PaymentVideoPlayer(
            controller: _video,
            title: 'How to pay (demo, loading only)',
          ),
        ],
      ),
      'status_header' => (
        'StatusHeader · variants',
        <Widget>[
          const StatusHeader(
            tone: StatusTone.success,
            icon: PaymentIcons.success,
            title: 'Paid',
          ),
          const StatusHeader(
            tone: StatusTone.warning,
            icon: Icons.schedule,
            title: 'Pending',
          ),
          const StatusHeader(
            tone: StatusTone.danger,
            icon: Icons.error_outline,
            title: 'Failed',
          ),
          const StatusHeader(
            tone: StatusTone.neutral,
            icon: Icons.help_outline,
            title: 'Not confirmed',
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
            title: 'No transactions yet',
            message: 'Your first payment will appear here.',
            actionLabel: 'Make a payment',
            onAction: () {},
          ),
          StateMessage(
            icon: Icons.warning_amber,
            title: 'Spending did not load',
            message: 'Payments are still available.',
            tone: StatusTone.warning,
            actionLabel: 'Retry',
            onAction: () {},
          ),
          StateMessage(
            icon: Icons.error_outline,
            title: 'Transactions did not load',
            message: 'Retry to see your payment history.',
            tone: StatusTone.danger,
            actionLabel: 'Retry',
            onAction: () {},
          ),
          PaymentDetailPagePropertyList(
            title: 'No matches',
            pending: false,
            emptyMessage: PaymentEmptyMessage(
              'No matching settlements',
              message: 'Clear the search to see all records.',
              actionLabel: 'Clear search',
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
              title: 'Weekly spending · ${state.name}',
              state: state,
              height: 200,
              headline: state == ChartState.ready
                  ? const Money.idr(102500)
                  : null,
              chart: state == ChartState.ready
                  ? const PaymentBarChart(
                      points: [
                        ChartPoint(label: 'W1', value: Money.idr(25000)),
                        ChartPoint(label: 'W2', value: Money.idr(77500)),
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
