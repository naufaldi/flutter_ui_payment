// Host application source, not package API. Copy and adapt the callbacks
// to your own adapters, persistence and routing.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';

import 'host_checkout.dart';
import 'host_payment_recovery.dart';

/// One bounded screen from review through recovery to a confirmed receipt.
///
/// The host supplies a quote already priced for the selected method. Requote
/// in [onSelectMethod] and rebuild [order] before allowing submission. No
/// challenge is performed here: this example's wallet needs none. A host
/// requiring authorization must finish that step before exposing this send
/// step, and keep its credentials and cancellation handling outside it.
class HostCheckoutJourney extends StatefulWidget {
  const HostCheckoutJourney({
    super.key,
    required this.order,
    required this.clock,
    required this.newAttemptId,
    required this.onSelectMethod,
    required this.onReceiptEmailChanged,
    required this.onSubmit,
    required this.onCheckStatus,
    required this.onLoadReceipt,
    required this.onOtherAction,
    required this.onDone,
    required this.onShare,
    required this.onCopy,
  });

  final CheckoutOrder order;
  final DateTime Function() clock;
  final String Function() newAttemptId;
  final ValueChanged<PaymentMethod> onSelectMethod;
  final ValueChanged<String> onReceiptEmailChanged;

  /// Persist the attempt before sending. A lost response returns null or
  /// throws; both leave the result unknown and preserve this attempt ID.
  /// This is a send callback, not an authorization challenge callback.
  final Future<PaymentStatusSnapshot?> Function(
    PaymentAttempt attempt,
    CheckoutOrder order,
  )
  onSubmit;
  final Future<PaymentStatusSnapshot> Function(PaymentAttempt) onCheckStatus;
  final Future<PaymentReceiptData> Function(PaymentAttempt) onLoadReceipt;
  final FutureOr<void> Function(PaymentAttempt, PaymentAction) onOtherAction;
  final VoidCallback onDone;
  final Future<ShareOutcome> Function(ReceiptShareData) onShare;
  final Future<bool> Function(String) onCopy;

  @override
  State<HostCheckoutJourney> createState() => _HostCheckoutJourneyState();
}

class _HostCheckoutJourneyState extends State<HostCheckoutJourney> {
  PaymentAttempt? _attempt;
  CheckoutOrder? _submittedOrder;
  PaymentReceiptData? _receipt;
  PaymentAction? _busyAction;
  bool _working = false;
  bool _receiptFailed = false;
  int _generation = 0;

