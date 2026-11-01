import 'package:flutter/material.dart';
import '../foundation/primitives.dart';
import '../foundation/payment_theme.dart';
import '../foundation/payment_type.dart';
import '../foundation/payment_tokens.dart';
import '../foundation/payment_localizations.dart';
import '../foundation/kit_strings.dart';
import '../foundation/page_module_frame.dart';
import '../foundation/first_line.dart';
import '../controls/actions.dart';
import '../foundation/tap_target.dart';
import '../interaction/interaction.dart';
import '../content/empty_message.dart';
import '../content/property_list.dart';

/// One displayed detail value with optional secondary copy.
@immutable
class PaymentDetailValue {
  const PaymentDetailValue(
    String this.text, {
    this.subText,
    this.reference = false,
    this.onCopy,
  }) : link = null;
  const PaymentDetailValue.link(PaymentLink this.link, {this.subText})
    : text = null,
      reference = false,
      onCopy = null;

  /// Plain detail value; absent when a link is used.
  final String? text;

  /// Interactive detail value; absent for plain text.
  final PaymentLink? link;

  /// Supporting copy below a detail value.
  final String? subText;

  /// Shows [text] as a reference or ID: monospace tabular text on the value
  /// edge, without a fill (D57).
  final bool reference;

  /// Host copy for [text]; adds a [PaymentCopyButton] whose glyph sits on
  /// the value edge.
  final Future<bool> Function(String value)? onCopy;
}

/// A labeled set of related values.
@immutable
class PaymentDetailProperty {
  const PaymentDetailProperty({
    required this.label,
    required this.values,
    this.description,
  });

  /// Visible name identifying this value or control.
  final String label;

  /// Related values displayed together.
  final List<PaymentDetailValue> values;

  /// Persistent explanation below the heading or label.
  final String? description;
}

/// Property module with loading, empty and retry states.
class PaymentDetailPagePropertyList extends StatelessWidget {
  const PaymentDetailPagePropertyList({
    super.key,
    required this.title,
    required this.pending,
    this.items = const [],
    this.orientation = Axis.vertical,
    this.onCreate,
    this.emptyMessage,
    this.errorText,
    this.onRetry,
    this.extraActions = const [],
  });

  /// Heading displayed above the content.
  final String title;

  /// Shows placeholders while the host loads content.
  final bool pending;

  /// Host facts rendered in order.
  final List<PaymentDetailProperty> items;

  /// Preferred arrangement of labels and values.
  final Axis orientation;

  /// Host action for adding a detail record.
  final VoidCallback? onCreate;

  /// Explanation and optional recovery action for missing content.
  final PaymentEmptyMessage? emptyMessage;

  /// Safe error copy displayed with the affected content.
  final String? errorText;

  /// Retries the failed host request.
  final VoidCallback? onRetry;

  /// Supporting actions in the module header.
  final List<PaymentLink> extraActions;
  @override
  Widget build(BuildContext context) {
    final l = PaymentLocalizations.of(context);

    final type = PaymentType.of(context);

    Widget copy(PaymentDetailValue v) => EdgeAlignedIcon(
      child: PaymentCopyButton(value: v.text!, onCopy: v.onCopy!),
    );
    Widget text(PaymentDetailValue v) => Text(
      v.text!,
      style: v.reference ? type.reference(type.label) : type.label,
    );
    Widget facts(List<PaymentDetailProperty> properties) => PaymentPropertyList(
      orientation: orientation,
      items: [
        for (final p in properties)
          // One copyable value keeps InfoRow's first-line copy button.
          if (p.values.length == 1 &&
              p.values.single.onCopy != null &&
              p.values.single.subText == null)
            PaymentPropertyListItem(
              label: p.label,
              caption: p.description,
              valueText: p.values.single.text,
              reference: p.values.single.reference,
              trailing: copy(p.values.single),
            )
          // One link value rides InfoRow's first-line trailing slot, so the
          // link text shares the label's line instead of sitting 14 dp
          // lower in its 48 dp target (#66).
          else if (p.values.length == 1 &&
              p.values.single.link != null &&
              p.values.single.subText == null)
            PaymentPropertyListItem(
              label: p.label,
              caption: p.description,
              value: const SizedBox.shrink(),
              trailing: p.values.single.link,
            )
          else
            PaymentPropertyListItem(
              label: p.label,
              caption: p.description,
              value: Column(
                crossAxisAlignment: PaymentType.isLarge(context)
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.end,
                children: [
                  for (final v in p.values) ...[
                    if (v.link != null)
                      v.link!
                    else if (v.onCopy != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(child: text(v)),
                          copy(v),
                        ],
                      )
                    else
                      text(v),
                    if (v.subText != null)
                      Text(v.subText!, style: type.caption),
                  ],
                ],
              ),
            ),
      ],
    );

    final body = pending
        ? const LoadingSkeleton(rows: 3, leading: false)
        : errorText != null
        ? StateMessage(
            icon: Icons.cloud_off_outlined,
            title: errorText!,
            tone: StatusTone.warning,
            actionLabel: onRetry == null ? null : l.retry,
            onAction: onRetry,
          )
        : items.isEmpty
        ? StateMessage(
            icon: emptyMessage?.icon ?? Icons.inbox_outlined,
            title: emptyMessage?.title ?? l.emptyTitle,
            message: emptyMessage?.message,
            actionLabel: emptyMessage?.actionLabel,
            onAction: emptyMessage?.onAction,
          )
        : orientation == Axis.horizontal
        ? facts(items)
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final p in items)
                if (p.values.length == 1 &&
                    p.values.single.link != null &&
                    p.values.single.subText == null &&
                    p.description == null)
                  MergeSemantics(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: PaymentTheme.of(
                          context,
                        ).space(PaymentSpace.related),
                      ),
                      child: PaymentType.isLarge(context)
                          ? Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: PaymentTheme.of(
                                context,
                              ).space(PaymentSpace.group),
                              children: [
                                Text(
                                  p.label,
                                  style: type.label.copyWith(
                                    color: PaymentTheme.of(
                                      context,
                                    ).textSecondary,
                                  ),
                                ),
                                p.values.single.link!,
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    p.label,
                                    style: type.label.copyWith(
                                      color: PaymentTheme.of(
                                        context,
                                      ).textSecondary,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: PaymentTheme.of(
                                    context,
                                  ).space(PaymentSpace.group),
                                ),
                                TextActionEdge.end(
                                  child: p.values.single.link!,
                                ),
                              ],
                            ),
                    ),
                  )
                else
                  facts([p]),
            ],
          );
    return PageModuleFrame(
      title: title,
      actions: [
        if (onCreate != null)
          PaymentButton(
            label: l.create,
            onPressed: onCreate,
            variant: PaymentButtonVariant.secondary,
            size: PaymentSize.small,
            width: PaymentWidth.hug,
          ),
      ],
      trailing: extraActions.isEmpty
          ? null
          : PaymentMenu(
              entries: [
                for (final link in extraActions)
                  PaymentMenuItem(
                    label: link.label,
                    onSelected: link.onPressed,
                  ),
              ],
            ),
      child: body,
    );
  }
}
