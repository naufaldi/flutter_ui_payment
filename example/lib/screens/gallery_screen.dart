import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';

import '../adapters/fake_host.dart';
import '../adapters/synthetic_capture.dart';
import '../adapters/video_adapter.dart';
import '../demo_strings.dart';
import '../dev_chrome.dart';
import 'flow_screen.dart' show documentRequirements, identityFields;

part 'gallery_kit.dart';
part 'gallery_charts.dart';
part 'gallery_capture.dart';

void _galleryFeedback(BuildContext context, String en, String id) {
  showPaymentSnackBar(context, message: _t(context, en, id));
}

Future<bool> _copyGalleryValue(String value) async {
  try {
    await Clipboard.setData(ClipboardData(text: value));
    return true;
  } catch (_) {
    return false;
  }
}

/// Every package component on its own, with a state selector. Uses only
/// static synthetic data; nothing here talks to the simulated host.
///
/// Sections are navigated with the kit's own [AdaptiveNavShell]: a sidebar
/// on wide windows, a modal drawer on phones.
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key, required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  String _section = 'foundation';

  @override
  Widget build(BuildContext context) {
    final s = DemoStrings.of(context);
    String t(String en, String id) => _t(context, en, id);
    final sections = [
      PaymentNavSection(
        title: t('Building blocks', 'Dasar'),
        items: [
          PaymentNavItem(
            id: 'foundation',
            label: t('Foundation', 'Fondasi'),
            icon: Icons.palette_outlined,
          ),
          PaymentNavItem(
            id: 'interaction',
            label: t('Interaction', 'Interaksi'),
            icon: Icons.touch_app_outlined,
          ),
          PaymentNavItem(
            id: 'controls',
            label: t('Controls', 'Kontrol'),
            icon: Icons.toggle_on_outlined,
          ),
          PaymentNavItem(
            id: 'navigation',
            label: t('Navigation', 'Navigasi'),
            icon: Icons.menu_open,
          ),
          PaymentNavItem(
            id: 'sheets',
            label: t('Sheets & drawers', 'Sheet & drawer'),
            icon: Icons.vertical_split_outlined,
          ),
          PaymentNavItem(
            id: 'media',
            label: t('Video', 'Video'),
            icon: Icons.play_circle_outline,
          ),
          PaymentNavItem(
            id: 'promo',
            label: t('Promotions', 'Promosi'),
            icon: Icons.campaign_outlined,
          ),
        ],
      ),
      PaymentNavSection(
        title: t('Payment', 'Pembayaran'),
        items: [
          const PaymentNavItem(
            id: 'checkout',
            label: 'Checkout',
            icon: Icons.shopping_cart_outlined,
          ),
          PaymentNavItem(
            id: 'status',
            label: t('Status & receipt', 'Status & struk'),
            icon: Icons.receipt_long_outlined,
          ),
          PaymentNavItem(
            id: 'history',
            label: t('History', 'Riwayat'),
            icon: Icons.history,
            badge: '2',
          ),
          PaymentNavItem(
            id: 'charts',
            label: t('Charts', 'Grafik'),
            icon: Icons.insert_chart_outlined,
          ),
          PaymentNavItem(
            id: 'kyc',
            label: t('Verification (KYC)', 'Verifikasi (KYC)'),
            icon: Icons.badge_outlined,
          ),
          PaymentNavItem(
            id: 'cards',
            label: t('Saved cards', 'Kartu tersimpan'),
            icon: Icons.credit_card,
            enabled: false,
            disabledReason: t(
              'Out of scope: no card storage',
              'Di luar cakupan: tanpa simpan kartu',
            ),
          ),
        ],
      ),
    ];
    final List<Widget> entries = switch (_section) {
      'interaction' => const [
        _ActionsDemo(),
        _FeedbackDemo(),
        _ExpandableDemo(),
        _StatesDemo(),
      ],
      'controls' => const [_ButtonsDemo(), _ChoicesDemo(), _TabsDemo()],
      'navigation' => const [_NavigationDemo()],
      'sheets' => const [_SheetsDemo()],
      'media' => const [_VideoDemo()],
      'promo' => const [_PromoDemo()],
      'checkout' => const [
        _MerchantStepsDemo(),
        _SummaryDemo(),
        _MethodsDemo(),
        _BalanceDemo(),
        _PromoCodeDemo(),
        _ActionBarDemo(),
        _AuthDemo(),
      ],
      'status' => const [_StatusDemo(), _InstructionsDemo(), _ReceiptDemo()],
      'history' => const [_HistoryDemo()],
      'charts' => const [
        _ChartDemo(kind: 'line'),
        _ChartDemo(kind: 'bar'),
        _ChartDemo(kind: 'meter'),
        _ChartDemo(kind: 'sparkline'),
        _ChartStatesDemo(),
        _SpendingInContextDemo(),
      ],
      'kyc' => const [
        _KycIntroDemo(),
        _IdentityDemo(),
        _DocumentDemo(),
        _CaptureSourceDemo(),
        _CaptureGuideDemo(),
        _KycStatusDemo(),
      ],
      _ => const [_Foundation(), _AmountTextVariantsDemo(), _AmountDemo()],
    };
    return AdaptiveNavShell(
      title: Text(s.tabGallery),
      sections: sections,
      selectedId: _section,
      onSelected: (item) => setState(() => _section = item.id),
      breakpoint: 720,
      actions: [
        IconButton(
          tooltip: s.settings,
          icon: const Icon(Icons.tune),
          onPressed: widget.onOpenSettings,
        ),
      ],
      body: ColoredBox(
        color: devWorkbench(context),
        child: SafeArea(
          // A new list per section so each one starts at the top.
          child: ListView(
            key: PageStorageKey('gallery-$_section'),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: entries,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _t(BuildContext context, String en, String id) =>
    Localizations.localeOf(context).languageCode == 'id' ? id : en;

// Gallery chrome uses its own quieter voice (see dev_chrome.dart) so it is
// never mistaken for the product: a grey workbench, class names as a small
// monospace caption, the fixture state selector outside the frame, and the
// component itself on its real surface inside the frame.

class _Entry extends StatelessWidget {
  const _Entry({required this.name, required this.child, this.states});

  final String name;
  final Widget child;
  final Widget? states;

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            // Developer-facing chrome follows text size only a little (1.2×)
            // so it never outgrows the component it documents.
            child: Text(
              name,
              textScaler: devScaler(context),
              style: devMono(theme.textSecondary),
            ),
          ),
          if (states != null) ...[const SizedBox(height: 8), states!],
          const SizedBox(height: 8),
          // A Material, not a decorated box, so list tiles and ink inside the
          // specimen paint on it.
          Material(
            color: theme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: theme.outline),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// Fixture state selector for the gallery only: one scrolling row of compact
/// monospace segments, deliberately unlike the kit's own filters and chips.
class _StatePicker<T> extends StatelessWidget {
  const _StatePicker({
    required this.values,
    required this.selected,
    required this.onSelected,
    required this.label,
  });

  final List<T> values;
  final T selected;
  final ValueChanged<T> onSelected;
  final String Function(T) label;

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final scaler = devScaler(context);
    final mono = devMono(theme.textSecondary);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ExcludeSemantics(
            child: Text('state ', style: mono, textScaler: scaler),
          ),
          for (final v in values)
            Semantics(
              selected: v == selected,
              button: true,
              child: InkWell(
                onTap: () => onSelected(v),
                borderRadius: BorderRadius.circular(6),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: v == selected ? theme.surface : null,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: v == selected
                                ? theme.textSecondary
                                : Colors.transparent,
                          ),
                        ),
                        child: Text(
                          label(v),
                          textScaler: scaler,
                          style: mono.copyWith(
                            color: v == selected
                                ? theme.textPrimary
                                : theme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

final _now = DateTime.now();

PaymentQuote _quote({bool changed = false, String methodId = 'balance'}) {
  final lines = [
    const QuoteLine(
      label: 'Paket Belajar',
      amount: Money.idr(100000),
      detail: '1 × 1 bulan',
    ),
    QuoteLine(
      label: 'Biaya layanan',
      amount: Money.idr(changed ? 3500 : 2500),
      kind: QuoteLineKind.fee,
    ),
  ];
  return PaymentQuote(
    id: 'Q-GALLERY',
    revision: changed ? 2 : 1,
    lines: lines,
    total: Money.idr(changed ? 103500 : 102500),
    expiresAt: _now.add(const Duration(minutes: 10)),
    methodId: methodId,
  );
}

class _Foundation extends StatelessWidget {
  const _Foundation();

  @override
  Widget build(BuildContext context) {
    return _Entry(
      name: 'PaymentTheme · AmountText · InfoRow · StatusBadge · PaymentButton',
      child: PaymentSection(
        title: 'Foundation',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AmountText(
              Money.idr(102500),
              variant: AmountTextVariant.display,
            ),
            const InfoRow(
              label: 'Biaya layanan',
              value: AmountText(Money.idr(2500)),
            ),
            const InfoRow(
              label: 'Nominal besar',
              value: AmountText(Money.idr(1250000000)),
            ),
            const InfoRow(
              label: 'USD (2 decimals)',
              value: AmountText(Money(1999, 'USD')),
            ),
            InfoRow(
              label: 'Ringkas (sumbu grafik)',
              value: Text(
                PaymentLocalizations.of(
                  context,
                ).moneyFormat.compact(const Money.idr(1250000000)),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tone in StatusTone.values)
                  StatusBadge(
                    tone: tone,
                    icon: Icons.circle_outlined,
                    label: tone.name,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            PaymentButton(
              label: 'Async action (2 s lock)',
              onPressed: () => Future.delayed(const Duration(seconds: 2)),
            ),
            const SizedBox(height: 8),
            const PaymentButton(
              label: 'Disabled',
              variant: PaymentButtonVariant.secondary,
              onPressed: null,
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountDemo extends StatefulWidget {
  const _AmountDemo();
  @override
  State<_AmountDemo> createState() => _AmountDemoState();
}

class _AmountDemoState extends State<_AmountDemo> {
  AmountParseResult _result = const AmountParseResult.issue(AmountIssue.empty);

  @override
  Widget build(BuildContext context) {
    return _Entry(
      name: 'AmountInput',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AmountInput(
            currency: 'IDR',
            minimum: const Money.idr(10000),
            maximum: const Money.idr(2000000),
            onChanged: (r) => setState(() => _result = r),
          ),
          const SizedBox(height: 4),
          Text(
            '→ $_result',
            textScaler: devScaler(context),
            style: devMono(PaymentTheme.of(context).textSecondary),
          ),
        ],
      ),
    );
  }
}

class _SummaryDemo extends StatefulWidget {
  const _SummaryDemo();
  @override
  State<_SummaryDemo> createState() => _SummaryDemoState();
}

class _SummaryDemoState extends State<_SummaryDemo> {
  bool _changed = false;

  @override
  Widget build(BuildContext context) {
    return _Entry(
      name: 'PaymentSummary · PaymentConfirmation',
      states: _StatePicker<bool>(
        values: const [false, true],
        selected: _changed,
        label: (v) => v ? 'quote changed' : 'stable',
        onSelected: (v) => setState(() => _changed = v),
      ),
      child: PaymentConfirmation(
        quote: _quote(changed: _changed),
        previousQuote: _changed ? _quote() : null,
        method: const PaymentMethod(
          id: 'balance',
          label: 'Saldo Ruang Bayar',
          detail: 'Saldo Rp350.000',
          kind: PaymentMethodKind.balance,
        ),
        onConfirm: () async {
          await Future<void>.delayed(const Duration(milliseconds: 500));
          if (context.mounted) {
            _galleryFeedback(
              context,
              'Confirmation received. No payment sent.',
              'Konfirmasi diterima. Tidak ada pembayaran dikirim.',
            );
          }
        },
      ),
    );
  }
}

class _MethodsDemo extends StatefulWidget {
  const _MethodsDemo();
  @override
  State<_MethodsDemo> createState() => _MethodsDemoState();
}

class _MethodsDemoState extends State<_MethodsDemo> {
  String? _selected = 'balance';
  bool _empty = false;

  static const _methods = [
    PaymentMethod(
      id: 'balance',
      label: 'Saldo Ruang Bayar',
      detail: 'Saldo Rp350.000',
      kind: PaymentMethodKind.balance,
    ),
    PaymentMethod(
      id: 'va',
      label: 'Virtual account (Bank Contoh)',
      detail: 'Bayar lewat transfer bank',
      feeNote: '+ biaya transfer Rp1.500',
      kind: PaymentMethodKind.virtualAccount,
    ),
    PaymentMethod(
      id: 'card',
      label: 'Kartu •••• 4242',
      kind: PaymentMethodKind.card,
      unavailableReason: 'Tidak diterima untuk pembelian ini',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _Entry(
      name: 'PaymentMethodPicker',
      states: _StatePicker<bool>(
        values: const [false, true],
        selected: _empty,
        label: (v) => v ? 'empty' : 'methods',
        onSelected: (v) => setState(() => _empty = v),
      ),
      child: PaymentMethodPicker(
        methods: _empty ? const [] : _methods,
        selectedId: _selected,
        onChanged: (m) => setState(() => _selected = m.id),
      ),
    );
  }
}

class _AuthDemo extends StatefulWidget {
  const _AuthDemo();
  @override
  State<_AuthDemo> createState() => _AuthDemoState();
}

class _AuthDemoState extends State<_AuthDemo> {
  AuthorizationPhase _phase = AuthorizationPhase.ready;

  @override
  Widget build(BuildContext context) {
    return _Entry(
      name: 'AuthorizationPrompt',
      states: _StatePicker(
        values: AuthorizationPhase.values,
        selected: _phase,
        label: (v) => v.name,
        onSelected: (v) => setState(() => _phase = v),
      ),
      child: AuthorizationPrompt(
        phase: _phase,
        onStart: () async {
          setState(() => _phase = AuthorizationPhase.inProgress);
          await Future<void>.delayed(const Duration(milliseconds: 500));
          if (mounted && _phase == AuthorizationPhase.inProgress) {
            setState(() => _phase = AuthorizationPhase.approved);
          }
        },
        onBackToReview: () {
          setState(() => _phase = AuthorizationPhase.ready);
          _galleryFeedback(
            context,
            'Returned to the demo review state.',
            'Kembali ke tinjauan simulasi.',
          );
        },
      ),
    );
  }
}

class _StatusDemo extends StatefulWidget {
  const _StatusDemo();
  @override
  State<_StatusDemo> createState() => _StatusDemoState();
}

class _StatusDemoState extends State<_StatusDemo> {
  String _state = 'unknown';

  static const _states = [
    'sending',
    'unknown',
    'processing',
    'pending',
    'offline',
    'succeeded',
    'failed',
    'canceled',
    'expired',
    'refund',
  ];

  PaymentAttempt _attempt() {
    const base = PaymentAttempt(
      attemptId: 'att-gallery-01',
      quoteId: 'Q-GALLERY',
      quoteRevision: 1,
      methodId: 'balance',
    );
    PaymentStatusSnapshot snap(
      PaymentStatus status,
      Set<PaymentAction> actions, {
      RefundInfo refund = const RefundInfo(status: RefundStatus.none),
    }) => PaymentStatusSnapshot(
      attemptId: base.attemptId,
      serverReference: 'TRX-004071',
      status: status,
      revision: 3,
      updatedAt: _now,
      allowedActions: actions,
      refund: refund,
    );
    return switch (_state) {
      'sending' => base.copyWith(submission: SubmissionState.sending),
      'unknown' => base.copyWith(submission: SubmissionState.outcomeUnknown),
      'processing' =>
        base
            .reconcile(
              snap(PaymentStatus.processing, {PaymentAction.checkStatus}),
            )
            .attempt,
      'pending' =>
        base
            .reconcile(
              snap(PaymentStatus.pending, {
                PaymentAction.checkStatus,
                PaymentAction.requestCancel,
              }),
            )
            .attempt,
      'offline' =>
        base
            .reconcile(snap(PaymentStatus.pending, {PaymentAction.checkStatus}))
            .attempt
            .copyWith(
              observation: Observation.unavailable,
              lastCheckedAt: _now,
            ),
      'succeeded' =>
        base
            .reconcile(
              snap(PaymentStatus.succeeded, {PaymentAction.viewReceipt}),
            )
            .attempt,
      'failed' =>
        base
            .reconcile(
              snap(PaymentStatus.failed, {
                PaymentAction.startNewAttempt,
                PaymentAction.contactSupport,
              }),
            )
            .attempt,
      'canceled' =>
        base
            .reconcile(
              snap(PaymentStatus.canceled, {PaymentAction.startNewAttempt}),
            )
            .attempt,
      'expired' =>
        base
            .reconcile(
              snap(PaymentStatus.expired, {PaymentAction.startNewAttempt}),
            )
            .attempt,
      _ =>
        base
            .reconcile(
              snap(
                PaymentStatus.succeeded,
                {PaymentAction.viewReceipt},
                refund: const RefundInfo(
                  status: RefundStatus.partial,
                  amount: Money.idr(50000),
                ),
              ),
            )
            .attempt,
    };
  }

  @override
  Widget build(BuildContext context) {
    return _Entry(
      name: 'PaymentStatusView · RefundSection',
      states: _StatePicker(
        values: _states,
        selected: _state,
        label: (v) => v,
        onSelected: (v) => setState(() => _state = v),
      ),
      child: PaymentStatusView(
        attempt: _attempt(),
        amount: const Money.idr(102500),
        onAction: (action) => _galleryFeedback(
          context,
          'Demo host received: ${action.name}. No payment sent.',
          'Host simulasi menerima: ${action.name}. Tidak ada pembayaran dikirim.',
        ),
      ),
    );
  }
}

class _InstructionsDemo extends StatelessWidget {
  const _InstructionsDemo();

  @override
  Widget build(BuildContext context) {
    return _Entry(
      name: 'PaymentInstructions · CountdownText',
      child: PaymentInstructions(
        instructions: VirtualAccountInstructions(
          providerLabel: 'Bank Contoh — Virtual Account',
          accountNumber: '8808 0012 3456 7890',
          amount: const Money.idr(104000),
          expiresAt: _now.add(const Duration(hours: 23, minutes: 59)),
          steps: const ['Buka aplikasi bank.', 'Transfer ke nomor di atas.'],
        ),
        clock: DateTime.now,
        onCopyNumber: _copyGalleryValue,
      ),
    );
  }
}

class _ReceiptDemo extends StatelessWidget {
  const _ReceiptDemo();

  @override
  Widget build(BuildContext context) {
    return _Entry(
      name: 'PaymentReceipt',
      child: PaymentReceipt(
        data: PaymentReceiptData(
          transactionId: 'TRX-004071',
          merchantName: 'Ruang Bayar Akademi',
          paidAt: _now,
          lines: _quote().lines,
          total: const Money.idr(102500),
          methodLabel: 'Saldo Ruang Bayar •••• 2190',
        ),
        onShare: (data) async {
          await showPaymentSheet<void>(
            context: context,
            builder: (sheet) => PaymentSheet(
              header: PaymentSheetHeader(
                title: _t(
                  context,
                  'Synthetic receipt preview',
                  'Pratinjau struk sintetis',
                ),
                onClose: () => Navigator.pop(sheet),
              ),
              body: SelectableText(data.text),
            ),
          );
          return ShareOutcome.dismissed;
        },
        onCopyTransactionId: _copyGalleryValue,
      ),
    );
  }
}

class _KycIntroDemo extends StatelessWidget {
  const _KycIntroDemo();

  @override
  Widget build(BuildContext context) {
    final s = DemoStrings.of(context);
    return _Entry(
      name: 'VerificationIntro',
      child: VerificationIntro(
        requirements: [
          DataRequirement(
            title: s.reqIdentityTitle,
            purpose: s.reqIdentityPurpose,
          ),
          DataRequirement(title: s.reqIdTitle, purpose: s.reqIdPurpose),
        ],
        onOpenPolicy: () => showPaymentSheet<void>(
          context: context,
          builder: (sheet) => PaymentSheet(
            header: PaymentSheetHeader(
              title: _t(context, 'Demo data policy', 'Kebijakan data demo'),
              onClose: () => Navigator.pop(sheet),
            ),
            body: Text(
              _t(
                context,
                'Use synthetic identity only. This gallery sends no identity or documents to a server.',
                'Gunakan identitas sintetis saja. Galeri tidak mengirim identitas atau dokumen ke server.',
              ),
            ),
          ),
        ),
        onContinue: () => _galleryFeedback(
          context,
          'Consent received. Try the identity form below.',
          'Persetujuan diterima. Coba formulir identitas di bawah.',
        ),
      ),
    );
  }
}

class _IdentityDemo extends StatelessWidget {
  const _IdentityDemo();

  @override
  Widget build(BuildContext context) {
    return _Entry(
      name: 'IdentityForm · VerificationReview',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IdentityForm(
            fields: identityFields(DemoStrings.of(context)),
            onSubmit: (_) => _galleryFeedback(
              context,
              'Demo form validated. No identity submitted.',
              'Formulir demo valid. Identitas tidak dikirim.',
            ),
          ),
          const SizedBox(height: 16),
          VerificationReview(
            fields: identityFields(DemoStrings.of(context)),
            values: const {
              'name': 'Đặng Thị Ngọc Ánh (Demo)',
              'nik': '3100000000001234',
              'dob': '17-08-1995',
            },
            documents: [
              for (final (i, r) in documentRequirements(
                DemoStrings.of(context),
              ).indexed)
                (
                  r,
                  DocumentSlotState.uploaded(
                    demoFixtures[i].file,
                    requestId: 'g$i',
                  ),
                ),
            ],
            onSubmit: () async {
              _galleryFeedback(
                context,
                'Review callback received. Use Demo for the full KYC journey.',
                'Tinjauan diterima. Gunakan tab Demo untuk alur KYC lengkap.',
              );
            },
            onEditDetails: () => _galleryFeedback(
              context,
              'Edit the identity form above.',
              'Ubah formulir identitas di atas.',
            ),
            onEditDocuments: () => _galleryFeedback(
              context,
              'Use the document fixture tile below.',
              'Gunakan pilihan dokumen sintetis di bawah.',
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentDemo extends StatefulWidget {
  const _DocumentDemo();
  @override
  State<_DocumentDemo> createState() => _DocumentDemoState();
}

class _DocumentDemoState extends State<_DocumentDemo> {
  String _state = 'empty';

  static final _states = <String, DocumentSlotState>{
    'empty': const DocumentSlotState.empty(),
    'uploading': DocumentSlotState.uploading(
      demoFixtures[0].file,
      requestId: 'g1',
      progress: 0.4,
    ),
    'uploaded': DocumentSlotState.uploaded(
      demoFixtures[0].file,
      requestId: 'g1',
    ),
    'denied': const DocumentSlotState.failed(
      DocumentIssue(DocumentIssueKind.permissionDenied),
    ),
    'blocked': const DocumentSlotState.failed(
      DocumentIssue(
        DocumentIssueKind.permissionPermanentlyDenied,
        canRetry: false,
        canOpenSettings: true,
      ),
    ),
    'tooLarge': DocumentSlotState.failed(
      const DocumentIssue(DocumentIssueKind.tooLarge),
      file: demoFixtures[2].file,
    ),
    'interrupted': DocumentSlotState.failed(
      const DocumentIssue(DocumentIssueKind.uploadInterrupted),
      file: demoFixtures[0].file,
    ),
  };

  @override
  Widget build(BuildContext context) {
    return _Entry(
      name: 'DocumentUploadTile',
      states: _StatePicker(
        values: _states.keys.toList(),
        selected: _state,
        label: (v) => v,
        onSelected: (v) => setState(() => _state = v),
      ),
      child: DocumentUploadTile(
        requirement: documentRequirements(DemoStrings.of(context)).first,
        state: _states[_state]!,
        onPick: () => setState(() => _state = 'uploaded'),
        onOpenSettings: () {
          setState(() => _state = 'empty');
          _galleryFeedback(
            context,
            'Demo capture permission restored.',
            'Izin dokumen simulasi dipulihkan.',
          );
        },
      ),
    );
  }
}

class _KycStatusDemo extends StatefulWidget {
  const _KycStatusDemo();
  @override
  State<_KycStatusDemo> createState() => _KycStatusDemoState();
}

class _KycStatusDemoState extends State<_KycStatusDemo> {
  VerificationStatus? _status = VerificationStatus.inReview;

  @override
  Widget build(BuildContext context) {
    final status = _status;
    return _Entry(
      name: 'VerificationStatusView',
      states: _StatePicker<VerificationStatus?>(
        values: [...VerificationStatus.values, null],
        selected: status,
        label: (v) => v?.name ?? 'unknown (timeout)',
        onSelected: (v) => setState(() => _status = v),
      ),
      child: VerificationStatusView(
        snapshot: VerificationSnapshot(
          status: status ?? VerificationStatus.inReview,
          updatedAt: _now,
          allowedActions: switch (status) {
            VerificationStatus.notStarted ||
            VerificationStatus.expired => {VerificationAction.start},
            VerificationStatus.inReview => {VerificationAction.checkStatus},
            VerificationStatus.actionRequired => {
              VerificationAction.fixDetails,
              VerificationAction.contactSupport,
            },
            VerificationStatus.verified => {
              VerificationAction.continueToPayment,
            },
            VerificationStatus.rejected => {VerificationAction.contactSupport},
            null => const {},
          },
        ),
        outcomeUnknown: status == null,
        onAction: (action) => _galleryFeedback(
          context,
          'Demo host received: ${action.name}. No identity submitted.',
          'Host simulasi menerima: ${action.name}. Identitas tidak dikirim.',
        ),
      ),
    );
  }
}
