import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../foundation/first_line.dart';
import '../foundation/payment_theme.dart';
import '../foundation/payment_type.dart';
import '../foundation/row_shell.dart';
import '../foundation/kit_strings.dart';
import '../foundation/payment_localizations.dart';
import '../foundation/payment_tokens.dart';

/// Host-owned task progress.
enum PaymentTaskStatus {
  /// Work has not begun.
  notStarted,

  /// Work is underway.
  inProgress,

  /// Work requires intervention.
  blocked,

  /// Work is complete.
  complete,
}

/// Sequential setup tasks with distinct status marks.
class PaymentTaskList extends StatelessWidget {
  /// Creates a task list.
  const PaymentTaskList({super.key, required this.items});

  /// Top-level tasks, each with at most one level of sub-tasks.
  final List<PaymentTaskListItem> items;
  @override
  Widget build(BuildContext context) {
    assert(items.every((t) => t.subTasks.every((s) => s.subTasks.isEmpty)));
    final theme = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    final strings = PaymentLocalizations.of(context);
    // The icon centres on the label's first line: the 48 dp row centre at
    // normal text, the first line inside the row padding when it wraps.
    final iconBand = math.max(
      48.0,
      lineHeightOf(context, type.label) + 2 * theme.space(PaymentSpace.block),
    );
    Widget row(PaymentTaskListItem item, {bool last = true}) {
      final done = item.status == PaymentTaskStatus.complete;
      final label = [
        item.title,
        strings.taskStatus(item.status),
        if (item.subTasks.isNotEmpty)
          strings.subTasksComplete(
            item.subTasks
                .where((s) => s.status == PaymentTaskStatus.complete)
                .length,
            item.subTasks.length,
          ),
      ].join(', ');
      final icon = switch (item.status) {
        PaymentTaskStatus.notStarted => Icons.radio_button_unchecked,
        PaymentTaskStatus.inProgress => Icons.contrast,
        PaymentTaskStatus.blocked => Icons.lock_outline,
        PaymentTaskStatus.complete => Icons.check_circle,
      };
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 24,
                  child: Column(
                    children: [
                      SizedBox(
                        height: iconBand,
                        child: Icon(
                          icon,
                          color:
                              done ||
                                  item.status == PaymentTaskStatus.inProgress
                              ? theme.accent
                              : theme.textSecondary,
                          size: 24,
                        ),
                      ),
                      if (!last)
                        Expanded(
                          child: Center(
                            child: Container(width: 2, color: theme.outline),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(width: theme.space(PaymentSpace.block)),
                Expanded(
                  child: Semantics(
                    container: true,
                    excludeSemantics: true,
                    label: label,
                    button: item.onPressed != null,
                    onTap: item.onPressed,
                    child: RowShell(
                      onTap: item.onPressed,
                      child: Text(
                        item.title,
                        style: type.label.copyWith(
                          color: done ? theme.textSecondary : theme.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!done && item.subTasks.isNotEmpty)
            Padding(
              padding: EdgeInsetsDirectional.only(
                start: 24 + theme.space(PaymentSpace.block),
              ),
              child: Column(
                children: [for (final sub in item.subTasks) row(sub)],
              ),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < items.length; i++)
          row(items[i], last: i == items.length - 1),
      ],
    );
  }
}

/// One task and its host-defined status.
@immutable
class PaymentTaskListItem {
  /// Creates a setup task.
  const PaymentTaskListItem({
    required this.title,
    this.status = PaymentTaskStatus.notStarted,
    this.onPressed,
    this.subTasks = const [],
  });

  /// Task name.
  final String title;

  /// Host-owned progress state.
  final PaymentTaskStatus status;

  /// Optional host action.
  final VoidCallback? onPressed;

  /// One level of child tasks; hidden when complete.
  final List<PaymentTaskListItem> subTasks;
}
