import '../content/property_list.dart';
import '../layout/content.dart';
import '../layout/layout.dart';
import '../foundation/payment_tokens.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import '../foundation/money.dart';
import '../foundation/payment_localizations.dart';
import '../foundation/payment_motion.dart';
import '../foundation/payment_theme.dart';
import '../foundation/payment_type.dart';
import '../foundation/primitives.dart';
import '../interaction/interaction.dart';
import 'payment_models.dart';

/// Manual transfer instructions (for example a virtual account).
///
/// The countdown uses the host [clock] and stops at zero. Reaching zero is
/// not proof the customer did not pay, so the widget only reports
/// [onElapsed] and keeps the status check available.
class PaymentInstructions extends StatelessWidget {
  const PaymentInstructions({
    super.key,
    required this.instructions,
    required this.clock,
    this.onCopyNumber,
    this.onElapsed,
  });

  final VirtualAccountInstructions instructions;
  final DateTime Function() clock;

  /// Host clipboard; returns false when copying failed.
  final Future<bool> Function(String value)? onCopyNumber;
  final VoidCallback? onElapsed;

  @override
  Widget build(BuildContext context) {
    final l10n = PaymentLocalizations.of(context);
    final theme = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    final elapsed =
        CountdownText.remaining(instructions.expiresAt, clock()) ==
        Duration.zero;
    return PaymentSection(
      title: l10n.instructionsTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: theme.spacing * 0.5),
          PaymentBox(
            gap: PaymentSpace.inline,
            children: [
              PaymentInline(
                instructions.providerLabel,
                role: PaymentTextRole.caption,
              ),
              PaymentCode(
                instructions.accountNumber,
                size: PaymentSize.large,
                onCopy: onCopyNumber,
                semanticLabel: l10n.accountNumber,
              ),
            ],
          ),
          PaymentDivider(height: theme.spacing * 2),
          // A total row, not a second display amount: the status header
          // already shows the one large figure on this screen.
          PaymentPropertyList(
            items: [
              PaymentPropertyListItem(
                label: l10n.amountToPay,
                emphasis: true,
                value: AmountText(
                  instructions.amount,
                  variant: AmountTextVariant.total,
                ),
              ),
              PaymentPropertyListItem(
                label: l10n.payBefore,
                caption: l10n.formatDateTime(instructions.expiresAt),
                value: CountdownText(
                  expiresAt: instructions.expiresAt,
                  clock: clock,
                  onElapsed: onElapsed,
                  style: type.heading.tabular,
                ),
              ),
            ],
          ),
          if (elapsed) ...[
            SizedBox(height: theme.spacing),
            PaymentBanner(
              tone: StatusTone.warning,
              icon: Icons.timer_off_outlined,
              title: l10n.instructionsElapsedTitle,
              message: l10n.instructionsElapsedMessage,
              announce: true,
            ),
          ],
          // Collapsed so the status action stays on the first screen; the
          // account and amount above are what most people need.
          if (instructions.steps.isNotEmpty)
            PaymentAccordionItem(
              title: l10n.howToPay,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, step) in instructions.steps.indexed)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: theme.spacing * 0.5,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Scales with the text so "10." never wraps.
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: MediaQuery.textScalerOf(
                                context,
                              ).scale(20),
                            ),
                            child: Text(
                              '${i + 1}.',
                              style: type
                                  .bodyFor(context)
                                  .tabular
                                  .copyWith(color: theme.textSecondary),
                            ),
                          ),
                          SizedBox(width: theme.spacing),
                          Expanded(
                            child: Text(step, style: type.bodyFor(context)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Visual description of one status, shared by the status view.
@immutable
class _StatusLook {
  const _StatusLook(this.tone, this.icon, this.title, this.message);

  final StatusTone tone;
  final IconData icon;
  final String title;
  final String message;
}

/// Renders an attempt from host-authoritative data.
///
/// The view never infers success, never polls and never offers paying again
/// while the outcome is unresolved. Actions come from
/// [PaymentAttempt.availableActions].
class PaymentStatusView extends StatelessWidget {
  const PaymentStatusView({
    super.key,
    required this.attempt,
    required this.onAction,
    this.amount,
    this.busyAction,
    this.instructions,
  });

  final PaymentAttempt attempt;
  final Money? amount;

  /// Manual payment instructions, shown after the explanation and before the
  /// actions, so the account to pay into comes before Check status.
  ///
  /// Above 1.5× text they move after the actions. Not shown while the
  /// outcome is unknown, where an account to pay into would read as an
  /// invitation to pay again.
  final Widget? instructions;
  final FutureOr<void> Function(PaymentAction action) onAction;

  /// Action whose host call is running, shown as busy.
  final PaymentAction? busyAction;

  _StatusLook _look(PaymentLocalizations l10n) {
    final snapshot = attempt.snapshot;
    if (attempt.submission == SubmissionState.sending) {
      return _StatusLook(
        StatusTone.info,
        Icons.sync,
        l10n.statusSendingTitle,
        l10n.statusSendingMessage,
      );
    }
    if (attempt.submission == SubmissionState.outcomeUnknown ||
        snapshot == null) {
      return _StatusLook(
        StatusTone.warning,
        Icons.help_outline,
        l10n.statusUnknownTitle,
        l10n.statusUnknownMessage,
      );
    }
    final reason = snapshot.safeReason;
    return switch (snapshot.status) {
      PaymentStatus.requiresAction => _StatusLook(
        StatusTone.info,
        Icons.touch_app_outlined,
        l10n.statusRequiresActionTitle,
        reason ?? l10n.statusRequiresActionMessage,
      ),
      PaymentStatus.processing => _StatusLook(
        StatusTone.info,
        Icons.sync,
        l10n.statusProcessingTitle,
        reason ?? l10n.statusProcessingMessage,
      ),
      PaymentStatus.pending => _StatusLook(
        StatusTone.warning,
        Icons.schedule,
        l10n.statusPendingTitle,
        reason ?? l10n.statusPendingMessage,
      ),
      PaymentStatus.succeeded => _StatusLook(
        StatusTone.success,
        Icons.check_circle_outline,
        l10n.statusSucceededTitle,
        reason ?? l10n.statusSucceededMessage,
      ),
      PaymentStatus.failed => _StatusLook(
        StatusTone.danger,
        Icons.error_outline,
        l10n.statusFailedTitle,
        reason ?? l10n.statusFailedMessage,
      ),
      PaymentStatus.canceled => _StatusLook(
        StatusTone.neutral,
        Icons.block,
        l10n.statusCanceledTitle,
        reason ?? l10n.statusCanceledMessage,
      ),
      PaymentStatus.expired => _StatusLook(
        StatusTone.neutral,
        Icons.timer_off_outlined,
        l10n.statusExpiredTitle,
        reason ?? l10n.statusExpiredMessage,
      ),
    };
  }

  bool get _unknown =>
      attempt.submission != SubmissionState.sending &&
      (attempt.submission == SubmissionState.outcomeUnknown ||
          attempt.snapshot == null);

  @override
  Widget build(BuildContext context) {
    final l10n = PaymentLocalizations.of(context);
    final theme = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    final look = _look(l10n);
    final motion = PaymentMotion.of(context);
    final snapshot = attempt.snapshot;
    final actions = attempt.availableActions;
    final refreshing = attempt.observation == Observation.refreshing;
    final unknown = _unknown;
    final large = PaymentType.isLarge(context);
    // Large glyphs need less relative leading than 15 px body text.
    final body = type.bodyFor(context);
    final slot = unknown ? null : instructions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          container: true,
          liveRegion: true,
          // A status change is the one moment worth animating here: the new
          // state fades and scales in from 0.95; exits are faster.
          child: AnimatedSwitcher(
            duration: motion.enter,
            reverseDuration: motion.exit,
            switchInCurve: PaymentMotion.easeOut,
            transitionBuilder: PaymentMotion.fadeScale,
            layoutBuilder: PaymentMotion.topLayout,
            child: StatusHeader(
              key: ValueKey(look.title),
              tone: look.tone,
              icon: look.icon,
              title: look.title,
              hatched: unknown,
            ),
          ),
        ),
        if (amount != null) ...[
          SizedBox(height: theme.spacing * 1.5),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: AmountText(amount!, variant: AmountTextVariant.display),
          ),
        ],
        SizedBox(height: theme.spacing * 1.5),
        if (unknown) ...[
          Text(
            l10n.statusUnknownLead,
            style: body.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: theme.spacing * 0.5),
          Text(l10n.statusUnknownDetail, style: body),
        ] else
          Text(look.message, style: body),
        if (attempt.observation == Observation.unavailable) ...[
          SizedBox(height: theme.spacing * 2),
          PaymentBanner(
            tone: StatusTone.neutral,
            icon: Icons.cloud_off_outlined,
            announce: true,
            title: l10n.statusUnavailableTitle,
            message: attempt.lastCheckedAt == null
                ? l10n.statusUnavailableMessage
                : l10n.statusLastKnown(
                    l10n.formatDateTime(attempt.lastCheckedAt!),
                  ),
          ),
        ],
        // What to pay into comes before Check status at normal text. At large
        // text the instructions are taller than the first screen, so they
        // follow the actions to keep the action visible without scrolling.
        if (slot != null && !large) ...[
          SizedBox(height: theme.spacing * 2),
          slot,
        ],
        // What to do now comes before the reference numbers, so the action
        // stays on the first screen at large text.
        SizedBox(height: theme.spacing * 3),
        for (final action in _orderedActions(actions))
          Padding(
            padding: EdgeInsets.only(bottom: theme.spacing),
            child: PaymentButton(
              label: l10n.paymentActionLabel(action),
              variant: action == _primaryAction(actions)
                  ? PaymentButtonVariant.primary
                  : action == PaymentAction.contactSupport
                  ? PaymentButtonVariant.quiet
                  : PaymentButtonVariant.secondary,
              busy:
                  busyAction == action ||
                  (action == PaymentAction.checkStatus && refreshing),
              busyLabel: l10n.checkingStatus,
              onPressed: () => onAction(action),
            ),
          ),
        if (slot != null && large) ...[SizedBox(height: theme.spacing), slot],
        PaymentDivider(height: theme.spacing * 3),
        PaymentPropertyList(
          items: [
            PaymentPropertyListItem(
              label: l10n.attemptReference,
              value: MiddleEllipsisText(
                attempt.attemptId,
                style: type.label.reference(theme),
              ),
            ),
            if (snapshot != null) ...[
              PaymentPropertyListItem(
                label: l10n.transactionReference,
                valueText: snapshot.serverReference,
              ),
              // Only a real host snapshot has an update time. Without one the
              // row is left out rather than filled with a status phrase.
              PaymentPropertyListItem(
                label: l10n.lastUpdated,
                valueText: l10n.formatDateTime(snapshot.updatedAt),
              ),
            ],
          ],
        ),
        if (snapshot != null &&
            snapshot.refund.status != RefundStatus.none) ...[
          PaymentDivider(height: theme.spacing * 3),
          RefundSection(refund: snapshot.refund, paidAmount: amount),
        ],
      ],
    );
  }

  static const _order = [
    PaymentAction.viewReceipt,
    PaymentAction.checkStatus,
    PaymentAction.viewInstructions,
    PaymentAction.startNewAttempt,
    PaymentAction.requestCancel,
    PaymentAction.contactSupport,
  ];

  List<PaymentAction> _orderedActions(Set<PaymentAction> actions) =>
      _order.where(actions.contains).toList();

  PaymentAction? _primaryAction(Set<PaymentAction> actions) {
    final ordered = _orderedActions(actions);
    return ordered.isEmpty ? null : ordered.first;
  }
}

