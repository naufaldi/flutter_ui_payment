import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../foundation/primitives.dart';
import '../foundation/payment_tokens.dart';
import '../foundation/payment_theme.dart';
import '../foundation/button_copy.dart';
import '../interaction/interaction.dart';

/// Responsive action overflow policy.
enum PaymentButtonGroupCollapse {
  /// Move trailing actions into a menu, retaining the first action.
  auto,

  /// Stack an overflowing row at full width, with the emphasized action on
  /// top.
  none,
}

/// Related actions with at most one primary and separated destructive actions.
class PaymentButtonGroup extends StatefulWidget {
  /// Creates an action group.
  const PaymentButtonGroup({
    super.key,
    required this.children,
    this.direction = Axis.horizontal,
    this.collapse = PaymentButtonGroupCollapse.auto,
    this.menuTrigger,
  });

  /// Actions in host reading order.
  final List<PaymentButton> children;

  /// Vertical actions fill the available width.
  final Axis direction;

  /// Horizontal overflow policy.
  final PaymentButtonGroupCollapse collapse;

  /// Optional menu trigger receiving its toggle and focus node.
  final Widget Function(VoidCallback toggle, FocusNode focusNode)? menuTrigger;
  @override
  State<PaymentButtonGroup> createState() => _PaymentButtonGroupState();
}

class _PaymentButtonGroupState extends State<PaymentButtonGroup> {
  int? _visible;
  @override
  Widget build(BuildContext context) {
    final buttons = widget.children;
    assert(buttons.isNotEmpty);
    final primary = buttons
        .where((b) => b.variant == PaymentButtonVariant.primary)
        .length;
    final danger = buttons
        .where((b) => b.variant == PaymentButtonVariant.destructive)
        .toList();
    assert(primary <= 1);
    assert(
      !(widget.direction == Axis.vertical ||
              widget.collapse == PaymentButtonGroupCollapse.none) ||
          !(primary > 0 && danger.isNotEmpty),
    );
    final spacing = PaymentTheme.of(context).space(PaymentSpace.related);
    if (widget.direction == Axis.vertical) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: spacing,
        children: buttons,
      );
    }
    if (widget.collapse == PaymentButtonGroupCollapse.none) {
      // One row of hug buttons when it fits; otherwise a full-width stack
      // with the emphasized action on top (D45, #65).
      return _RowOrStack(
        spacing: spacing,
        direction: Directionality.of(context),
        lastOnTop:
            buttons.last.variant == PaymentButtonVariant.primary ||
            buttons.last.variant == PaymentButtonVariant.destructive,
        children: buttons.map(hugButton).toList(),
      );
    }
    final inline = buttons
        .where((b) => b.variant != PaymentButtonVariant.destructive)
        .toList();
    final count = (_visible ?? inline.length).clamp(0, inline.length);
    PaymentMenuItem item(PaymentButton b) => PaymentMenuItem(
      label: b.label,
      icon: b.icon,
      destructive: b.variant == PaymentButtonVariant.destructive,
      onSelected: b.onPressed == null
          ? null
          : () {
              b.onPressed!();
            },
    );
    return _CollapseRow(
      spacing: spacing,
      hasDanger: danger.isNotEmpty,
      direction: Directionality.of(context),
      onFit: (n) {
        if (mounted && _visible != n) setState(() => _visible = n);
      },
      children: [
        for (var i = 0; i < inline.length; i++)
          ExcludeFocus(excluding: i >= count, child: hugButton(inline[i])),
        PaymentMenu(
          trigger: widget.menuTrigger,
          entries: [
            for (final b in inline.skip(count)) item(b),
            if (danger.isNotEmpty)
              PaymentMenuGroup(items: danger.map(item).toList()),
          ],
        ),
      ],
    );
  }
}

class _CollapseRow extends MultiChildRenderObjectWidget {
  const _CollapseRow({
    required this.spacing,
    required this.hasDanger,
    required this.direction,
    required this.onFit,
    required super.children,
  });
  final double spacing;
  final bool hasDanger;
  final TextDirection direction;
  final ValueChanged<int> onFit;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderCollapseRow(spacing, hasDanger, direction, onFit);
  @override
  void updateRenderObject(BuildContext context, _RenderCollapseRow r) {
    r
      ..spacing = spacing
      ..hasDanger = hasDanger
      ..direction = direction
      ..onFit = onFit
      ..markNeedsLayout();
  }
}

