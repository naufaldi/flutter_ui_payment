import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rakit_ui/rakit_ui.dart';

import 'block_demo_shell.dart';
import 'compositions/kyc_onboarding_block.dart';

void main() => runBlockDemo(const KycOnboardingDemo());

enum KycOnboardingScenario { fresh, hostRejectsId, saveFails }

/// Synthetic identity used by the prefilled scenarios. The demo host rejects
/// this ID number, so the person has to correct it.
const kycOnboardingRejectedId = '9999 0000 0000 2190';
const kycOnboardingPrefill = {
  'name': 'Rina Contoh',
  'nik': kycOnboardingRejectedId,
  'dob': '1994-05-17',
  'occupation': 'employee',
};

const kycOnboardingRequirements = [
  DataRequirement(
    title: 'Nama dan tanggal lahir',
    purpose: 'Mencocokkan Anda dengan data kependudukan.',
  ),
  DataRequirement(
    title: 'Nomor KTP (NIK)',
    purpose:
        'Mencegah akun ganda. Hanya empat digit terakhir yang ditampilkan.',
  ),
  DataRequirement(
    title: 'Pekerjaan',
    purpose: 'Diminta regulasi untuk menilai risiko transaksi.',
  ),
  DataRequirement(
    title: 'Foto KTP dan swafoto',
    purpose:
        'Memastikan pemilik KTP adalah Anda. Diambil di langkah berikutnya.',
  ),
];

/// Host identity rules. They run on the device; the host checks again when
/// it receives the details.
final kycOnboardingFields = [
  IdentityFieldSpec(
    key: 'name',
    label: 'Nama lengkap sesuai KTP',
    textCapitalization: TextCapitalization.words,
    autofillHints: const [AutofillHints.name],
    validator: (v) => v.runes.length < 2 ? 'Isi nama lengkap Anda.' : null,
  ),
  IdentityFieldSpec(
    key: 'nik',
    label: 'NIK',
    hint: '16 digit di KTP',
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]'))],
    maskInReview: true,
    validator: (v) => RegExp(r'^\d{16}$').hasMatch(v.replaceAll(' ', ''))
        ? null
        : 'NIK terdiri dari 16 angka.',
  ),
  IdentityFieldSpec(
    key: 'dob',
    label: 'Tanggal lahir',
    kind: IdentityFieldKind.date,
    firstDate: DateTime(1900),
    lastDate: DateTime(2009, 12, 31),
    validator: (v) => v.isEmpty ? 'Pilih tanggal lahir Anda.' : null,
  ),
  const IdentityFieldSpec(
    key: 'occupation',
    label: 'Pekerjaan',
    kind: IdentityFieldKind.choice,
    options: [
      PaymentSelectOption(value: 'employee', label: 'Karyawan'),
      PaymentSelectOption(value: 'entrepreneur', label: 'Wiraswasta'),
      PaymentSelectOption(value: 'student', label: 'Pelajar atau mahasiswa'),
      PaymentSelectOption(value: 'other', label: 'Lainnya'),
    ],
    validator: _required,
  ),
];

String? _required(String v) => v.isEmpty ? 'Pilih pekerjaan Anda.' : null;

/// Synthetic onboarding host. Consent, field checks and saving are declared
/// fixture answers; nothing leaves the device and no identity is verified.
class KycOnboardingDemo extends StatefulWidget {
  const KycOnboardingDemo({
    super.key,
    this.initialScenario = KycOnboardingScenario.fresh,
    this.initialStep = KycOnboardingStep.consent,
    this.initialDark = false,
    this.delay = const Duration(milliseconds: 500),
  });
  final KycOnboardingScenario initialScenario;

  /// Starts past consent for captures; the person still saw consent first in
  /// any real session.
  final KycOnboardingStep initialStep;
  final bool initialDark;
  final Duration delay;

  @override
  State<KycOnboardingDemo> createState() => _KycOnboardingDemoState();
}