/// Refund lifecycle shown beside, never instead of, the original payment.
class RefundSection extends StatelessWidget {
  const RefundSection({super.key, required this.refund, this.paidAmount});

  final RefundInfo refund;

  /// Original amount; a refund above it is treated as invalid host data.
  final Money? paidAmount;

  @override
  Widget build(BuildContext context) {
    final l10n = PaymentLocalizations.of(context);
    final theme = PaymentTheme.of(context);
    final amount = refund.amount;
    final invalidAmount =
        amount != null &&
        paidAmount != null &&
        (amount.currency != paidAmount!.currency || amount > paidAmount!);
    final (tone, icon) = switch (refund.status) {
      RefundStatus.none => (StatusTone.neutral, Icons.remove),
      RefundStatus.pending => (StatusTone.warning, Icons.schedule),
      RefundStatus.partial => (StatusTone.info, Icons.call_split),
      RefundStatus.refunded => (StatusTone.success, Icons.undo),
      RefundStatus.failed => (StatusTone.danger, Icons.error_outline),
    };
    return PaymentSection(
      title: l10n.refundTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: theme.spacing * 0.5),
          PaymentBadge(
            tone: tone,
            icon: icon,
            label: l10n.refundStatusLabel(refund.status),
          ),
          SizedBox(height: theme.spacing),
          PaymentPropertyList(
            items: [
              if (amount != null)
                PaymentPropertyListItem(
                  label: l10n.refundAmount,
                  value: invalidAmount
                      ? Text(l10n.refundAmountUnavailable)
                      : AmountText(amount),
                ),
              if (refund.updatedAt != null)
                PaymentPropertyListItem(
                  label: l10n.lastUpdated,
                  valueText: l10n.formatDateTime(refund.updatedAt!),
                ),
            ],
          ),
          Text(
            refund.safeReason ?? l10n.refundSeparateNote,
            style: PaymentType.of(context).caption,
          ),
        ],
      ),
    );
  }
}
