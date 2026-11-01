import 'package:flutter/material.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import '../../coordinator/demo_coordinator.dart';
import '../../demo_strings.dart';

Future<void> showReportProblem(
  BuildContext context,
  DemoCoordinator c,
  TransactionRecord r,
) async {
  final id = await showPaymentFocusView<String>(
    context,
    builder: (_) => _ReportProblem(c, r),
  );
  if (id != null && context.mounted) {
    showPaymentToast(context, message: DemoStrings.of(context).reportSent(id));
  }
}

class _ReportProblem extends StatefulWidget {
  const _ReportProblem(this.c, this.record);
  final DemoCoordinator c;
  final TransactionRecord record;
  @override
  State<_ReportProblem> createState() => _ReportProblemState();
}

class _ReportProblemState extends State<_ReportProblem> {
  final controller = TextEditingController();
  String? category;
  bool sending = false, failed = false;
  bool get dirty => category != null || controller.text.isNotEmpty;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> send() async {
    setState(() {
      sending = true;
      failed = false;
    });
    try {
      final id = await widget.c.reportProblem(
        category: category!,
        length: controller.text.characters.length,
      );
      if (mounted) Navigator.pop(context, id);
    } catch (_) {
      if (mounted) {
        setState(() {
          sending = false;
          failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = DemoStrings.of(context);
    final l = PaymentLocalizations.of(context);
    return PaymentFocusView(
      title: s.reportProblem,
      confirmClose: dirty
          ? PaymentConfirmClose(
              title: s.discardTitle,
              message: s.discardMessage,
              exitLabel: s.discard,
            )
          : null,
      primaryAction: PaymentButton(
        key: const Key('send-report'),
        label: s.sendReport,
        busy: sending,
        onPressed: category == null ? null : send,
      ),
      secondaryAction: PaymentButton(
        key: const Key('report-cancel'),
        label: l.cancel,
        variant: PaymentButtonVariant.quiet,
        onPressed: sending ? null : () => Navigator.maybePop(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: PaymentTheme.of(context).space(PaymentSpace.group),
        children: [
          PaymentPropertyList(
            items: [
              PaymentPropertyListItem(
                label: s.propertyReference,
                valueText: widget.record.reference,
              ),
              PaymentPropertyListItem(
                label: s.columnAmount,
                value: AmountText(widget.record.amount),
              ),
            ],
          ),
          if (failed)
            PaymentBanner(
              tone: StatusTone.danger,
              title: s.reportFailed,
              announce: true,
            ),
          PaymentSelect<String>(
            label: s.whatWentWrong,
            value: category,
            onChanged: sending ? null : (v) => setState(() => category = v),
            options: [
              PaymentSelectOption(value: 'chargedTwice', label: s.chargedTwice),
              PaymentSelectOption(value: 'wrongAmount', label: s.wrongAmount),
              PaymentSelectOption(value: 'notReceived', label: s.notReceived),
              PaymentSelectOption(value: 'other', label: s.otherProblem),
            ],
          ),
          PaymentTextArea(
            label: s.describeProblem,
            description: s.noSecrets,
            controller: controller,
            maxLength: 500,
            enabled: !sending,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }
}
