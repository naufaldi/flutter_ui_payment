import '../forms/select.dart';
import '../foundation/kit_strings.dart';
import '../foundation/action_frame.dart';
import '../foundation/field_decoration.dart';
import '../foundation/first_line.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import '../foundation/focus_ring.dart';
import '../foundation/payment_tokens.dart';
import '../foundation/radio_mark.dart';
import '../controls/controls.dart';
import '../foundation/money.dart';
import '../foundation/payment_localizations.dart';
import '../foundation/payment_motion.dart';
import '../foundation/payment_theme.dart';
import '../foundation/payment_type.dart';
import '../foundation/primitives.dart';
import 'payment_models.dart';

/// Free-form amount entry with strict, locale-aware parsing.
///
/// Every change reports an [AmountParseResult]; hosts enable confirmation
/// only for valid results. Errors appear after the field loses focus, after
/// submit, or when [showErrors] is set.
class PaymentCurrencyField extends StatefulWidget {
  const PaymentCurrencyField({
    super.key,
    required this.currency,
    required this.onChanged,
    this.currencies = const [],
    this.onCurrencyChanged,
    this.minimum,
    this.maximum,
    this.initialText,
    this.label,
    this.showErrors = false,
    this.description,
    this.size = PaymentSize.medium,
    this.padFractionDigits = false,
    this.errorText,
    this.hiddenElements = const {},
  });

  /// Host allowlist; two or more show a selector above the amount.
  final List<String> currencies;

  /// Reports currency selection; the host passes the new currency back.
  final ValueChanged<String>? onCurrencyChanged;

  /// Helper text above the host's limits.
  final String? description;

  /// Medium retains the default height; small is 8 dp shorter, large 8 taller.
  final PaymentSize size;

  /// Pads missing minor digits on blur/submit without reporting a new value.
  final bool padFractionDigits;

  /// Host error shown instead of a parse issue.
  final String? errorText;

  /// Hidden field parts remain spoken.
  final Set<PaymentFieldPart> hiddenElements;

  /// Currency code for parsing and formatting.
  final String currency;

  /// Reports every parse result.
  final ValueChanged<AmountParseResult> onChanged;

  /// Optional lower bound.
  final Money? minimum;

  /// Optional upper bound.
  final Money? maximum;

  /// Initial formatted input.
  final String? initialText;

  /// Persistent field label.
  final String? label;

  /// Whether parse errors are visible before interaction.
  final bool showErrors;

  @override
  State<PaymentCurrencyField> createState() => _PaymentCurrencyFieldState();
}

