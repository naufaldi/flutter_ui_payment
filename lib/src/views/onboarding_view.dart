import 'package:flutter/material.dart';
import '../foundation/primitives.dart';
import '../foundation/payment_theme.dart';
import '../foundation/payment_localizations.dart';
import '../foundation/kit_strings.dart';
import '../foundation/view_frame.dart';
import '../foundation/layout_rules.dart';
import '../foundation/first_line.dart';
import '../foundation/payment_icons.dart';
import '../foundation/payment_motion.dart';
import '../foundation/motion_swap.dart';
import '../foundation/payment_type.dart';
import '../foundation/payment_tokens.dart';
import '../interaction/interaction.dart';
import '../content/task_list.dart';

/// Host-guided setup with current content before the task list on phones.
///
/// [primaryAction], with at most one quiet [secondaryAction], is the current
/// step's submit. Given a bounded height the content scrolls and the actions
/// pin to a footer at the bottom (D62); inside a scroll view they follow the
/// content. A step's form then leaves its own button out: [IdentityForm]
/// takes an [IdentityFormController], and [VerificationReview] takes
/// `inlineSubmit: false` with [VerificationReview.submitButton] here. Without
/// actions the step's content keeps its own inline button, as before.
class PaymentOnboardingView extends StatefulWidget {
  const PaymentOnboardingView({
    super.key,
    required this.title,
    required this.tasks,
    required this.child,
    this.description,
    this.pending = false,
    this.error,
    this.completed = false,
    this.onCompleted,
    this.primaryAction,
    this.secondaryAction,
  });

  /// Heading displayed above the content.
  final String title;

  /// Tasks and progress states decided by the host.
  final List<PaymentTaskListItem> tasks;

  /// Content rendered inside this layout body.
  final Widget child;

  /// Persistent explanation below the heading or label.
  final String? description;

  /// Shows placeholders while the host loads content.
  final bool pending;

  /// Host error banner above the current task content.
  final PaymentBanner? error;

  /// Whether all host work is complete.
  final bool completed;

  /// Host action for leaving the completed onboarding flow.
  final VoidCallback? onCompleted;

  /// The current step's submit, pinned at the bottom (D62). Hidden while
  /// [pending] or [completed], when the step's content isn't shown.
  final PaymentButton? primaryAction;

  /// Quiet only (D59), under [primaryAction].
  final PaymentButton? secondaryAction;
  @override
  State<PaymentOnboardingView> createState() => _PaymentOnboardingViewState();
}

class _PaymentOnboardingViewState extends State<PaymentOnboardingView> {
  // True once the flow finishes while on screen: only then does the done
  // mark settle in. A view first built completed shows it at rest.
  bool _finishedHere = false;

  void completed() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onCompleted?.call();
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.completed) completed();
  }

  @override
  void didUpdateWidget(covariant PaymentOnboardingView old) {
    super.didUpdateWidget(old);
    if (!old.completed && widget.completed) {
      _finishedHere = true;
      completed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    assert(
      w.secondaryAction == null ||
          w.secondaryAction!.variant == PaymentButtonVariant.quiet,
    );
    final showActions =
        !w.completed &&
        !w.pending &&
        (w.primaryAction != null || w.secondaryAction != null);

    final l = PaymentLocalizations.of(context);

    final current = w.tasks.indexWhere(
      (t) => t.status != PaymentTaskStatus.complete,
    );

    final motion = PaymentMotion.of(context);
    final gap = PaymentTheme.of(context).space(PaymentSpace.group);
    final content = w.completed
        ? _DoneMessage(title: l.onboardingDone, settle: _finishedHere)
        : w.pending
        ? Semantics(
            liveRegion: true,
            child: Row(
              spacing: PaymentTheme.of(context).space(PaymentSpace.block),
              children: [
                const PaymentSpinner(),
                Flexible(child: Text(l.loading)),
              ],
            ),
          )
        : w.child;
    return LayoutBuilder(
      builder: (context, k) {
        final wide = k.maxWidth >= kTwoColumnBreakpoint;

        final frame = ViewFrame(
          header: ViewHeader(
            title: w.title,
            description: w.description,
            below: wide || current < 0
                ? null
                : Text(
                    l.stepOf(
                      current + 1,
                      w.tasks.length,
                      w.tasks[current].title,
                    ),
                  ),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: gap,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // The kit-owned banner slot fades and its height eases,
                  // so the step below glides when an error shows or clears
                  // (D94). Its gap travels with it.
                  motion.fullWidthSwap(
                    w.error == null
                        ? const SizedBox.shrink(key: ValueKey('no-error'))
                        : Padding(
                            key: const ValueKey('error'),
                            padding: EdgeInsets.only(bottom: gap),
                            child: w.error,
                          ),
                  ),
                  // Loading, each task and done arrive from below as the
                  // flow moves forward (D94). The leaving step takes no
                  // taps or focus and is hidden from screen readers. If
                  // reduced motion turns on mid-swap, the swap ends at once.
                  MotionSwap(
                    transition: PaymentMotion.fadeRise,
                    easeSize: false,
                    child: SizedBox(
                      key: ValueKey(
                        w.completed
                            ? 'done'
                            : w.pending
                            ? 'loading'
                            : 'task-$current',
                      ),
                      // Filled, so the step keeps the column's start edge in
                      // the switcher's stack.
                      width: double.infinity,
                      child: content,
                    ),
                  ),
                ],
              ),
              if (!wide)
                PaymentAccordionItem(
                  title: l.allSteps,
                  child: PaymentTaskList(items: w.tasks),
                ),
            ],
          ),
          footer: showActions
              ? ViewFooter(
                  primaryAction: w.primaryAction,
                  secondaryAction: w.secondaryAction,
                )
              : null,
        );
        if (!wide) return frame;
        // Two columns stay two columns, centred up to 1040 dp (D53, Q1).
        return ContentColumn(
          maxWidth: kTwoColumnMaxWidth,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 280,
                child: SingleChildScrollView(
                  child: PaymentTaskList(items: w.tasks),
                ),
              ),
              VerticalDivider(
                width: 1,
                color: PaymentTheme.of(context).outline,
              ),
              Expanded(child: frame),
            ],
          ),
        );
      },
    );
  }
}

/// The "done" message, laid out as a [StateMessage], whose mark settles in
/// with a compact fade and scale from 0.95 when [settle] is set (D94).
class _DoneMessage extends StatelessWidget {
  const _DoneMessage({required this.title, required this.settle});

  final String title;
  final bool settle;

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final motion = PaymentMotion.of(context);
    return Semantics(
      container: true,
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: theme.space(PaymentSpace.group),
        ),
        child: FirstLineRow(
          leading: ExcludeSemantics(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: settle && !motion.reduced ? 0 : 1, end: 1),
              duration: motion.enter,
              builder: (context, t, glyph) =>
                  PaymentMotion.fadeScale(glyph!, AlwaysStoppedAnimation(t)),
              child: const PaymentIcon(
                Icons.check_circle_outline,
                color: PaymentTextColor.secondary,
              ),
            ),
          ),
          gap: theme.space(PaymentSpace.block),
          text: Text(title, style: PaymentType.of(context).heading),
        ),
      ),
    );
  }
}
