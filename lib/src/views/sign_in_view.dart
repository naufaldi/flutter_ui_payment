import '../interaction/interaction.dart';
import 'package:flutter/material.dart';
import '../foundation/primitives.dart';
import '../foundation/focus_ring.dart';
import '../foundation/payment_icons.dart';
import '../foundation/payment_theme.dart';
import '../foundation/payment_type.dart';
import '../foundation/payment_localizations.dart';
import '../foundation/first_line.dart';
import '../foundation/view_frame.dart';
import '../controls/actions.dart';
import '../layout/content.dart';
import '../overlay/sheets.dart';
import '../foundation/payment_tokens.dart';
import '../foundation/token_resolvers.dart';

/// Supplemental explanation presented separately in a focus view.
@immutable
class PaymentSignInLearnMore {
  const PaymentSignInLearnMore({
    required this.label,
    required this.title,
    required this.builder,
  });

  /// Visible label for the control.
  final String label;

  /// Heading displayed above the content.
  final String title;

  /// Builds the supplemental explanation.
  final WidgetBuilder builder;
}

/// External sign-in entry point with no credential input or free content slot.
///
/// An account-linking screen (D61): both app tiles, one specific headline,
/// what the connecting app can and can never do in plain view, and a pinned
/// footer with one legal sentence, a short primary and a quiet cancel, so
/// the action is on the first screen at any text size.
class PaymentSignInView extends StatefulWidget {
  const PaymentSignInView({
    super.key,
    required this.primaryAction,
    this.title,
    this.description,
    this.brand,
    this.requesterBrand,
    this.canDo = const [],
    this.cannotDo = const [],
    this.legalNotice,
    @Deprecated(
      'Show what the app can see with canDo and cannotDo. Removed in 0.2.0.',
    )
    this.learnMore,
    this.secondaryAction,
    this.legalLinks = const [],
    @Deprecated(
      'Put reassurance such as "never sees your PIN" in cannotDo. '
      'Removed in 0.2.0.',
    )
    this.footnote,
    this.errorText,
  });

  /// The single primary action that starts host sign-in, such as "Continue".
  final PaymentButton primaryAction;

  /// Heading displayed above the content, such as "Sign in with Ruang Bayar".
  final String? title;

  /// Supporting explanation below the heading.
  final String? description;

  /// Host brand icon or image: the account being signed in to.
  final Widget? brand;

  /// The connecting app's icon or image, shown before [brand].
  final Widget? requesterBrand;

  /// What the connecting app can do, shown with ✓.
  final List<String> canDo;

  /// What the connecting app can never do, shown with ✕.
  final List<String> cannotDo;

  /// One legal sentence above the actions. `{0}`, `{1}` … become inline
  /// links to the matching [legalLinks]. Without it, [legalLinks] show as a
  /// row of links.
  final String? legalNotice;

  /// Disclosure that opens a supplemental explanation.
  @Deprecated(
    'Show what the app can see with canDo and cannotDo. Removed in 0.2.0.',
  )
  final PaymentSignInLearnMore? learnMore;

  /// Optional quiet action under the primary, such as "Cancel".
  final PaymentButton? secondaryAction;

  /// Host terms and privacy destinations.
  final List<PaymentLink> legalLinks;

  /// Short reassurance below the content.
  @Deprecated(
    'Put reassurance such as "never sees your PIN" in cannotDo. '
    'Removed in 0.2.0.',
  )
  final String? footnote;

  /// Safe error message displayed beside the control.
  final String? errorText;
  @override
  State<PaymentSignInView> createState() => _PaymentSignInViewState();
}

