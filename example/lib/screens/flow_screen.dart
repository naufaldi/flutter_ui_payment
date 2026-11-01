import 'steps/transaction_detail_step.dart';
import 'steps/statement_step.dart';
import 'steps/fees_step.dart';
import 'steps/account_settings_step.dart';
export 'steps/kyc_fields.dart';
import 'steps/kyc_onboarding_step.dart';
import 'steps/sign_in_step.dart';
import 'steps/history_step.dart';
import 'steps/order_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';

import '../coordinator/demo_coordinator.dart';
import '../demo_strings.dart';
import '../dev_chrome.dart';

/// The demo purchase flow. Renders [DemoCoordinator] state step by step and
/// forwards every user intent to it; no business state lives here.
class FlowScreen extends StatelessWidget {
  const FlowScreen({
    super.key,
    required this.coordinator,
    required this.scenarioLabel,
    required this.onRestart,
    required this.onBackground,
    required this.onOpenSettings,
  });

  final DemoCoordinator coordinator;
  final String scenarioLabel;
  final VoidCallback onRestart;
  final VoidCallback onBackground;

  /// Opens the settings sheet with a "Demo tools" entry, so the app bar keeps
  /// at most two trailing actions and step titles fit (P7a).
  final void Function(VoidCallback demoTools) onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: coordinator,
      builder: (context, _) {
        final c = coordinator;
        final s = DemoStrings.of(context);
        final atRoot = c.step == FlowStep.overview || c.step == FlowStep.signIn;
        final view = _isViewStep(c.step) && !c.starting;
        final title = _ownHeader(c) ? null : _title(s, c.step);
        final titleLines = title == null
            ? 1
            : _appBarTitleLines(
                context,
                title,
                leading: !atRoot,
                actions: c.signedIn ? 2 : 1,
              );
        return PopScope(
          canPop: atRoot,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _handleBack(context, c);
          },
          child: Scaffold(
            appBar: AppBar(
              // A title that doesn't fit on one line wraps to two in a
              // taller bar instead of ending in "…" (#80).
              toolbarHeight: titleLines == 1
                  ? null
                  : kToolbarHeight + _appBarTitleLine(context),
              leading: atRoot
                  ? null
                  : BackButton(onPressed: () => _handleBack(context, c)),
              title: title == null
                  ? null
                  : Text(title, maxLines: titleLines, softWrap: true),
              actions: [
                if (c.signedIn) _AccountMenu(coordinator: c),
                IconButton(
                  key: const Key('settings'),
                  tooltip: s.settings,
                  icon: const Icon(Icons.tune),
                  onPressed: () => onOpenSettings(
                    () => _showDemoTools(
                      context,
                      coordinator: c,
                      scenarioLabel: scenarioLabel,
                      onRestart: onRestart,
                      onBackground: onBackground,
                    ),
                  ),
                ),
              ],
            ),
            // Checkout pins its action under the list; the other payment
            // steps pin theirs inside the step (D62).
            bottomNavigationBar:
                c.step == FlowStep.checkout && !c.starting && !c.obscured
                ? _CheckoutBar(c)
                : null,
            // A view step's pinned footer pads the bottom inset itself.
            body: SafeArea(
              bottom: !view,
              child: PrivacyMask(
                obscured: c.obscured,
                // Each step enters with a short fade and 8 px rise; the
                // previous step leaves faster. Collapses under reduced motion.
                child: AnimatedSwitcher(
                  duration: PaymentMotion.of(context).enter,
                  reverseDuration: PaymentMotion.of(context).exit,
                  transitionBuilder: PaymentMotion.fadeRise,
                  layoutBuilder: PaymentMotion.topLayout,
                  child: view
                      ? SizedBox.expand(
                          key: ValueKey('flow-view-${c.step.name}'),
                          child: _StepBody(coordinator: c),
                        )
                      : ListView(
                          key: ValueKey('flow-list-${c.step.name}'),
                          // At 600 dp and wider the steps sit in a centred
                          // 640 dp column; the scrollbar stays at the
                          // window edge (D53).
                          padding: EdgeInsets.fromLTRB(
                            16 + listInset(context, c.step),
                            8,
                            16 + listInset(context, c.step),
                            24,
                          ),
                          children: [
                            if (c.starting)
                              Padding(
                                padding: const EdgeInsets.all(32),
                                child: Center(child: Text(s.loading)),
                              )
                            else
                              _StepBody(coordinator: c),
                          ],
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _title(DemoStrings s, FlowStep step) => switch (step) {
    FlowStep.overview => s.appName,
    FlowStep.signIn => s.appName,
    FlowStep.history => s.transactions,
    FlowStep.transactionDetail ||
    FlowStep.statement ||
    FlowStep.fees ||
    FlowStep.accountSettings => s.yourAccount,
    FlowStep.kycIntro => s.stepConsent,
    FlowStep.kycIdentity => s.stepIdentity,
    FlowStep.kycDocuments => s.stepDocuments,
    FlowStep.kycReview => s.stepReview,
    FlowStep.kycStatus => s.stepStatus,
    FlowStep.checkout => s.stepCheckout,
    FlowStep.confirm => s.stepConfirm,
    FlowStep.authorize => s.stepAuthorize,
    FlowStep.payment => s.stepPayment,
    FlowStep.receipt => s.stepReceipt,
  };

  Future<void> _handleBack(BuildContext context, DemoCoordinator c) async {
    switch (c.step) {
      case FlowStep.signIn:
      case FlowStep.overview:
        return;
      case FlowStep.transactionDetail:
        c.closeDetail();
      case FlowStep.history ||
          FlowStep.statement ||
          FlowStep.fees ||
          FlowStep.accountSettings:
        c.goHome();
      case FlowStep.kycIntro || FlowStep.kycStatus || FlowStep.checkout:
        c.goHome();
      case FlowStep.kycIdentity:
        c.kyc.status == VerificationStatus.actionRequired
            ? c.kycAction(VerificationAction.start)
            : c.goHome();
      case FlowStep.kycDocuments:
        c.editIdentity();
      case FlowStep.kycReview:
        c.editDocuments();
      case FlowStep.confirm:
        await c.openCheckout();
      case FlowStep.authorize:
        if (c.authPhase != AuthorizationPhase.inProgress) c.backToReview();
      case FlowStep.receipt:
        c.resumeAttempt();
      case FlowStep.payment:
        if (!c.hasUnresolvedAttempt) {
          c.finish();
          return;
        }
        final s = DemoStrings.of(context);
        final leave = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(s.leaveTitle),
            content: Text(s.leaveMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(s.stay),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(s.leave),
              ),
            ],
          ),
        );
        if (leave == true) c.goHome();
    }
  }
}

class _AccountMenu extends StatelessWidget {
  const _AccountMenu({required this.coordinator});

  final DemoCoordinator coordinator;

  @override
  Widget build(BuildContext context) {
    final s = DemoStrings.of(context);
    return PopupMenuButton<String>(
      key: const Key('account-menu'),
      tooltip: s.switchAccount,
      // Demo control for switching the signed-in test account: a plain
      // outlined initial, not a tinted avatar that implies a real profile.
      icon: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: PaymentTheme.of(context).outline),
        ),
        child: Text(
          coordinator.account,
          semanticsLabel: s.account(coordinator.account),
          // Developer chrome: capped near the AppBar title's own limit so
          // the initial never outgrows its circle.
          textScaler: MediaQuery.textScalerOf(
            context,
          ).clamp(maxScaleFactor: 1.3),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: PaymentTheme.of(context).textPrimary,
          ),
        ),
      ),
      onSelected: coordinator.switchAccount,
      itemBuilder: (context) => [
        for (final id in const ['A', 'B'])
          CheckedPopupMenuItem(
            key: Key('account-$id'),
            value: id,
            checked: coordinator.account == id,
            child: Text(s.account(id)),
          ),
      ],
    );
  }
}

