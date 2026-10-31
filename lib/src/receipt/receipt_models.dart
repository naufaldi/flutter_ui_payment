import 'package:flutter/foundation.dart';

import '../foundation/money.dart';
import '../payment/payment_models.dart';

/// Receipt detail for a payment the host has confirmed as succeeded.
///
/// Contains no KYC data, credentials or raw provider payload.
@immutable
class PaymentReceiptData {
  const PaymentReceiptData({
    required this.transactionId,
    required this.merchantName,
    required this.paidAt,
    required this.lines,
    required this.total,
    required this.methodLabel,
    this.refund = const RefundInfo(status: RefundStatus.none),
  });

  final String transactionId;
  final String merchantName;
  final DateTime paidAt;
  final List<QuoteLine> lines;
  final Money total;

  /// Already masked by the host, e.g. "Saldo •••• 2190".
  final String methodLabel;
  final RefundInfo refund;
}

/// The only fields that leave the app when a receipt is shared.
@immutable
class ReceiptShareData {
  const ReceiptShareData({
    required this.title,
    required this.text,
    required this.fields,
  });

  /// Builds the allowlisted share payload. Line items, account identifiers
  /// and anything not listed here are deliberately excluded.
  factory ReceiptShareData.fromReceipt(
    PaymentReceiptData receipt, {
    required String title,
    required Map<String, String> labels,
    required MoneyFormat moneyFormat,
    required String Function(DateTime) formatDate,
  }) {
    final fields = <String, String>{
      labels['merchant']!: receipt.merchantName,
      labels['transactionId']!: receipt.transactionId,
      labels['paidAt']!: formatDate(receipt.paidAt),
      labels['total']!: moneyFormat.format(receipt.total),
      labels['method']!: receipt.methodLabel,
    };
    final text = StringBuffer(title);
    fields.forEach((k, v) => text.write('\n$k: $v'));
    return ReceiptShareData(
      title: title,
      text: text.toString(),
      fields: fields,
    );
  }

  final String title;
  final String text;
  final Map<String, String> fields;
}

/// Result reported by the host's share or clipboard implementation.
enum ShareOutcome { shared, dismissed, failed }
