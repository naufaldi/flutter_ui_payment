import 'package:flutter/material.dart';
import 'package:rakit_ui/rakit_ui.dart';

import 'block_demo_shell.dart';
import 'compositions/payment_preferences_block.dart';

void main() => runBlockDemo(const PaymentPreferencesDemo());

enum PreferencesScenario { saves, firstSaveFails }

const preferenceMethods = [
  PaymentMethod(
    id: 'balance',
    label: 'Saldo Ruang Bayar',
    kind: PaymentMethodKind.balance,
    detail: 'Saldo •••• 2190',
  ),
  PaymentMethod(
    id: 'va',
    label: 'Virtual account',
    kind: PaymentMethodKind.virtualAccount,
    detail: 'Bank Demo',
  ),
  PaymentMethod(
    id: 'qris',
    label: 'QRIS',
    kind: PaymentMethodKind.eWallet,
    detail: 'Bayar dengan aplikasi apa pun',
  ),
  PaymentMethod(
    id: 'card',
    label: 'Kartu kredit',
    kind: PaymentMethodKind.card,
    unavailableReason: 'Tambahkan kartu dulu di Metode tersimpan.',
  ),
];

const preferencesSnapshot = PaymentPreferences(
  defaultMethodId: 'balance',
  receipts: true,
  reminders: false,
);

/// Synthetic preferences host. Saving returns the host's stored copy after a
/// declared delay; nothing leaves the device.
class PaymentPreferencesDemo extends StatefulWidget {
  const PaymentPreferencesDemo({
    super.key,
    this.initialScenario = PreferencesScenario.saves,
    this.initialDark = false,
    this.delay = const Duration(milliseconds: 600),
  });
  final PreferencesScenario initialScenario;
  final bool initialDark;
  final Duration delay;

  @override
  State<PaymentPreferencesDemo> createState() => _PaymentPreferencesDemoState();
}

class _PaymentPreferencesDemoState extends State<PaymentPreferencesDemo> {
  late bool dark = widget.initialDark;
  late PreferencesScenario scenario = widget.initialScenario;
  PaymentPreferences saved = preferencesSnapshot;
  PaymentPreferences draft = preferencesSnapshot;
  bool saving = false;
  bool confirmed = false;
  String? saveError;
  int saves = 0;
  int generation = 0;

  void reset(PreferencesScenario value) => setState(() {
    generation++;
    scenario = value;
    saved = preferencesSnapshot;
    draft = preferencesSnapshot;
    saving = false;
    confirmed = false;
    saveError = null;
    saves = 0;
  });

  Future<void> save() async {
    // Nothing changed: there is nothing for the host to confirm.
    if (saving || draft == saved) return;
    final current = generation;
    final count = ++saves;
    final sent = draft;
    setState(() {
      saving = true;
      saveError = null;
    });
    await Future<void>.delayed(widget.delay);
    if (!mounted || current != generation) return;
    setState(() {
      saving = false;
      if (scenario == PreferencesScenario.firstSaveFails && count == 1) {
        saveError = 'Periksa koneksi, lalu simpan lagi.';
        return;
      }
      // The host's stored copy is the truth; the draft follows it.
      saved = sent;
      draft = sent;
      confirmed = true;
    });
  }

  @override
  Widget build(BuildContext context) => BlockDemoShell(
    title: 'Pengaturan · Demo',
    dark: dark,
    onToggleDark: () => setState(() => dark = !dark),
    scenarios: [
      (
        label: 'Simpan berhasil',
        onSelected: () => reset(PreferencesScenario.saves),
      ),
      (
        label: 'Simpan pertama gagal',
        onSelected: () => reset(PreferencesScenario.firstSaveFails),
      ),
    ],
    body: (context) => PaymentPreferencesBlock(
      key: ValueKey(generation),
      methods: preferenceMethods,
      saved: saved,
      draft: draft,
      saving: saving,
      confirmed: confirmed,
      saveError: saveError,
      onChanged: (next) => setState(() {
        draft = next;
        saveError = null;
      }),
      onSave: save,
    ),
  );
}