class _StepBody extends StatelessWidget {
  const _StepBody({required this.coordinator});

  final DemoCoordinator coordinator;

  @override
  Widget build(BuildContext context) {
    final c = coordinator;
    return switch (c.step) {
      FlowStep.overview => _Overview(c),
      FlowStep.signIn => SignInStep(c),
      FlowStep.history => HistoryStep(c),
      FlowStep.transactionDetail => TransactionDetailStep(c),
      FlowStep.statement => StatementStep(c),
      FlowStep.fees => FeesStep(c),
      FlowStep.accountSettings => AccountSettingsStep(c),
      FlowStep.kycIntro => _KycIntro(c),
      FlowStep.kycIdentity ||
      FlowStep.kycDocuments ||
      FlowStep.kycReview => KycOnboardingStep(c),
      FlowStep.kycStatus => VerificationStatusView(
        header: _supportNotice(context, c),
        snapshot: c.kyc,
        outcomeUnknown: c.kycOutcomeUnknown,
        busyAction: c.kycBusyAction,
        onAction: c.kycAction,
      ),
      FlowStep.checkout => _Checkout(c),
      FlowStep.confirm => _Confirm(c),
      FlowStep.authorize => _Authorize(c),
      FlowStep.payment => _Payment(c),
      FlowStep.receipt => _Receipt(c),
    };
  }
}

