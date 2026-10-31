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
  @override
  Widget build(BuildContext context) {
    const facts = [
      PaymentPropertyListItem(label: 'Items', valueText: '2 items'),
      PaymentPropertyListItem(label: 'Subtotal', valueText: 'Rp100.000'),
      PaymentPropertyListItem(label: 'Fee', valueText: 'Rp2.500'),
      PaymentPropertyListItem(
        label: 'Total',
        valueText: 'Rp102.500',
        emphasis: true,
      ),
    ];
    final view = switch (widget.name) {
      'PaymentContextView' => PaymentContextView(
        title: 'Order context',
        description: 'Toko Contoh · Order DEMO-42',
        brand: const PaymentIcon(Icons.storefront_outlined),
        actions: [button('Copy order ID')],
        externalLink: PaymentLink(
          label: 'Merchant help',
          external: true,
          onPressed: () {},
        ),
        secondaryAction: button('Close'),
        primaryAction: button(
          'Continue to payment',
          variant: PaymentButtonVariant.primary,
        ),
        child: const PaymentPropertyList(items: facts),
      ),
      'PaymentFullPageView' => PaymentFullPageView(
        title: 'Transactions',
        pageAction: button('Download statement'),
        child: Column(
          children: [
            PaymentTabs(
              tabs: const [
                PaymentTab(label: 'All'),
                PaymentTab(label: 'In progress'),
                PaymentTab(label: 'Refunds'),
              ],
              selectedIndex: state,
              onSelected: (v) => setState(() => state = v),
            ),
            const PaymentPropertyList(items: facts),
          ],
        ),
      ),
      'PaymentFocusView' => PaymentFocusView(
        title: 'Report a problem',
        secondaryAction: button('Cancel', variant: PaymentButtonVariant.quiet),
        primaryAction: button('Send', variant: PaymentButtonVariant.primary),
        child: Column(
          children: [
            const PaymentTextArea(label: 'What went wrong?'),
            PaymentButton(
              label: 'Open report a problem',
              variant: PaymentButtonVariant.secondary,
              onPressed: () => showPaymentFocusView<void>(
                context,
                builder: (_) => const PaymentFocusView(
                  title: 'Report a problem',
                  confirmClose: PaymentConfirmClose(
                    title: 'Discard report?',
                    message: 'Your changes will be lost.',
                    exitLabel: 'Discard',
                  ),
                  child: PaymentTextArea(label: 'What went wrong?'),
                ),
              ),
            ),
          ],
        ),
      ),
      'PaymentSettingsView' => PaymentSettingsView(
        title: 'Payment settings',
        statusMessage: 'Saved',
        statusTone: StatusTone.success,
        onSave: () async {
          await Future<void>.delayed(const Duration(milliseconds: 600));
        },
        child: Column(
          children: [
            PaymentFormFieldGroup(
              legend: 'Notifications',
              children: [
                PaymentSwitch(
                  label: 'Refund notifications',
                  value: refunds,
                  onChanged: (v) => setState(() => refunds = v),
                ),
                PaymentSwitch(
                  label: 'Promotions',
                  value: promos,
                  onChanged: (v) => setState(() => promos = v),
                ),
              ],
            ),
            PaymentFormFieldGroup(
              legend: 'Default method',
              children: [
                for (final value in ['bank', 'wallet'])
                  PaymentRadio<String>(
                    value: value,
                    groupValue: method,
                    onChanged: (v) => setState(() => method = v),
                    label: value == 'bank' ? 'BCA virtual account' : 'Wallet',
                  ),
              ],
            ),
            PaymentFormFieldGroup(
              legend: 'Language',
              children: [
                PaymentSelect<String>(
                  label: 'Statement language',
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
      'PaymentSignInView' => PaymentSignInView(
        brand: const PaymentIcon(Icons.account_balance_wallet_outlined),
        description: 'Sign in with your bank app to see payments and refunds.',
        learnMore: PaymentSignInLearnMore(
          label: 'What we can see',
          title: 'Permissions',
          builder: (_) => const Text('Payment history and refunds.'),
        ),
        primaryAction: button(
          'Continue with bank app',
          variant: PaymentButtonVariant.primary,
        ),
        secondaryAction: button('Use another account'),
        legalLinks: [
          PaymentLink(label: 'Terms', external: true, onPressed: () {}),
          PaymentLink(label: 'Privacy', external: true, onPressed: () {}),
        ],
        footnote: 'We never ask for your PIN here.',
        errorText: state == 1 ? 'Sign-in was canceled. Try again.' : null,
      ),
      'PaymentOnboardingView' => PaymentOnboardingView(
        title: 'Verify your identity',
        tasks: const [
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
          PaymentTaskListItem(title: 'Review'),
        ],
        pending: state == 1,
        error: state == 2
            ? const PaymentBanner(
                tone: StatusTone.warning,
                title: 'Documents need attention',
              )
            : null,
        completed: state == 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Add your identity documents to get started.'),
            button('Continue', variant: PaymentButtonVariant.primary),
          ],
        ),
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
                    child: Text(['Ready', 'Pending', 'Error', 'Complete'][i]),
                  ),
              ],
            )
          : null,
      child: SizedBox(height: 560, child: view),
    );
  }
}
