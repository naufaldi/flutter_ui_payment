import 'package:flutter/material.dart';
import '../foundation/primitives.dart';
import '../foundation/page_module_frame.dart';

/// A flat, ruled section of a page.
class PaymentPageModule extends StatelessWidget {
  const PaymentPageModule({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.extraActions = const [],
  });

  /// Heading displayed above the content.
  final String title;

  /// Content rendered inside this layout body.
  final Widget child;

  /// Supporting text below the module title.
  final String? subtitle;

  /// Supporting actions in the module header.
  final List<PaymentButton> extraActions;
  @override
  Widget build(BuildContext context) => PageModuleFrame(
    title: title,
    subtitle: subtitle,
    actions: extraActions,
    child: child,
  );
}

/// Ancestor navigation delegated to the host.
@immutable
class PaymentBreadcrumb {
  const PaymentBreadcrumb({required this.label, required this.onPressed});

  /// Visible name identifying this value or control.
  final String label;

  /// Runs the host action for this destination.
  final VoidCallback onPressed;
}