class _Overview extends StatelessWidget {
  const _Overview(this.c);
  final DemoCoordinator c;

  @override
  Widget build(BuildContext context) {
    final s = DemoStrings.of(context);
    final l10n = PaymentLocalizations.of(context);
    final theme = PaymentTheme.of(context);
    final text = Theme.of(context).textTheme;
    final flexible = c.config.flexibleAmount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PaymentBanner(
          tone: StatusTone.info,
          icon: Icons.science_outlined,
          title: s.simulated,
        ),
        const SizedBox(height: 16),
        if (c.hasUnresolvedAttempt || c.attempt != null) ...[
          PaymentBanner(
            tone: StatusTone.warning,
            icon: Icons.receipt_long_outlined,
            title: s.unresolvedTitle,
            message: s.unresolvedMessage,
            actions: [
              PaymentButton(
                onPressed: c.resumeAttempt,
                label: s.openPayment,
                variant: PaymentButtonVariant.secondary,
                width: PaymentWidth.hug,
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        PaymentSection(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product thumbnail: a plain muted tile. The demo has no product
              // photography, and a gradient would only decorate the gap.
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.surfaceMuted,
                  borderRadius: BorderRadius.circular(theme.radius * 0.75),
                ),
                child: Icon(
                  flexible ? Icons.savings_outlined : Icons.school_outlined,
                  size: 24,
                  color: theme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                flexible ? s.topUpTitle : s.productTitle,
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                s.productSubtitle,
                style: text.bodyMedium?.copyWith(color: theme.textSecondary),
              ),
              if (!flexible) ...[
                const SizedBox(height: 12),
                const AmountText(
                  Money.idr(100000),
                  variant: AmountTextVariant.display,
                ),
              ],
              const SizedBox(height: 8),
              InfoRow(
                label: s.identityStatus,
                value: c.config.kycRequired
                    ? PaymentBadge(
                        tone: c.kyc.status == VerificationStatus.verified
                            ? StatusTone.success
                            : StatusTone.neutral,
                        icon: c.kyc.status == VerificationStatus.verified
                            ? Icons.verified_outlined
                            : Icons.badge_outlined,
                        label: l10n.kycStatusTitle(c.kyc.status),
                      )
                    : Text(s.kycNotRequired, textAlign: TextAlign.end),
              ),
              const SizedBox(height: 12),
              PaymentButton(
                key: const Key('buy'),
                label: flexible ? s.topUpNow : s.buyNow,
                onPressed: c.beginPurchase,
              ),
            ],
          ),
        ),
        PaymentSection(
          title: s.yourAccount,
          child: PaymentList(
            children: [
              PaymentListItem(
                icon: Icons.receipt_long_outlined,
                title: s.transactions,
                onPressed: c.openHistory,
              ),
              PaymentListItem(
                icon: Icons.description_outlined,
                title: s.statement,
                onPressed: c.openStatement,
              ),
              PaymentListItem(
                icon: Icons.sell_outlined,
                title: s.fees,
                onPressed: c.openFees,
              ),
              PaymentListItem(
                icon: Icons.settings_outlined,
                title: s.accountSettings,
                onPressed: c.openAccountSettings,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KycIntro extends StatelessWidget {
  const _KycIntro(this.c);
  final DemoCoordinator c;

  @override
  Widget build(BuildContext context) {
    final s = DemoStrings.of(context);
    return VerificationIntro(
      requirements: [
        DataRequirement(
          title: s.reqIdentityTitle,
          purpose: s.reqIdentityPurpose,
        ),
        DataRequirement(title: s.reqIdTitle, purpose: s.reqIdPurpose),
        DataRequirement(title: s.reqSelfieTitle, purpose: s.reqSelfiePurpose),
      ],
      onOpenPolicy: () => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.policyOpened))),
      onContinue: c.acceptConsent,
    );
  }
}

class _Checkout extends StatelessWidget {
  const _Checkout(this.c);
  final DemoCoordinator c;

  @override
  Widget build(BuildContext context) {
    final s = DemoStrings.of(context);
    final quote = c.quote;
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (c.config.flexibleAmount) ...[
          PaymentSection(
            title: s.topUpTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PaymentCurrencyField(
                  key: const Key('amount'),
                  currency: 'IDR',
                  minimum: const Money.idr(10000),
                  maximum: const Money.idr(2000000),
                  onChanged: c.setAmount,
                ),
                const SizedBox(height: 12),
                PaymentButton(
                  key: const Key('get-quote'),
                  label: s.getQuote,
                  variant: PaymentButtonVariant.secondary,
                  busy: c.quoting,
                  onPressed: c.amount.isValid && c.selectedMethod != null
                      ? c.loadQuote
                      : null,
                ),
              ],
            ),
          ),
        ],
        if (c.quoteError != null) ...[
          PaymentBanner(
            tone: StatusTone.danger,
            announce: true,
            title: s.quoteFailedTitle,
            message: c.quoteError!.safeMessage,
            actions: [
              PaymentButton(
                key: const Key('retry-quote'),
                onPressed: c.quoting ? null : c.loadQuote,
                label: s.retry,
                variant: PaymentButtonVariant.secondary,
                width: PaymentWidth.hug,
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        // While a re-quote runs, the pinned button says "Updating total…"
        // and is busy; the summary is not dimmed, which would need
        // an offscreen layer over the whole card on every method switch.
        if (quote != null)
          PaymentSummary(quote: quote)
        else if (c.quoting)
          const PaymentSection(child: LoadingSkeleton(rows: 3, leading: false)),
        // Sections stack flush: their own padding gives the 24 dp gap.
        PaymentMethodPicker(
          methods: c.methods,
          selectedId: c.selectedMethodId,
          onChanged: c.selectMethod,
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, k) => k.maxWidth < 840
          ? body
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: PaymentTheme.of(context).space(PaymentSpace.section),
              children: [
                Expanded(child: body),
                SizedBox(width: 360, child: OrderContext(c)),
              ],
            ),
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar(this.c);
  final DemoCoordinator c;

  @override
  Widget build(BuildContext context) {
    final s = DemoStrings.of(context);
    final quote = c.quote;
    // The summary already shows the total twice, so the bar holds only the
    // action: compact at 200% text on a small phone (#64, #58).
    return PaymentActionBar(
      action: PaymentButton(
        key: const Key('review-order'),
        label: s.reviewAndPay,
        busy: c.quoting,
        busyLabel: PaymentLocalizations.of(context).updatingTotal,
        onPressed: quote != null && c.selectedMethod != null && !c.quoting
            ? c.reviewOrder
            : null,
      ),
    );
  }
}

class _Confirm extends StatelessWidget {
  const _Confirm(this.c);
  final DemoCoordinator c;

  @override
  Widget build(BuildContext context) {
    final s = DemoStrings.of(context);
    final error = c.submitError;
    return PaymentConfirmation(
      header: error == null
          ? null
          : PaymentBanner(
              tone: StatusTone.warning,
              announce: true,
              icon: Icons.lock_clock_outlined,
              title: error.category == HostErrorCategory.sessionExpired
                  ? s.sessionExpiredTitle
                  : s.quoteFailedTitle,
              message: error.safeMessage,
            ),
      quote: c.quote!,
      method: c.selectedMethod!,
      previousQuote: c.previousQuote,
      busy: c.confirming,
      footnote: s.confirmFootnote,
      onConfirm: c.confirm,
    );
  }
}

class _Authorize extends StatelessWidget {
  const _Authorize(this.c);
  final DemoCoordinator c;

  @override
  Widget build(BuildContext context) {
    final l10n = PaymentLocalizations.of(context);
    final theme = PaymentTheme.of(context);
    return AuthorizationPrompt(
      phase: c.authPhase,
      onStart: c.authorize,
      onBackToReview: c.backToReview,
      header: PaymentSection(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The one display amount, left-aligned under a caption rather
            // than squeezed into the end of a row.
            Text(
              l10n.totalLabel,
              style: TextStyle(
                fontSize: 13,
                height: 18 / 13,
                letterSpacing: 0,
                color: theme.textSecondary,
              ),
            ),
            SizedBox(height: theme.spacing * 0.5),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: AmountText(
                c.quote!.total,
                variant: AmountTextVariant.display,
              ),
            ),
            InfoRow(
              label: l10n.payWithTitle,
              valueText: c.selectedMethod?.label ?? '',
            ),
          ],
        ),
      ),
    );
  }
}

class _Payment extends StatelessWidget {
  const _Payment(this.c);
  final DemoCoordinator c;

  @override
  Widget build(BuildContext context) {
    final s = DemoStrings.of(context);
    final attempt = c.attempt;
    if (attempt == null) return const SizedBox.shrink();
    final instructions = attempt.snapshot?.instructions;
    final status = attempt.status;
    final support = _supportNotice(context, c);
    final canceling = c.cancelRequested && !(status?.isTerminal ?? false);
    return PaymentStatusView(
      header: support == null && !canceling
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                ?support,
                if (canceling)
                  PaymentBanner(
                    tone: StatusTone.info,
                    announce: true,
                    title: s.cancelRequestedTitle,
                    message: s.cancelRequestedMessage,
                  ),
              ],
            ),
      attempt: attempt,
      amount: c.attemptAmount,
      busyAction: c.busyAction,
      onAction: c.paymentAction,
      instructions: instructions != null && c.showInstructions
          ? PaymentInstructions(
              instructions: instructions,
              clock: c.host.clock,
              onCopyNumber: c.copy,
              onElapsed: c.onInstructionsElapsed,
            )
          : null,
      secondaryAction: status != null && status.isTerminal
          ? PaymentButton(
              key: const Key('done'),
              label: s.done,
              variant: PaymentButtonVariant.quiet,
              onPressed: c.finish,
            )
          : null,
    );
  }
}

class _Receipt extends StatelessWidget {
  const _Receipt(this.c);
  final DemoCoordinator c;

