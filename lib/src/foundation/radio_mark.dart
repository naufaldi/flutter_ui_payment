import 'dart:ui' show ColorSpace;

import 'package:flutter/material.dart';

import 'payment_motion.dart';
import 'payment_theme.dart';

/// Internal radio look shared by selection controls and the method picker.
///
/// The selected transition eases the ring over [PaymentMotion.quick] on
/// [PaymentMotion.easeOut], retargeting from the look on screen, so a rapid
/// change never restarts from an endpoint. It is paint only: the 20 dp box,
/// the final colors and strokes, and the consumers' checked state are
/// unchanged. Keyboard-driven selection and reduced motion (either flag)
/// land on the final look at once; nothing animates on the first build.
class RadioMark extends StatefulWidget {
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
  State<RadioMark> createState() => _RadioMarkState();
}

class _RadioMarkState extends State<RadioMark>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // 0 paints the unselected ring, 1 the selected one. The first build lands
  // on the final value, so mounting never animates.
  late final AnimationController _look = AnimationController(
    vsync: this,
    value: widget.selected ? 1.0 : 0.0,
  );

  double get _target => widget.selected ? 1.0 : 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _look.dispose();
    super.dispose();
  }

  // iOS Reduce Motion is not part of MediaQueryData, so a flag flipped while
  // the ring is on screen reaches the kit only through this callback (the
  // same gap MotionSwap observes for).
  @override
  void didChangeAccessibilityFeatures() => setState(() {});

  @override
  void didUpdateWidget(RadioMark oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected == widget.selected) return;
    final motion = PaymentMotion.of(context);
    // Keyboard-driven changes are instant, as everywhere in the kit; the
    // mark is feedback and never a gate on the selection itself.
    final keyboard =
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    if (motion.reduced || keyboard) {
      _look.value = _target;
    } else {
      _look.animateTo(
        _target,
        duration: motion.quick,
        curve: PaymentMotion.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final motion = PaymentMotion.of(context);
    // Reduced motion ends a running transition on the next frame whichever
    // flag turned it on: a MediaQuery change rebuilds into this check, and
    // the platform flag arrives through didChangeAccessibilityFeatures.
    if (motion.reduced && _look.value != _target) _look.value = _target;
    final theme = PaymentTheme.of(context);
    // The endpoints are today's colors exactly: selected wins over error,
    // and disabled wins over both.
    final selectedColor = !widget.enabled ? theme.disabled : theme.accent;
    final unselectedColor = !widget.enabled
        ? theme.disabled
        : widget.error
        ? theme.danger.foreground
        : theme.textSecondary;
    // Flutter's Color.lerp does not support extended sRGB. Keep the host's
    // exact color in that case and animate only the width.
    final canInterpolateColor =
        unselectedColor.colorSpace != ColorSpace.extendedSRGB &&
        selectedColor.colorSpace != ColorSpace.extendedSRGB;
    return AnimatedBuilder(
      animation: _look,
      builder: (context, _) {
        final t = _look.value;
        final color = switch (t) {
          _ when !canInterpolateColor =>
            widget.selected ? selectedColor : unselectedColor,
          0 => unselectedColor,
          1 => selectedColor,
          _ => Color.lerp(unselectedColor, selectedColor, t)!,
        };
        return Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.5 + (6 - 1.5) * t),
          ),
        );
      },
    );
  }
}
