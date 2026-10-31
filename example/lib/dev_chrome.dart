import 'package:flutter/material.dart';

/// Gallery and host-tool chrome. It is deliberately unlike the product: a
/// grey workbench, small monospace captions, and text that stops scaling at
/// 1.2×, so chrome never reads as an end-user component.
Color devWorkbench(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFF0B0C0E)
    : const Color(0xFFEEF0F3);

/// 12/16.8 monospace for class names, state selectors and host logs.
TextStyle devMono(Color color) => TextStyle(
  fontSize: 12,
  height: 1.4,
  color: color,
  fontFamily: 'Menlo',
  fontFamilyFallback: const ['monospace'],
);

/// Chrome text follows the system text size only up to 1.2×.
TextScaler devScaler(BuildContext context) =>
    MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.2);
