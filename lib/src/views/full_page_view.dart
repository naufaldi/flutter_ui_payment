import 'package:flutter/material.dart';
import '../foundation/primitives.dart';
import '../foundation/view_frame.dart';
import '../foundation/button_copy.dart';

/// Full-page body; the host supplies its scaffold and navigation.
class PaymentFullPageView extends StatelessWidget {
  const PaymentFullPageView({
    super.key,
    required this.title,
    required this.child,
    this.pageAction,
  });

  /// Heading displayed above the content.
  final String title;

  /// Content rendered inside this layout body.
  final Widget child;

  /// Supporting action alongside the page heading.
  final PaymentButton? pageAction;
  @override
  Widget build(BuildContext context) => ViewFrame(
    header: ViewHeader(
      title: title,
      trailing: pageAction == null ? null : hugButton(pageAction!),
    ),
    body: child,
  );
}