class _KycOnboardingDemoState extends State<KycOnboardingDemo> {
  late bool dark = widget.initialDark;
  late KycOnboardingScenario scenario = widget.initialScenario;
  late KycOnboardingStep step = widget.initialStep;
  late Map<String, String> values = prefill(scenario);
  final form = IdentityFormController();
  Map<String, String> serverErrors = const {};
  bool saving = false;
  String? saveError;
  int saves = 0;
  int generation = 0;

  static Map<String, String> prefill(KycOnboardingScenario value) =>
      value == KycOnboardingScenario.fresh ? const {} : kycOnboardingPrefill;

  @override
  void dispose() {
    form.dispose();
    super.dispose();
  }

  void reset(KycOnboardingScenario value) => setState(() {
    generation++;
    scenario = value;
    step = KycOnboardingStep.consent;
    values = prefill(value);
    serverErrors = const {};
    saving = false;
    saveError = null;
    saves = 0;
  });

  Future<void> details(Map<String, String> submitted) async {
    final current = generation;
    await Future<void>.delayed(widget.delay);
    if (!mounted || current != generation) return;
    final id = submitted['nik']!.replaceAll(' ', '');
    setState(() {
      values = submitted;
      if (scenario == KycOnboardingScenario.hostRejectsId &&
          id == kycOnboardingRejectedId.replaceAll(' ', '')) {
        serverErrors = const {
          'nik': 'NIK ini tidak cocok dengan data kependudukan. Periksa lagi.',
        };
        return;
      }
      serverErrors = const {};
      step = KycOnboardingStep.review;
    });
  }

  Future<void> save() async {
    if (saving) return;
    final current = generation;
    final count = ++saves;
    setState(() {
      saving = true;
      saveError = null;
    });
    await Future<void>.delayed(widget.delay);
    if (!mounted || current != generation) return;
    setState(() {
      saving = false;
      if (scenario == KycOnboardingScenario.saveFails && count == 1) {
        saveError =
            'Periksa koneksi, lalu simpan lagi. Data Anda tetap di sini.';
        return;
      }
      step = KycOnboardingStep.saved;
    });
  }

  @override
  Widget build(BuildContext context) => BlockDemoShell(
    title: 'Verifikasi · Demo',
    dark: dark,
    onToggleDark: () => setState(() => dark = !dark),
    scenarios: [
      for (final (value, label) in [
        (KycOnboardingScenario.fresh, 'Isi data baru'),
        (KycOnboardingScenario.hostRejectsId, 'NIK ditolak host'),
        (KycOnboardingScenario.saveFails, 'Simpan gagal'),
      ])
        (label: label, onSelected: () => reset(value)),
    ],
    body: (context) => KycOnboardingBlock(
      key: ValueKey(generation),
      step: step,
      requirements: kycOnboardingRequirements,
      fields: kycOnboardingFields,
      values: values,
      formController: form,
      serverErrors: serverErrors,
      saving: saving,
      saveError: saveError,
      onConsent: () => setState(() => step = KycOnboardingStep.details),
      onOpenPolicy: () => showPaymentSheet<void>(
        context: context,
        builder: (sheet) => PaymentSheet(
          header: PaymentSheetHeader(
            title: 'Kebijakan privasi · Demo',
            onClose: () => Navigator.pop(sheet),
          ),
          body: const Text(
            'Ringkasan contoh. Aplikasi Anda menampilkan kebijakan privasinya '
            'sendiri: data apa yang disimpan, berapa lama, siapa yang dapat '
            'mengaksesnya, dan cara menarik persetujuan.',
          ),
        ),
      ),
      onDetails: details,
      onEditDetails: () => setState(() => step = KycOnboardingStep.details),
      onSave: save,
      savedAction: PaymentButton(
        label: 'Mulai ulang demo',
        variant: PaymentButtonVariant.quiet,
        onPressed: () => reset(scenario),
      ),
    ),
  );
}
