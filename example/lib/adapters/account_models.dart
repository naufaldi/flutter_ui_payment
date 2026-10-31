import 'package:flutter_ui_payment/flutter_ui_payment.dart';

class AttemptRow {
  const AttemptRow(this.id, this.at, this.method, this.status, this.amount);
  final String id, method;
  final DateTime at;
  final PaymentStatus? status;
  final Money amount;
}

class Settlement {
  const Settlement(
    this.id,
    this.date,
    this.description,
    this.status,
    this.amount,
  );
  final String id, description, status;
  final DateTime date;
  final Money amount;
}

class DemoAccountSettings {
  const DemoAccountSettings({
    this.refundUpdates = true,
    this.promotions = false,
    this.defaultMethodId = 'balance',
    this.statementLanguage = 'id',
  });
  final bool refundUpdates, promotions;
  final String defaultMethodId, statementLanguage;
  DemoAccountSettings copyWith({
    bool? refundUpdates,
    bool? promotions,
    String? defaultMethodId,
    String? statementLanguage,
  }) => DemoAccountSettings(
    refundUpdates: refundUpdates ?? this.refundUpdates,
    promotions: promotions ?? this.promotions,
    defaultMethodId: defaultMethodId ?? this.defaultMethodId,
    statementLanguage: statementLanguage ?? this.statementLanguage,
  );
}
