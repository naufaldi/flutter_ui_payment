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

  /// Title supplied by the host.
  final String title;

  /// Pending supplied by the host.
  final bool pending;

  /// Columns supplied by the host.
  final List<PaymentDataColumn<T>> columns;

  /// Rows supplied by the host.
  final List<T> rows;

  /// Rowkey supplied by the host.
  final String Function(T row) rowKey;

  /// Onrowpressed supplied by the host.
  final void Function(T row)? onRowPressed;

  /// Rowactions supplied by the host.
  final List<PaymentRowActionEntry<T>> rowActions;

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