  @override
  Widget build(BuildContext context) {
    final s = DemoStrings.of(context);
    final receipt = c.receipt;
    if (receipt != null) {
      // "Done" ends the purchase, so it is the one primary (#49-1); sharing
      // stays with the receipt as a hug button.
      return PaymentFullPageView(
        title: s.stepReceipt,
        primaryAction: PaymentButton(
          key: const Key('receipt-done'),
          label: s.done,
          onPressed: c.finish,
        ),
        secondaryAction: PaymentButton(
          key: const Key('receipt-details'),
          label: s.viewDetails,
          variant: PaymentButtonVariant.quiet,
          onPressed: c.openCurrentDetail,
        ),
        child: PaymentReceipt(
          data: receipt,
          onShare: c.share,
          onCopyTransactionId: c.copy,
        ),
      );
    }
    return PaymentStatusView(
      header: c.receiptError == null
          ? null
          : PaymentBanner(
              tone: StatusTone.warning,
              announce: true,
              title: s.receiptLoadFailedTitle,
              message: s.receiptLoadFailedMessage,
              actions: [
                PaymentButton(
                  key: const Key('retry-receipt'),
                  onPressed: c.loadingReceipt ? null : c.loadReceipt,
                  label: s.retry,
                  variant: PaymentButtonVariant.secondary,
                  width: PaymentWidth.hug,
                ),
              ],
            ),
      attempt: c.attempt!,
      amount: c.attemptAmount,
      busyAction: c.loadingReceipt ? PaymentAction.viewReceipt : null,
      onAction: c.paymentAction,
    );
  }
}

/// Contact support was opened (simulated): shown above the step's content.
Widget? _supportNotice(BuildContext context, DemoCoordinator c) =>
    c.notice != 'support'
    ? null
    : PaymentBanner(
        tone: StatusTone.info,
        title: DemoStrings.of(context).supportOpened,
        announce: true,
      );

/// Host tools in a sheet, opened from the settings sheet's "Demo tools", so
/// they never sit in the step's content or between the content and its
/// pinned action (D62).
Future<void> _showDemoTools(
  BuildContext context, {
  required DemoCoordinator coordinator,
  required String scenarioLabel,
  required VoidCallback onRestart,
  required VoidCallback onBackground,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  backgroundColor: devWorkbench(context),
  builder: (sheet) => _HostTools(
    coordinator: coordinator,
    scenarioLabel: scenarioLabel,
    // Restart re-keys the flow, so the sheet closes first.
    onRestart: () {
      Navigator.pop(sheet);
      onRestart();
    },
    onBackground: () {
      Navigator.pop(sheet);
      onBackground();
    },
  ),
);

class _HostTools extends StatelessWidget {
  const _HostTools({
    required this.coordinator,
    required this.scenarioLabel,
    required this.onRestart,
    required this.onBackground,
  });

  final DemoCoordinator coordinator;
  final String scenarioLabel;
  final VoidCallback onRestart;
  final VoidCallback onBackground;

  @override
  Widget build(BuildContext context) {
    final s = DemoStrings.of(context);
    final theme = PaymentTheme.of(context);
    final host = coordinator.host;
    final scaler = devScaler(context);
    final mono = devMono(theme.textPrimary);
    // Gallery workbench voice, not product styling: a grey fill and mono
    // text, so the sheet never reads as part of the purchase.
    return SafeArea(
      child: ListenableBuilder(
        listenable: Listenable.merge([coordinator, host.log]),
        builder: (context, _) {
          final entries = host.log.value;
          return ListView(
            key: const Key('host-tools'),
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Semantics(
                header: true,
                child: Text(
                  s.hostTools,
                  style: devMono(theme.textSecondary),
                  textScaler: scaler,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${s.activeScenario(scenarioLabel)} · ${s.account(coordinator.account)}',
                style: mono,
                textScaler: scaler,
              ),
              const SizedBox(height: 8),
              Text(
                s.hostStats(
                  coordinator.submitEvents,
                  host.attemptCount,
                  host.chargeCount,
                ),
                key: const Key('host-stats'),
                style: mono,
                textScaler: scaler,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    key: const Key('host-restart'),
                    onPressed: onRestart,
                    icon: const Icon(Icons.restart_alt),
                    label: Text(s.simulateRestart),
                  ),
                  OutlinedButton.icon(
                    key: const Key('host-background'),
                    onPressed: onBackground,
                    icon: const Icon(Icons.flip_to_back),
                    label: Text(s.simulateBackground),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (entries.isEmpty)
                Text(s.hostLogEmpty, style: mono, textScaler: scaler)
              else
                for (final e in entries.reversed.take(30))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      '${e.at.toIso8601String().substring(11, 19)}  ${e.message}',
                      style: mono,
                      textScaler: scaler,
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}

/// Side inset that centres the content column in the window (D53): 640 dp,
/// or 1040 dp for checkout's two columns from 840 dp (Q1).
double listInset(BuildContext context, FlowStep step) {
  final content = MediaQuery.sizeOf(context).width - 32;
  if (content < 600 - 32) return 0;
  final cap = step == FlowStep.checkout && content >= 840 ? 1040 : 640;
  return ((content - cap) / 2).clamp(0, double.infinity);
}

/// AppBar caps its title at 1.34x text (Material's limit), on one line.
TextScaler _appBarTitleScaler(BuildContext context) =>
    MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.34);

/// One line of the app bar title at the current text size.
double _appBarTitleLine(BuildContext context) {
  final style = Theme.of(context).appBarTheme.titleTextStyle!;
  return _appBarTitleScaler(context).scale(style.fontSize!) * style.height!;
}

/// 1 when [title] fits on one line between the back button and the
/// [actions] 48 dp buttons, else 2. Breaks fall between words; step titles
/// are two words at most.
int _appBarTitleLines(
  BuildContext context,
  String title, {
  required bool leading,
  required int actions,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: title,
      style: Theme.of(context).appBarTheme.titleTextStyle,
    ),
    textScaler: _appBarTitleScaler(context),
    textDirection: Directionality.of(context),
    maxLines: 1,
  )..layout();
  final width = painter.width;
  painter.dispose();
  final room =
      MediaQuery.sizeOf(context).width -
      (leading ? kToolbarHeight : 0) -
      actions * kMinInteractiveDimension -
      NavigationToolbar.kMiddleSpacing * 2;
  return width <= room ? 1 : 2;
}

/// Steps that fill the screen and pin their own footer (D62).
bool _isViewStep(FlowStep step) => switch (step) {
  FlowStep.signIn ||
  FlowStep.kycIntro ||
  FlowStep.kycIdentity ||
  FlowStep.kycDocuments ||
  FlowStep.kycReview ||
  FlowStep.kycStatus ||
  FlowStep.confirm ||
  FlowStep.authorize ||
  FlowStep.payment ||
  FlowStep.receipt ||
  FlowStep.history ||
  FlowStep.transactionDetail ||
  FlowStep.statement ||
  FlowStep.fees ||
  FlowStep.accountSettings => true,
  _ => false,
};

/// Steps whose page header carries the title, so the app bar has none.
bool _ownHeader(DemoCoordinator c) => switch (c.step) {
  FlowStep.signIn ||
  FlowStep.kycIdentity ||
  FlowStep.kycDocuments ||
  FlowStep.kycReview ||
  FlowStep.history ||
  FlowStep.transactionDetail ||
  FlowStep.statement ||
  FlowStep.fees ||
  FlowStep.accountSettings => true,
  FlowStep.receipt => c.receipt != null,
  _ => false,
};

/// The payment flow, from KYC through the receipt: the app's tab bar is
/// hidden here so nothing competes with the pinned action (D62).
bool inPaymentFlow(FlowStep step) => switch (step) {
  FlowStep.kycIntro ||
  FlowStep.kycIdentity ||
  FlowStep.kycDocuments ||
  FlowStep.kycReview ||
  FlowStep.kycStatus ||
  FlowStep.checkout ||
  FlowStep.confirm ||
  FlowStep.authorize ||
  FlowStep.payment ||
  FlowStep.receipt => true,
  _ => false,
};
