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

  /// Title supplied by the host.
  final String title;

  /// Child supplied by the host.
  final Widget child;

  /// Subtitle supplied by the host.
  final String? subtitle;

  /// Extraactions supplied by the host.
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

  /// Label supplied by the host.
  final String label;

  /// Onpressed supplied by the host.
  final VoidCallback onPressed;
}