class _PaymentCurrencyFieldState extends State<PaymentCurrencyField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialText,
  );
  final FocusNode _focus = FocusNode();
  bool _touched = false;
  AmountParseResult _result = const AmountParseResult.issue(AmountIssue.empty);

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus && _controller.text.isNotEmpty) {
        _pad();
        setState(() => _touched = true);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _result = _parse(_controller.text);
  }

  AmountParseResult _parse(String text) => PaymentLocalizations.of(context)
      .moneyFormat
      .parse(text, widget.currency)
      .withinLimits(minimum: widget.minimum, maximum: widget.maximum);

  void _pad() {
    final spec = CurrencySpec.of(widget.currency);
    if (!widget.padFractionDigits ||
        _result.issue != null ||
        spec.minorDigits == 0) {
      return;
    }
    final separator = PaymentLocalizations.of(
      context,
    ).moneyFormat.decimalSeparator;
    final text = _controller.text;
    final index = text.indexOf(separator);
    final existing = index < 0 ? 0 : text.length - index - separator.length;
    if (index >= 0 && existing >= spec.minorDigits) return;
    final padded =
        text +
        (index < 0 ? separator : '') +
        List.filled(spec.minorDigits - existing, '0').join();
    final previous = _result.money;
    _controller.value = TextEditingValue(
      text: padded,
      selection: TextSelection.collapsed(offset: padded.length),
    );
    _result = _parse(padded);
    assert(_result.money == previous);
  }

  void _onChanged(String text) {
    setState(() => _result = _parse(text));
    widget.onChanged(_result);
  }

  @override
  void didUpdateWidget(PaymentCurrencyField old) {
    super.didUpdateWidget(old);
    if (old.currency != widget.currency) {
      _result = _parse(_controller.text);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onChanged(_result);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = PaymentLocalizations.of(context);
    final theme = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    final spec = CurrencySpec.of(widget.currency);
    final issue = _result.issue;
    final showError = (_touched || widget.showErrors) && issue != null;
    final limits = [
      if (widget.minimum != null)
        l10n.minimumAmount(l10n.moneyFormat.format(widget.minimum!)),
      if (widget.maximum != null)
        l10n.maximumAmount(l10n.moneyFormat.format(widget.maximum!)),
    ].join(' · ');
    // The entered amount is a large amount, so it follows text scaling only
    // up to 1.6×, like the other 20 px amounts. Its line matches the text
    // field's input line, so both fields are the same height (#47).
    final amountSize = MediaQuery.textScalerOf(
      context,
    ).clamp(maxScaleFactor: 1.6).scale(type.amountLarge.fontSize!);
    final amountStyle = type.amountLarge.copyWith(
      height: lineHeightOf(context, type.input) / amountSize,
    );
    final label = widget.label ?? l10n.amountLabel;
    final hideLabel = widget.hiddenElements.contains(PaymentFieldPart.label);
    // At large text the label sits above the box at full scale, outside the
    // 1.6× clamp, like every other field's (#73).
    final above = !hideLabel && fieldLabelAbove(context);
    final input = MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.6,
      child: TextField(
        enabled: !(FieldGroupScope.of(context)?.disabled ?? false),
        controller: _controller,
        focusNode: _focus,
        onChanged: _onChanged,
        onSubmitted: (_) {
          _pad();
          setState(() => _touched = true);
        },
        keyboardType: TextInputType.numberWithOptions(
          decimal: spec.minorDigits > 0,
        ),
        textInputAction: TextInputAction.done,
        style: amountStyle,
        decoration:
            paymentFieldDecoration(
              context,
              label: label,
              hideLabel: hideLabel,
              labelAbove: above,
              contentPadding: fieldContentPadding(
                theme,
                widget.size,
                labelAbove: above,
              ),
              prefixText: '${spec.symbol} ',
              prefixStyle: amountStyle.copyWith(color: theme.textSecondary),
              helper: widget.description == null && limits.isEmpty
                  ? null
                  : FieldMessage(
                      [
                        ?widget.description,
                        if (limits.isNotEmpty) limits,
                      ].join('\n'),
                      hidden: widget.hiddenElements.contains(
                        PaymentFieldPart.description,
                      ),
                    ),
            ).copyWith(
              error: widget.errorText == null && !showError
                  ? null
                  : FieldMessage(
                      widget.errorText ??
                          l10n.amountIssue(
                            issue!,
                            minimum: widget.minimum,
                            maximum: widget.maximum,
                          ),
                      tone: StatusTone.danger,
                      hidden: widget.hiddenElements.contains(
                        PaymentFieldPart.error,
                      ),
                    ),
            ),
      ),
    );
    final field = FieldLabelAbove(
      label: above ? label : null,
      enabled: !(FieldGroupScope.of(context)?.disabled ?? false),
      onTap: _focus.requestFocus,
      child: Semantics(label: above ? label : null, child: input),
    );
    assert(
      widget.currencies.length < 2 ||
          (widget.onCurrencyChanged != null &&
              widget.currencies.contains(widget.currency)),
    );
    if (widget.currencies.length < 2) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.space(PaymentSpace.group),
      children: [
        PaymentSelect<String>(
          label: l10n.currencyLabel,
          options: [
            for (final c in widget.currencies)
              PaymentSelectOption(
                value: c,
                label: '$c · ${CurrencySpec.of(c).symbol}',
              ),
          ],
          value: widget.currency,
          onChanged: widget.onCurrencyChanged,
          size: widget.size,
        ),
        field,
      ],
    );
  }
}

/// Deprecated alias of [PaymentCurrencyField].
@Deprecated('Use PaymentCurrencyField. Removed in 0.2.0.')
typedef AmountInput = PaymentCurrencyField;

/// Items, every fee and the host total. Fees are never collapsed.
///
/// Pass [previousQuote] after a re-quote to highlight a changed total.
class PaymentSummary extends StatelessWidget {
  const PaymentSummary({
    super.key,
    required this.quote,
    this.previousQuote,
    this.title,
  });

