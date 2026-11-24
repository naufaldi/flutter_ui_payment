import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rakit_ui/rakit_ui.dart';

enum ReportProblemReason { chargedTwice, wrongAmount, notReceived, other }

typedef ReportProblemDraft = ({
  String transactionId,
  String reference,
  ReportProblemReason reason,
  String note,
});

typedef ConfirmedProblemReport = ({ReportProblemDraft draft, String caseId});

/// Returns the draft the host actually accepted and its nonblank case ID.
/// Do not relabel an earlier confirmation with an edited draft. Throw if the
/// submitted draft cannot be confirmed. The host owns safe retries.
typedef SubmitProblemReport =
    Future<ConfirmedProblemReport> Function(ReportProblemDraft draft);

/// Opens a draft for this transaction. Closing the sheet never submits a
/// report or changes the payment. Drafts only live while the sheet is open.
Future<void> showReportProblem(
  BuildContext context, {
  required TransactionRecord record,
  required SubmitProblemReport onSubmit,
}) async {
  if (ModalRoute.of(context)?.isCurrent == false) return;
  await showPaymentFocusView<void>(
    context,
    builder: (_) => _ReportProblemSheet(record: record, onSubmit: onSubmit),
  );
}

enum _SendState { idle, sending, failed }

class _ReportProblemSheet extends StatefulWidget {
  const _ReportProblemSheet({required this.record, required this.onSubmit});

  final TransactionRecord record;
  final SubmitProblemReport onSubmit;

  @override
  State<_ReportProblemSheet> createState() => _ReportProblemSheetState();
}

class _ReportProblemSheetState extends State<_ReportProblemSheet> {
  final _note = TextEditingController();
  final _retryMessage = GlobalKey();
  ReportProblemReason? _reason;
  _SendState _state = _SendState.idle;
  String? _caseId;
  int _attempt = 0;
  bool _closeAfterKeyboard = false;