class _PaymentSignInViewState extends State<PaymentSignInView> {
  final _errorFocus = FocusNode();
  void focusError() {
    if (widget.errorText != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _errorFocus.requestFocus();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    focusError();
  }

  @override
  void didUpdateWidget(covariant PaymentSignInView old) {
    super.didUpdateWidget(old);
    if (old.errorText != widget.errorText) focusError();
  }

  @override
  void dispose() {
    _errorFocus.dispose();
    super.dispose();
  }

  /// The legal sentence with `{n}` replaced by inline links.
  ///
  /// Each link is a focusable inline control (#235): keyboard focus reaches
  /// it in reading order, Enter or Space activates it and it shows the kit
  /// focus ring. It stays an inline caption link, exempt from the 48 dp
  /// target rule (D61, WCAG 2.5.8).
  Widget _legal(BuildContext context, String notice) {
    final theme = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    final spans = <InlineSpan>[];
    var start = 0;
    for (final m in RegExp(r'\{(\d+)\}').allMatches(notice)) {
      spans.add(TextSpan(text: notice.substring(start, m.start)));
      final i = int.parse(m.group(1)!);
      if (i < widget.legalLinks.length) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: _InlineLegalLink(
              link: widget.legalLinks[i],
              style: type.caption.copyWith(
                color: theme.textPrimary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        );
      }
      start = m.end;
    }
    spans.add(TextSpan(text: notice.substring(start)));
    return Text.rich(
      TextSpan(children: spans),
      style: type.caption.copyWith(color: theme.textSecondary),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final theme = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    final l = PaymentLocalizations.of(context);
    bool isMark(Widget? b) =>
        b == null || b is PaymentImage || b is PaymentIcon;
    assert(isMark(w.brand) && isMark(w.requesterBrand));
    assert(
      w.secondaryAction?.variant != PaymentButtonVariant.primary &&
          w.secondaryAction?.variant != PaymentButtonVariant.destructive,
    );
    // ignore: deprecated_member_use_from_same_package
    final learnMore = w.learnMore;
    // ignore: deprecated_member_use_from_same_package
    final footnote = w.footnote;
    final gap = theme.space(PaymentSpace.group);
    Widget tile(Widget mark, {required bool host}) => SizedBox.square(
      dimension: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: host ? theme.accent : theme.surfaceMuted,
          borderRadius: theme.sheetBorderRadius,
        ),
        child: ClipRRect(
          borderRadius: theme.sheetBorderRadius,
          child: IconTheme.merge(
            data: IconThemeData(
              color: host ? theme.onAccent : theme.textPrimary,
            ),
            child: mark is PaymentImage ? mark : Center(child: mark),
          ),
        ),
      ),
    );
    final dots = ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: theme.space(PaymentSpace.related),
        children: [
          for (var i = 0; i < 3; i++)
            DecoratedBox(
              decoration: BoxDecoration(
                color: theme.textSecondary,
                shape: BoxShape.circle,
              ),
              child: const SizedBox.square(dimension: 4),
            ),
        ],
      ),
    );
    Widget scope(String heading, List<String> items, bool can) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.space(PaymentSpace.related),
      children: [
        Semantics(
          header: true,
          child: Text(
            heading,
            style: type.heading.copyWith(color: theme.textSecondary),
          ),
        ),
        for (final item in items)
          FirstLineRow(
            leading: Icon(
              can ? Icons.check : Icons.close,
              size: PaymentIconSize.medium.resolve(context),
              color: can
                  ? theme.tone(StatusTone.success).foreground
                  : theme.tone(StatusTone.danger).foreground,
            ),
            text: Text(item, style: type.label),
          ),
      ],
    );
    final legal = w.legalNotice != null
        ? _legal(context, w.legalNotice!)
        : w.legalLinks.isEmpty
        ? null
        : Wrap(spacing: gap, children: w.legalLinks);
    return ViewFrame(
      // A narrow column, as the old 420 cap: header text, lists and the
      // footer share its edges.
      maxContentWidth: 420,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: gap,
        children: [
          if (w.brand != null || w.requesterBrand != null)
            Row(
              spacing: theme.space(PaymentSpace.group),
              children: [
                if (w.requesterBrand != null)
                  tile(w.requesterBrand!, host: false),
                if (w.requesterBrand != null && w.brand != null) dots,
                if (w.brand != null) tile(w.brand!, host: true),
              ],
            ),
          Semantics(
            header: true,
            child: Text(w.title ?? l.signInTitle, style: type.title),
          ),
          if (w.description != null)
            Text(
              w.description!,
              style: type.bodyFor(context).copyWith(color: theme.textSecondary),
            ),
          if (w.canDo.isNotEmpty || w.cannotDo.isNotEmpty)
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: theme.outline),
                borderRadius: theme.borderRadius,
              ),
              child: Padding(
                padding: EdgeInsets.all(gap),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: gap,
                  children: [
                    if (w.canDo.isNotEmpty) scope(l.signInCan, w.canDo, true),
                    if (w.cannotDo.isNotEmpty)
                      scope(l.signInCannot, w.cannotDo, false),
                  ],
                ),
              ),
            ),
          if (learnMore != null)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: PaymentListItem(
                icon: Icons.info_outline,
                title: learnMore.label,
                trailing: const PaymentIcon(Icons.chevron_right),
                onPressed: () => showPaymentFocusView<void>(
                  context,
                  builder: (_) => PaymentFocusView(
                    title: learnMore.title,
                    child: Builder(builder: learnMore.builder),
                  ),
                ),
              ),
            ),
          if (w.errorText != null)
            Focus(
              focusNode: _errorFocus,
              child: PaymentBanner(
                tone: StatusTone.danger,
                title: w.errorText!,
                announce: true,
              ),
            ),
          if (footnote != null) Text(footnote, style: type.caption),
        ],
      ),
      footer: ViewFooter(
        footer: legal,
        primaryAction: w.primaryAction,
        secondaryAction: w.secondaryAction,
      ),
    );
  }
}

/// One link inside the legal sentence: the host's [PaymentLink] label and
/// callback, drawn as underlined caption text that a keyboard can reach.
class _InlineLegalLink extends StatelessWidget {
  const _InlineLegalLink({required this.link, required this.style});

  final PaymentLink link;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final onPressed = link.onPressed;
    final enabled = onPressed != null;
    return PaymentFocusRing(
      radius: PaymentTheme.of(context).controlBorderRadius,
      child: Semantics(
        container: true,
        link: true,
        enabled: enabled,
        label: link.semanticLabel ?? link.label,
        onTap: onPressed,
        child: FocusableActionDetector(
          enabled: enabled,
          mouseCursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                onPressed?.call();
                return null;
              },
            ),
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            onTap: onPressed,
            // The sentence already scales this placeholder with the text.
            child: ExcludeSemantics(
              child: Text(
                link.label,
                style: style,
                textScaler: TextScaler.noScaling,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
