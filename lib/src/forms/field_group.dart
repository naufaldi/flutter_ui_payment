import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../controls/controls.dart';
import '../controls/text_field.dart';
import '../foundation/field_decoration.dart';
import '../foundation/payment_theme.dart';
import '../foundation/payment_tokens.dart';
import '../foundation/payment_type.dart';
import 'date_field.dart';
import 'select.dart';

/// Narrowest field in a horizontal group: two fit a 329 dp phone card (#65).
const _minFieldWidth = 140.0;

/// Related fields under a legend. A horizontal group stacks when its fields
/// would be narrower than 140 dp each, or at large text. Hosts put 24 dp
/// (`PaymentSpace.section`) between groups; fields inside sit 16 apart.
/// The legend sits 8 dp (`related`) above the first control's visible top:
/// a field's edge, or a checkbox, radio or switch row's label (#66).
class PaymentFormFieldGroup extends StatelessWidget {
  const PaymentFormFieldGroup({
    super.key,
    required this.legend,
    required this.children,
    this.description,
    this.disabled = false,
    this.layout = Axis.vertical,
  });

  /// legend for this field.
  final String legend;

  /// children for this field.
  final List<Widget> children;

  /// description for this field.
  final String? description;

  /// disabled for this field.
  final bool disabled;

  /// layout for this field.
  final Axis layout;
  bool? _required(Widget w) => switch (w) {
    PaymentTextField() => w.required,
    PaymentTextArea() => w.required,
    PaymentSelect() => w.required,
    PaymentDateField() => w.required,
    _ => null,
  };

  /// Space above the label inside a selection row's 48 dp target, or 0 for
  /// anything else. A row with only a one-line label centres it in the
  /// target; a row with a detail or error line keeps the `block` padding.
  double _rowSlack(BuildContext context, Widget w) {
    final row = switch (w) {
      PaymentCheckbox() => (w.description, w.disabledReason, w.errorText),
      PaymentRadio() => (w.description, w.disabledReason, w.errorText),
      PaymentSwitch() => (w.description, w.disabledReason, w.errorText),
      _ => null,
    };
    if (row == null) return 0;
    final (description, reason, error) = row;
    final block = PaymentTheme.of(context).space(PaymentSpace.block);
    // A disabled reason only shows while disabled; counting it either way
    // can only leave the label 2 dp lower, never overlap the legend.
    if (description != null || reason != null || error != null) return block;
    return math.max(block, (48 - PaymentType.firstLineHeight(context)) / 2);
  }

  @override
  Widget build(BuildContext context) {
    final t = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    final flags = children.map(_required).nonNulls.toList();
    // A selection row's target slack overhangs the legend gap, so the label
    // sits `related` below the legend like a field's edge (#66). Side by
    // side, the shallowest child sets it.
    final slack = children.isEmpty
        ? 0.0
        : layout == Axis.vertical
        ? _rowSlack(context, children.first)
        : children.map((w) => _rowSlack(context, w)).reduce(math.min);
    Widget vertical() => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: t.space(PaymentSpace.group),
      children: children,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(header: true, child: Text(legend, style: type.heading)),
        if (description != null)
          Padding(
            padding: EdgeInsets.only(top: t.space(PaymentSpace.inline)),
            child: Text(description!, style: type.caption),
          ),
        SizedBox(height: t.space(PaymentSpace.related)),
        _LeadingOverhang(
          overhang: slack,
          child: FieldGroupScope(
            disabled: disabled,
            markOptional: flags.contains(true) && flags.contains(false),
            child: layout == Axis.vertical
                ? vertical()
                : LayoutBuilder(
                    builder: (context, constraints) =>
                        constraints.maxWidth <
                                children.length * _minFieldWidth +
                                    (children.length - 1) *
                                        t.space(PaymentSpace.group) ||
                            PaymentType.isLarge(context)
                        ? vertical()
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: t.space(PaymentSpace.group),
                            children: [
                              for (final child in children)
                                Expanded(child: child),
                            ],
                          ),
                  ),
          ),
        ),
      ],
    );
  }
}

/// Internal: lays [child] out [overhang] dp higher than its slot and keeps
/// that strip hit-testable, so a row's 48 dp target can reach into the gap
/// above it while its label keeps the gap's visible size.
class _LeadingOverhang extends SingleChildRenderObjectWidget {
  const _LeadingOverhang({required this.overhang, required super.child});
  final double overhang;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderLeadingOverhang(overhang);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderLeadingOverhang renderObject,
  ) => renderObject.overhang = overhang;
}

class _RenderLeadingOverhang extends RenderProxyBox {
  _RenderLeadingOverhang(this._overhang);
  double _overhang;
  set overhang(double value) {
    if (value == _overhang) return;
    _overhang = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final child = this.child!;
    child.layout(
      constraints.copyWith(
        minHeight: 0,
        maxHeight: constraints.maxHeight + _overhang,
      ),
      parentUsesSize: true,
    );
    size = constraints.constrain(
      Size(child.size.width, math.max(0, child.size.height - _overhang)),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      context.paintChild(child!, offset.translate(0, -_overhang));

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) =>
      transform.translateByDouble(0, -_overhang, 0, 1);

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (position.dx < 0 ||
        position.dx >= size.width ||
        position.dy < -_overhang ||
        position.dy >= size.height) {
      return false;
    }
    if (!hitTestChildren(result, position: position)) return false;
    result.add(BoxHitTestEntry(this, position));
    return true;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      result.addWithPaintOffset(
        offset: Offset(0, -_overhang),
        position: position,
        hitTest: (result, transformed) =>
            child!.hitTest(result, position: transformed),
      );
}
