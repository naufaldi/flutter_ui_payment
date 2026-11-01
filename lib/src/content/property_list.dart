import 'package:flutter/material.dart';
import '../foundation/primitives.dart';
import '../foundation/payment_theme.dart';
import '../foundation/payment_type.dart';
import '../foundation/payment_tokens.dart';

/// Label/value pairs, stacked or arranged horizontally when space permits.
class PaymentPropertyList extends StatelessWidget {
  /// Creates a list of host-provided facts.
  const PaymentPropertyList({
    super.key,
    required this.items,
    this.orientation = Axis.vertical,
    this.title,
  });

  /// Facts in reading order.
  final List<PaymentPropertyListItem> items;

  /// Preferred arrangement; narrow or large text always stacks.
  final Axis orientation;

  /// Optional section heading.
  final String? title;
  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    final list = LayoutBuilder(
      builder: (context, constraints) {
        if (orientation == Axis.vertical ||
            constraints.maxWidth < 360 ||
            PaymentType.isLarge(context)) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final item in items)
                InfoRow(
                  label: item.label,
                  value: item.value,
                  valueText: item.valueText,
                  emphasis: item.emphasis,
                  caption: item.caption,
                  trailing: item.trailing,
                  reference: item.reference,
                ),
            ],
          );
        }
        return Wrap(
          spacing: theme.space(PaymentSpace.section),
          runSpacing: theme.space(PaymentSpace.group),
          children: [
            for (final item in items)
              MergeSemantics(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: theme.space(PaymentSpace.inline),
                  children: [
                    Text(item.label, style: type.caption),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child:
                              item.value ??
                              Text(
                                item.valueText!,
                                style: switch ((
                                  item.emphasis,
                                  item.reference,
                                )) {
                                  (true, _) => type.heading,
                                  (false, true) => type.reference(type.label),
                                  (false, false) => type.label,
                                },
                              ),
                        ),
                        if (item.trailing != null) item.trailing!,
                      ],
                    ),
                    if (item.caption != null)
                      Text(item.caption!, style: type.caption),
                  ],
                ),
              ),
          ],
        );
      },
    );
    return title == null ? list : PaymentSection(title: title!, child: list);
  }
}

/// A fact with exactly one text or widget value.
@immutable
class PaymentPropertyListItem {
  /// Creates a fact. Supply either valueText or value.
  const PaymentPropertyListItem({
    required this.label,
    this.valueText,
    this.value,
    this.emphasis = false,
    this.caption,
    this.trailing,
    this.reference = false,
  }) : assert((valueText == null) != (value == null));

  /// Descriptive label.
  final String label;

  /// Plain value.
  final String? valueText;

  /// Rich value.
  final Widget? value;

  /// Emphasizes a total or important fact.
  final bool emphasis;

  /// Supporting explanation.
  final String? caption;

  /// Optional action after the value, such as a [PaymentCopyButton].
  final Widget? trailing;

  /// Shows [valueText] as a reference or ID: monospace tabular text on the
  /// value edge, without a fill (D57). Add a copy button as [trailing].
  final bool reference;
}