class _RowOrStack extends MultiChildRenderObjectWidget {
  const _RowOrStack({
    required this.spacing,
    required this.direction,
    required this.lastOnTop,
    required super.children,
  });
  final double spacing;
  final TextDirection direction;
  final bool lastOnTop;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderRowOrStack(spacing, direction, lastOnTop);
  @override
  void updateRenderObject(BuildContext context, _RenderRowOrStack r) {
    r
      ..spacing = spacing
      ..direction = direction
      ..lastOnTop = lastOnTop
      ..markNeedsLayout();
  }
}

class _RenderRowOrStack extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _Data>,
        RenderBoxContainerDefaultsMixin<RenderBox, _Data> {
  _RenderRowOrStack(this.spacing, this.direction, this.lastOnTop);
  double spacing;
  TextDirection direction;
  bool lastOnTop;

  List<RenderBox> get boxes {
    final result = <RenderBox>[];
    RenderBox? c = firstChild;
    while (c != null) {
      result.add(c);
      c = (c.parentData! as _Data).nextSibling;
    }
    return result;
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _Data) child.parentData = _Data();
  }

  double _rowWidth(List<RenderBox> list) =>
      list.fold(0.0, (a, c) => a + c.getMaxIntrinsicWidth(double.infinity)) +
      math.max(0, list.length - 1) * spacing;

  @override
  void performLayout() {
    final list = boxes;
    if (_rowWidth(list) <= constraints.maxWidth) {
      double x = 0;
      double height = 0;
      for (final c in list) {
        c.layout(
          BoxConstraints(maxWidth: constraints.maxWidth),
          parentUsesSize: true,
        );
        height = math.max(height, c.size.height);
      }
      final width = _rowWidth(list);
      size = constraints.constrain(Size(width, height));
      for (final c in list) {
        (c.parentData! as _Data).offset = Offset(
          direction == TextDirection.ltr ? x : size.width - x - c.size.width,
          (size.height - c.size.height) / 2,
        );
        x += c.size.width + spacing;
      }
      return;
    }
    final order = lastOnTop ? list.reversed.toList() : list;
    double y = 0;
    for (final c in order) {
      c.layout(
        BoxConstraints.tightFor(width: constraints.maxWidth),
        parentUsesSize: true,
      );
      (c.parentData! as _Data).offset = Offset(0, y);
      y += c.size.height + spacing;
    }
    size = constraints.constrain(
      Size(constraints.maxWidth, math.max(0, y - spacing)),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  double computeMaxIntrinsicWidth(double height) => _rowWidth(boxes);
  @override
  double computeMinIntrinsicWidth(double height) =>
      boxes.fold(0.0, (a, c) => math.max(a, c.getMinIntrinsicWidth(height)));
  @override
  double computeMaxIntrinsicHeight(double width) {
    final list = boxes;
    if (_rowWidth(list) <= width) {
      return list.fold(
        0.0,
        (a, c) => math.max(a, c.getMaxIntrinsicHeight(double.infinity)),
      );
    }
    return list.fold(0.0, (a, c) => a + c.getMaxIntrinsicHeight(width)) +
        math.max(0, list.length - 1) * spacing;
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      computeMaxIntrinsicHeight(width);

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final list = boxes;
    if (_rowWidth(list) <= constraints.maxWidth) {
      return constraints.constrain(
        Size(
          _rowWidth(list),
          list.fold(
            0.0,
            (a, c) => math.max(
              a,
              c
                  .getDryLayout(BoxConstraints(maxWidth: constraints.maxWidth))
                  .height,
            ),
          ),
        ),
      );
    }
    final tight = BoxConstraints.tightFor(width: constraints.maxWidth);
    return constraints.constrain(
      Size(
        constraints.maxWidth,
        list.fold(0.0, (a, c) => a + c.getDryLayout(tight).height) +
            math.max(0, list.length - 1) * spacing,
      ),
    );
  }
}

class _Data extends ContainerBoxParentData<RenderBox> {}

class _RenderCollapseRow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _Data>,
        RenderBoxContainerDefaultsMixin<RenderBox, _Data> {
  _RenderCollapseRow(this.spacing, this.hasDanger, this.direction, this.onFit);
  double spacing;
  bool hasDanger;
  TextDirection direction;
  ValueChanged<int> onFit;
  int _shown = 0;
  bool _trigger = false;
  int? _reported;
  List<RenderBox> get boxes {
    final result = <RenderBox>[];
    RenderBox? c = firstChild;
    while (c != null) {
      result.add(c);
      c = (c.parentData! as _Data).nextSibling;
    }
    return result;
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _Data) child.parentData = _Data();
  }

  @override
  void performLayout() {
    final list = boxes;
    final n = list.length - 1;
    final widths = [
      for (final c in list) c.getMaxIntrinsicWidth(double.infinity),
    ];
    _shown = n;
    double width = 0;
    for (var count = n; count >= 0; count--) {
      final trigger = count < n || hasDanger;
      final need =
          widths.take(count).fold(0.0, (a, b) => a + b) +
          math.max(0, count - 1) * spacing +
          (trigger ? widths.last + (count > 0 ? spacing : 0) : 0);
      if (need <= constraints.maxWidth || count == math.min(1, n)) {
        _shown = count;
        break;
      }
    }
    _trigger = _shown < n || hasDanger;
    double height = 0;
    for (var i = 0; i < list.length; i++) {
      final limit = i == 0 && _shown == 1
          ? math.max(
              0.0,
              constraints.maxWidth - (_trigger ? spacing + widths.last : 0),
            )
          : widths[i];
      list[i].layout(
        BoxConstraints(maxWidth: limit, maxHeight: constraints.maxHeight),
        parentUsesSize: true,
      );
      if (i < _shown || (i == n && _trigger)) {
        height = math.max(height, list[i].size.height);
        width += list[i].size.width;
      }
    }
    width += math.max(0, _shown + (_trigger ? 1 : 0) - 1) * spacing;
    size = constraints.constrain(Size(width, height));
    double x = 0;
    for (var i = 0; i < list.length; i++) {
      if (i < _shown || (i == n && _trigger)) {
        final c = list[i];
        (c.parentData! as _Data).offset = Offset(
          direction == TextDirection.ltr ? x : size.width - x - c.size.width,
          (size.height - c.size.height) / 2,
        );
        x += c.size.width + spacing;
      }
    }
    if (_reported != _shown) {
      _reported = _shown;
      final count = _shown;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (attached) onFit(count);
      });
    }
  }

  Iterable<RenderBox> get shown sync* {
    final list = boxes;
    for (var i = 0; i < list.length; i++) {
      if (i < _shown || (i == list.length - 1 && _trigger)) yield list[i];
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    for (final c in shown) {
      context.paintChild(c, offset + (c.parentData! as _Data).offset);
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final c in shown.toList().reversed) {
      if (result.addWithPaintOffset(
        offset: (c.parentData! as _Data).offset,
        position: position,
        hitTest: (result, p) => c.hitTest(result, position: p),
      )) {
        return true;
      }
    }
    return false;
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    for (final c in shown) {
      visitor(c);
    }
  }

  @override
  double computeMaxIntrinsicWidth(double height) =>
      boxes.fold(0.0, (a, b) => a + b.getMaxIntrinsicWidth(height)) +
      math.max(0, childCount - 1) * spacing;
  @override
  double computeMinIntrinsicWidth(double height) =>
      boxes.first.getMinIntrinsicWidth(height) +
      (childCount > 2 || hasDanger
          ? spacing + boxes.last.getMaxIntrinsicWidth(height)
          : 0);
  @override
  double computeMaxIntrinsicHeight(double width) =>
      boxes.fold(0.0, (a, b) => math.max(a, b.getMaxIntrinsicHeight(width)));
  @override
  double computeMinIntrinsicHeight(double width) =>
      computeMaxIntrinsicHeight(width);
}
