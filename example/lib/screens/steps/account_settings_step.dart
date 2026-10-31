import 'package:flutter/material.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import '../../coordinator/demo_coordinator.dart';
import '../../demo_strings.dart';

class AccountSettingsStep extends StatelessWidget {
  const AccountSettingsStep(this.c, {super.key});
  final DemoCoordinator c;
  @override
  Widget build(BuildContext context) {
    final s = DemoStrings.of(context);
    final v = c.accountSettings;
    return PaymentSettingsView(
      title: s.accountSettings,
      statusMessage: c.settingsStatus == null
          ? null
          : c.settingsStatus == 'saved'
          ? s.saved
          : s.saveFailed,
      statusTone: c.settingsTone,
      onSave: c.saveAccountSettings,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: PaymentTheme.of(context).space(PaymentSpace.section),
        children: [
          PaymentFormFieldGroup(
            legend: s.notifications,
            children: [
              PaymentSwitch(
                label: s.refundUpdates,
                description: 'When a refund is sent or arrives',
                value: v.refundUpdates,
                onChanged: (b) =>
                    c.updateAccountSettings(v.copyWith(refundUpdates: b)),
              ),
              PaymentSwitch(
                label: s.promotions,
                value: v.promotions,
                onChanged: (b) =>
                    c.updateAccountSettings(v.copyWith(promotions: b)),
              ),
            ],
          ),
          PaymentFormFieldGroup(
            legend: s.payments,
            children: [
              for (final (id, label) in [
                ('balance', 'Ruang Bayar balance'),
                ('bca', 'BCA virtual account'),
                ('qris', 'QRIS'),
              ])
                PaymentRadio<String>(
                  label: label,
                  value: id,
                  groupValue: v.defaultMethodId,
                  onChanged: (id) =>
                      c.updateAccountSettings(v.copyWith(defaultMethodId: id)),
                ),
            ],
          ),
          PaymentFormFieldGroup(
            legend: s.statementLanguage,
            children: [
              PaymentSelect<String>(
                label: s.statementLanguage,
                value: v.statementLanguage,
                options: const [
                  PaymentSelectOption(value: 'en', label: 'English'),
                  PaymentSelectOption(value: 'id', label: 'Bahasa Indonesia'),
                ],
                onChanged: (id) =>
                    c.updateAccountSettings(v.copyWith(statementLanguage: id)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
