// Example host code, not kit API (D98 host adoption).
//
// Two checkout layouts built from the same kit components, the same host
// model and the same host callbacks. The host owns every decision: the
// quote, the selected method, the balance verdict and what "pay" does. These
// widgets only arrange kit components; they make no network or payment call.
//
// Styling follows the D98 adoption order: shared tokens from the app theme,
// one product look for buttons and fields applied as a scoped theme, and one
// named host preset for the pay action that both layouts share. Everyday
// buttons and fields here take no `style`.

import 'package:flutter/material.dart';
import 'package:rakit_ui/rakit_ui.dart';

/// The host's checkout state. Immutable; the host rebuilds it on change.
class CheckoutOrder {
  const CheckoutOrder({
    required this.merchant,
    required this.reference,
    required this.quote,
    required this.methods,
    required this.selectedMethodId,
    required this.balance,
    required this.balanceState,
    this.merchantVerified = false,
    this.receiptEmail = '',
    this.paying = false,
  });

  final String merchant;

  /// Set only when the host has verified this merchant.
  final bool merchantVerified;
  final String reference;
  final PaymentQuote quote;
  final List<PaymentMethod> methods;
  final String? selectedMethodId;
  final Money balance;
  final BalanceState balanceState;
  final String receiptEmail;

  /// True while the host is paying, so both layouts block a second press.
  final bool paying;
}

/// The host's callbacks. Both layouts report intent through the same set.
class CheckoutActions {
  const CheckoutActions({
    required this.onSelectMethod,
    required this.onChangeMethod,
    required this.onReceiptEmailChanged,
    required this.onPay,
  });

  final ValueChanged<PaymentMethod> onSelectMethod;
  final VoidCallback onChangeMethod;
  final ValueChanged<String> onReceiptEmailChanged;

  /// The host pays. The button stays busy until the future completes.
  final Future<void> Function() onPay;
}

/// The product's shared button and field look, as theme extensions. It
/// reads the current theme, so light, dark and brand changes follow.
List<ThemeExtension<dynamic>> productLooks(BuildContext context) {
  final theme = PaymentTheme.of(context);
  return [
    PaymentButtonTheme(
      style: PaymentButtonStyle(
        borderRadius: BorderRadius.circular(theme.space(PaymentSpace.major)),
      ),
    ),
    PaymentFieldTheme(
      fillColor: theme.surfaceMuted,
      borderRadius: BorderRadius.circular(theme.space(PaymentSpace.group)),
    ),
  ];
}

/// Applies [productLooks] to a subtree, keeping the parent's other
/// extensions (the payment theme included).
class ProductLooks extends StatelessWidget {
  const ProductLooks({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final parent = Theme.of(context);
    return Theme(
      data: parent.copyWith(
        extensions: [...parent.extensions.values, ...productLooks(context)],
      ),
      child: child,
    );
  }
}

/// Named host preset for the checkout's pay action, shared by both layouts.
/// An ink fill on the surface color: high contrast in light and dark.
PaymentButtonStyle payActionStyle(BuildContext context) {
  final theme = PaymentTheme.of(context);
  return PaymentButtonStyle(
    backgroundColor: theme.textPrimary,
    foregroundColor: theme.surface,
  );
}

String _t(BuildContext context, String en, String id) =>
    Localizations.localeOf(context).languageCode == 'id' ? id : en;

String _payLabel(BuildContext context, Money total) => _t(
  context,
  'Pay ${PaymentLocalizations.of(context).moneyFormat.format(total)}',
  'Bayar ${PaymentLocalizations.of(context).moneyFormat.format(total)}',
);

class _ReceiptEmail extends StatelessWidget {
  const _ReceiptEmail({required this.order, required this.actions});

  final CheckoutOrder order;
  final CheckoutActions actions;

  @override
  Widget build(BuildContext context) => PaymentTextField(
    label: _t(context, 'Email for receipt', 'Email untuk struk'),
    type: PaymentTextFieldType.email,
    initialValue: order.receiptEmail,
    onChanged: actions.onReceiptEmailChanged,
  );
}

/// Layout one: a stacked invoice. Merchant, line items with fees, method
/// choice, receipt email, then one full-width pay action at the end.
class InvoiceCheckout extends StatelessWidget {
  const InvoiceCheckout({
    super.key,
    required this.order,
    required this.actions,
    this.inlinePayAction = true,
  });

  final CheckoutOrder order;
  final CheckoutActions actions;

  /// A screen host can move this action into its pinned footer instead.
  final bool inlinePayAction;

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.space(PaymentSpace.section),
      children: [
        MerchantHeader(
          name: order.merchant,
          orderReference: order.reference,
          verified: order.merchantVerified,
        ),
        PaymentSummary(quote: order.quote),
        PaymentSection(
          title: _t(context, 'Pay with', 'Bayar dengan'),
          child: PaymentMethodPicker(
            methods: order.methods,
            selectedId: order.selectedMethodId,
            onChanged: actions.onSelectMethod,
          ),
        ),
        _ReceiptEmail(order: order, actions: actions),
        if (inlinePayAction)
          PaymentButton(
            label: _payLabel(context, order.quote.total),
            style: payActionStyle(context),
            busy: order.paying,
            onPressed: actions.onPay,
          ),
      ],
    );
  }
}

/// Layout two: a wallet review. Balance first, the review beside it on wide
/// screens (under it on phones), and the total with the pay action in an
/// action bar at the end.
class WalletReviewCheckout extends StatelessWidget {
  const WalletReviewCheckout({
    super.key,
    required this.order,
    required this.actions,
  });

  final CheckoutOrder order;
  final CheckoutActions actions;

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final gap = theme.space(PaymentSpace.section);
    final wallet = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: gap,
      children: [
        BalanceCard(state: order.balanceState, balance: order.balance),
        PaymentButton(
          label: _t(context, 'Use another method', 'Pakai metode lain'),
          variant: PaymentButtonVariant.secondary,
          onPressed: actions.onChangeMethod,
        ),
        _ReceiptEmail(order: order, actions: actions),
      ],
    );
    final review = PaymentSummary(
      quote: order.quote,
      title: _t(context, 'Review', 'Tinjau'),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: gap,
      children: [
        LayoutBuilder(
          builder: (context, constraints) => constraints.maxWidth >= 600
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: gap,
                  children: [
                    Expanded(child: wallet),
                    Expanded(child: review),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: gap,
                  children: [wallet, review],
                ),
        ),
        PaymentActionBar(
          total: order.quote.total,
          action: PaymentButton(
            label: _t(context, 'Pay from wallet', 'Bayar dari dompet'),
            width: PaymentWidth.hug,
            style: payActionStyle(context),
            busy: order.paying,
            onPressed: order.balanceState == BalanceState.sufficient
                ? actions.onPay
                : null,
          ),
        ),
      ],
    );
  }
}
