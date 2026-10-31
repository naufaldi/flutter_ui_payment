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

  /// Title supplied by the host.
  final String title;

  /// Tasks supplied by the host.
  final List<PaymentTaskListItem> tasks;

  /// Child supplied by the host.
  final Widget child;

  /// Description supplied by the host.
  final String? description;

  /// Pending supplied by the host.
  final bool pending;

  /// Error supplied by the host.
  final PaymentBanner? error;

  /// Completed supplied by the host.
  final bool completed;

  /// Oncompleted supplied by the host.
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

    /// L=paymentlocalizations.of(context) supplied by the host.
    final l = PaymentLocalizations.of(context);

    /// Current=w.tasks.indexwhere((t)=>t.status!=paymenttaskstatus.complete) supplied by the host.
    final current = w.tasks.indexWhere(
      (t) => t.status != PaymentTaskStatus.complete,
    );

    /// Paymentspinner(),flexible(child:text(l.loading))])):w.child supplied by the host.
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

        /// Frame=viewframe(header:viewheader(title:w.title,description:w.description,below:wide||current<0?null:text(l.stepof(current+1,w.tasks.length,w.tasks[current].title))),body:column(crossaxisalignment:crossaxisalignment.stretch,children:[if(w.error!=null)w.error!,content,if(!wide)paymentaccordionitem(title:l.allsteps,child:paymenttasklist(items:w.tasks))])) supplied by the host.
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