  final PaymentQuote quote;
  final PaymentQuote? previousQuote;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final l10n = PaymentLocalizations.of(context);
    final theme = PaymentTheme.of(context);
    final previous = previousQuote;
    final changed = previous != null && quote.termsDifferFrom(previous);
    final large = PaymentType.isLarge(context);
    return PaymentSection(
      title: title ?? l10n.summaryTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The amount comes first, as on a receipt: the customer sees what
          // they pay before the breakdown that explains it. At large text it
          // is dropped: the Total row carries the total and the pinned bar
          // repeats it.
          if (!large) ...[
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: AmountText(
                quote.total,
                variant: AmountTextVariant.display,
              ),
            ),
            SizedBox(height: theme.space(PaymentSpace.related)),
          ],
          if (changed) ...[
            PaymentBanner(
              tone: StatusTone.warning,
              announce: true,
              title: l10n.totalChangedTitle,
              message: l10n.totalChangedMessage(
                l10n.moneyFormat.format(previous.total),
                l10n.moneyFormat.format(quote.total),
              ),
            ),
            SizedBox(height: theme.space(PaymentSpace.related)),
          ],
          for (final line in quote.items)
            InfoRow(
              label: line.label,
              caption: line.detail,
              value: AmountText(line.amount),
            ),
          for (final line in quote.adjustments)
            InfoRow(
              label: line.label,
              caption: line.detail,
              value: AmountText(line.amount),
            ),
          PaymentDivider(height: theme.space(PaymentSpace.group)),
          InfoRow(
            label: l10n.totalLabel,
            emphasis: true,
            value: AmountText(quote.total, variant: AmountTextVariant.total),
          ),
        ],
      ),
    );
  }
}

/// Single-choice list of host-supplied methods.
///
/// Unavailable methods stay visible with their reason. A [selectedId] that is
/// missing or unavailable renders as no selection.
class PaymentMethodPicker extends StatelessWidget {
  const PaymentMethodPicker({
    super.key,
    required this.methods,
    required this.selectedId,
    required this.onChanged,
    this.emptyMessage,
  });

  final List<PaymentMethod> methods;
  final String? selectedId;
  final ValueChanged<PaymentMethod> onChanged;
  final String? emptyMessage;

