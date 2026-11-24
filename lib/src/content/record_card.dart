import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../foundation/first_line.dart';
import '../foundation/focus_ring.dart';
import '../foundation/layout_rules.dart';
import '../foundation/payment_theme.dart';
import '../foundation/payment_tokens.dart';
import '../foundation/payment_type.dart';
import '../foundation/primitives.dart';

/// Placement of the divider above a [PaymentRecordCard] footer.
enum PaymentRecordCardDivider {
  /// Draws the divider across the card, the default.
  fullWidth,

  /// Aligns the divider with the footer's horizontal inset.
  inset,

  /// Does not draw a divider.
  none,
}

/// Optional appearance overrides for a [PaymentRecordCard].
class PaymentRecordCardStyle {
  const PaymentRecordCardStyle({
    this.titleStyle,
    this.metadataStyle,
    this.inset,
    this.divider = PaymentRecordCardDivider.fullWidth,
    this.elevation = 0,
  }) : assert(inset == null || (inset >= 0 && inset < double.infinity)),
       assert(elevation >= 0 && elevation < double.infinity);

  /// Merged over the kit heading style for the title slot.
  final TextStyle? titleStyle;

  /// Merged over the kit caption style for the metadata slot.
  final TextStyle? metadataStyle;

  /// Outer inset in dp around the body row and footer. Defaults to the kit's
  /// block spacing. Extra horizontal inset yields to the title and 48 dp
  /// action targets when space is tight.
  final double? inset;

  /// Divider above the footer. Has no effect without a footer.
  final PaymentRecordCardDivider divider;

  /// Material elevation in dp. Defaults to a flat card.
  final double elevation;
}

/// A record surface with a separately actionable body, trailing slot and footer.
/// Only the body opens the record. Use passive widgets for the title, leading
/// visual and metadata, and put controls in [trailing] or [footer].
class PaymentRecordCard extends StatelessWidget {
  const PaymentRecordCard({
    super.key,
    required this.title,
    this.leading,
    this.metadata,
    this.trailing,
    this.footer,
    this.onOpen,
    this.openLabel,
    this.hugTrailing = false,
    this.style = const PaymentRecordCardStyle(),
  });

  /// A record title, styled as a heading by default.
  final Widget title;

  /// A decorative icon or thumbnail, limited to 40 × 40 dp and not spoken.
  final Widget? leading;

  /// Supporting content below the title, styled as a caption by default.
  final Widget? metadata;

  /// An independent end slot. It moves below the body at large text sizes
  /// or when the inline slot would be narrower than 48 dp.
  final Widget? trailing;

  /// An independent full-width slot below a divider.
  final Widget? footer;

  /// Opens the record from its body. If omitted, the body is read-only.
  final VoidCallback? onOpen;

  /// Replaces the open action's spoken title and metadata, when supplied.
  final String? openLabel;

  /// Lets an inline trailing slot take only the width its child needs, up to
  /// the default one-third allocation. Stacking and tap targets are unchanged.
  final bool hugTrailing;

