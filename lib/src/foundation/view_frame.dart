import 'package:flutter/material.dart';
import 'payment_theme.dart';
import 'payment_type.dart';
import 'primitives.dart';
import 'payment_icons.dart';
import 'payment_tokens.dart';
import 'layout_rules.dart';
import 'button_copy.dart';
import 'first_line.dart';
import 'focus_ring.dart';
import 'tap_target.dart';
import '../controls/button_group.dart';
import '../interaction/interaction.dart';
import '../controls/actions.dart';
import 'token_resolvers.dart';
import 'payment_localizations.dart';
import 'kit_strings.dart';

/// Internal: the width [text] takes on one line in [style], as a `Text`
/// under the ambient default style and text scale draws it.
double oneLineWidth(BuildContext context, String text, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: DefaultTextStyle.of(context).style.merge(style),
    ),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    locale: Localizations.maybeLocaleOf(context),
    maxLines: 1,
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}

/// Internal: centres [child] in a column at most [maxWidth] wide (D53).
/// Phones are narrower than the cap, so they are unchanged.
class ContentColumn extends StatelessWidget {
  const ContentColumn({
    super.key,
    required this.child,
    this.maxWidth = kContentMaxWidth,
  });
  final Widget child;
  final double maxWidth;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    heightFactor: 1,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

/// Internal: the one pinned bottom band of the kit: views, `PaymentSheet`,
/// the full-height search and date sheets, and the action bar. A hairline on
/// top, then `group` padding or the bottom safe-area inset when that is
/// larger. The hairline spans its parent; with [maxContentWidth] the content
/// keeps that column cap, so it lines up with the content above it (D53).
class PinnedFooter extends StatelessWidget {
  const PinnedFooter({
    super.key,
    required this.child,
    this.padding,
    this.maxContentWidth = kContentMaxWidth,
  });
  final Widget child;

  /// Inset inside the safe area; defaults to `group` on every side.
  final EdgeInsets? padding;

  /// Column cap for the content. Null leaves the child at the full width,
  /// for a sheet whose body has no cap of its own.
  final double? maxContentWidth;
  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final cap = maxContentWidth;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.outline)),
      ),
      child: SafeArea(
        top: false,
        minimum: padding ?? EdgeInsets.all(theme.space(PaymentSpace.group)),
        child: cap == null ? child : ContentColumn(maxWidth: cap, child: child),
      ),
    );
  }
}

class ViewFrame extends StatelessWidget {
  const ViewFrame({
    super.key,
    this.header,
    required this.body,
    this.footer,
    this.bodyPadding,
    this.maxContentWidth = kContentMaxWidth,
  });

  /// Null leaves `section` above the body, so a brand mark never sits
  /// against the app bar.
  final Widget? header;
  final Widget body;
  final Widget? footer;
  final EdgeInsetsGeometry? bodyPadding;

  /// Widest content column; the header and footer keep the same edges.
  final double maxContentWidth;
  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final space = theme.space(PaymentSpace.group);
    final top = header == null ? theme.space(PaymentSpace.section) : 0.0;
    // The header carries its own `group` padding, so its column is wider by
    // that much on each side and its text shares the body's edges.
    final head = header == null
        ? null
        : ContentColumn(maxWidth: maxContentWidth + space * 2, child: header!);
    final content = ContentColumn(maxWidth: maxContentWidth, child: body);
    return LayoutBuilder(
      builder: (context, k) {
        final Widget? bottom = footer == null
            ? null
            : PinnedFooter(maxContentWidth: maxContentWidth, child: footer!);
        if (!k.hasBoundedHeight) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ?head,
              Padding(
                padding:
                    bodyPadding ??
                    EdgeInsets.fromLTRB(
                      space,
                      header == null ? top : space,
                      space,
                      space,
                    ),
                child: content,
              ),
              ?bottom,
            ],
          );
        }
        final padding =
            bodyPadding ?? EdgeInsets.fromLTRB(space, top, space, space);
        // At large text a pinned header can leave little room for the body,
        // so it scrolls away with the content instead (#49-4, #66).
        final scroll = PaymentType.isLarge(context)
            ? SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ?head,
                    Padding(padding: padding, child: content),
                  ],
                ),
              )
            : SingleChildScrollView(padding: padding, child: content);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!PaymentType.isLarge(context)) ?head,
            Expanded(child: scroll),
            ?bottom,
          ],
        );
      },
    );
  }
}

