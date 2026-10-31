import 'package:flutter/material.dart';
import 'payment_theme.dart';
import 'payment_type.dart';
import 'primitives.dart';
import 'button_copy.dart';
import '../controls/button_group.dart';

class ViewFrame extends StatelessWidget {
  const ViewFrame({
    super.key,
    required this.header,
    required this.body,
    this.footer,
    this.bodyPadding,
  });
  final Widget header, body;
  final Widget? footer;
  final EdgeInsetsGeometry? bodyPadding;
  @override
  Widget build(BuildContext context) {
    final space = PaymentTheme.of(context).spacing * 2;
    return LayoutBuilder(
      builder: (context, k) => Column(
        mainAxisSize: k.hasBoundedHeight ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          if (k.hasBoundedHeight)
            Expanded(
              child: SingleChildScrollView(
                padding:
                    bodyPadding ?? EdgeInsets.fromLTRB(space, 0, space, space),
                child: body,
              ),
            )
          else
            Padding(padding: bodyPadding ?? EdgeInsets.all(space), child: body),
          if (footer != null)
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: PaymentTheme.of(context).outline),
                ),
              ),
              child: SafeArea(
                top: false,
                minimum: EdgeInsets.all(space),
                child: footer!,
              ),
            ),
        ],
      ),
    );
  }
}

class ViewHeader extends StatelessWidget {
  const ViewHeader({
    super.key,
    required this.title,
    this.description,
    this.leading,
    this.trailing,
    this.below,
  });
  final String title;
  final String? description;
  final Widget? leading, trailing, below;
  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    Widget copy() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: theme.spacing * .5,
      children: [
        Semantics(header: true, child: Text(title, style: type.title)),
        if (description != null)
          Text(
            description!,
            style: type.bodyFor(context).copyWith(color: theme.textSecondary),
          ),
      ],
    );
    return Padding(
      padding: EdgeInsets.all(theme.spacing * 2),
      child: LayoutBuilder(
        builder: (context, k) {
          final stack = k.maxWidth < 600 || PaymentType.isLarge(context);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: theme.spacing * 1.5,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (leading != null)
                    Padding(
                      padding: EdgeInsetsDirectional.only(
                        end: theme.spacing * 1.5,
                      ),
                      child: SizedBox.square(dimension: 40, child: leading),
                    ),
                  Expanded(child: copy()),
                  if (!stack && trailing != null) trailing!,
                ],
              ),
              if (stack && trailing != null)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: trailing!,
                ),
              ?below,
            ],
          );
        },
      ),
    );
  }
}

class ViewFooter extends StatelessWidget {
  const ViewFooter({
    super.key,
    this.primaryAction,
    this.secondaryAction,
    this.footer,
  });
  final PaymentButton? primaryAction, secondaryAction;
  final Widget? footer;
  @override
  Widget build(BuildContext context) {
    final actions = [
      if (secondaryAction != null) hugButton(secondaryAction!),
      if (primaryAction != null) hugButton(primaryAction!),
    ];
    assert(
      actions.where((a) => a.variant == PaymentButtonVariant.primary).length <=
          1,
    );
    return LayoutBuilder(
      builder: (context, k) {
        final group = actions.isEmpty
            ? const SizedBox.shrink()
            : PaymentButtonGroup(
                collapse: PaymentButtonGroupCollapse.none,
                children: actions,
              );
        if (k.maxWidth < 400 || PaymentType.isLarge(context)) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [?footer, group],
          );
        }
        return Row(
          children: [
            Expanded(child: footer ?? const SizedBox.shrink()),
            group,
          ],
        );
      },
    );
  }
}
