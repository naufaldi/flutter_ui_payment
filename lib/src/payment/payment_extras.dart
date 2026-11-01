import '../forms/chip.dart';
import '../foundation/payment_icons.dart';
import '../foundation/payment_tokens.dart';
import '../controls/text_field.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../foundation/kit_strings.dart';
import '../foundation/money.dart';
import '../foundation/payment_localizations.dart';
import '../foundation/payment_motion.dart';
import '../foundation/payment_theme.dart';
import '../foundation/payment_type.dart';
import '../foundation/primitives.dart';

/// Pinned bottom bar with the total and the step's main action, so both
/// stay reachable however long the page is.
///
/// Place it in `Scaffold.bottomNavigationBar`. While [updating] the total
/// says so and the host should pass a disabled action.
class PaymentActionBar extends StatelessWidget {
  const PaymentActionBar({
    super.key,
    required this.action,
    this.total,
    this.totalLabel,
    this.updating = false,
  });

  /// Main action; pass width: PaymentWidth.hug on PaymentButton.
  final Widget action;
  final Money? total;
  final String? totalLabel;
  final bool updating;

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final l10n = PaymentLocalizations.of(context);
    final type = PaymentType.of(context);
    final large = PaymentType.isLarge(context);
    final motion = PaymentMotion.of(context);
    Widget? totalBlock;
    if (total != null) {
      totalBlock = Semantics(
        liveRegion: true,
        child: AnimatedSwitcher(
          duration: motion.quick,
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          layoutBuilder: (current, previous) => Stack(
            alignment: AlignmentDirectional.centerStart,
            children: [...previous, ?current],
          ),
          child: updating
              ? Text(
                  l10n.updatingTotal,
                  key: const ValueKey('updating'),
                  style: type.caption,
                )
              : MergeSemantics(
                  key: ValueKey(total),
                  // Label above the amount beside the button; one baseline
                  // row when stacked over a full-width button.
                  child: Flex(
                    direction: large ? Axis.horizontal : Axis.vertical,
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: large
                        ? CrossAxisAlignment.baseline
                        : CrossAxisAlignment.start,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(totalLabel ?? l10n.totalLabel, style: type.caption),
                      if (large)
                        SizedBox(width: theme.space(PaymentSpace.related)),
                      // A step below the 32 px headline: the bar repeats
                      // the total, it does not compete with it. Capped at
                      // 1.6x like other display amounts; the clamp sits
                      // inside Flexible so the Flex still gets its parent
                      // data.
                      Flexible(
                        child: MediaQuery.withClampedTextScaling(
                          maxScaleFactor: 1.6,
                          child: AmountText(
                            total!,
                            variant: AmountTextVariant.large,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      );
    }
    return Material(
      color: theme.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: theme.outline)),
        ),
        child: SafeArea(
          top: false,
          minimum: EdgeInsets.fromLTRB(
            theme.space(PaymentSpace.group),
            theme.space(PaymentSpace.block),
            theme.space(PaymentSpace.group),
            theme.space(PaymentSpace.block),
          ),
          // Side by side at normal text sizes; stacked when text is large so
          // the amount never shrinks to fit beside the button.
          child: totalBlock == null
              ? action
              : large
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    totalBlock,
                    SizedBox(height: theme.space(PaymentSpace.related)),
                    action,
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: totalBlock),
                    SizedBox(width: theme.space(PaymentSpace.group)),
                    // The button hugs its label (up to 240) so it never
                    // wraps; the total takes the rest.
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 112,
                        maxWidth: 240,
                      ),
                      child: IntrinsicWidth(child: action),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Who is being paid and for which order.
class MerchantHeader extends StatelessWidget {
  const MerchantHeader({
    super.key,
    required this.name,
    this.orderReference,
    this.category,
    this.verified = false,
    this.logo,
  });

  final String name;
  final String? orderReference;
  final String? category;

  /// Set only when the host has verified the merchant.
  final bool verified;

  /// Host-supplied logo. Defaults to the merchant's initials.
  final Widget? logo;

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final l10n = PaymentLocalizations.of(context);
    final type = PaymentType.of(context);
    final initials = name
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w.characters.first.toUpperCase())
        .join();
    final detail = [
      ?category,
      if (orderReference != null) l10n.orderRef(orderReference!),
    ].join(' · ');
    final boxRadius = theme.controlBorderRadius;
    // Centers the 32 px mark on the first 15/20 name line once that line is
    // taller than the mark; zero at normal text sizes.
    final markInset = math.max(
      0.0,
      (PaymentType.firstLineHeight(context) - 32) / 2,
    );
    return MergeSemantics(
      // Top-aligned: when the name wraps at large text, the mark stays beside
      // the first line instead of floating in the middle of the block.
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Padding(
              padding: EdgeInsets.only(top: markInset),
              child: SizedBox.square(
                dimension: 32,
                child: ClipRRect(
                  borderRadius: boxRadius,
                  child:
                      logo ??
                      ColoredBox(
                        color: theme.surfaceMuted,
                        // Initials shrink to the box at large text sizes; the
                        // name next to it carries the readable label.
                        child: Padding(
                          padding: EdgeInsets.all(
                            theme.space(PaymentSpace.related),
                          ),
                          child: Center(
                            child: FittedBox(
                              child: Text(
                                initials,
                                style: type.tag.copyWith(
                                  color: theme.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                ),
              ),
            ),
          ),
          SizedBox(width: theme.space(PaymentSpace.block)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The badge flows with the name, so it stays right after
                // the last word when a long name wraps.
                Text.rich(
                  TextSpan(
                    text: name,
                    children: [
                      if (verified)
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Padding(
                            padding: EdgeInsetsDirectional.only(
                              start: theme.space(PaymentSpace.inline),
                            ),
                            child: PaymentIcon(
                              Icons.verified_outlined,
                              size: PaymentIconSize.small,
                              color: PaymentTextColor.accent,
                              semanticLabel: l10n.merchantVerified,
                            ),
                          ),
                        ),
                    ],
                  ),
                  style: type.heading,
                ),
                if (detail.isNotEmpty) Text(detail, style: type.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Where the customer is in a multi-step flow.
///
/// The bars are a visual aid; screen readers hear "Step 2 of 4: Checkout".
class PaymentStepIndicator extends StatelessWidget {
  const PaymentStepIndicator({
    super.key,
    required this.steps,
    required this.current,
  }) : assert(current >= 0 && current < steps.length);

  final List<String> steps;

  /// Zero-based index of the active step.
  final int current;

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final l10n = PaymentLocalizations.of(context);
    final type = PaymentType.of(context);
    final motion = PaymentMotion.of(context);
    return Semantics(
      label: l10n.stepOf(current + 1, steps.length, steps[current]),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 0; i < steps.length; i++) ...[
                if (i > 0) SizedBox(width: theme.space(PaymentSpace.inline)),
                Expanded(
                  child: AnimatedContainer(
                    duration: motion.quick,
                    curve: PaymentMotion.easeOut,
                    height: 3,
                    decoration: BoxDecoration(
                      color: i <= current ? theme.accent : theme.outline,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: theme.space(PaymentSpace.related)),
          Text(
            '${current + 1}/${steps.length} · ${steps[current]}',
            style: type.caption.tabular,
          ),
        ],
      ),
    );
  }
}

/// Balance state as decided by the host for the current quote.
enum BalanceState { sufficient, insufficient, unavailable }

/// Wallet balance, whether it covers the payment, and limit usage.
///
/// The host decides [state] and [shortfall]; the widget never compares the
/// balance with a total itself, because holds, limits and pending debits are
/// only known to the backend.
class BalanceCard extends StatelessWidget {
  const BalanceCard({
    super.key,
    required this.state,
    this.balance,
    this.title,
    this.shortfall,
    this.limitUsed,
    this.limitTotal,
    this.action,
  });

  final BalanceState state;
  final Money? balance;
  final String? title;
  final Money? shortfall;
  final Money? limitUsed;
  final Money? limitTotal;

  /// Optional host action such as "Top up".
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final l10n = PaymentLocalizations.of(context);
    final type = PaymentType.of(context);
    final fmt = l10n.moneyFormat;
    final limit = limitUsed != null && limitTotal != null
        ? (limitUsed!.minorUnits / limitTotal!.minorUnits).clamp(0.0, 1.0)
        : null;
    return PaymentSection(
      title: title ?? l10n.balanceTitle,
      trailing: action,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: theme.space(PaymentSpace.inline)),
          if (state == BalanceState.unavailable || balance == null)
            Text(
              l10n.balanceUnavailable,
              style: type.label.copyWith(color: theme.textSecondary),
            )
          else
            // The large amount, not the 32 px headline: the balance usually
            // shares a screen with the total, which owns the display size.
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: AmountText(balance!, variant: AmountTextVariant.large),
            ),
          if (state == BalanceState.insufficient) ...[
            SizedBox(height: theme.space(PaymentSpace.related)),
            PaymentBanner(
              tone: StatusTone.warning,
              icon: Icons.account_balance_wallet_outlined,
              title: l10n.balanceInsufficient,
              message: shortfall == null
                  ? null
                  : l10n.balanceShortfall(fmt.format(shortfall!)),
            ),
          ],
          if (limit != null) ...[
            SizedBox(height: theme.space(PaymentSpace.block)),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: limit,
                minHeight: 4,
                color: limit >= 0.9 ? theme.warning.foreground : theme.accent,
                backgroundColor: theme.surfaceMuted,
                semanticsLabel: l10n.limitUsed(
                  fmt.format(limitUsed!),
                  fmt.format(limitTotal!),
                ),
              ),
            ),
            SizedBox(height: theme.space(PaymentSpace.related)),
            ExcludeSemantics(
              child: Text(
                l10n.limitUsed(fmt.format(limitUsed!), fmt.format(limitTotal!)),
                style: type.caption,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Text scale above which the promo row stacks. It is earlier than the kit's
/// 1.5× large-text threshold because the field and the Apply button, or the
/// code tag and its discount, share one tight row.
const _stackAt = 1.3;

/// Host verdict on a promo code.
enum PromoCodeStatus { idle, checking, applied, rejected }

/// Promo code entry. The host validates the code and, if accepted, returns
/// a new quote with a discount line; this widget only collects the code and
/// shows the host's verdict. It never computes a discount.
class PromoCodeInput extends StatefulWidget {
  const PromoCodeInput({
    super.key,
    required this.status,
    required this.onApply,
    this.appliedCode,
    this.discount,
    this.message,
    this.onRemove,
  });

  final PromoCodeStatus status;
  final Future<void> Function(String code) onApply;
  final String? appliedCode;

  /// Discount the host applied, shown next to the applied code.
  final Money? discount;

  /// Host reason for a rejected code ("Code expired").
  final String? message;
  final VoidCallback? onRemove;

  @override
  State<PromoCodeInput> createState() => _PromoCodeInputState();
}

class _PromoCodeInputState extends State<PromoCodeInput> {
  final _controller = TextEditingController();
  bool _emptyTried = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final code = _controller.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _emptyTried = true);
      return;
    }
    setState(() => _emptyTried = false);
    await widget.onApply(code);
  }

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final l10n = PaymentLocalizations.of(context);
    final stacked = MediaQuery.textScalerOf(context).scale(10) > 10 * _stackAt;
    if (widget.status == PromoCodeStatus.applied &&
        widget.appliedCode != null) {
      final code = Align(
        alignment: AlignmentDirectional.centerStart,
        child: PaymentChip(
          label: l10n.promoCodeLabel,
          value: widget.appliedCode,
          onClose: widget.onRemove,
        ),
      );
      final discount = widget.discount == null
          ? null
          // Ink, not green: the minus sign carries the meaning, and colored
          // money would compete with the total.
          : AmountText(widget.discount!);
      // The applied code is a small tag, as in a hosted checkout's summary;
      // the remove control beside it keeps a full 48 dp target. Large text
      // moves the discount under the code instead of squeezing both.
      return Semantics(
        label: l10n.promoApplied(widget.appliedCode!),
        liveRegion: true,
        container: true,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: discount == null
              ? code
              : stacked
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    code,
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: discount,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: code),
                    SizedBox(width: theme.space(PaymentSpace.related)),
                    discount,
                  ],
                ),
        ),
      );
    }
    final checking = widget.status == PromoCodeStatus.checking;
    final error = _emptyTried
        ? l10n.promoCodeEmpty
        : widget.status == PromoCodeStatus.rejected
        ? widget.message
        : null;
    final field = PaymentTextField(
      label: l10n.promoCodeLabel,
      controller: _controller,
      enabled: !checking,
      reference: true,
      textCapitalization: TextCapitalization.characters,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _apply(),
      onChanged: (_) {
        if (_emptyTried) setState(() => _emptyTried = false);
      },
      errorText: error,
      description: checking ? l10n.checkingCode : null,
    );
    final button = PaymentButton(
      label: l10n.apply,
      variant: PaymentButtonVariant.secondary,
      busy: checking,
      busyLabel: l10n.checkingCode,
      onPressed: checking ? null : _apply,
    );
    // Large text stacks the button under the field instead of squeezing it.
    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          field,
          SizedBox(height: theme.space(PaymentSpace.related)),
          button,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: field),
        SizedBox(width: theme.space(PaymentSpace.related)),
        SizedBox(width: 112, child: button),
      ],
    );
  }
}
