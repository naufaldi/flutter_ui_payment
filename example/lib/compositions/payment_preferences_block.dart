import 'package:flutter/material.dart';
import 'package:rakit_ui/rakit_ui.dart';

/// The host's payment preferences. Choosing a default method only preselects
/// it at checkout; it never charges or authorizes anything.
@immutable
class PaymentPreferences {
  const PaymentPreferences({
    required this.defaultMethodId,
    required this.receipts,
    required this.reminders,
  });
  final String defaultMethodId;
  final bool receipts;
  final bool reminders;

  PaymentPreferences copyWith({
    String? defaultMethodId,
    bool? receipts,
    bool? reminders,
  }) => PaymentPreferences(
    defaultMethodId: defaultMethodId ?? this.defaultMethodId,
    receipts: receipts ?? this.receipts,
    reminders: reminders ?? this.reminders,
  );

  @override
  bool operator ==(Object other) =>
      other is PaymentPreferences &&
      other.defaultMethodId == defaultMethodId &&
      other.receipts == receipts &&
      other.reminders == reminders;

  @override
  int get hashCode => Object.hash(defaultMethodId, receipts, reminders);
}

/// Copyable host composition: default payment method and payment
/// notifications with an explicit Save.
///
/// [saved] is the host's last confirmed snapshot and [draft] is what the
/// person has chosen since. The block says "saved" only when [confirmed] is
/// true and the draft equals the host's snapshot. A failed save keeps the
/// draft so the person can retry without choosing again. Controls are locked
/// while the host saves.
class PaymentPreferencesBlock extends StatelessWidget {
  const PaymentPreferencesBlock({
    super.key,
    required this.methods,
    required this.saved,
    required this.draft,
    required this.onChanged,
    required this.onSave,
    this.saving = false,
    this.confirmed = false,
    this.saveError,
  });

  /// Methods the host can make default; unavailable ones explain why.
  final List<PaymentMethod> methods;
  final PaymentPreferences saved;
  final PaymentPreferences draft;
  final ValueChanged<PaymentPreferences> onChanged;
  final Future<void> Function() onSave;
  final bool saving;

  /// The host confirmed [saved] in this session.
  final bool confirmed;
  final String? saveError;

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final dirty = draft != saved;
    final (message, tone) = saving
        ? ('Menyimpan perubahan…', StatusTone.info)
        : saveError != null
        ? ('Belum tersimpan. $saveError', StatusTone.danger)
        : dirty
        ? ('Ada perubahan yang belum disimpan.', StatusTone.neutral)
        : confirmed
        ? ('Preferensi tersimpan.', StatusTone.success)
        : (null, StatusTone.neutral);
    return PaymentSettingsView(
      title: 'Preferensi pembayaran',
      statusMessage: message,
      statusTone: tone,
      saveLabel: 'Simpan',
      onSave: onSave,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: theme.space(PaymentSpace.group),
        children: [
          PaymentSection(
            title: 'Metode utama',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final method in methods)
                  PaymentRadio<String>(
                    value: method.id,
                    groupValue: draft.defaultMethodId,
                    label: method.label,
                    description: method.detail,
                    disabledReason: method.unavailableReason,
                    onChanged: saving || !method.isAvailable
                        ? null
                        : (id) =>
                              onChanged(draft.copyWith(defaultMethodId: id)),
                  ),
              ],
            ),
          ),
          PaymentSection(
            title: 'Notifikasi',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PaymentSwitch(
                  value: draft.receipts,
                  label: 'Struk pembayaran',
                  description: 'Dikirim ke email setelah pembayaran berhasil.',
                  onChanged: saving
                      ? null
                      : (on) => onChanged(draft.copyWith(receipts: on)),
                ),
                PaymentSwitch(
                  value: draft.reminders,
                  label: 'Pengingat tagihan',
                  description: 'Satu hari sebelum batas pembayaran.',
                  onChanged: saving
                      ? null
                      : (on) => onChanged(draft.copyWith(reminders: on)),
                ),
                const PaymentSwitch(
                  value: true,
                  label: 'Peringatan keamanan',
                  onChanged: null,
                  disabledReason: 'Selalu aktif untuk melindungi akun Anda.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