  String get _reference => widget.record.reference ?? widget.record.id;
  bool get _sending => _state == _SendState.sending;
  String _t(String en, String id) =>
      Localizations.localeOf(context).languageCode == 'id' ? id : en;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    final route = ModalRoute.of(context);
    if (_sending || route == null || !route.isCurrent) return;
    if (_caseId == null && (_reason != null || _note.text.isNotEmpty)) {
      if (MediaQuery.viewInsetsOf(context).bottom > 0) {
        // The confirmation sheet does not avoid the keyboard. Wait for the
        // actual inset change rather than guessing the IME animation time.
        _closeAfterKeyboard = true;
        FocusScope.of(context).unfocus();
        return;
      }
      final discard = await showPaymentConfirmDialog(
        context,
        title: _t('Discard this report?', 'Buang laporan ini?'),
        message: _t(
          'Your reason and note will be lost.',
          'Alasan dan catatan Anda akan hilang.',
        ),
        confirmLabel: _t('Discard', 'Buang'),
        destructive: true,
      );
      if (!discard || !mounted || !route.isCurrent || _sending) return;
    }
    Navigator.pop(context);
  }

  Future<void> _send() async {
    final reason = _reason;
    if (reason == null ||
        _sending ||
        _caseId != null ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    final draft = (
      transactionId: widget.record.id,
      reference: _reference,
      reason: reason,
      note: _note.text,
    );
    FocusScope.of(context).unfocus();
    setState(() {
      _closeAfterKeyboard = false;
      _attempt++;
      _state = _SendState.sending;
    });
    String? caseId;
    try {
      final confirmed = await widget.onSubmit(draft);
      if (confirmed.draft == draft) caseId = confirmed.caseId.trim();
    } catch (_) {
      // Host errors may contain private details; only show safe recovery copy.
    }
    if (!mounted) return;
    setState(() {
      if (caseId != null && caseId.isNotEmpty) {
        _caseId = caseId;
        _state = _SendState.idle;
      } else {
        _state = _SendState.failed;
      }
    });
    if (_state == _SendState.failed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // On a short screen this banner scrolls with the form. Bring it
        // into view even when the editor was at the bottom of the viewport.
        final message = _retryMessage.currentContext;
        if (message != null) unawaited(Scrollable.ensureVisible(message));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    if (_closeAfterKeyboard && keyboard == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Send may have canceled the close since this frame was built.
        if (!mounted || !_closeAfterKeyboard) return;
        _closeAfterKeyboard = false;
        unawaited(_close());
      });
    }
    return PopScope<void>(
      // Every dismissal goes through live state, even if Back follows Send
      // before Flutter rebuilds the footer.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_close());
      },
      child: LayoutBuilder(
        builder: (context, constraints) => _buildSheet(
          context,
          constraints.maxHeight - keyboard,
          keyboard > 0,
        ),
      ),
    );
  }

  Widget _buildSheet(
    BuildContext context,
    double availableHeight,
    bool keyboardOpen,
  ) {
    final l = PaymentLocalizations.of(context);
    final t = _t;
    final theme = PaymentTheme.of(context);
    final compact = availableHeight < 360 || keyboardOpen;
    // Leave an editing viewport as well as a full-sized button. At smaller
    // heights the action scrolls with the form instead of taking all the room.
    final pinAction = availableHeight >= 160;
    const sheetKey = Key('report-problem-sheet');
    if (_caseId case final caseId?) {
      final title = t('Report sent', 'Laporan terkirim');
      final caseLabel = t('Case ID', 'ID kasus');
      final header = PaymentSheetHeader(
        title: title,
        onClose: () => unawaited(_close()),
      );
      final done = PaymentButton(
        label: t('Done', 'Selesai'),
        onPressed: _close,
      );
      return PaymentSheet(
        key: sheetKey,
        header: compact ? null : header,
        footer: pinAction ? done : null,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (compact) header,
            Semantics(
              container: true,
              liveRegion: true,
              excludeSemantics: true,
              label: '$title. $caseLabel: $caseId',
              child: PaymentPropertyList(
                items: [
                  PaymentPropertyListItem(label: caseLabel, valueText: caseId),
                ],
              ),
            ),
            if (!pinAction) done,
          ],
        ),
      );
    }

    final header = PaymentSheetHeader(
      title: t('Report a problem', 'Laporkan masalah'),
      onClose: _sending ? null : () => unawaited(_close()),
    );
    final error = _state == _SendState.failed
        ? KeyedSubtree(
            key: _retryMessage,
            child: PaymentBanner(
              key: ValueKey(_attempt),
              tone: StatusTone.danger,
              title: t(
                'No case ID yet. Try again.',
                'Belum ada ID kasus. Coba lagi.',
              ),
              announce: !keyboardOpen,
            ),
          )
        : null;
    final send = PaymentButton(
      key: const Key('send-report'),
      label: t('Send report', 'Kirim laporan'),
      busyLabel: t('Sending report', 'Mengirim laporan'),
      busy: _sending,
      onPressed: _reason == null || _sending ? null : _send,
    );
    return PaymentSheet(
      key: sheetKey,
      // Keep the scroll view mounted when both header and footer change.
      header: SizedBox(child: compact ? null : header),
      footer: !pinAction
          ? null
          : compact
          ? send
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: theme.space(PaymentSpace.related),
              children: [
                ?error,
                PaymentButtonGroup(
                  direction: Axis.vertical,
                  children: [
                    send,
                    PaymentButton(
                      key: const Key('report-cancel'),
                      label: l.cancel,
                      variant: PaymentButtonVariant.quiet,
                      onPressed: _sending ? null : _close,
                    ),
                  ],
                ),
              ],
            ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: theme.space(PaymentSpace.group),
        children: [
          if (compact) ...[header, ?error],
          PaymentPropertyList(
            items: [
              PaymentPropertyListItem(
                label: t('Reference', 'Referensi'),
                valueText: _reference,
              ),
              PaymentPropertyListItem(
                label: t('Amount', 'Nominal'),
                value: AmountText(widget.record.amount),
              ),
            ],
          ),
          PaymentSelect<ReportProblemReason>(
            label: t('What went wrong?', 'Apa masalahnya?'),
            value: _reason,
            onChanged: _sending
                ? null
                : (value) => setState(() => _reason = value),
            options: [
              for (final reason in ReportProblemReason.values)
                PaymentSelectOption(
                  value: reason,
                  label: switch (reason) {
                    ReportProblemReason.chargedTwice => t(
                      'Charged twice',
                      'Terdebit dua kali',
                    ),
                    ReportProblemReason.wrongAmount => t(
                      'Wrong amount',
                      'Nominal salah',
                    ),
                    ReportProblemReason.notReceived => t(
                      "Didn't get what I paid for",
                      'Pesanan tidak diterima',
                    ),
                    ReportProblemReason.other => t('Something else', 'Lainnya'),
                  },
                ),
            ],
          ),
          PaymentTextArea(
            key: const ValueKey('report-note'),
            label: t(
              'Describe the problem (optional)',
              'Jelaskan masalahnya (opsional)',
            ),
            description: t(
              "Don't include your PIN, OTP or card number.",
              'Jangan tulis PIN, OTP, atau nomor kartu.',
            ),
            controller: _note,
            minLines: compact ? 1 : 3,
            maxLength: 500,
            enabled: !_sending,
          ),
          if (!pinAction) send,
        ],
      ),
    );
  }
}
