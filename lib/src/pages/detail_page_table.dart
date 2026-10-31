import 'package:flutter/material.dart';
import '../foundation/primitives.dart';
import '../foundation/payment_theme.dart';
import '../foundation/payment_tokens.dart';
import '../foundation/payment_localizations.dart';
import '../foundation/kit_strings.dart';
import '../foundation/page_module_frame.dart';
import '../controls/actions.dart';
import '../interaction/interaction.dart';
import '../content/empty_message.dart';
import '../content/data_table.dart';

/// A table module with host row actions and no selection or pagination.
class PaymentDetailPageTable<T> extends StatelessWidget {
  const PaymentDetailPageTable({
    super.key,
    required this.title,
    required this.pending,
    required this.columns,
    required this.rows,
    required this.rowKey,
    this.onRowPressed,
    this.rowActions = const <Never>[],
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

  /// Columns defining how host row values are rendered.
  final List<PaymentDataColumn<T>> columns;

  /// Host records displayed by the table module.
  final List<T> rows;

  /// Stable host identifier for each row.
  final String Function(T row) rowKey;

  /// Opens a host destination for the chosen row.
  final void Function(T row)? onRowPressed;

  /// Host actions offered for each record.
  final List<PaymentRowActionEntry<T>> rowActions;

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
      child: errorText != null && !pending
          ? StateMessage(
              icon: Icons.cloud_off_outlined,
              title: errorText!,
              tone: StatusTone.warning,
              actionLabel: onRetry == null ? null : l.retry,
              onAction: onRetry,
            )
          : PaymentDataTable<T>(
              columns: columns,
              rows: rows,
              rowKey: rowKey,
              onRowPressed: onRowPressed,
              rowActions: rowActions,
              pagination: null,
              pending: pending,
              emptyMessage: emptyMessage,
            ),
    );
  }
}
