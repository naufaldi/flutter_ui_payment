import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Child slots of [SectionLayout].
enum SectionSlot { title, trailing, body }

/// Internal layout of [PaymentSection]: vertical [padding], a header band at
/// least [band] tall, then the body.
///
/// The title's first line centres in the band, so a section reads the same
/// with or without an action. The trailing action centres on that line at
/// its own size: a 48 dp target overhangs the 36 dp band into the padding
/// and the body's top edge. This render object owns that padding, so the
/// whole target stays inside it and hit-testable (#62). Without a title the
/// trailing action is not shown, as before.
class SectionLayout
    extends SlottedMultiChildRenderObjectWidget<SectionSlot, RenderBox> {
  const SectionLayout({
    super.key,
    this.title,
    this.trailing,
    required this.body,
    required this.padding,
    required this.line,
    this.band = 36,
    this.gap = 8,
  });

  final Widget? title;
  final Widget? trailing;
  final Widget body;

  /// Space above the band and below the body.
  final double padding;

  /// Height of the title's first line.
  final double line;

  /// Minimum header height.
  final double band;

  /// Gap between the title and the trailing action.
  final double gap;

  @override
  Iterable<SectionSlot> get slots => SectionSlot.values;

  @override
  Widget? childForSlot(SectionSlot slot) => switch (slot) {
    SectionSlot.title => title,
    SectionSlot.trailing => title == null ? null : trailing,
    SectionSlot.body => body,
  };

  @override
  RenderSectionLayout createRenderObject(BuildContext context) =>
      RenderSectionLayout(
        padding: padding,
        line: line,
        band: band,
        gap: gap,
        textDirection: Directionality.of(context),
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderSectionLayout renderObject,
  ) {
    renderObject
      ..padding = padding
      ..line = line
      ..band = band
      ..gap = gap
      ..textDirection = Directionality.of(context);
  }
}

class RenderSectionLayout extends RenderBox
    with SlottedContainerRenderObjectMixin<SectionSlot, RenderBox> {
  RenderSectionLayout({
    required this._padding,
    required this._line,
    required this._band,
    required this._gap,
    required this._textDirection,
  });

  double _padding;
  set padding(double v) => _set(_padding != v, () => _padding = v);
  double _line;
  set line(double v) => _set(_line != v, () => _line = v);
  double _band;
  set band(double v) => _set(_band != v, () => _band = v);
  double _gap;
  set gap(double v) => _set(_gap != v, () => _gap = v);
  TextDirection _textDirection;
  set textDirection(TextDirection v) =>
      _set(_textDirection != v, () => _textDirection = v);

  void _set(bool changed, VoidCallback apply) {
    if (!changed) return;
    apply();
    markNeedsLayout();
  }

  RenderBox? get _title => childForSlot(SectionSlot.title);
  RenderBox? get _trailing => childForSlot(SectionSlot.trailing);
  RenderBox? get _body => childForSlot(SectionSlot.body);

  // Reading, semantics and focus order.
  @override
  Iterable<RenderBox> get children => [?_title, ?_trailing, ?_body];

  // Lays every child out (or measures it dry) and returns the height plus
  // each child's offset from the start edge and top.
  ({double height, List<(RenderBox, double, double)> places}) _arrange(
    BoxConstraints constraints,
    Size Function(RenderBox, BoxConstraints) size,
  ) {
    final width = constraints.maxWidth;
    final places = <(RenderBox, double, double)>[];
    var top = _padding;
    var bottom = 0.0;
    if (_title != null) {
      final trail = _trailing == null
          ? Size.zero
          : size(_trailing!, BoxConstraints(maxWidth: width));
      final reserve = _trailing == null ? 0.0 : trail.width + _gap;
      final title = size(
        _title!,
        BoxConstraints.tightFor(width: math.max(0.0, width - reserve)),
      );
      final band = math.max(_band, _line);
      final titleTop = (band - _line) / 2;
      places.add((_title!, 0, top + titleTop));
      if (_trailing != null) {
        final y = top + (band - trail.height) / 2;
        places.add((_trailing!, width - trail.width, y));
        bottom = y + trail.height;
      }
      top += math.max(band, titleTop + title.height);
    }
    // Loose, as the start-aligned column this replaced gave it.
    final body = _body == null
        ? Size.zero
        : size(_body!, BoxConstraints(maxWidth: width));
    if (_body != null) places.add((_body!, 0, top));
    return (
      height: math.max(top + body.height + _padding, bottom),
      places: places,
    );
  }

  @override
  void performLayout() {
    assert(
      constraints.hasBoundedWidth,
      'PaymentSection needs a bounded width.',
    );
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
    final header = _title == null
        ? 0.0
        : of(_title!) + (_trailing == null ? 0.0 : _gap + of(_trailing!));
    return math.max(header, _body == null ? 0.0 : of(_body!));
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      _width((c) => c.getMinIntrinsicWidth(height));

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _width((c) => c.getMaxIntrinsicWidth(height));

  double _height(double width, double Function(RenderBox, double) of) {
    var header = 0.0;
    if (_title != null) {
      final reserve = _trailing == null
          ? 0.0
          : _trailing!.getMaxIntrinsicWidth(double.infinity) + _gap;
      final band = math.max(_band, _line);
      header = math.max(
        band,
        (band - _line) / 2 + of(_title!, math.max(0.0, width - reserve)),
      );
    }
    return _padding * 2 + header + (_body == null ? 0.0 : of(_body!, width));
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      _height(width, (c, w) => c.getMinIntrinsicHeight(w));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _height(width, (c, w) => c.getMaxIntrinsicHeight(w));

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    final first = _title ?? _body;
    if (first == null) return null;
    final distance = first.getDistanceToActualBaseline(baseline);
    if (distance == null) return null;
    return distance + (first.parentData! as BoxParentData).offset.dy;
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

  // The trailing action is tested first: its target overhangs the body.
  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final child in [?_trailing, ?_title, ?_body]) {
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
