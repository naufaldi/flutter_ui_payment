import 'package:flutter/material.dart';
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
  @override
  Widget build(BuildContext context) {
    final t = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    final flags = children.map(_required).nonNulls.toList();
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
        FieldGroupScope(
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
      ],
    );
  }
}
