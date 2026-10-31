import 'package:flutter/material.dart';

/// Empty-state explanation and an optional next action.
@immutable
class PaymentEmptyMessage {
  /// Creates host-authored empty-state copy.
  const PaymentEmptyMessage(
    this.title, {
    this.message,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.inbox_outlined,
  }) : assert((actionLabel == null) == (onAction == null));

  /// What is empty.
  final String title;

  /// Why it is empty.
  final String? message;

  /// Next action label.
  final String? actionLabel;

  /// Host action, supplied together with its label.
  final VoidCallback? onAction;

  /// Supporting visual cue.
  final IconData icon;
}
