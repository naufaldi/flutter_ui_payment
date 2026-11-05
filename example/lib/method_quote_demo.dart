import 'package:flutter/material.dart';
import 'package:rakit_ui/rakit_ui.dart';

import 'block_demo_shell.dart';
import 'compositions/method_quote_block.dart';

void main() => runBlockDemo(const MethodQuoteDemo());

enum MethodQuoteScenario { normal, repriced, quoteError }

final methodQuoteNow = DateTime(2026, 11, 4, 10, 42);

const methodQuoteMethods = [
  PaymentMethod(
    id: 'balance',
    label: 'Saldo Ruang Bayar',
    kind: PaymentMethodKind.balance,
    detail: 'Saldo Rp400.000',
    feeNote: 'Tanpa biaya',
  ),
  PaymentMethod(
    id: 'va',
    label: 'Virtual account',
    kind: PaymentMethodKind.virtualAccount,
    detail: 'Bank Demo',
    feeNote: 'Biaya bank Rp4.000',
  ),
  PaymentMethod(
    id: 'qris',
    label: 'QRIS',
    kind: PaymentMethodKind.eWallet,
    feeNote: 'Biaya layanan 0,7%',
  ),
  PaymentMethod(
    id: 'card',
    label: 'Kartu kredit',
    kind: PaymentMethodKind.card,
    unavailableReason: 'Belum didukung merchant ini',
  ),
];

/// Synthetic pricing table. A real host asks its server for every quote.
PaymentQuote methodQuoteFixture(String methodId, {int revision = 1}) {
  final fee = switch (methodId) {
    'va' => revision > 1 ? 5000 : 4000,
    'qris' => 1750,
    _ => 0,
  };
  return PaymentQuote(
    id: 'QUOTE-DEMO-218-$methodId',
    revision: revision,
    methodId: methodId,
    lines: [
      const QuoteLine(label: 'Paket Belajar Pro', amount: Money.idr(250000)),
      if (fee > 0)
        QuoteLine(
          label: methodId == 'va' ? 'Biaya bank' : 'Biaya layanan',
          amount: Money.idr(fee),
          kind: QuoteLineKind.fee,
        ),
    ],
    total: Money.idr(250000 + fee),
    expiresAt: methodQuoteNow.add(const Duration(minutes: 10)),
  );
}

/// Host answer to a submit: accepted, or the server re-priced the order.
typedef MethodSubmitAnswer = ({bool accepted, PaymentQuote? newQuote});

/// Synthetic checkout host. No payment, authorization or network happens;
/// delays only make the busy states visible.
class MethodQuoteDemo extends StatefulWidget {
  const MethodQuoteDemo({
    super.key,
    this.initialScenario = MethodQuoteScenario.normal,
    this.initialDark = false,
    this.quoteFor,
    this.delay = const Duration(milliseconds: 500),
  });
  final MethodQuoteScenario initialScenario;
  final bool initialDark;

  /// Replaces the fixture pricing, e.g. to control answer order in tests.
  final Future<PaymentQuote> Function(String methodId)? quoteFor;
  final Duration delay;

  @override
  State<MethodQuoteDemo> createState() => _MethodQuoteDemoState();
}

class _MethodQuoteDemoState extends State<MethodQuoteDemo> {
  late bool dark = widget.initialDark;
  late MethodQuoteScenario scenario = widget.initialScenario;
  MethodQuoteStep step = MethodQuoteStep.choose;
  String? selectedId;
  PaymentQuote? quote;
  PaymentQuote? previousQuote;
  bool quoting = false;
  String? quoteError;
  bool submitting = false;
  bool submitted = false;
  int quoteRequest = 0;
  int quoteCalls = 0;
  int submits = 0;
  int generation = 0;

  void reset(MethodQuoteScenario value) => setState(() {
    generation++;
    scenario = value;
    step = MethodQuoteStep.choose;
    selectedId = null;
    quote = previousQuote = quoteError = null;
    quoting = submitting = submitted = false;
    quoteCalls = submits = 0;
  });

