import 'package:flutter/material.dart';
import 'payment_theme.dart';

/// Internal radio look shared by selection controls and the method picker.
class RadioMark extends StatelessWidget {
  const RadioMark({
    super.key,
    required this.selected,
    required this.enabled,
    this.error = false,
  });
  final bool selected;
  final bool enabled;
  final bool error;
  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final color = !enabled
        ? theme.disabled
        : selected
        ? theme.accent
        : error
        ? theme.danger.foreground
        : theme.textSecondary;
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: selected ? 6 : 1.5),
      ),
    );
  }
}
