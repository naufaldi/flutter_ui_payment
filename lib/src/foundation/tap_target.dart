// Adapted from Flutter's button_style_button.dart (BSD-3-Clause).
// Copyright 2014 The Flutter Authors. All rights reserved.
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Internal minimum hit box around the visual button: centred by default;
/// text actions pass a start alignment so their text sits on the column
/// edge and the box extends past its end (#65).
///
/// [hang] draws the child that far past the edge [alignment] names, so a
/// quiet button's text, not its padding, sits on the edge (#65). It applies
/// only while the width is loose: a stretched or stacked button fills its
/// slot. The overhang is drawn but not hit-tested, since parents test
/// their own bounds; the box forwards hits across the rest of the child,
/// widened to [minSize], so the target stays at least that large.
class MinTapTarget extends SingleChildRenderObjectWidget {
  const MinTapTarget({
    super.key,
    required super.child,
    this.minSize = const Size.square(48),
    this.alignment = Alignment.center,
    this.hang = 0,
  });
  final Size minSize;
  final AlignmentGeometry alignment;
  final double hang;
  @override
  RenderObject createRenderObject(BuildContext context) => _RenderMinTapTarget(
    minSize,
    alignment.resolve(Directionality.maybeOf(context)),
    hang,
  );
  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderObject renderObject,
  ) {
    (renderObject as _RenderMinTapTarget)
      ..minSize = minSize
      ..alignment = alignment.resolve(Directionality.maybeOf(context))
      ..hang = hang;
  }
}

/// Internal: the edge a text action's text sits on inside its 48 dp
/// target. Text actions start on the column edge by default; a container
/// that places one at the end of a row wraps it in [TextActionEdge.end],
/// and a button row wraps its buttons in [TextActionEdge.none] so a quiet
/// button keeps its centred label beside its neighbours.
class TextActionEdge extends InheritedWidget {
  const TextActionEdge.end({super.key, required super.child})
    : alignment = AlignmentDirectional.centerEnd;
  const TextActionEdge.none({super.key, required super.child})
    : alignment = Alignment.center;
  final AlignmentGeometry alignment;
  static AlignmentGeometry of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TextActionEdge>()?.alignment ??
      AlignmentDirectional.centerStart;
  @override
  bool updateShouldNotify(TextActionEdge old) => alignment != old.alignment;
}

class _RenderMinTapTarget extends RenderShiftedBox {
  _RenderMinTapTarget(this._minSize, this._alignment, this._hang) : super(null);

  double get hang => _hang;
  double _hang;
  set hang(double value) {
    if (_hang == value) return;
    _hang = value;
    markNeedsLayout();
  }

  Alignment get alignment => _alignment;
  Alignment _alignment;
  set alignment(Alignment value) {
    if (_alignment == value) return;
    _alignment = value;
    markNeedsLayout();
  }

  Size get minSize => _minSize;
  Size _minSize;
  set minSize(Size value) {
    if (_minSize == value) {
      return;
    }
    _minSize = value;
    markNeedsLayout();
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    if (child != null) {
      return math.max(child!.getMinIntrinsicWidth(height), minSize.width);
    }
    return 0.0;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    if (child != null) {
      return math.max(child!.getMinIntrinsicHeight(width), minSize.height);
    }
    return 0.0;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    if (child != null) {
      return math.max(child!.getMaxIntrinsicWidth(height), minSize.width);
    }
    return 0.0;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    if (child != null) {
      return math.max(child!.getMaxIntrinsicHeight(width), minSize.height);
    }
    return 0.0;
  }

  Size _computeSize({
    required BoxConstraints constraints,
    required ChildLayouter layoutChild,
  }) {
    if (child != null) {
      final Size childSize = layoutChild(child!, constraints);
      final double width = math.max(childSize.width, minSize.width);
      final double height = math.max(childSize.height, minSize.height);
      return constraints.constrain(Size(width, height));
    }
    return Size.zero;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return _computeSize(
      constraints: constraints,
      layoutChild: ChildLayoutHelper.dryLayoutChild,
    );
  }

  @override
  double? computeDryBaseline(
    covariant BoxConstraints constraints,
    TextBaseline baseline,
  ) {
    final RenderBox? child = this.child;
    if (child == null) {
      return null;
    }
    final double? result = child.getDryBaseline(constraints, baseline);
    if (result == null) {
      return null;
    }
    final Size childSize = child.getDryLayout(constraints);
    return result +
        alignment
            .alongOffset(getDryLayout(constraints) - childSize as Offset)
            .dy;
  }

  @override
  void performLayout() {
    size = _computeSize(
      constraints: constraints,
      layoutChild: ChildLayoutHelper.layoutChild,
    );
    if (child != null) {
      final childParentData = child!.parentData! as BoxParentData;
      childParentData.offset =
          alignment.alongOffset(size - child!.size as Offset) +
          (constraints.hasTightWidth
              ? Offset.zero
              : Offset(alignment.x.sign * hang, 0));
    }
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (super.hitTest(result, position: position)) {
      return true;
    }
    if (!size.contains(position) || child == null) return false;
    // A hanging child leaves the far end of the box bare. Forward only
    // across the drawn child, widened to the minimum, so a neighbour in a
    // host's row keeps the start of its own box.
    final dx = (child!.parentData! as BoxParentData).offset.dx;
    if (dx < 0 || dx + child!.size.width > size.width) {
      var start = math.max(dx, 0.0);
      var end = math.min(dx + child!.size.width, size.width);
      if (end - start < minSize.width) {
        if (dx < 0) {
          end = math.min(size.width, start + minSize.width);
        } else {
          start = math.max(0.0, end - minSize.width);
        }
      }
      if (position.dx < start || position.dx > end) return false;
    }
    final Offset center = child!.size.center(Offset.zero);
    return result.addWithRawTransform(
      transform: MatrixUtils.forceToPoint(center),
      position: center,
      hitTest: (BoxHitTestResult result, Offset position) {
        assert(position == center);
        return child!.hitTest(result, position: center);
      },
    );
  }
}