  Future<PaymentQuote> fixtureQuote(String methodId) async {
    await Future<void>.delayed(widget.delay);
    if (scenario == MethodQuoteScenario.quoteError && quoteCalls == 1) {
      throw StateError('Synthetic pricing failure');
    }
    return methodQuoteFixture(methodId);
  }

  Future<void> select(PaymentMethod method) async {
    if (submitting) return;
    // Every request gets a number; only the newest may update the screen.
    final request = ++quoteRequest;
    final current = generation;
    quoteCalls++;
    setState(() {
      selectedId = method.id;
      quoting = true;
      quoteError = null;
      previousQuote = null;
    });
    try {
      final answer = await (widget.quoteFor ?? fixtureQuote)(method.id);
      if (!mounted || current != generation || request != quoteRequest) {
        return;
      }
      setState(() {
        quoting = false;
        quote = answer;
      });
    } catch (_) {
      if (!mounted || current != generation || request != quoteRequest) {
        return;
      }
      setState(() {
        quoting = false;
        quote = null;
        quoteError = 'Periksa koneksi, lalu coba lagi.';
      });
    }
  }

  Future<void> confirm() async {
    final approved = quote;
    if (submitting || approved == null) return;
    final current = generation;
    setState(() => submitting = true);
    await Future<void>.delayed(widget.delay);
    if (!mounted || current != generation) return;
    // The host re-validates the approved quote; the fixture re-prices the
    // first VA submit in the "changed" scenario.
    final answer =
        scenario == MethodQuoteScenario.repriced &&
            approved.methodId == 'va' &&
            submits++ == 0
        ? (
            accepted: false,
            newQuote: methodQuoteFixture('va', revision: approved.revision + 1),
          )
        : (accepted: true, newQuote: null);
    setState(() {
      submitting = false;
      if (answer.newQuote case final next?) {
        previousQuote = approved;
        quote = next;
      } else {
        submitted = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) => BlockDemoShell(
    title: 'Pembayaran · Demo',
    dark: dark,
    onToggleDark: () => setState(() => dark = !dark),
    scenarios: [
      for (final (value, label) in [
        (MethodQuoteScenario.normal, 'Harga tetap'),
        (MethodQuoteScenario.repriced, 'Biaya VA berubah saat bayar'),
        (MethodQuoteScenario.quoteError, 'Biaya gagal dihitung'),
      ])
        (label: label, onSelected: () => reset(value)),
    ],
    body: (context) => submitted
        ? PaymentStatusView(
            key: ValueKey('done-$generation'),
            attempt: PaymentAttempt(
              attemptId: 'PAY-DEMO-218',
              quoteId: quote!.id,
              quoteRevision: quote!.revision,
              methodId: quote!.methodId!,
              submission: SubmissionState.accepted,
              snapshot: PaymentStatusSnapshot(
                attemptId: 'PAY-DEMO-218',
                serverReference: 'TX-DEMO-218',
                status: PaymentStatus.processing,
                revision: 1,
                updatedAt: methodQuoteNow,
                safeReason:
                    'Total yang Anda setujui diteruskan ke host untuk '
                    'otorisasi. Demo berhenti di sini.',
              ),
            ),
            amount: quote!.total,
            onAction: (_) {},
            secondaryAction: PaymentButton(
              label: 'Mulai ulang demo',
              variant: PaymentButtonVariant.quiet,
              onPressed: () => reset(scenario),
            ),
          )
        : MethodQuoteBlock(
            key: ValueKey(generation),
            title: 'Paket Belajar Pro',
            step: step,
            methods: methodQuoteMethods,
            selectedId: selectedId,
            quote: quote,
            previousQuote: previousQuote,
            quoting: quoting,
            quoteError: quoteError,
            submitting: submitting,
            onSelect: select,
            onRetryQuote: () => select(
              methodQuoteMethods.firstWhere((m) => m.id == selectedId),
            ),
            onContinue: () => setState(() => step = MethodQuoteStep.review),
            onChangeMethod: () => setState(() {
              step = MethodQuoteStep.choose;
              previousQuote = null;
            }),
            onConfirm: confirm,
          ),
  );
}
