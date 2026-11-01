import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'payment_type.dart';

/// Height of one line of [style] at the current text scale.
double lineHeightOf(BuildContext context, TextStyle style) =>
    MediaQuery.textScalerOf(context).scale(style.fontSize ?? 14) *
    (style.height ?? 1);

/// Child slots of [FirstLineRow].
enum FirstLineSlot { leading, text, trailing }

/// Internal row that centres its leading and trailing widgets on the first
/// line of [text] (D56, D48a).
///
/// The band is the tallest of [line], the leading and trailing heights and
/// the two extents. Leading and trailing centre in the band, and the text
/// starts `(band − line) / 2` below the top, so a single-line row shares one
/// centre line and a multi-line row keeps its icon and control beside the
/// first line. Leading and trailing keep their own size: a 48 dp control is
/// never squeezed, and nothing paints outside the row, so hit-testing stays
/// inside it.
class FirstLineRow
    extends SlottedMultiChildRenderObjectWidget<FirstLineSlot, RenderBox> {
  const FirstLineRow({
    super.key,
    this.leading,
    this.leadingExtent = 0,
    required this.text,
    this.trailing,
    this.trailingExtent = 0,
    this.gap,
    this.trailingGap,
    this.line,
  });

  final Widget? leading;

  /// Minimum band height reserved for [leading].
  final double leadingExtent;

  /// The text column; it takes the remaining width.
  final Widget text;
  final Widget? trailing;

  /// Minimum band height reserved for [trailing].
  final double trailingExtent;

  /// Gap after [leading]; defaults to 12, the `block` icon → text gap.
  final double? gap;

  /// Gap before [trailing]; defaults to [gap].
  final double? trailingGap;

  /// Height of the text's first line box; defaults to one 15/20 line.
  final double? line;

  @override
  Iterable<FirstLineSlot> get slots => FirstLineSlot.values;

  @override
  Widget? childForSlot(FirstLineSlot slot) => switch (slot) {
    FirstLineSlot.leading => leading,
    FirstLineSlot.text => text,
    FirstLineSlot.trailing => trailing,
  };

  @override
  RenderFirstLineRow createRenderObject(BuildContext context) =>
      RenderFirstLineRow(
        line: line ?? PaymentType.firstLineHeight(context),
        leadingExtent: leadingExtent,
        trailingExtent: trailingExtent,
        gap: gap ?? 12,
        trailingGap: trailingGap ?? gap ?? 12,
        textDirection: Directionality.of(context),
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderFirstLineRow renderObject,
  ) {
    renderObject
      ..line = line ?? PaymentType.firstLineHeight(context)
      ..leadingExtent = leadingExtent
      ..trailingExtent = trailingExtent
      ..gap = gap ?? 12
      ..trailingGap = trailingGap ?? gap ?? 12
      ..textDirection = Directionality.of(context);
  }
}

