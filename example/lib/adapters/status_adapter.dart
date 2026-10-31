import 'package:flutter_ui_payment/flutter_ui_payment.dart';

import 'fake_host.dart';

/// Parsed, trusted view of one status response.
class ParsedStatus {
  const ParsedStatus(this.snapshot, this.amount);
  final PaymentStatusSnapshot snapshot;
  final Money amount;
}

/// Host adapter: provider JSON → library domain model.
///
/// Anything unexpected (unknown enum, missing field, wrong type) rejects the
/// whole snapshot with [HostErrorCategory.invalidResponse]. It never guesses
/// an outcome and never forwards the raw payload to the UI.
ParsedStatus parseStatus(Map<String, Object?> json) {
  // `why` documents each rejection for debugging; it never reaches the UI.
  Never invalid(String why) =>
      throw const HostException(HostError(HostErrorCategory.invalidResponse));

  T field<T>(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is! T) invalid('$key has unexpected type');
    return value;
  }

  final status = PaymentStatus.tryParse(field<String>(json, 'status'));
  if (status == null) invalid('unknown status');
  final updatedAt = DateTime.tryParse(field<String>(json, 'updatedAt'));
  if (updatedAt == null) invalid('bad updatedAt');

  final actions = <PaymentAction>{};
  for (final raw in field<List<Object?>>(json, 'actions')) {
    final action = PaymentAction.values.where((a) => a.name == raw);
    // Unknown actions are dropped rather than rendered; they grant nothing.
    if (action.isNotEmpty) actions.add(action.first);
  }

  final amountJson = field<Map<String, Object?>>(json, 'amount');
  final amount = Money(
    field<int>(amountJson, 'minor'),
    field<String>(amountJson, 'currency'),
  );

  final refundJson = field<Map<String, Object?>>(json, 'refund');
  final refundStatus = RefundStatus.values
      .where((s) => s.name == refundJson['status'])
      .firstOrNull;
  if (refundStatus == null) invalid('unknown refund status');
  final refundMinor = refundJson['amount'];
  if (refundMinor != null && refundMinor is! int) invalid('refund amount');

  VirtualAccountInstructions? instructions;
  final instructionsJson = json['instructions'];
  if (instructionsJson != null) {
    if (instructionsJson is! Map<String, Object?>) invalid('instructions');
    final expiresAt = DateTime.tryParse(
      field<String>(instructionsJson, 'expiresAt'),
    );
    if (expiresAt == null) invalid('instructions.expiresAt');
    instructions = VirtualAccountInstructions(
      providerLabel: field<String>(instructionsJson, 'provider'),
      accountNumber: field<String>(instructionsJson, 'number'),
      amount: amount,
      expiresAt: expiresAt,
      steps: field<List<Object?>>(
        instructionsJson,
        'steps',
      ).whereType<String>().toList(),
    );
  }

  final reason = json['reason'];
  return ParsedStatus(
    PaymentStatusSnapshot(
      attemptId: field<String>(json, 'attemptId'),
      serverReference: field<String>(json, 'reference'),
      status: status,
      revision: field<int>(json, 'revision'),
      updatedAt: updatedAt,
      allowedActions: actions,
      safeReason: reason is String ? reason : null,
      refund: RefundInfo(
        status: refundStatus,
        amount: refundMinor is int ? Money(refundMinor, amount.currency) : null,
        updatedAt: refundStatus == RefundStatus.none ? null : updatedAt,
      ),
      instructions: instructions,
    ),
    amount,
  );
}
