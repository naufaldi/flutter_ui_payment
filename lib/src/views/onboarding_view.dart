import 'package:flutter/material.dart';
import '../foundation/primitives.dart';
import '../foundation/payment_theme.dart';
import '../foundation/payment_localizations.dart';
import '../foundation/kit_strings.dart';
import '../foundation/view_frame.dart';
import '../foundation/layout_rules.dart';
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
    if (!old.completed && widget.completed) completed();
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

    final content = w.completed
        ? StateMessage(
            icon: Icons.check_circle_outline,
            title: l.onboardingDone,
          )
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
            spacing: PaymentTheme.of(context).space(PaymentSpace.group),
            children: [
              if (w.error != null) w.error!,
              content,
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
