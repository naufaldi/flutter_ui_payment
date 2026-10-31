import '../foundation/payment_icons.dart';
import '../controls/actions.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import '../foundation/kit_strings.dart';
import '../foundation/payment_localizations.dart';
import '../foundation/payment_theme.dart';
import '../foundation/payment_type.dart';
import '../foundation/primitives.dart';
import '../interaction/interaction.dart';

/// Whether content is paid placement or the host's own offer. Both are
/// always labeled; a sponsored item also names who paid for it.
enum PromoKind { sponsored, promotion }

/// Host-supplied promotion. The kit renders it and reports taps; it never
/// fetches campaigns, tracks impressions or applies discounts itself.
@immutable
class PromoContent {
  const PromoContent({
    required this.id,
    required this.kind,
    required this.title,
    required this.ctaLabel,
    this.message,
    this.advertiser,
    this.icon,
    this.media,
    this.terms,
  }) : assert(
         kind != PromoKind.sponsored || advertiser != null,
         'Sponsored content must name the advertiser.',
       );

  final String id;
  final PromoKind kind;
  final String title;
  final String? message;
  final String ctaLabel;

  /// Who paid for a sponsored placement.
  final String? advertiser;

  /// Kept for compatibility. Cards no longer draw it: a generic icon beside
  /// the title adds nothing the title does not already say.
  final IconData? icon;

  /// Optional image or illustration supplied by the host (already loaded or
  /// with its own loading state). Decorative: excluded from semantics.
  /// Prefer PaymentImage with empty alt; the card labels the promotion.
  final Widget? media;

  /// Short conditions, e.g. "Until 31 Dec. Min. purchase Rp50.000".
  final String? terms;
}

enum PromoLayout { card, banner }

/// A clearly labeled promotion with a call to action and optional dismiss.
///
/// [onAction] and [onDismiss] go to the host, which decides what the CTA
/// does and whether a dismissed promo stays hidden. Promotions never sit
/// between the customer and the pay button, and never change a quote.
class PromoCard extends StatelessWidget {
  const PromoCard({
    super.key,
    required this.content,
    required this.onAction,
    this.onDismiss,
    this.onAbout,
    this.layout = PromoLayout.card,
  });

  final PromoContent content;
  final FutureOr<void> Function() onAction;
  final VoidCallback? onDismiss;

  /// Opens the host's "why am I seeing this" explanation.
  final VoidCallback? onAbout;
  final PromoLayout layout;

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final l10n = PaymentLocalizations.of(context);
    final type = PaymentType.of(context);
    final sponsored = content.kind == PromoKind.sponsored;
    final disclosure = sponsored
        ? '${l10n.sponsored} · ${content.advertiser}'
        : l10n.promotion;
    // At large text sizes the banner's side-by-side CTA no longer fits, so it
    // stacks under the copy like the card layout does.
    final stacked = PaymentType.isLarge(context);
    final banner = layout == PromoLayout.banner;
    final caption = type.caption;

    // A link set no larger than the disclosure it explains, on a full 48 dp
    // target. At large text sizes it moves under the disclosure.
    final why = onAbout == null
        ? null
        : PaymentLink(
            label: l10n.whyThisAd,
            variant: PaymentLinkVariant.secondary,
            onPressed: onAbout,
          );