  /// Appearance overrides. Unspecified properties keep the kit defaults.
  final PaymentRecordCardStyle style;

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    final gap = theme.space(PaymentSpace.related);
    final block = theme.space(PaymentSpace.block);
    final inset = style.inset ?? block;
    final radius = theme.controlBorderRadius;
    final titleStyle = type.heading.merge(style.titleStyle);
    final titleLine = lineHeightOf(context, titleStyle);
    Widget body = Padding(
      padding: EdgeInsets.all(gap),
      child: FirstLineRow(
        gap: block,
        line: style.titleStyle == null ? null : titleLine,
        leading: leading == null
            ? null
            : ExcludeSemantics(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: kMediaTile,
                    maxHeight: kMediaTile,
                  ),
                  child: leading,
                ),
              ),
        text: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DefaultTextStyle.merge(style: titleStyle, child: title),
            if (metadata case final metadata?) ...[
              SizedBox(height: theme.space(PaymentSpace.inline)),
              DefaultTextStyle.merge(
                style: type.caption.merge(style.metadataStyle),
                child: metadata,
              ),
            ],
          ],
        ),
      ),
    );
    if (onOpen != null) {
      body = MergeSemantics(
        child: Semantics(
          button: true,
          enabled: true,
          label: openLabel,
          onTap: onOpen,
          child: PaymentFocusRing(
            radius: radius,
            child: InkWell(
              borderRadius: radius,
              excludeFromSemantics: true,
              focusColor: Colors.transparent,
              onTap: onOpen,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: ExcludeSemantics(
                    excluding: openLabel != null,
                    child: body,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Material(
      color: theme.surface,
      elevation: style.elevation,
      shape: RoundedRectangleBorder(
        borderRadius: theme.borderRadius,
        side: BorderSide(color: theme.outline),
      ),
      child: _RecordCardLayout(
        body: body,
        trailing: trailing,
        footer: footer,
        divider:
            footer != null && style.divider != PaymentRecordCardDivider.none
            ? const PaymentDivider()
            : null,
        geometry: (
          inset: inset,
          block: block,
          gap: gap,
          minBodyWidth: math.max(
            kMinInteractiveDimension,
            3 * titleLine +
                2 * gap +
                (leading == null ? 0 : kMediaTile + block),
          ),
          fitCustomInset: style.inset != null,
          insetDivider: style.divider == PaymentRecordCardDivider.inset,
          largeText: PaymentType.isLarge(context),
          hugTrailing: hugTrailing,
          direction: Directionality.of(context),
        ),
      ),
    );
  }
}

enum _RecordSlot { body, trailing, divider, footer }

typedef _RecordGeometry = ({
  double inset,
  double block,
  double gap,
  double minBodyWidth,
  bool fitCustomInset,
  bool insetDivider,
  bool largeText,
  bool hugTrailing,
  TextDirection direction,
});

// Keep each action in its slot when its neighbours or the layout change.
class _RecordCardLayout
    extends SlottedMultiChildRenderObjectWidget<_RecordSlot, RenderBox> {
  const _RecordCardLayout({
    required this.body,
    required this.trailing,
    required this.divider,
    required this.footer,
    required this.geometry,
  });

  final Widget body;
  final Widget? trailing;
  final Widget? divider;
  final Widget? footer;
  final _RecordGeometry geometry;

  @override
  Iterable<_RecordSlot> get slots => _RecordSlot.values;

  @override
  Widget? childForSlot(_RecordSlot slot) {
    final child = switch (slot) {
      _RecordSlot.body => body,
      _RecordSlot.trailing => trailing,
      _RecordSlot.divider => divider,
      _RecordSlot.footer => footer,
    };
    // Host-local keys in separate slots must not share a parent.
    return child == null
        ? null
        : KeyedSubtree(key: ValueKey(slot), child: child);
  }

  @override
  _RenderRecordCard createRenderObject(BuildContext context) =>
      _RenderRecordCard(geometry);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderRecordCard renderObject,
  ) {
    renderObject.geometry = geometry;
  }
}

class _RenderRecordCard extends RenderBox
    with SlottedContainerRenderObjectMixin<_RecordSlot, RenderBox> {
  _RenderRecordCard(this._geometry);

  _RecordGeometry _geometry;
  set geometry(_RecordGeometry value) {
    if (_geometry == value) return;
    _geometry = value;
    markNeedsLayout();
  }

  @override
  Iterable<RenderBox> get children =>
      _RecordSlot.values.map(childForSlot).nonNulls;

  double _bodyInset(double width) {
    final g = _geometry;
    final inset = g.inset;
    if (!g.fitCustomInset && childForSlot(_RecordSlot.trailing) == null) {
      return inset;
    }
    final targetInset = ((width - kMinInteractiveDimension) / 2).clamp(
      0.0,
      inset,
    );
    if (inset <= g.block) return targetInset;
    // Standard gutters stay; extra inset yields to the leading visual and title.
    return ((width - g.minBodyWidth) / 2).clamp(
      targetInset.clamp(0.0, g.block),
      inset,
    );
  }

  double _arrange(
    double width,
    Size Function(RenderBox, BoxConstraints) measure, [
    void Function(RenderBox, Offset)? place,
  ]) {
    final g = _geometry;
    final bodyInset = _bodyInset(width);
    final rowWidth = math.max(0.0, width - 2 * bodyInset);
    final trailing = childForSlot(_RecordSlot.trailing);
    final third = (rowWidth - g.gap) / 3;
    final stacked =
        trailing != null &&
        (g.largeText ||
            third < kMinInteractiveDimension ||
            (g.inset > g.block && 2 * third < g.minBodyWidth));
    final trailingSize = trailing == null
        ? Size.zero
        : measure(
            trailing,
            BoxConstraints(maxWidth: stacked ? rowWidth : third),
          );
    final body = childForSlot(_RecordSlot.body)!;
    final bodyWidth = trailing == null || stacked
        ? rowWidth
        : rowWidth - g.gap - (g.hugTrailing ? trailingSize.width : third);
    final bodySize = measure(body, BoxConstraints.tightFor(width: bodyWidth));
    final band = stacked
        ? bodySize.height
        : math.max(bodySize.height, trailingSize.height);
    place?.call(
      body,
      Offset(
        g.direction == TextDirection.ltr
            ? bodyInset
            : width - bodyInset - bodyWidth,
        g.inset + (band - bodySize.height) / 2,
      ),
    );
    if (trailing != null) {
      place?.call(
        trailing,
        Offset(
          g.direction == TextDirection.ltr
              ? width - bodyInset - trailingSize.width
              : bodyInset,
          g.inset + (stacked ? band + g.gap : (band - trailingSize.height) / 2),
        ),
      );
    }

    var top = 2 * g.inset + band + (stacked ? g.gap + trailingSize.height : 0);
    final footerInset = g.fitCustomInset ? bodyInset : g.inset;
    if (childForSlot(_RecordSlot.divider) case final divider?) {
      final inset = g.insetDivider ? footerInset : 0.0;
      place?.call(divider, Offset(inset, top));
      top += measure(
        divider,
        BoxConstraints.tightFor(width: math.max(0.0, width - 2 * inset)),
      ).height;
    }
    if (childForSlot(_RecordSlot.footer) case final footer?) {
      final footerSize = measure(
        footer,
        BoxConstraints.tightFor(width: math.max(0.0, width - 2 * footerInset)),
      );
      place?.call(footer, Offset(footerInset, top + g.inset));
      top += 2 * g.inset + footerSize.height;
    }
    return top;
  }

  Size _measure(
    BoxConstraints constraints,
    Size Function(RenderBox, BoxConstraints) measure, [
    void Function(RenderBox, Offset)? place,
  ]) {
    final width = constraints.hasBoundedWidth
        ? constraints.maxWidth
        : constraints.constrainWidth(getMaxIntrinsicWidth(double.infinity));
    final height = _arrange(width, measure, place);
    return constraints.constrain(
      Size(
        width,
        constraints.hasBoundedHeight ? constraints.maxHeight : height,
      ),
    );
  }

  @override
  void performLayout() {
    size = _measure(
      constraints,
      (child, c) => (child..layout(c, parentUsesSize: true)).size,
      (child, offset) => (child.parentData! as BoxParentData).offset = offset,
    );
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _measure(constraints, (child, c) => child.getDryLayout(c));

  double _intrinsicWidth(double Function(RenderBox, double) measure) {
    var width = 0.0;
    for (final child in children) {
      // Like a Column's non-flex children, the slots contribute their width
      // at their own natural height, not at the card's full height budget.
      width = math.max(
        width,
        measure(child, child.getMaxIntrinsicHeight(double.infinity)),
      );
    }
    return width + 2 * _geometry.inset;
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      _intrinsicWidth((child, height) => child.getMinIntrinsicWidth(height));

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _intrinsicWidth((child, height) => child.getMaxIntrinsicWidth(height));

  double _intrinsicHeight(
    double width,
    double Function(RenderBox, double) measure,
  ) => _arrange(
    width.isFinite ? width : getMaxIntrinsicWidth(double.infinity),
    (child, c) {
      final w = c.hasTightWidth
          ? c.maxWidth
          : c.constrainWidth(child.getMaxIntrinsicWidth(double.infinity));
      return Size(w, measure(child, w));
    },
  );

  @override
  double computeMinIntrinsicHeight(double width) =>
      _intrinsicHeight(width, (child, w) => child.getMinIntrinsicHeight(w));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _intrinsicHeight(width, (child, w) => child.getMaxIntrinsicHeight(w));

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    final body = childForSlot(_RecordSlot.body)!;
    final distance = body.getDistanceToActualBaseline(baseline);
    return distance == null
        ? null
        : distance + (body.parentData! as BoxParentData).offset.dy;
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final offset = (child.parentData! as BoxParentData).offset;
    transform.translateByDouble(offset.dx, offset.dy, 0, 1);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    for (final child in children) {
      context.paintChild(
        child,
        offset + (child.parentData! as BoxParentData).offset,
      );
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final slot in _RecordSlot.values.reversed) {
      if (childForSlot(slot) case final child?) {
        if (result.addWithPaintOffset(
          offset: (child.parentData! as BoxParentData).offset,
          position: position,
          hitTest: (result, position) =>
              child.hitTest(result, position: position),
        )) {
          return true;
        }
      }
    }
    return false;
  }
}
