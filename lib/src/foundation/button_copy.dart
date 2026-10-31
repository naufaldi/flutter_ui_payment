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
);
