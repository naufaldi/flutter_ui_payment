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
    title: 'Payment details',
    pending: pending,
    orientation: horizontal ? Axis.horizontal : Axis.vertical,
    errorText: error ? 'Details didn’t load' : null,
    onRetry: () {},
    onCreate: empty ? () {} : null,
    emptyMessage: const PaymentEmptyMessage(
      'No details yet',
      message: 'Add a payment detail to get started.',
    ),
    items: empty
        ? const []
        : [
            const PaymentDetailProperty(
              label: 'Amount',
              values: [
                PaymentDetailValue('Rp102.500', subText: 'Including fee'),
              ],
            ),
            PaymentDetailProperty(
              label: 'Merchant',
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
    title: 'Attempts',
    pending: pending,
    errorText: error ? 'Attempts didn’t load' : null,
    onRetry: () {},
    columns: [
      PaymentDataColumn<int>(
        key: 'time',
        label: 'Time',
        value: (r) => DateTime(2026, 10, 1, 10, r),
        cell: PaymentCellType.date,
      ),
      PaymentDataColumn<int>(
        key: 'method',
        label: 'Method',
        value: (r) => 'BCA virtual account',
        pinned: true,
      ),
      PaymentDataColumn<int>(
        key: 'status',
        label: 'Status',
        value: (r) => r == 3 ? 'Paid' : 'Pending',
        cell: PaymentCellType.status,
        statusMap: {'Paid': StatusTone.success, 'Pending': StatusTone.warning},
      ),
      PaymentDataColumn<int>(
        key: 'amount',
        label: 'Amount',
        value: (r) => const Money.idr(102500),
        cell: PaymentCellType.currency,
      ),
    ],
    rows: empty ? const [] : const [1, 2, 3],
    rowKey: (r) => '$r',
    rowActions: [
      PaymentRowAction<int>(
        id: 'view',
        label: 'View attempt',
        onPressed: (_) {},
      ),
    ],
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
      'PaymentDetailPage' => PaymentDetailPage(
        title: 'Rp102.500 to Toko Contoh',
        description: 'Paid with BCA virtual account · 1 Oct 2026',
        breadcrumbs: [
          PaymentBreadcrumb(label: 'Transactions', onPressed: () {}),
        ],
        actions: [
          button('View receipt'),
          button('Report a problem', variant: PaymentButtonVariant.quiet),
          button('Request refund', variant: PaymentButtonVariant.destructive),
        ],
        primary: [
          PaymentPageModule(title: 'Payment details', child: property()),
          PaymentPageModule(title: 'Attempts', child: attempts()),
        ],
        secondary: const [
          PaymentPageModule(
            title: 'Merchant',
            child: PaymentPropertyList(
              items: [
                PaymentPropertyListItem(
                  label: 'Name',
                  valueText: 'Toko Contoh',
                ),
              ],
            ),
          ),
        ],
      ),
      'PaymentOverviewPage' => PaymentFullPageView(
        title: 'Spending',
        child: PaymentOverviewPage(
          primary: [
            PaymentPageModule(
              title: 'This month',
              child: PaymentBarChart(points: _chartFixture('typical')),
            ),
            const PaymentPageModule(
              title: 'Recent transactions',
              child: PaymentPropertyList(
                items: [
                  PaymentPropertyListItem(
                    label: 'Toko Contoh',
                    valueText: 'Rp102.500',
                  ),
                  PaymentPropertyListItem(
                    label: 'Groceries',
                    valueText: 'Rp75.000',
                  ),
                  PaymentPropertyListItem(
                    label: 'Coffee',
                    valueText: 'Rp25.000',
                  ),
                ],
              ),
            ),
          ],
          secondary: const [
            PaymentPageModule(
              title: 'Balance',
              child: PaymentPropertyList(
                items: [
                  PaymentPropertyListItem(
                    label: 'Available',
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
                    child: Text(['Ready', 'Pending', 'Error', 'Complete'][i]),
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