/// Internal: a header navigation action drawn as a link with a › glyph
/// inside its 48 dp target, whose text ends on the column edge (D59a).
class HeaderLink extends StatelessWidget {
  const HeaderLink({
    super.key,
    required this.label,
    required this.onPressed,
    this.semanticLabel,
    this.external = false,
    this.alignment = AlignmentDirectional.centerEnd,
  });
  final String label;
  final VoidCallback? onPressed;
  final String? semanticLabel;

  /// Opens outside the app: link role and the "opens externally" hint.
  final bool external;

  /// Where the text sits in its 48 dp target: on the end edge on the title
  /// row, on the start edge when the link has its own line.
  final AlignmentGeometry alignment;

  /// Width of [label] and its › glyph on one line, for the header's fit
  /// check.
  static double naturalWidth(BuildContext context, String label) =>
      oneLineWidth(context, label, PaymentType.of(context).heading) +
      PaymentIconSize.medium.resolve(context);
  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    final style = type.heading;
    return Semantics(
      container: true,
      excludeSemantics: true,
      button: !external,
      link: external,
      enabled: onPressed != null,
      label: semanticLabel ?? label,
      hint: external ? PaymentLocalizations.of(context).opensExternally : null,
      onTap: onPressed,
      child: MinTapTarget(
        alignment: alignment,
        child: PaymentFocusRing(
          radius: theme.controlBorderRadius,
          child: PaymentPressScale(
            enabled: onPressed != null,
            child: TextButton(
              onPressed: onPressed,
              style: PaymentFocusRing.withoutFocusFill(
                TextButton.styleFrom(
                  foregroundColor: theme.accent,
                  disabledForegroundColor: theme.disabled,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.standard,
                  shape: RoundedRectangleBorder(
                    borderRadius: theme.controlBorderRadius,
                  ),
                  textStyle: style,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(child: Text(label)),
                  SizedBox(
                    height:
                        MediaQuery.textScalerOf(
                          context,
                        ).scale(style.fontSize!) *
                        style.height!,
                    child: Center(
                      child: Icon(
                        PaymentIcons.forward,
                        size: PaymentIconSize.medium.resolve(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Page header (D59a). On phones it holds navigation only: [link], or one
/// action, sits on the title row as "Label ›"; two or more actions go behind
/// ⋮ (the D55 action sheet). Wide screens keep their hug buttons.
class ViewHeader extends StatelessWidget {
  const ViewHeader({
    super.key,
    required this.title,
    this.description,
    this.leading,
    this.link,
    this.actions = const [],
    this.inlineActions = false,
    this.above,
    this.below,
  });
  final String title;
  final String? description;
  final Widget? leading;

  /// Navigation on the title row at every width.
  final PaymentLink? link;

  /// Header actions; see the class doc for the phone layout.
  final List<PaymentButton> actions;

  /// On wide screens, puts [actions] on the title row instead of under it.
  final bool inlineActions;

  /// Shown above the title with no gap of its own, e.g. a breadcrumb.
  final Widget? above;
  final Widget? below;
  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    final space = theme.space(PaymentSpace.group);
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: theme.space(PaymentSpace.inline),
      children: [
        Semantics(header: true, child: Text(title, style: type.title)),
        if (description != null)
          Text(
            description!,
            style: type.bodyFor(context).copyWith(color: theme.textSecondary),
          ),
      ],
    );
    final lead = switch (leading) {
      null => null,
      PaymentIcon() => leading,
      _ => SizedBox.square(dimension: kMediaTile, child: leading),
    };
    return Padding(
      // A breadcrumb's 48 dp target already spaces it from the edge above.
      padding: EdgeInsets.fromLTRB(
        space,
        above == null ? space : theme.space(PaymentSpace.inline),
        space,
        space,
      ),
      child: LayoutBuilder(
        builder: (context, k) {
          final compact = k.maxWidth < kCompactBreakpoint;
          final large = PaymentType.isLarge(context);
          final menu = PaymentMenu(
            entries: [
              for (final a in actions)
                PaymentMenuItem(
                  label: a.label,
                  destructive: a.variant == PaymentButtonVariant.destructive,
                  onSelected: a.onPressed == null ? null : () => a.onPressed!(),
                ),
            ],
          );
          // One header link at most: the page link, or a phone's single
          // action.
          final single = compact && actions.length == 1 && link == null
              ? actions.single
              : null;
          final linkLabel = link?.label ?? single?.label;
          final hasMenu = compact && actions.isNotEmpty && single == null;
          Widget? headerLink(AlignmentGeometry alignment) => link != null
              ? HeaderLink(
                  key: link!.key,
                  label: link!.label,
                  semanticLabel: link!.semanticLabel,
                  external: link!.external,
                  onPressed: link!.onPressed,
                  alignment: alignment,
                )
              : single != null
              ? HeaderLink(
                  key: single.key,
                  label: single.label,
                  onPressed: single.onPressed,
                  alignment: alignment,
                )
              : null;
          // The title has priority and never breaks inside a word: when the
          // title on one line and the link don't fit side by side, the link
          // takes its own line under the header text, start-aligned.
          final leadWidth = switch (leading) {
            null => 0.0,
            PaymentIcon(:final size) =>
              size.resolve(context) + theme.space(PaymentSpace.block),
            _ => kMediaTile + theme.space(PaymentSpace.block),
          };
          final linkOnRow =
              linkLabel != null &&
              oneLineWidth(context, title, type.title) +
                      space +
                      HeaderLink.naturalWidth(context, linkLabel) +
                      (hasMenu ? kMinInteractiveDimension : 0) <=
                  k.maxWidth - leadWidth;
          final nav = [
            if (linkOnRow) headerLink(AlignmentDirectional.centerEnd)!,
            if (hasMenu) menu,
            if (!compact && inlineActions && !large && actions.isNotEmpty)
              PaymentButtonGroup(
                children: [for (final a in actions) hugButton(a)],
              ),
          ];
          final actionsBelow = !compact && (!inlineActions || large);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ?above,
              FirstLineRow(
                leading: lead,
                line: lineHeightOf(context, type.title),
                gap: theme.space(PaymentSpace.block),
                trailingGap: space,
                text: copy,
                trailing: nav.isEmpty
                    ? null
                    // A link on the row already fits beside the title; other
                    // navigation never takes more than half the row, so a
                    // long label at large text can't squeeze the title out.
                    : ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: linkOnRow
                              ? double.infinity
                              : k.maxWidth / 2,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [for (final n in nav) Flexible(child: n)],
                        ),
                      ),
              ),
              if (linkLabel != null && !linkOnRow) ...[
                SizedBox(height: theme.space(PaymentSpace.related)),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: headerLink(AlignmentDirectional.centerStart),
                ),
              ],
              if (actionsBelow && actions.isNotEmpty) ...[
                SizedBox(height: theme.space(PaymentSpace.block)),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: PaymentButtonGroup(children: actions),
                ),
              ],
              if (below != null) ...[
                SizedBox(height: theme.space(PaymentSpace.block)),
                below!,
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Footer actions (D59): below 600 dp, and at large text, a full-width
/// stack with the primary on top; wider, hug buttons at the end edge.
class ViewFooter extends StatelessWidget {
  const ViewFooter({
    super.key,
    this.primaryAction,
    this.secondaryAction,
    this.footer,
  });
  final PaymentButton? primaryAction, secondaryAction;
  final Widget? footer;
  @override
  Widget build(BuildContext context) {
    final actions = [
      if (secondaryAction != null) hugButton(secondaryAction!),
      if (primaryAction != null) hugButton(primaryAction!),
    ];
    assert(
      actions.where((a) => a.variant == PaymentButtonVariant.primary).length <=
          1,
    );
    return LayoutBuilder(
      builder: (context, k) {
        final group = actions.isEmpty
            ? const SizedBox.shrink()
            : PaymentButtonGroup(
                collapse: PaymentButtonGroupCollapse.none,
                children: actions,
              );
        if (k.maxWidth < kCompactBreakpoint || PaymentType.isLarge(context)) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: PaymentTheme.of(context).space(PaymentSpace.related),
            children: [
              ?footer,
              if (primaryAction != null || secondaryAction != null)
                PaymentButtonGroup(
                  direction: Axis.vertical,
                  children: [?primaryAction, ?secondaryAction],
                ),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: footer ?? const SizedBox.shrink()),
            group,
          ],
        );
      },
    );
  }
}
