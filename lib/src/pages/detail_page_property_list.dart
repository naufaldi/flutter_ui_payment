import 'package:flutter/material.dart';
import '../foundation/primitives.dart';
import '../foundation/payment_theme.dart';
import '../foundation/payment_type.dart';
import '../foundation/payment_tokens.dart';
import '../foundation/payment_localizations.dart';
import '../foundation/kit_strings.dart';
import '../foundation/page_module_frame.dart';
import '../controls/actions.dart';
import '../interaction/interaction.dart';
import '../content/empty_message.dart';
import '../content/property_list.dart';

/// One displayed detail value with optional secondary copy.
@immutable
class PaymentDetailValue {
  const PaymentDetailValue(String this.text, {this.subText}) : link = null;
  const PaymentDetailValue.link(PaymentLink this.link, {this.subText})
    : text = null;

  /// Text supplied by the host.
  final String? text;

  /// Link supplied by the host.
  final PaymentLink? link;

  /// Subtext supplied by the host.
  final String? subText;
}

/// A labeled set of related values.
@immutable
class PaymentDetailProperty {
  const PaymentDetailProperty({
    required this.label,
    required this.values,
    this.description,
  });

  /// Label supplied by the host.
  final String label;

  /// Values supplied by the host.
  final List<PaymentDetailValue> values;

  /// Description supplied by the host.
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

  /// Title supplied by the host.
  final String title;

  /// Pending supplied by the host.
  final bool pending;

  /// Items supplied by the host.
  final List<PaymentDetailProperty> items;

  /// Orientation supplied by the host.
  final Axis orientation;

  /// Oncreate supplied by the host.
  final VoidCallback? onCreate;

  /// Emptymessage supplied by the host.
  final PaymentEmptyMessage? emptyMessage;

  /// Errortext supplied by the host.
  final String? errorText;

  /// Onretry supplied by the host.
  final VoidCallback? onRetry;

  /// Extraactions supplied by the host.
  final List<PaymentLink> extraActions;
  @override
  Widget build(BuildContext context) {
    final l = PaymentLocalizations.of(context);

    /// Type=paymenttype.of(context) supplied by the host.
    final type = PaymentType.of(context);

    /// P.values)...[v.link??text(v.text!,style:type.label),if(v.subtext!=null)text(v.subtext!,style:type.caption)]]))]) supplied by the host.
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
                        vertical: PaymentTheme.of(context).spacing,
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
                                p.values.single.link!,
                              ],
                            ),
                    ),
                  )
                else
                  PaymentPropertyList(
                    orientation: orientation,
                    items: [
                      PaymentPropertyListItem(
                        label: p.label,
                        caption: p.description,
                        value: Column(
                          crossAxisAlignment: PaymentType.isLarge(context)
                              ? CrossAxisAlignment.start
                              : CrossAxisAlignment.end,
                          children: [
                            for (final v in p.values) ...[
                              v.link ?? Text(v.text!, style: type.label),
                              if (v.subText != null)
                                Text(v.subText!, style: type.caption),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
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
