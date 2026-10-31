import 'package:flutter/material.dart';
import 'payment_theme.dart';
import 'payment_type.dart';
import 'payment_tokens.dart';
import 'primitives.dart';
import 'button_copy.dart';
import '../controls/button_group.dart';

class PageModuleFrame extends StatelessWidget {
  const PageModuleFrame({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions = const [],
    this.trailing,
  });
  final String title;
  final Widget child;
  final String? subtitle;
  final List<PaymentButton> actions;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(header: true, child: Text(title, style: type.heading)),
        if (subtitle != null) Text(subtitle!, style: type.caption),
      ],
    );
    final buttons = actions.isEmpty
        ? null
        : PaymentButtonGroup(
            children: [
              for (final a in actions) hugButton(a, size: PaymentSize.small),
            ],
          );
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.outline)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          top: theme.spacing * 2,
          bottom: theme.spacing * 3,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: theme.spacing * 1.5,
          children: [
            LayoutBuilder(
              builder: (context, k) {
                if (k.maxWidth < 400 || PaymentType.isLarge(context)) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [heading, ?buttons, ?trailing],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: heading),
                    if (buttons != null) Flexible(child: buttons),
                    ?trailing,
                  ],
                );
              },
            ),
            child,
          ],
        ),
      ),
    );
  }
}
