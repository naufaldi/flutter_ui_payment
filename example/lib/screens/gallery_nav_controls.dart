part of 'gallery_screen.dart';

class _MenuSpecimen extends StatelessWidget {
  const _MenuSpecimen();
  @override
  Widget build(BuildContext context) => _Entry(
    name: 'PaymentMenu · variants',
    child: Column(
      children: [
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: PaymentMenu(
            key: const Key('menu-specimen'),
            onAction: (id) => _hostSays(context, id, id),
            entries: [
              PaymentMenuGroup(
                title: _t(context, 'Receipt', 'Struk'),
                items: [
                  PaymentMenuItem(
                    id: 'download',
                    label: _t(context, 'Download PDF', 'Unduh PDF'),
                    icon: Icons.download_outlined,
                  ),
                  PaymentMenuItem(
                    id: 'share',
                    label: _t(context, 'Share', 'Bagikan'),
                    icon: Icons.share_outlined,
                  ),
                ],
              ),
              PaymentMenuGroup(
                items: [
                  PaymentMenuItem(
                    label: _t(context, 'Export history', 'Ekspor riwayat'),
                    disabled: true,
                  ),
                ],
              ),
              PaymentMenuGroup(
                items: [
                  PaymentMenuItem(
                    id: 'cancel',
                    label: _t(context, 'Cancel payment', 'Batalkan pembayaran'),
                    destructive: true,
                    icon: Icons.cancel_outlined,
                  ),
                ],
              ),
            ],
          ),
        ),
        PaymentMenu(
          key: const Key('menu-trigger'),
          trigger: (toggle, node) => PaymentButton(
            label: _t(context, 'Options', 'Opsi'),
            width: PaymentWidth.hug,
            variant: PaymentButtonVariant.secondary,
            size: PaymentSize.small,
            focusNode: node,
            onPressed: toggle,
          ),
          entries: [
            PaymentMenuItem(
              label: _t(context, 'Download', 'Unduh'),
              onSelected: () {},
            ),
          ],
        ),
      ],
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
        PaymentAccordionItem(
          title: _t(
            context,
            'When will my payment arrive?',
            'Kapan pembayaran saya masuk?',
          ),
          child: Text(
            _t(
              context,
              'Most transfers arrive within a few minutes.',
              'Sebagian besar transfer masuk dalam beberapa menit.',
            ),
          ),
        ),
        PaymentAccordionItem(
          title: _t(context, 'Receipt details', 'Rincian struk'),
          subtitle: _t(
            context,
            'Keep a copy for your records',
            'Simpan salinan untuk catatan Anda',
          ),
          media: const PaymentIcon(
            Icons.receipt_long_outlined,
            color: PaymentTextColor.secondary,
          ),
          initiallyExpanded: true,
          child: Text(
            _t(
              context,
              'The reference identifies this payment.',
              'Referensi ini mengenali pembayaran ini.',
            ),
          ),
        ),
        PaymentAccordionItem(
          title: _t(context, 'Saved method', 'Metode tersimpan'),
          actions: [
            PaymentButton(
              label: _t(context, 'Edit', 'Ubah'),
              size: PaymentSize.small,
              width: PaymentWidth.hug,
              variant: PaymentButtonVariant.secondary,
              onPressed: () {},
            ),
            PaymentMenu(
              entries: [
                PaymentMenuGroup(
                  items: [
                    PaymentMenuItem(
                      label: _t(context, 'View details', 'Lihat rincian'),
                      onSelected: () {},
                    ),
                  ],
                ),
                PaymentMenuGroup(
                  items: [
                    PaymentMenuItem(
                      label: _t(context, 'Remove method', 'Hapus metode'),
                      destructive: true,
                      onSelected: () {},
                    ),
                  ],
                ),
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
        PaymentListItem(
          id: 'history',
          title: _t(context, 'Transaction history', 'Riwayat transaksi'),
          secondaryTitle: _t(context, 'Last 90 days', '90 hari terakhir'),
          icon: Icons.receipt_long_outlined,
        ),
        PaymentListItem(
          id: 'balance',
          title: _t(context, 'Balance', 'Saldo'),
          icon: Icons.account_balance_wallet_outlined,
          value: const AmountText(Money.idr(250000)),
        ),
        PaymentListItem(
          title: _t(context, 'Available balance', 'Saldo tersedia'),
          icon: Icons.account_balance_wallet_outlined,
          value: const AmountText(Money.idr(250000)),
        ),
        PaymentListItem(
          title: _t(context, 'Saved method', 'Metode tersimpan'),
          icon: Icons.credit_card_outlined,
          trailing: PaymentButton(
            label: _t(context, 'Change', 'Ganti'),
            variant: PaymentButtonVariant.secondary,
            size: PaymentSize.small,
            width: PaymentWidth.hug,
            onPressed: () {},
          ),
        ),
        PaymentListItem(
          id: 'cancel',
          title: _t(context, 'Cancel payment', 'Batalkan pembayaran'),
          icon: Icons.cancel_outlined,
          destructive: true,
        ),
        PaymentListItem(
          title: _t(context, 'Change PIN', 'Ubah PIN'),
          icon: Icons.password_outlined,
          disabledReason: _t(
            context,
            'Managed by your bank app',
            'Diatur oleh aplikasi bank Anda',
          ),
        ),
        PaymentListItem(
          id: 'bank',
          title: 'Bank Contoh · •••• 8890',
          secondaryTitle: _t(context, 'Savings', 'Tabungan'),
          icon: Icons.account_balance_outlined,
          size: PaymentListItemSize.large,
        ),
      ],
    ),
  );
}
