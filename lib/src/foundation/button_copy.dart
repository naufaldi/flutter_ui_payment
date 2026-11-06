import 'package:flutter/widgets.dart';

import 'primitives.dart';
import 'payment_tokens.dart';

PaymentButton hugButton(PaymentButton b, {PaymentSize? size}) => PaymentButton(
  key: b.key,
  focusNode: b.focusNode,
  label: b.label,
  onPressed: b.onPressed,
  variant: b.variant,
  size: size ?? b.size,
  width: PaymentWidth.hug,
  autofocus: b.autofocus,
  busy: b.busy,
  busyLabel: b.busyLabel,
  icon: b.icon,
  style: b.style,
);

/// Package-internal: gives each disabled [PaymentButton] below it [hint] as
/// its semantics hint, so a screen reader that moves straight to the button
/// hears why it is unavailable (D119). Not exported.
class DisabledButtonHint extends InheritedWidget {
  const DisabledButtonHint({
    super.key,
    required this.hint,
    required super.child,
  });

  final String hint;

  static String? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DisabledButtonHint>()?.hint;

  @override
  bool updateShouldNotify(DisabledButtonHint old) => hint != old.hint;
}
