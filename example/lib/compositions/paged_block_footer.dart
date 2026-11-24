import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:rakit_ui/rakit_ui.dart';

/// The host keeps the active page on failure and supplies a fresh attempt ID.
class PagedBlockFooter extends StatefulWidget {
  const PagedBlockFooter({
    super.key,
    required this.label,
    required this.loading,
    required this.error,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final ({String message, int attempt})? error;
  final VoidCallback onPressed;

  @override
  State<PagedBlockFooter> createState() => _PagedBlockFooterState();
}

class _PagedBlockFooterState extends State<PagedBlockFooter> {
  @override
  void didUpdateWidget(PagedBlockFooter oldWidget) {
    super.didUpdateWidget(oldWidget);
    final attempt = widget.error?.attempt;
    if (attempt == null || attempt == oldWidget.error?.attempt) return;

    final footer = context.findRenderObject()! as RenderBox;
    final viewport = RenderAbstractViewport.of(footer);
    final position = Scrollable.of(context).position;
    final offset = position.pixels;
    final top = viewport.getOffsetToReveal(footer, 0).offset;
    // Don't pull the reader back to the footer if they scrolled away.
    if (position.isScrollingNotifier.value ||
        top + footer.size.height <= offset ||
        top >= offset + position.viewportDimension) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          widget.error?.attempt != attempt ||
          !footer.attached ||
          position.isScrollingNotifier.value ||
          position.pixels != offset) {
        return;
      }
      // When the message cannot fit with Retry, reveal the button first.
      position.ensureVisible(
        footer,
        alignmentPolicy: footer.size.height > position.viewportDimension
            ? ScrollPositionAlignmentPolicy.explicit
            : ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.space(PaymentSpace.related),
      children: [
        PaymentButton(
          label: widget.label,
          variant: PaymentButtonVariant.secondary,
          busy: widget.loading,
          onPressed: widget.onPressed,
        ),
        if (widget.error case (:final message, :final attempt))
          VisibleBlockError(
            key: ValueKey(attempt),
            message: message,
            child: Text(
              message,
              style: PaymentType.of(
                context,
              ).bodyFor(context).copyWith(color: theme.textSecondary),
            ),
          ),
      ],
    );
  }
}

/// A keyed live region whose copy isn't announced while clipped offscreen.
class VisibleBlockError extends Semantics {
  VisibleBlockError({super.key, required String message, required super.child})
    : super(
        container: true,
        excludeSemantics: true,
        liveRegion: true,
        label: message,
      );

  @override
  RenderSemanticsAnnotations createRenderObject(BuildContext context) =>
      _RenderVisibleErrorSemantics(properties, Directionality.of(context));
}

class _RenderVisibleErrorSemantics extends RenderSemanticsAnnotations {
  _RenderVisibleErrorSemantics(
    SemanticsProperties properties,
    TextDirection textDirection,
  ) : super(
        properties: properties,
        textDirection: textDirection,
        container: true,
        excludeSemantics: true,
      );

  @override
  void assembleSemanticsNode(
    SemanticsNode node,
    SemanticsConfiguration config,
    Iterable<SemanticsNode> children,
  ) {
    // Flutter computes clipping before assembly. A scroll can supersede the
    // reveal, so never publish a new label while the node is hidden.
    if (config.isHidden) {
      config = config.copy()..liveRegion = false;
      if (node.label != config.label) config.label = '';
    }
    super.assembleSemanticsNode(node, config, children);
  }
}
