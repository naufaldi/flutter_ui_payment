import 'package:flutter/material.dart';
import '../foundation/primitives.dart';
import '../foundation/payment_theme.dart';
import '../foundation/payment_localizations.dart';
import '../foundation/kit_strings.dart';
import '../foundation/view_frame.dart';
import '../interaction/interaction.dart';
import '../content/task_list.dart';

/// Host-guided setup with current content before the task list on phones.
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
              children: [
                const PaymentSpinner(),
                Flexible(child: Text(l.loading)),
              ],
            ),
          )
        : w.child;
    return LayoutBuilder(
      builder: (context, k) {
        final wide = k.maxWidth >= 840;

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
        );
        if (!wide) return frame;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 280,
              child: SingleChildScrollView(
                child: PaymentTaskList(items: w.tasks),
              ),
            ),
            VerticalDivider(width: 1, color: PaymentTheme.of(context).outline),
            Expanded(child: frame),
          ],
        );
      },
    );
  }
}
