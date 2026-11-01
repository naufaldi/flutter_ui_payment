import 'package:flutter/material.dart';
import 'payment_theme.dart';

/// Internal horizontal overflow affordance.
class EdgeFadeScroll extends StatefulWidget {
  const EdgeFadeScroll({
    super.key,
    required this.child,
    this.padding,
    this.clipBehavior = Clip.hardEdge,
  });
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Clip clipBehavior;
  @override
  State<EdgeFadeScroll> createState() => _EdgeFadeScrollState();
}

class _EdgeFadeScrollState extends State<EdgeFadeScroll> {
  final _controller = ScrollController();
  // The mask comes and goes with overflow; the key moves the scroll view
  // with its offset instead of rebuilding it at 0.
  final _scrollKey = GlobalKey();
  bool _start = false, _end = false;
  void _update() {
    if (!mounted || !_controller.hasClients) return;
    final start = _controller.position.extentBefore > 0;
    final end = _controller.position.extentAfter > 0;
    if (start != _start || end != _end) {
      setState(() {
        _start = start;
        _end = end;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_update);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _update());
    final scroll = SingleChildScrollView(
      key: _scrollKey,
      controller: _controller,
      scrollDirection: Axis.horizontal,
      padding: widget.padding,
      clipBehavior: widget.clipBehavior,
      child: widget.child,
    );
    if (!_start && !_end) return scroll;
    final color = PaymentTheme.of(context).surface;
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (r) {
        final edge = (24 / r.width).clamp(0.0, 0.5);
        final rtl = Directionality.of(context) == TextDirection.rtl;
        return LinearGradient(
          colors: [
            (rtl ? _end : _start) ? color.withValues(alpha: 0) : color,
            color,
            color,
            (rtl ? _start : _end) ? color.withValues(alpha: 0) : color,
          ],
          stops: [0, edge, 1 - edge, 1],
        ).createShader(r);
      },
      child: scroll,
    );
  }
}
