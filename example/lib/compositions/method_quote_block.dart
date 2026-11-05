import 'package:flutter/material.dart';
import 'package:rakit_ui/rakit_ui.dart';

enum MethodQuoteStep { choose, review }

/// Copyable host composition: choose a method, see its host-priced fees and
/// total, then review and approve before paying.
///
/// A selection is not a price. Continue is enabled only when the host quote
/// names the selected method and no newer quote request is running, so a late
/// answer for an earlier choice can never enable paying. When the host
/// re-prices at submit, pass the approved quote as [previousQuote]: the kit
/// shows the change and keeps Pay disabled until the payer accepts the new
/// total. Authorization (PIN, OTP, biometrics) stays in the host; this block
/// collects no credentials.
class MethodQuoteBlock extends StatelessWidget {
  const MethodQuoteBlock({
    super.key,
    required this.title,
    required this.step,
    required this.methods,
    required this.selectedId,
    required this.quote,
    required this.onSelect,
    required this.onContinue,
    required this.onChangeMethod,
    required this.onConfirm,
    required this.onRetryQuote,
    this.quoting = false,
    this.quoteError,
    this.previousQuote,
    this.submitting = false,
  });

  /// What is being paid for; the method list carries its own heading.
  final String title;
  final MethodQuoteStep step;
  final List<PaymentMethod> methods;
  final String? selectedId;

  /// Latest host quote, or null before the first answer.
  final PaymentQuote? quote;
  final ValueChanged<PaymentMethod> onSelect;
  final VoidCallback onContinue;
  final VoidCallback onChangeMethod;
  final Future<void> Function() onConfirm;
  final VoidCallback onRetryQuote;
  final bool quoting;
  final String? quoteError;
  final PaymentQuote? previousQuote;
  final bool submitting;

  /// True only for a settled quote that prices the current selection.
  static bool quoteMatches({
    required List<PaymentMethod> methods,
    required String? selectedId,
    required PaymentQuote? quote,
    required bool quoting,
  }) =>
      !quoting &&
      quote != null &&
      PaymentMethodPicker.validSelection(methods, selectedId) != null &&
      quote.methodId == selectedId;

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    final ready = quoteMatches(
      methods: methods,
      selectedId: selectedId,
      quote: quote,
      quoting: quoting,
    );
    if (step == MethodQuoteStep.review && ready) {
      final method = methods.firstWhere((m) => m.id == selectedId);
      return PaymentConfirmation(
        // A new quote revision resets the kit's acceptance checkbox.
        quote: quote!,
        previousQuote: previousQuote,
        method: method,
        busy: submitting,
        onConfirm: onConfirm,
        footnote:
            'Setelah Anda menyetujui, aplikasi meminta otorisasi di '
            'langkah berikutnya.',
        header: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: theme.space(PaymentSpace.related),
          children: [
            Expanded(child: Text(title, style: type.heading)),
            PaymentLink(
              label: 'Ganti metode',
              semanticLabel: 'Ganti metode pembayaran',
              onPressed: submitting ? null : onChangeMethod,
            ),
          ],
        ),
      );
    }
    final l10n = PaymentLocalizations.of(context);
    return PaymentFullPageView(
      title: title,
      // The priced total rides on the pinned action, so the payer sees it
      // without scrolling past the method list.
      primaryAction: PaymentButton(
        label: ready
            ? 'Lanjutkan · ${l10n.moneyFormat.format(quote!.total)}'
            : 'Lanjutkan',
        onPressed: ready ? onContinue : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: theme.space(PaymentSpace.group),
        children: [
          PaymentMethodPicker(
            methods: methods,
            selectedId: selectedId,
            onChanged: onSelect,
          ),
          if (selectedId == null)
            Text(
              'Pilih metode untuk melihat biaya dan total dari merchant.',
              style: type.caption,
            )
          else if (quoting)
            Row(
              spacing: theme.space(PaymentSpace.related),
              children: [
                const PaymentIcon(
                  PaymentIcons.busy,
                  color: PaymentTextColor.secondary,
                ),
                Expanded(
                  child: Text(
                    'Menghitung biaya untuk metode ini…',
                    style: type.label,
                  ),
                ),
              ],
            )
          else if (quoteError != null)
            PaymentBanner(
              tone: StatusTone.danger,
              icon: Icons.cloud_off_outlined,
              title: 'Biaya belum dapat dihitung',
              message: quoteError,
              actions: [
                PaymentButton(
                  label: 'Coba lagi',
                  variant: PaymentButtonVariant.secondary,
                  width: PaymentWidth.hug,
                  onPressed: onRetryQuote,
                ),
              ],
            )
          else if (ready)
            PaymentSummary(quote: quote!),
        ],
      ),
    );
  }
}