    // One muted caption line, "Sponsored · Bank Contoh". It wraps instead of
    // truncating: who paid for a sponsored placement must stay visible at
    // every text size. The card's semantics label already reads it whole.
    final label = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: theme.spacing * 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: theme.spacing * 0.5,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      sponsored ? l10n.sponsored : l10n.promotion,
                      style: caption,
                    ),
                    if (sponsored) ...[
                      ExcludeSemantics(child: Text('·', style: caption)),
                      Text(content.advertiser!, style: caption),
                    ],
                  ],
                ),
                if (stacked) ?why,
              ],
            ),
          ),
        ),
        if (!stacked) ?why,
        if (onDismiss != null)
          PaymentIconButton(
            icon: PaymentIcons.close,
            tooltip: '${l10n.dismiss}: ${content.title}',
            onPressed: onDismiss,
          ),
      ],
    );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(content.title, style: type.heading),
        if (content.message != null) ...[
          SizedBox(height: theme.spacing * 0.5),
          Text(
            content.message!,
            style: type.bodyFor(context).copyWith(color: theme.textSecondary),
          ),
        ],
        if (content.terms != null) ...[
          SizedBox(height: theme.spacing * 0.5),
          Text(content.terms!, style: caption),
        ],
      ],
    );

    final leading = content.media != null
        ? ExcludeSemantics(
            child: ClipRRect(
              borderRadius: theme.tagBorderRadius,
              child: SizedBox.square(
                dimension: banner ? 48 : 64,
                child: content.media,
              ),
            ),
          )
        // A generic icon beside the title only indents the copy; the title
        // already says what the offer is.
        : null;
    final leadingGap = SizedBox(
      width: content.media != null ? theme.spacing * 1.5 : theme.spacing,
    );

    final quietCta = PaymentLink(label: content.ctaLabel, onPressed: onAction);

    // The one bordered box here: a promo is a single dismissible object.
    return Semantics(
      container: true,
      label: disclosure,
      child: Container(
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: theme.borderRadius,
          border: Border.all(color: theme.outline),
        ),
        padding: EdgeInsetsDirectional.fromSTEB(
          theme.spacing * 2,
          0,
          theme.spacing * 0.5,
          theme.spacing * 2,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            label,
            Padding(
              padding: EdgeInsetsDirectional.only(end: theme.spacing * 1.5),
              child: banner
                  ? (stacked
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ?leading,
                                  if (leading != null) leadingGap,
                                  Expanded(child: body),
                                ],
                              ),
                              SizedBox(height: theme.spacing),
                              quietCta,
                            ],
                          )
                        : LayoutBuilder(
                            // The CTA keeps its natural width so the title gets
                            // the room, but a long host label wraps at 40% of
                            // the row instead of overflowing it.
                            builder: (context, constraints) => Row(
                              children: [
                                ?leading,
                                if (leading != null) leadingGap,
                                Expanded(child: body),
                                SizedBox(width: theme.spacing),
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: constraints.maxWidth * 0.4,
                                  ),
                                  child: quietCta,
                                ),
                              ],
                            ),
                          ))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ?leading,
                            if (leading != null) leadingGap,
                            Expanded(child: body),
                          ],
                        ),
                        SizedBox(height: theme.spacing * 2),
                        PaymentButton(
                          label: content.ctaLabel,
                          variant: PaymentButtonVariant.secondary,
                          onPressed: onAction,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Where a promotion slot is while the host loads it.
enum PromoSlotState { loading, ready, empty, error }

/// A placement that can be loading, filled, empty or failed.
///
/// Empty and failed slots collapse by default ([collapseWhenEmpty]): a
/// missing offer should not leave a hole or an error in a checkout. Turn it
/// off where the slot is the content, such as an offers page.
class PromoSlot extends StatelessWidget {
  const PromoSlot({
    super.key,
    required this.state,
    required this.onAction,
    this.content,
    this.onDismiss,
    this.onAbout,
    this.onRetry,
    this.layout = PromoLayout.card,
    this.collapseWhenEmpty = true,
  });

  final PromoSlotState state;
  final PromoContent? content;
  final FutureOr<void> Function(PromoContent content) onAction;
  final ValueChanged<PromoContent>? onDismiss;
  final ValueChanged<PromoContent>? onAbout;
  final FutureOr<void> Function()? onRetry;
  final PromoLayout layout;
  final bool collapseWhenEmpty;

  @override
  Widget build(BuildContext context) {
    final l10n = PaymentLocalizations.of(context);
    final theme = PaymentTheme.of(context);
    switch (state) {
      case PromoSlotState.loading:
        return Container(
          padding: EdgeInsets.symmetric(horizontal: theme.spacing * 1.5),
          decoration: BoxDecoration(
            borderRadius: theme.borderRadius,
            border: Border.all(color: theme.outline),
          ),
          child: const LoadingSkeleton(rows: 1),
        );
      case PromoSlotState.ready:
        final c = content!;
        return PromoCard(
          content: c,
          layout: layout,
          onAction: () => onAction(c),
          onDismiss: onDismiss == null ? null : () => onDismiss!(c),
          onAbout: onAbout == null ? null : () => onAbout!(c),
        );
      case PromoSlotState.empty:
        if (collapseWhenEmpty) return const SizedBox.shrink();
        return StateMessage(
          icon: Icons.local_offer_outlined,
          title: l10n.promoUnavailable,
        );
      case PromoSlotState.error:
        if (collapseWhenEmpty) return const SizedBox.shrink();
        return StateMessage(
          icon: Icons.cloud_off_outlined,
          tone: StatusTone.warning,
          title: l10n.promoLoadFailed,
          actionLabel: onRetry == null ? null : l10n.retry,
          onAction: onRetry,
        );
    }
  }
}