  /// Returns [selectedId] only when it still names an available method.
  static String? validSelection(List<PaymentMethod> methods, String? id) {
    for (final m in methods) {
      if (m.id == id && m.isAvailable) return id;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = PaymentLocalizations.of(context);
    final theme = PaymentTheme.of(context);
    if (methods.isEmpty) {
      return PaymentBanner(
        tone: StatusTone.neutral,
        title: l10n.noMethodsTitle,
        message: emptyMessage ?? l10n.noMethodsMessage,
      );
    }
    final effective = validSelection(methods, selectedId);
    final radius = theme.borderRadius;
    // One bordered list, as in a hosted checkout: rows are separated by
    // rules and only the selected row gets an outline. The title sits 8
    // above the box: the section's 4 plus 4 here.
    return PaymentSection(
      title: l10n.methodTitle,
      child: Padding(
        padding: EdgeInsets.only(top: theme.space(PaymentSpace.inline)),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: radius,
            border: Border.all(color: theme.outline),
          ),
          child: Column(
            children: [
              for (final (i, method) in methods.indexed) ...[
                if (i > 0) const PaymentDivider(),
                _MethodTile(
                  method: method,
                  selected: method.id == effective,
                  onTap: method.isAvailable ? () => onChanged(method) : null,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final PaymentMethod method;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final l10n = PaymentLocalizations.of(context);
    final type = PaymentType.of(context);
    final enabled = onTap != null;
    final motion = PaymentMotion.of(context);
    final radius = theme.borderRadius;
    // The selected row's outline fades in (150 ms); its width never changes
    // the layout because it is painted over the row, not around it.
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      enabled: enabled,
      button: true,
      child: PaymentFocusRing(
        radius: radius,
        child: AnimatedContainer(
          duration: motion.quick,
          curve: PaymentMotion.easeOut,
          foregroundDecoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: selected
                  ? theme.accent
                  : theme.accent.withValues(alpha: 0),
              width: 2,
            ),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              borderRadius: radius,
              focusColor: Colors.transparent,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: theme.space(PaymentSpace.block),
                    vertical: theme.space(PaymentSpace.block),
                  ),
                  child: Row(
                    children: [
                      RadioMark(selected: selected, enabled: enabled),
                      SizedBox(width: theme.space(PaymentSpace.block)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              method.label,
                              style: enabled
                                  ? type.label
                                  : type.label.copyWith(
                                      color: theme.textSecondary,
                                    ),
                            ),
                            if (method.detail != null)
                              Text(method.detail!, style: type.caption),
                            if (method.feeNote != null)
                              Text(method.feeNote!, style: type.caption),
                            if (!method.isAvailable)
                              Padding(
                                padding: EdgeInsets.only(
                                  top: theme.space(PaymentSpace.inline),
                                ),
                                child: Text(
                                  '${l10n.unavailable}: ${method.unavailableReason}',
                                  style: type.caption.copyWith(
                                    color: theme.danger.foreground,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Final review before the host authorizes and submits.
///
/// When [previousQuote] has different terms the customer must explicitly
/// accept the new total before [onConfirm] becomes available. Only one
/// [onConfirm] call can be active at a time.
///
/// Given a bounded height, e.g. as a screen's body, the review scrolls and
/// the pay button pins to a footer at the bottom (D62). Inside a scroll view
/// it follows the review, as before.
class PaymentConfirmation extends StatefulWidget {
  const PaymentConfirmation({
    super.key,
    required this.quote,
    required this.method,
    required this.onConfirm,
    this.previousQuote,
    this.busy = false,
    this.footnote,
    this.header,
  });

  final PaymentQuote quote;
  final PaymentMethod method;
  final PaymentQuote? previousQuote;
  final Future<void> Function()? onConfirm;
  final bool busy;
  final String? footnote;

  /// Host content shown above this widget's content, inside its scroll
  /// region (D62), e.g. a banner.
  final Widget? header;

  @override
  State<PaymentConfirmation> createState() => _PaymentConfirmationState();
}

class _PaymentConfirmationState extends State<PaymentConfirmation> {
  bool _acceptedChange = false;

  @override
  void didUpdateWidget(PaymentConfirmation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quote.revision != widget.quote.revision ||
        oldWidget.quote.id != widget.quote.id) {
      _acceptedChange = false;
    }
  }

  bool get _needsReapproval {
    final previous = widget.previousQuote;
    return previous != null && widget.quote.termsDifferFrom(previous);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = PaymentLocalizations.of(context);
    final theme = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    final canConfirm =
        widget.onConfirm != null && (!_needsReapproval || _acceptedChange);
    final pay = PaymentButton(
      label: l10n.payAmount(l10n.moneyFormat.format(widget.quote.total)),
      busyLabel: l10n.sendingPayment,
      busy: widget.busy,
      onPressed: canConfirm ? widget.onConfirm : null,
    );
    return ActionFrame(
      header: widget.header,
      primaryAction: pay,
      builder: (context, pinned) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PaymentSummary(
            quote: widget.quote,
            previousQuote: widget.previousQuote,
          ),
          // Sections stack flush; their own padding makes the gap.
          PaymentSection(
            title: l10n.payWithTitle,
            // The method name is the information; its detail supports it.
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: theme.space(PaymentSpace.inline)),
                Text(widget.method.label, style: type.label),
                if (widget.method.detail != null)
                  Text(widget.method.detail!, style: type.caption),
              ],
            ),
          ),
          if (_needsReapproval) ...[
            SizedBox(height: theme.space(PaymentSpace.related)),
            PaymentCheckbox(
              value: _acceptedChange,
              onChanged: widget.busy
                  ? null
                  : (v) => setState(() => _acceptedChange = v),
              label: l10n.acceptNewTotal(
                l10n.moneyFormat.format(widget.quote.total),
              ),
            ),
          ],
          if (widget.footnote != null) ...[
            SizedBox(height: theme.space(PaymentSpace.related)),
            Text(widget.footnote!, style: type.caption),
          ],
          if (!pinned) ...[
            SizedBox(height: theme.space(PaymentSpace.section)),
            pay,
          ],
        ],
      ),
    );
  }
}

/// Shows the state of the host's authorization challenge.
///
/// The library never collects the PIN, OTP or biometric result: [onStart]
/// hands control to the host, which reports back a new [phase].
///
/// Given a bounded height, the status scrolls and the authorize button pins
/// to a footer, with the quiet back-to-review under it (D62). Inside a
/// scroll view they follow the status, as before.
class AuthorizationPrompt extends StatelessWidget {
  const AuthorizationPrompt({
    super.key,
    required this.phase,
    required this.onStart,
    required this.onBackToReview,
    this.methodLabel,
    this.header,
  });

  final AuthorizationPhase phase;
  final FutureOr<void> Function()? onStart;
  final VoidCallback? onBackToReview;
  final String? methodLabel;

  /// Host content shown above this widget's content, inside its scroll
  /// region (D62), e.g. the total being authorized.
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final l10n = PaymentLocalizations.of(context);
    final theme = PaymentTheme.of(context);
    final (tone, title, message, icon) = switch (phase) {
      AuthorizationPhase.ready => (
        StatusTone.info,
        l10n.authReadyTitle,
        l10n.authReadyMessage,
        Icons.fingerprint,
      ),
      AuthorizationPhase.inProgress => (
        StatusTone.info,
        l10n.authInProgressTitle,
        l10n.authInProgressMessage,
        Icons.schedule,
      ),
      AuthorizationPhase.approved => (
        StatusTone.success,
        l10n.authApprovedTitle,
        l10n.authApprovedMessage,
        Icons.verified_user_outlined,
      ),
      AuthorizationPhase.canceled => (
        StatusTone.neutral,
        l10n.authCanceledTitle,
        l10n.authCanceledMessage,
        Icons.cancel_outlined,
      ),
      AuthorizationPhase.failed => (
        StatusTone.danger,
        l10n.authFailedTitle,
        l10n.authFailedMessage,
        Icons.gpp_bad_outlined,
      ),
      AuthorizationPhase.expired => (
        StatusTone.warning,
        l10n.authExpiredTitle,
        l10n.authExpiredMessage,
        Icons.timer_off_outlined,
      ),
    };
    // The expected path reads as plain text; a tinted notice is kept for
    // the exceptions that need the customer's attention.
    final exception =
        phase == AuthorizationPhase.canceled ||
        phase == AuthorizationPhase.failed ||
        phase == AuthorizationPhase.expired;
    final type = PaymentType.of(context);
    final retryable =
        phase == AuthorizationPhase.ready ||
        phase == AuthorizationPhase.canceled ||
        phase == AuthorizationPhase.failed ||
        phase == AuthorizationPhase.expired;
    final start = retryable || phase == AuthorizationPhase.inProgress
        ? PaymentButton(
            label: phase == AuthorizationPhase.ready
                ? l10n.authorize
                : l10n.authorizeAgain,
            busy: phase == AuthorizationPhase.inProgress,
            busyLabel: l10n.authInProgressTitle,
            icon: Icons.fingerprint,
            onPressed: onStart,
          )
        : null;
    final back =
        phase != AuthorizationPhase.inProgress &&
            phase != AuthorizationPhase.approved &&
            onBackToReview != null
        ? PaymentButton(
            label: l10n.backToReview,
            variant: PaymentButtonVariant.quiet,
            onPressed: onBackToReview,
          )
        : null;
    return ActionFrame(
      header: header,
      primaryAction: start,
      secondaryAction: back,
      builder: (context, pinned) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (exception)
            PaymentBanner(
              tone: tone,
              icon: icon,
              title: title,
              message: message,
              announce: true,
            )
          else
            Semantics(
              liveRegion: phase != AuthorizationPhase.ready,
              container: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(title, style: type.heading),
                  ),
                  SizedBox(height: theme.space(PaymentSpace.inline)),
                  Text(
                    message,
                    style: type
                        .bodyFor(context)
                        .copyWith(color: theme.textSecondary),
                  ),
                ],
              ),
            ),
          if (!pinned) ...[
            SizedBox(height: theme.space(PaymentSpace.section)),
            ?start,
            if (back != null) ...[
              SizedBox(height: theme.space(PaymentSpace.related)),
              back,
            ],
          ],
        ],
      ),
    );
  }
}
