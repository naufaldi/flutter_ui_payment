part of 'gallery_screen.dart';

class _MenuSpecimen extends StatelessWidget {
  const _MenuSpecimen();
  @override
  Widget build(BuildContext context) => _Entry(
    name: 'PaymentMenu · variants',
    child: Align(
      alignment: AlignmentDirectional.centerEnd,
      child: PaymentMenu(
        key: const Key('menu-specimen'),
        onAction: (id) => _hostSays(context, id, id),
        entries: const [
          PaymentMenuGroup(
            title: 'Receipt',
            items: [
              PaymentMenuItem(
                id: 'download',
                label: 'Download PDF',
                icon: Icons.download_outlined,
              ),
              PaymentMenuItem(
                id: 'share',
                label: 'Share',
                icon: Icons.share_outlined,
              ),
            ],
          ),
          PaymentMenuGroup(
            items: [PaymentMenuItem(label: 'Export history', disabled: true)],
          ),
          PaymentMenuGroup(
            items: [
              PaymentMenuItem(
                id: 'cancel',
                label: 'Cancel payment',
                destructive: true,
                icon: Icons.cancel_outlined,
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _AccordionSpecimen extends StatelessWidget {
  const _AccordionSpecimen();
  @override
  Widget build(BuildContext context) => _Entry(
    name: 'PaymentAccordion · variants',
    child: PaymentAccordion(
      children: [
        const PaymentAccordionItem(
          title: 'When will my payment arrive?',
          child: Text('Most transfers arrive within a few minutes.'),
        ),
        const PaymentAccordionItem(
          title: 'Receipt details',
          subtitle: 'Keep a copy for your records',
          leading: Icons.receipt_long_outlined,
          initiallyExpanded: true,
          child: Text('The reference identifies this payment.'),
        ),
        PaymentAccordionItem(
          title: 'Saved method',
          actions: [
            PaymentButton(
              label: 'Edit',
              size: PaymentSize.small,
              width: PaymentWidth.hug,
              variant: PaymentButtonVariant.secondary,
              onPressed: () {},
            ),
            PaymentMenu(
              entries: [
                PaymentMenuItem(label: 'Remove method', onSelected: () {}),
                PaymentMenuItem(label: 'View details', onSelected: () {}),
              ],
            ),
          ],
          child: const Text('Bank Contoh •••• 8890'),
        ),
      ],
    ),
  );
}

class _ListSpecimen extends StatelessWidget {
  const _ListSpecimen();
  @override
  Widget build(BuildContext context) => _Entry(
    name: 'PaymentList · variants',
    child: PaymentList(
      onAction: (id) => _hostSays(context, id, id),
      children: [
        const PaymentListItem(
          id: 'history',
          title: 'Transaction history',
          secondaryTitle: 'Last 90 days',
          icon: Icons.receipt_long_outlined,
        ),
        const PaymentListItem(
          id: 'balance',
          title: 'Balance',
          icon: Icons.account_balance_wallet_outlined,
          value: AmountText(Money.idr(250000)),
        ),
        const PaymentListItem(
          title: 'Available balance',
          icon: Icons.account_balance_wallet_outlined,
          value: AmountText(Money.idr(250000)),
        ),
        PaymentListItem(
          title: 'Saved method',
          icon: Icons.credit_card_outlined,
          trailing: PaymentButton(
            label: 'Change',
            variant: PaymentButtonVariant.secondary,
            size: PaymentSize.small,
            width: PaymentWidth.hug,
            onPressed: () {},
          ),
        ),
        const PaymentListItem(
          id: 'cancel',
          title: 'Cancel payment',
          icon: Icons.cancel_outlined,
          destructive: true,
        ),
        const PaymentListItem(
          title: 'Change PIN',
          icon: Icons.password_outlined,
          disabledReason: 'Managed by your bank app',
        ),
        const PaymentListItem(
          id: 'bank',
          title: 'Bank Contoh · •••• 8890',
          secondaryTitle: 'Savings',
          icon: Icons.account_balance_outlined,
          size: PaymentListItemSize.large,
        ),
      ],
    ),
  );
}