class RenderFirstLineRow extends RenderBox
    with SlottedContainerRenderObjectMixin<FirstLineSlot, RenderBox> {
  RenderFirstLineRow({
    required this._line,
    required this._leadingExtent,
    required this._trailingExtent,
    required this._gap,
    required this._trailingGap,
    required this._textDirection,
  });

  double _line;
  set line(double v) => _set(_line != v, () => _line = v);
  double _leadingExtent;
  set leadingExtent(double v) =>
      _set(_leadingExtent != v, () => _leadingExtent = v);
  double _trailingExtent;
  set trailingExtent(double v) =>
      _set(_trailingExtent != v, () => _trailingExtent = v);
  double _gap;
  set gap(double v) => _set(_gap != v, () => _gap = v);
  double _trailingGap;
  set trailingGap(double v) => _set(_trailingGap != v, () => _trailingGap = v);
  TextDirection _textDirection;
  set textDirection(TextDirection v) =>
      _set(_textDirection != v, () => _textDirection = v);

  void _set(bool changed, VoidCallback apply) {
    if (!changed) return;
    apply();
    markNeedsLayout();
  }

  RenderBox? get _leading => childForSlot(FirstLineSlot.leading);
  RenderBox? get _text => childForSlot(FirstLineSlot.text);
  RenderBox? get _trailing => childForSlot(FirstLineSlot.trailing);

  @override
  Iterable<RenderBox> get children => [?_leading, ?_text, ?_trailing];

  double _leadingSpan(double w) => w == 0 ? 0 : w + _gap;
  double _trailingSpan(double w) => w == 0 ? 0 : w + _trailingGap;

  // Lays every child out (or measures it dry) and returns the row height
  // plus each child's offset from the start edge and top.
  ({double height, List<(RenderBox, double, double)> places}) _arrange(
    BoxConstraints constraints,
    Size Function(RenderBox, BoxConstraints) size,
  ) {
    final loose = BoxConstraints(maxWidth: constraints.maxWidth);
    final lead = _leading == null ? Size.zero : size(_leading!, loose);
    final trail = _trailing == null ? Size.zero : size(_trailing!, loose);
    final band = [
      _line,
      lead.height,
      trail.height,
      _leadingExtent,
      _trailingExtent,
    ].reduce(math.max);
    final textWidth = math.max(
      0.0,
      constraints.maxWidth -
          _leadingSpan(lead.width) -
          _trailingSpan(trail.width),
    );
    final top = (band - _line) / 2;
    final text = _text == null
        ? Size.zero
        : size(_text!, BoxConstraints.tightFor(width: textWidth));
    return (
      height: math.max(band, top + text.height),
      places: [
        if (_leading != null) (_leading!, 0, (band - lead.height) / 2),
        if (_text != null) (_text!, _leadingSpan(lead.width), top),
        if (_trailing != null)
          (
            _trailing!,
            constraints.maxWidth - trail.width,
            (band - trail.height) / 2,
          ),
      ],
    );
  }

  @override
  void performLayout() {
    assert(constraints.hasBoundedWidth, 'FirstLineRow needs a bounded width.');
    final result = _arrange(
      constraints,
      (child, c) => (child..layout(c, parentUsesSize: true)).size,
    );
    size = constraints.constrain(Size(constraints.maxWidth, result.height));
    for (final (child, start, top) in result.places) {
      final x = _textDirection == TextDirection.ltr
          ? start
          : size.width - start - child.size.width;
      (child.parentData! as BoxParentData).offset = Offset(x, top);
    }
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final result = _arrange(constraints, (child, c) => child.getDryLayout(c));
    return constraints.constrain(Size(constraints.maxWidth, result.height));
  }

  double _width(double Function(RenderBox) of) {
    final lead = _leading == null ? 0.0 : of(_leading!);
    final trail = _trailing == null ? 0.0 : of(_trailing!);
    return _leadingSpan(lead) +
        (_text == null ? 0.0 : of(_text!)) +
        _trailingSpan(trail);
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      _width((c) => c.getMinIntrinsicWidth(height));

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _width((c) => c.getMaxIntrinsicWidth(height));

  double _height(double width, double Function(RenderBox, double) of) {
    final lead = _leading == null ? 0.0 : of(_leading!, width);
    final trail = _trailing == null ? 0.0 : of(_trailing!, width);
    final band = [
      _line,
      lead,
      trail,
      _leadingExtent,
      _trailingExtent,
    ].reduce(math.max);
    final leadW = _leading == null
        ? 0.0
        : _leading!.getMaxIntrinsicWidth(double.infinity);
    final trailW = _trailing == null
        ? 0.0
        : _trailing!.getMaxIntrinsicWidth(double.infinity);
    final textW = math.max(
      0.0,
      width - _leadingSpan(leadW) - _trailingSpan(trailW),
    );
    final text = _text == null ? 0.0 : of(_text!, textW);
    return math.max(band, (band - _line) / 2 + text);
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      _height(width, (c, w) => c.getMinIntrinsicHeight(w));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _height(width, (c, w) => c.getMaxIntrinsicHeight(w));

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    final text = _text;
    if (text == null) return null;
    final distance = text.getDistanceToActualBaseline(baseline);
    if (distance == null) return null;
    return distance + (text.parentData! as BoxParentData).offset.dy;
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
    for (final child in children.toList().reversed) {
      final offset = (child.parentData! as BoxParentData).offset;
      final hit = result.addWithPaintOffset(
        offset: offset,
        position: position,
        hitTest: (result, transformed) =>
            child.hitTest(result, position: transformed),
      );
      if (hit) return true;
    }
    return false;
  }
}

/// Internal scope that puts a [PaymentIconButton]'s glyph on the end edge of
/// its 48 dp target instead of its centre, so a trailing copy glyph lines up
/// with the row's value edge while the target stays inside the row (D57).
class EdgeAlignedIcon extends InheritedWidget {
  const EdgeAlignedIcon({super.key, required super.child});

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<EdgeAlignedIcon>() != null;

  @override
  bool updateShouldNotify(EdgeAlignedIcon oldWidget) => false;
}