  @override
  void didUpdateWidget(HostCheckoutJourney oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order.reference != widget.order.reference) {
      // A different host order starts another session. Never let a response
      // belonging to the previous order populate this one.
      _generation++;
      _attempt = null;
      _submittedOrder = null;
      _receipt = null;
      _busyAction = null;
      _working = false;
      _receiptFailed = false;
    }
  }

  bool get _canPay {
    final order = widget.order;
    final methodId = PaymentMethodPicker.validSelection(
      order.methods,
      order.selectedMethodId,
    );
    final method = methodId == null
        ? null
        : order.methods.firstWhere((method) => method.id == methodId);
    return !_working &&
        !order.paying &&
        _attempt == null &&
        method != null &&
        order.quote.methodId == method.id &&
        !order.quote.isExpiredAt(widget.clock()) &&
        (method.kind != PaymentMethodKind.balance ||
            order.balanceState == BalanceState.sufficient);
  }

  bool _current(int generation, String id) =>
      mounted && generation == _generation && _attempt?.attemptId == id;

  Future<void> _submit() async {
    // Revalidate at the event boundary, including expiry since the last build.
    if (!_canPay) {
      setState(() {});
      return;
    }
    final order = widget.order;
    final attempt = PaymentAttempt(
      attemptId: widget.newAttemptId(),
      quoteId: order.quote.id,
      quoteRevision: order.quote.revision,
      methodId: order.selectedMethodId!,
      submission: SubmissionState.sending,
    );
    final generation = _generation;
    setState(() {
      _attempt = attempt;
      _submittedOrder = order;
      _working = true;
    });
    PaymentStatusSnapshot? response;
    try {
      response = await widget.onSubmit(attempt, order);
    } catch (_) {
      // Transport failure cannot establish that a debit failed.
    }
    if (!_current(generation, attempt.attemptId)) return;
    setState(() {
      _attempt = response == null
          ? attempt.copyWith(submission: SubmissionState.outcomeUnknown)
          : attempt.reconcile(response).attempt;
      if (_attempt!.submission == SubmissionState.sending) {
        _attempt = attempt.copyWith(submission: SubmissionState.outcomeUnknown);
      }
      _working = false;
    });
    if (_attempt!.status == PaymentStatus.succeeded) {
      await _action(attempt.attemptId, PaymentAction.viewReceipt);
    }
  }

  Future<void> _loadReceipt(int generation, String id) async {
    final receipt = await widget.onLoadReceipt(_attempt!);
    if (!_current(generation, id)) return;
    if (_attempt!.status != PaymentStatus.succeeded ||
        receipt.transactionId != _attempt!.serverReference) {
      throw StateError('Receipt does not belong to this confirmed payment');
    }
    setState(() => _receipt = receipt);
  }

  Future<void> _action(String id, PaymentAction action) async {
    final attempt = _attempt;
    if (_working ||
        attempt == null ||
        attempt.attemptId != id ||
        !attempt.availableActions.contains(action)) {
      return;
    }
    final generation = _generation;
    setState(() {
      _working = true;
      _busyAction = action;
      _receiptFailed = false;
      if (action == PaymentAction.checkStatus) {
        _attempt = attempt.copyWith(observation: Observation.refreshing);
      }
    });
    try {
      if (action == PaymentAction.checkStatus) {
        final response = await widget.onCheckStatus(attempt);
        if (!_current(generation, id)) return;
        final result = _attempt!.reconcile(response);
        setState(() {
          _attempt = result.applied
              ? result.attempt.copyWith(lastCheckedAt: widget.clock())
              : _attempt!.copyWith(observation: Observation.unavailable);
        });
        if (_attempt!.status == PaymentStatus.succeeded &&
            _attempt!.availableActions.contains(PaymentAction.viewReceipt)) {
          await _loadReceipt(generation, id);
        }
      } else if (action == PaymentAction.viewReceipt) {
        await _loadReceipt(generation, id);
      } else {
        await widget.onOtherAction(attempt, action);
      }
    } catch (_) {
      if (!_current(generation, id)) return;
      setState(() {
        if (_attempt!.status == PaymentStatus.succeeded) {
          _receiptFailed = true;
        } else {
          _attempt = _attempt!.copyWith(observation: Observation.unavailable);
        }
      });
    } finally {
      if (_current(generation, id)) {
        setState(() {
          _working = false;
          _busyAction = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = Localizations.localeOf(context).languageCode == 'id';
    final attempt = _attempt;
    return ProductLooks(
      child: Builder(
        builder: (context) {
          if (attempt != null) {
            return HostPaymentRecovery(
              attempt: attempt,
              amount: _submittedOrder!.quote.total,
              receipt: _receipt,
              busyAction:
                  _busyAction ??
                  (attempt.submission == SubmissionState.sending
                      ? PaymentAction.checkStatus
                      : null),
              header: _receiptFailed
                  ? PaymentBanner(
                      tone: StatusTone.warning,
                      title: id
                          ? 'Struk belum tersedia'
                          : 'Receipt unavailable',
                      message: id
                          ? 'Pembayaran berhasil. Coba muat struk lagi.'
                          : 'Payment succeeded. Try loading the receipt again.',
                    )
                  : null,
              onAction: _action,
              onDone: widget.onDone,
              onShare: widget.onShare,
              onCopy: widget.onCopy,
            );
          }
          final order = widget.order;
          return PaymentFullPageView(
            title: id ? 'Tinjau pembayaran' : 'Review payment',
            primaryAction: PaymentButton(
              label:
                  '${id ? 'Bayar' : 'Pay'} '
                  '${PaymentLocalizations.of(context).moneyFormat.format(order.quote.total)}',
              style: payActionStyle(context),
              onPressed: _canPay ? _submit : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: PaymentTheme.of(context).space(PaymentSpace.group),
              children: [
                if (!_canPay)
                  PaymentBanner(
                    tone: StatusTone.warning,
                    title: id
                        ? 'Pembayaran belum dapat dikirim'
                        : 'Payment not ready',
                    message: id
                        ? 'Host perlu memberikan quote yang masih berlaku, metode yang sesuai, dan saldo yang cukup.'
                        : 'The host must provide a current quote, a matching available method and sufficient balance.',
                  ),
                InvoiceCheckout(
                  order: order,
                  inlinePayAction: false,
                  actions: CheckoutActions(
                    onSelectMethod: widget.onSelectMethod,
                    onReceiptEmailChanged: widget.onReceiptEmailChanged,
                    onChangeMethod: () {},
                    onPay: _submit,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
