import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'payment_type.dart';

/// Height of one line of [style] at the current text scale.
double lineHeightOf(BuildContext context, TextStyle style) =>
    MediaQuery.textScalerOf(context).scale(style.fontSize ?? 14) *
    (style.height ?? 1);

/// Child slots of [FirstLineRow].
enum FirstLineSlot { leading, text, trailing, end }

/// When [FirstLineRow.trailing] moves to its own line under the text.
enum FirstLineWrap {
  /// Trailing always stays beside the text.
  never,

  /// Trailing moves under the text when a word of the text would otherwise
  /// break across lines beside it.
  whenWordsBreak,

  /// Trailing moves under the text when the text would otherwise need more
  /// than one line beside it.
  whenTextWraps,
}

/// Internal row that centres its leading and trailing widgets on the first
/// line of [text] (D56, D48a).
///
/// The band is the tallest of [line], the leading, trailing and end heights
/// and the two extents. Leading, trailing and end centre in the band, and the
/// text starts `(band − line) / 2` below the top, so a single-line row shares
/// one centre line and a multi-line row keeps its icon and control beside the
/// first line. Leading and trailing keep their own size: a 48 dp control is
/// never squeezed, and nothing paints outside the row, so hit-testing stays
/// inside it.
///
/// With [wrap], trailing can move under the text instead, on the end edge of
/// the text column, while [end] stays in the first-line band (D88).
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
    this.hug = false,
    this.end,
    this.wrap = FirstLineWrap.never,
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

  /// Size to the content instead of the full width, for a centred group
  /// such as a button label. The text gets loose constraints, so a `Text`
  /// with [TextWidthBasis.longestLine] hugs its longest line.
  final bool hug;

  /// A widget after [trailing], flush with the end edge and centred in the
  /// first-line band even when [trailing] wraps. It adds no gap.
  final Widget? end;

  /// When [trailing] moves under the text. Ignored with [hug].
  final FirstLineWrap wrap;

  @override
  Iterable<FirstLineSlot> get slots => FirstLineSlot.values;

  @override
  Widget? childForSlot(FirstLineSlot slot) => switch (slot) {
    FirstLineSlot.leading => leading,
    FirstLineSlot.text => text,
    FirstLineSlot.trailing => trailing,
    FirstLineSlot.end => end,
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
        hug: hug,
        wrap: wrap,
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
      ..textDirection = Directionality.of(context)
      ..hug = hug
      ..wrap = wrap;
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
    this._hug = false,
    this._wrap = FirstLineWrap.never,
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
  bool _hug;
  set hug(bool v) => _set(_hug != v, () => _hug = v);
  FirstLineWrap _wrap;
  set wrap(FirstLineWrap v) => _set(_wrap != v, () => _wrap = v);

  void _set(bool changed, VoidCallback apply) {
    if (!changed) return;
    apply();
    markNeedsLayout();
  }

  RenderBox? get _leading => childForSlot(FirstLineSlot.leading);
  RenderBox? get _text => childForSlot(FirstLineSlot.text);
  RenderBox? get _trailing => childForSlot(FirstLineSlot.trailing);
  RenderBox? get _end => childForSlot(FirstLineSlot.end);

  @override
  Iterable<RenderBox> get children => [?_leading, ?_text, ?_trailing, ?_end];

  double _leadingSpan(double w) => w == 0 ? 0 : w + _gap;
  double _trailingSpan(double w) => w == 0 ? 0 : w + _trailingGap;

  // Whether trailing goes under the text, given the text width beside it.
  bool _wraps(double inline) {
    final text = _text;
    if (_hug || _trailing == null || text == null) return false;
    return switch (_wrap) {
      FirstLineWrap.never => false,
      FirstLineWrap.whenWordsBreak =>
        text.getMinIntrinsicWidth(double.infinity) > inline,
      FirstLineWrap.whenTextWraps =>
        text.getMaxIntrinsicWidth(double.infinity) > inline,
    };
  }

  // Lays every child out (or measures it dry) and returns the row width and
  // height plus each child's offset from the start edge and top.
  ({double width, double height, List<(RenderBox, double, double)> places})
  _arrange(
    BoxConstraints constraints,
    Size Function(RenderBox, BoxConstraints) size,
  ) {
    final loose = BoxConstraints(maxWidth: constraints.maxWidth);
    final lead = _leading == null ? Size.zero : size(_leading!, loose);
    final trail = _trailing == null ? Size.zero : size(_trailing!, loose);
    final end = _end == null ? Size.zero : size(_end!, loose);
    final start = _leadingSpan(lead.width);
    final inline = math.max(
      0.0,
      constraints.maxWidth - start - _trailingSpan(trail.width) - end.width,
    );
    final wrapped = _wraps(inline);
    final band = [
      _line,
      lead.height,
      if (!wrapped) ...[trail.height, _trailingExtent],
      end.height,
      _leadingExtent,
    ].reduce(math.max);
    final textWidth = wrapped
        ? math.max(0.0, constraints.maxWidth - start - end.width)
        : inline;
    final top = (band - _line) / 2;
    final text = _text == null
        ? Size.zero
        : size(
            _text!,
            _hug
                ? BoxConstraints(maxWidth: textWidth)
                : BoxConstraints.tightFor(width: textWidth),
          );
    final width = _hug
        ? start + text.width + _trailingSpan(trail.width) + end.width
        : constraints.maxWidth;
    final firstRow = math.max(band, top + text.height);
    return (
      width: width,
      height: wrapped ? firstRow + trail.height : firstRow,
      places: [
        if (_leading != null) (_leading!, 0, (band - lead.height) / 2),
        if (_text != null) (_text!, start, top),
        if (_trailing != null)
          (
            _trailing!,
            width - end.width - trail.width,
            wrapped ? firstRow : (band - trail.height) / 2,
          ),
        if (_end != null) (_end!, width - end.width, (band - end.height) / 2),
      ],
    );
  }

  @override
  void performLayout() {
    assert(
      _hug || constraints.hasBoundedWidth,
      'FirstLineRow needs a bounded width.',
    );
    final result = _arrange(
      constraints,
      (child, c) => (child..layout(c, parentUsesSize: true)).size,
    );
    size = constraints.constrain(Size(result.width, result.height));
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
    return constraints.constrain(Size(result.width, result.height));
  }

  double _width(double Function(RenderBox) of) {
    final lead = _leading == null ? 0.0 : of(_leading!);
    final trail = _trailing == null ? 0.0 : of(_trailing!);
    final end = _end == null ? 0.0 : of(_end!);
    return _leadingSpan(lead) +
        (_text == null ? 0.0 : of(_text!)) +
        _trailingSpan(trail) +
        end;
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      _width((c) => c.getMinIntrinsicWidth(height));

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _width((c) => c.getMaxIntrinsicWidth(height));

  double _height(double width, double Function(RenderBox, double) of) {
    double widthOf(RenderBox? box) =>
        box == null ? 0.0 : box.getMaxIntrinsicWidth(double.infinity);
    final start = _leadingSpan(widthOf(_leading));
    final trailW = widthOf(_trailing);
    final endW = widthOf(_end);
    final inline = math.max(0.0, width - start - _trailingSpan(trailW) - endW);
    final wrapped = _wraps(inline);
    final lead = _leading == null ? 0.0 : of(_leading!, width);
    final trail = _trailing == null ? 0.0 : of(_trailing!, width);
    final end = _end == null ? 0.0 : of(_end!, width);
    final band = [
      _line,
      lead,
      if (!wrapped) ...[trail, _trailingExtent],
      end,
      _leadingExtent,
    ].reduce(math.max);
    final textW = wrapped ? math.max(0.0, width - start - endW) : inline;
    final text = _text == null ? 0.0 : of(_text!, textW);
    final firstRow = math.max(band, (band - _line) / 2 + text);
    return wrapped ? firstRow + trail : firstRow;
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
