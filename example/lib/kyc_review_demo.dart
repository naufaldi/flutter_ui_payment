import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';

import 'compositions/kyc_review_block.dart';
import 'themes.dart';

void main() => runApp(const KycReviewDemo());

const kycDemoRequirement = DocumentRequirement(
  key: 'identity',
  label: 'Foto identitas · Demo',
  acceptedTypes: {'image/jpeg'},
  acceptedTypesLabel: 'JPG',
  maxBytes: 5000000,
);
const kycDemoFile = DocumentFile(
  name: 'identitas_demo_baru.jpg',
  mimeType: 'image/jpeg',
  sizeBytes: 240000,
);

/// Synthetic host only: metadata, masked fictional identity and explicit
/// verification snapshots. No document bytes, camera, permission or network.
class KycReviewDemo extends StatefulWidget {
  const KycReviewDemo({
    super.key,
    this.initialDark = false,
    this.failFirstSubmit = false,
    this.delay = const Duration(milliseconds: 500),
  });
  final bool initialDark;
  final bool failFirstSubmit;
  final Duration delay;
  @override
  State<KycReviewDemo> createState() => _KycReviewDemoState();
}

class _KycReviewDemoState extends State<KycReviewDemo> {
  late bool dark = widget.initialDark;
  late bool failFirst = widget.failFirstSubmit;
  KycReviewStep step = KycReviewStep.status;
  VerificationSnapshot snapshot = const VerificationSnapshot(
    status: VerificationStatus.actionRequired,
    requestId: 'KYC-DEMO-1',
    safeReason:
        'Foto identitas kurang jelas. Ganti dengan foto baru yang terang dan tidak terpotong.',
    fieldsToFix: {'identity'},
    allowedActions: {VerificationAction.fixDetails},
  );
  DocumentSlotState document = const DocumentSlotState.failed(
    DocumentIssue(
      DocumentIssueKind.rejectedByHost,
      safeMessage: 'Foto buram. Unggah foto baru.',
    ),
    file: kycDemoFile,
  );
  String? error;
  bool busy = false;
  int generation = 0;
  int submits = 0;

  void reset(bool failure) => setState(() {
    generation++;
    busy = false;
    error = null;
    submits = 0;
    failFirst = failure;
    step = KycReviewStep.status;
    snapshot = const VerificationSnapshot(
      status: VerificationStatus.actionRequired,
      requestId: 'KYC-DEMO-1',
      safeReason:
          'Foto identitas kurang jelas. Ganti dengan foto baru yang terang dan tidak terpotong.',
      fieldsToFix: {'identity'},
      allowedActions: {VerificationAction.fixDetails},
    );
    document = const DocumentSlotState.failed(
      DocumentIssue(
        DocumentIssueKind.rejectedByHost,
        safeMessage: 'Foto buram. Unggah foto baru.',
      ),
      file: kycDemoFile,
    );
  });

  Future<void> submit() async {
    if (busy ||
        step != KycReviewStep.review ||
        document.phase != DocumentSlotPhase.uploaded) {
      return;
    }
    final current = generation;
    final reject = failFirst && submits++ == 0;
    setState(() {
      busy = true;
      error = null;
    });
    await Future<void>.delayed(widget.delay);
    if (!mounted || current != generation) return;
    setState(() {
      busy = false;
      if (reject) {
        error =
            'Belum ada data yang dikirim pada simulasi ini. Coba kirim perbaikan lagi.';
      } else {
        // Explicit synthetic host response, never inferred from upload/time.
        snapshot = const VerificationSnapshot(
          status: VerificationStatus.inReview,
          requestId: 'KYC-DEMO-1',
          allowedActions: {VerificationAction.checkStatus},
        );
        step = KycReviewStep.status;
      }
    });
  }

  Future<void> action(VerificationAction value) async {
    if (busy) return;
    if (value == VerificationAction.fixDetails) {
      setState(() {
        step = KycReviewStep.document;
        error = null;
      });
    } else if (value == VerificationAction.checkStatus &&
        snapshot.allowedActions.contains(value)) {
      final current = generation;
      setState(() => busy = true);
      await Future<void>.delayed(widget.delay);
      if (!mounted || current != generation) return;
      setState(() {
        busy = false;
        snapshot = const VerificationSnapshot(
          status: VerificationStatus.verified,
          requestId: 'KYC-DEMO-1',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: buildTheme(DemoBrand.ruangBayar, Brightness.light),
    darkTheme: buildTheme(DemoBrand.ruangBayar, Brightness.dark),
    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    locale: const Locale('id'),
    supportedLocales: const [Locale('id'), Locale('en')],
    localizationsDelegates: const [
      PaymentLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(
      appBar: AppBar(
        title: const Text('Identitas · Demo'),
        actions: [
          PaymentIconButton(
            icon: Icons.brightness_6_outlined,
            tooltip: 'Ganti tema',
            onPressed: () => setState(() => dark = !dark),
          ),
          PopupMenuButton<bool>(
            tooltip: 'Skenario demo',
            onSelected: reset,
            itemBuilder: (_) => const [
              PopupMenuItem(value: false, child: Text('Perbaikan dokumen')),
              PopupMenuItem(value: true, child: Text('Gagal kirim pertama')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: KycReviewBlock(
          step: step,
          snapshot: snapshot,
          requirement: kycDemoRequirement,
          document: document,
          fields: const [
            IdentityFieldSpec(key: 'name', label: 'Nama'),
            IdentityFieldSpec(
              key: 'reference',
              label: 'Referensi identitas',
              maskInReview: true,
            ),
          ],
          values: const {
            'name': 'Rina Contoh · Demo',
            'reference': 'DEMO-00002190',
          },
          busy: busy,
          error: error,
          onAction: action,
          onPick: () => setState(() {
            document = const DocumentSlotState.uploaded(
              kycDemoFile,
              requestId: 'UPLOAD-DEMO-2',
            );
          }),
          onReview: () => setState(() => step = KycReviewStep.review),
          onSubmit: submit,
        ),
      ),
    ),
  );
}
