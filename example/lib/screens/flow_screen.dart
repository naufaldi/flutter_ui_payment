import 'steps/transaction_detail_step.dart';
import 'steps/statement_step.dart';
import 'steps/fees_step.dart';
import 'steps/account_settings_step.dart';
export 'steps/kyc_fields.dart';
import 'steps/kyc_onboarding_step.dart';
import 'steps/sign_in_step.dart';
import 'steps/history_step.dart';
import 'steps/order_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';

import '../coordinator/demo_coordinator.dart';
import '../demo_strings.dart';
import '../dev_chrome.dart';

/// The demo purchase flow. Renders [DemoCoordinator] state step by step and
/// forwards every user intent to it; no business state lives here.
///
/// Hierarchical steps are routes on a nested [Navigator], so the iOS
/// edge swipe and Android predictive back pop them; the payment steps from
/// confirm on share one guarded route and switch in place (D93).
class FlowScreen extends StatefulWidget {
  const FlowScreen({
    super.key,
    required this.coordinator,
    required this.scenarioLabel,
    required this.onRestart,
    required this.onBackground,
    required this.onOpenSettings,
    this.active = true,
  });

  final DemoCoordinator coordinator;
  final String scenarioLabel;
  final VoidCallback onRestart;
  final VoidCallback onBackground;

  /// Opens the settings sheet with a "Demo tools" entry, so the app bar keeps
  /// at most two trailing actions and step titles fit (P7a).
  final void Function(VoidCallback demoTools) onOpenSettings;

  /// False while another tab is shown: system back and back gestures then
  /// leave this flow alone.
  final bool active;

  @override
  State<FlowScreen> createState() => _FlowScreenState();
}

/// The steps that stay in place on one route, with back guarded (D93).
bool _onPaymentRoute(FlowStep step) => switch (step) {
  FlowStep.confirm ||
  FlowStep.authorize ||
  FlowStep.payment ||
  FlowStep.receipt => true,
  _ => false,
};

String _routeKey(FlowStep step) =>
    _onPaymentRoute(step) ? 'flow-route-payment' : 'flow-route-${step.name}';

class _FlowScreenState extends State<FlowScreen> with WidgetsBindingObserver {
  final _navigator = GlobalKey<NavigatorState>();

  /// Route keys of the stack last handed to the navigator.
  Set<String> _keys = const {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  // Reduced motion on iOS arrives as a platform feature, not a MediaQuery
  // change, so the routes rebuild to read it.
  @override
  void didChangeAccessibilityFeatures() => setState(() {});

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// A route left the navigator. When the coordinator still shows it, the
  /// person popped it (back button, edge swipe or predictive back), so the
  /// coordinator takes the same back action. Otherwise the coordinator moved
  /// on first and the navigator only caught up.
  void _didRemovePage(Page<Object?> page) {
    if (page is! _FlowPage || !_keys.contains(_routeKey(page.step))) return;
    if (_onPaymentRoute(page.step)) return;
    _handleBack(context, widget.coordinator, page.step);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.coordinator,
      builder: (context, _) {
        final c = widget.coordinator;
        final stack = c.routeStack;
        _keys = {for (final step in stack) _routeKey(step)};
        return NavigatorPopHandler<Object?>(
          enabled: widget.active,
          onPopWithResult: (_) => _navigator.currentState?.maybePop(),
          child: Navigator(
            key: _navigator,
            onDidRemovePage: _didRemovePage,
            pages: [
              for (final step in stack)
                _FlowPage(
                  key: ValueKey(_routeKey(step)),
                  step: step,
                  active: widget.active,
                  child: _FlowStepPage(
                    coordinator: c,
                    step: step,
                    root: step == stack.first,
                    scenarioLabel: widget.scenarioLabel,
                    onRestart: widget.onRestart,
                    onBackground: widget.onBackground,
                    onOpenSettings: widget.onOpenSettings,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// One route of the flow. The page keeps the last child it was given, so a
/// route that is leaving keeps showing its own step.
class _FlowPage extends Page<void> {
  const _FlowPage({
    required LocalKey super.key,
    required this.step,
    required this.active,
    required this.child,
  });

  final FlowStep step;
  final bool active;
  final Widget child;

  @override
  Route<void> createRoute(BuildContext context) => _FlowRoute(this);
}

/// The platform page transition (Cupertino on iOS, predictive back on
/// Android), with no motion when reduced motion is on (B9, D66). A swipe
/// still follows the finger: it is direct manipulation, not animation.
class _FlowRoute extends PageRoute<void>
    with MaterialRouteTransitionMixin<void> {
  _FlowRoute(_FlowPage page) : super(settings: page);

  _FlowPage get _page => settings as _FlowPage;

  bool get _reduced => PaymentMotion.of(navigator!.context).reduced;

  @override
  Widget buildContent(BuildContext context) => _page.child;

  @override
  bool get maintainState => true;

  @override
  bool get popGestureEnabled => _page.active && super.popGestureEnabled;

  @override
  Duration get transitionDuration =>
      _reduced ? Duration.zero : super.transitionDuration;

  @override
  Duration get reverseTransitionDuration =>
      _reduced ? Duration.zero : super.reverseTransitionDuration;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Reduced motion turned on mid-transition: finish it next frame.
    final controller = this.controller;
    if (PaymentMotion.of(context).reduced &&
        controller != null &&
        controller.isAnimating &&
        !popGestureInProgress) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!controller.isAnimating) return;
        controller.value = controller.status == AnimationStatus.reverse ? 0 : 1;
      });
    }
    return super.buildTransitions(
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }

  @override
  String get debugLabel => '${super.debugLabel}(${_page.step.name})';
}

/// The screen for one route: its app bar, body and pinned action.
class _FlowStepPage extends StatelessWidget {
  const _FlowStepPage({
    required this.coordinator,
    required this.step,
    required this.root,
    required this.scenarioLabel,
    required this.onRestart,
    required this.onBackground,
    required this.onOpenSettings,
  });

  final DemoCoordinator coordinator;

  /// The step this route shows. The payment route follows the coordinator
  /// while it is on top.
  final FlowStep step;
  final bool root;
  final String scenarioLabel;
  final VoidCallback onRestart;
  final VoidCallback onBackground;
  final void Function(VoidCallback demoTools) onOpenSettings;

  @override
  Widget build(BuildContext context) {
    // The column is measured from the width this screen gets, not the
    // window: from 840 dp the app's side rail takes part of the window
    // (#84). Side safe-area insets come off it too, since the list, the
    // checkout bar and the app bar each sit inside them (#88). The list,
    // the bar and the title fit share this one width (#87).
    return LayoutBuilder(
      builder: (context, k) {
        final side = MediaQuery.paddingOf(context);
        return _build(context, k.maxWidth - side.left - side.right);
      },
    );
  }

  /// [width] is the screen's width inside the side safe-area insets.
  Widget _build(BuildContext context, double width) {
    final c = coordinator;
    final s = DemoStrings.of(context);
    final view = _isViewStep(step) && !c.starting;
    final title = _ownHeader(c, step) ? null : _title(s, step);
    final titleLines = title == null
        ? 1
        : _appBarTitleLines(
            context,
            title,
            room: appBarTitleRoom(
              width,
              leading: !root,
              actions: c.signedIn ? 2 : 1,
            ),
          );
    final content = view
        ? SizedBox.expand(
            key: ValueKey('flow-view-${step.name}'),
            child: _StepBody(coordinator: c, step: step),
          )
        : ListView(
            key: ValueKey('flow-list-${step.name}'),
            // At 600 dp and wider the steps sit in a centred
            // 640 dp column; the scrollbar stays at the
            // window edge (D53).
            // The order context adds its own group gutter. Extend
            // only the two-column end so its text meets the bar (#146).
            padding: EdgeInsetsDirectional.fromSTEB(
              16 + listInset(width, step),
              8,
              16 +
                  listInset(width, step) -
                  (step == FlowStep.checkout &&
                          !c.starting &&
                          _checkoutTwoColumns(width - 32)
                      ? PaymentTheme.of(context).space(PaymentSpace.group)
                      : 0),
              24,
            ),
            children: [
              if (c.starting)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(child: Text(s.loading)),
                )
              else
                _StepBody(coordinator: c, step: step),
            ],
          );
    final scaffold = Scaffold(
      appBar: AppBar(
        // A title that doesn't fit on one line wraps to two in a
        // taller bar instead of ending in "…" (#80).
        toolbarHeight: titleLines == 1
            ? null
            : kToolbarHeight + _appBarTitleLine(context),
        automaticallyImplyLeading: false,
        // Hierarchical routes pop like any route; the payment route's
        // guard below decides what back does there.
        leading: root ? null : const BackButton(),
        title: title == null
            ? null
            : Text(title, maxLines: titleLines, softWrap: true),
        actions: [
          if (c.signedIn) _AccountMenu(coordinator: c),
          IconButton(
            key: const Key('settings'),
            tooltip: s.settings,
            icon: const Icon(Icons.tune),
            onPressed: () => onOpenSettings(
              () => _showDemoTools(
                context,
                coordinator: c,
                scenarioLabel: scenarioLabel,
                onRestart: onRestart,
                onBackground: onBackground,
              ),
            ),
          ),
        ],
      ),
      // Checkout pins its action under the list; the other payment
      // steps pin theirs inside the step (D62).
      bottomNavigationBar:
          step == FlowStep.checkout && !c.starting && !c.obscured
          ? _CheckoutBar(c, maxContentWidth: contentCap(width, step))
          : null,
      // A view step's pinned footer pads the bottom inset itself.
      body: SafeArea(
        bottom: !view,
        child: PrivacyMask(
          obscured: c.obscured,
          child: _onPaymentRoute(step)
              ? _FlowStepSwitcher(step: step, child: content)
              : content,
        ),
      ),
    );
    if (!_onPaymentRoute(step)) return scaffold;
    // Payment steps keep back guarded: no swipe, and back is ignored while
    // authorizing and confirmed before leaving an unresolved payment.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack(context, c, step);
      },
      child: scaffold,
    );
  }
}

String _title(DemoStrings s, FlowStep step) => switch (step) {
  FlowStep.overview => s.appName,
  FlowStep.signIn => s.appName,
  FlowStep.history => s.transactions,
  FlowStep.transactionDetail ||
  FlowStep.statement ||
  FlowStep.fees ||
  FlowStep.accountSettings => s.yourAccount,
  FlowStep.kycIntro => s.stepConsent,
  FlowStep.kycIdentity => s.stepIdentity,
  FlowStep.kycDocuments => s.stepDocuments,
  FlowStep.kycReview => s.stepReview,
  FlowStep.kycStatus => s.stepStatus,
  FlowStep.checkout => s.stepCheckout,
  FlowStep.confirm => s.stepConfirm,
  FlowStep.authorize => s.stepAuthorize,
  FlowStep.payment => s.stepPayment,
  FlowStep.receipt => s.stepReceipt,
};

/// Back from [step]. A hierarchical step's target must be its parent in
/// [DemoCoordinator.routeStack], since its route has already popped.
Future<void> _handleBack(
  BuildContext context,
  DemoCoordinator c,
  FlowStep step,
) async {
  switch (step) {
    case FlowStep.signIn:
    case FlowStep.overview:
      return;
    case FlowStep.transactionDetail:
      c.closeDetail();
    case FlowStep.history ||
        FlowStep.statement ||
        FlowStep.fees ||
        FlowStep.accountSettings:
      c.goHome();
    case FlowStep.kycIntro || FlowStep.kycStatus || FlowStep.checkout:
      c.goHome();
    case FlowStep.kycIdentity:
      c.kyc.status == VerificationStatus.actionRequired
          ? c.kycAction(VerificationAction.start)
          : c.goHome();
    case FlowStep.kycDocuments:
      c.editIdentity();
    case FlowStep.kycReview:
      c.editDocuments();
    case FlowStep.confirm:
      await c.openCheckout();
    case FlowStep.authorize:
      if (c.authPhase != AuthorizationPhase.inProgress) c.backToReview();
    case FlowStep.receipt:
      c.resumeAttempt();
    case FlowStep.payment:
      if (!c.hasUnresolvedAttempt) {
        c.finish();
        return;
      }
      final s = DemoStrings.of(context);
      final leave = await showPaymentConfirmDialog(
        context,
        title: s.leaveTitle,
        message: s.leaveMessage,
        confirmLabel: s.leave,
        cancelLabel: s.stay,
        destructive: false,
      );
      if (leave) c.goHome();
  }
}

/// Switches the payment steps in place on their one route (D71, D93).
class _FlowStepSwitcher extends StatefulWidget {
  const _FlowStepSwitcher({required this.step, required this.child});
  final FlowStep step;
  final Widget child;
  @override
  State<_FlowStepSwitcher> createState() => _FlowStepSwitcherState();
}

class _StepEntry {
  _StepEntry(this.child, this.controller, {required this.back});
  Widget child;
  final AnimationController controller;
  bool back;

  /// The rise an interrupted entry had reached, held while it fades out.
  double heldRise = 0;
  late final Key key = ObjectKey(this);
}

/// PaymentMotion.fadeRise starts a forward step this far below rest.
const double _stepRise = 8;

class _FlowStepSwitcherState extends State<_FlowStepSwitcher>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final List<FlowStep> _path = [widget.step];
  late _StepEntry _current = _StepEntry(
    widget.child,
    AnimationController(vsync: this, value: 1),
    back: false,
  );
  final _leaving = <_StepEntry>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAccessibilityFeatures() => setState(() {});

  /// A visited step or a parent return goes back; anything else forward.
  bool _goingBack(FlowStep previous) {
    if (widget.step == previous) return false;
    final i = _path.lastIndexOf(widget.step);
    // Mirrors the payment parent returns in _handleBack.
    final parentReturn = switch ((previous, widget.step)) {
      (FlowStep.authorize, FlowStep.confirm) ||
      (FlowStep.receipt, FlowStep.payment) => true,
      _ => false,
    };
    if (i >= 0) {
      _path.removeRange(i + 1, _path.length);
    } else if (parentReturn) {
      _path
        ..removeLast()
        ..add(widget.step);
    } else {
      _path.add(widget.step);
    }
    return i >= 0 || parentReturn;
  }

  @override
  void didUpdateWidget(_FlowStepSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.step == oldWidget.step &&
        Widget.canUpdate(widget.child, _current.child)) {
      _current.child = widget.child;
      return;
    }
    final back = _goingBack(oldWidget.step);
    final motion = PaymentMotion.of(context);
    final leaving = _current;
    // Only the incoming forward step rises; outgoing content fades in place.
    // A step interrupted mid-rise holds its current offset instead of
    // snapping to rest (#129).
    if (!leaving.back) {
      leaving.heldRise =
          _stepRise *
          (1 - PaymentMotion.easeOut.transform(leaving.controller.value));
    }
    leaving.back = true;
    _current = _StepEntry(
      widget.child,
      AnimationController(vsync: this, duration: motion.enter),
      back: back,
    );
    _leaving.add(leaving);
    // A synchronous dismissed callback must not setState during build.
    if (motion.reduced) {
      _finish();
      return;
    }
    _current.controller.forward();
    leaving.controller
      ..reverseDuration = motion.exit
      ..addStatusListener((status) {
        if (status.isDismissed && mounted) {
          setState(() => _leaving.remove(leaving));
          leaving.controller.dispose();
        }
      })
      ..reverse();
  }

  void _finish() {
    for (final entry in _leaving) {
      entry.controller.dispose();
    }
    _leaving.clear();
    _current.controller.value = 1;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final entry in [_current, ..._leaving]) {
      entry.controller.dispose();
    }
    super.dispose();
  }

  // The outer translate is always present, so a step keeps its state when it
  // moves from current to leaving.
  Widget _transition(_StepEntry entry) => KeyedSubtree(
    key: entry.key,
    child: Transform.translate(
      offset: Offset(0, entry.heldRise),
      child: PaymentMotion.fadeRise(
        entry.child,
        entry.controller,
        back: entry.back,
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    if (PaymentMotion.of(context).reduced) _finish();
    return PaymentMotion.topLayout(_transition(_current), [
      for (final entry in _leaving) _transition(entry),
    ]);
  }
}

class _AccountMenu extends StatelessWidget {
  const _AccountMenu({required this.coordinator});

  final DemoCoordinator coordinator;

  @override
  Widget build(BuildContext context) {
    final s = DemoStrings.of(context);
    return PopupMenuButton<String>(
      key: const Key('account-menu'),
      tooltip: s.switchAccount,
      // Demo control for switching the signed-in test account: a plain
      // outlined initial, not a tinted avatar that implies a real profile.
      icon: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: PaymentTheme.of(context).outline),
        ),
        child: Text(
          coordinator.account,
          semanticsLabel: s.account(coordinator.account),
          // Developer chrome: capped near the AppBar title's own limit so
          // the initial never outgrows its circle.
          textScaler: MediaQuery.textScalerOf(
            context,
          ).clamp(maxScaleFactor: 1.3),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: PaymentTheme.of(context).textPrimary,
          ),
        ),
      ),
      onSelected: coordinator.switchAccount,
      itemBuilder: (context) => [
        for (final id in const ['A', 'B'])
          CheckedPopupMenuItem(
            key: Key('account-$id'),
            value: id,
            checked: coordinator.account == id,
            child: Text(s.account(id)),
          ),
      ],
    );
  }
}

class _StepBody extends StatelessWidget {
  const _StepBody({required this.coordinator, required this.step});

  final DemoCoordinator coordinator;
  final FlowStep step;

  @override
  Widget build(BuildContext context) {
    final c = coordinator;
    return switch (step) {
      FlowStep.overview => _Overview(c),
      FlowStep.signIn => SignInStep(c),
      FlowStep.history => HistoryStep(c),
      FlowStep.transactionDetail => TransactionDetailStep(c),
      FlowStep.statement => StatementStep(c),
      FlowStep.fees => FeesStep(c),
      FlowStep.accountSettings => AccountSettingsStep(c),
      FlowStep.kycIntro => _KycIntro(c),
      FlowStep.kycIdentity ||
      FlowStep.kycDocuments ||
      FlowStep.kycReview => KycOnboardingStep(c, step: step),
      FlowStep.kycStatus => VerificationStatusView(
        header: _supportNotice(context, c),
        snapshot: c.kyc,
        outcomeUnknown: c.kycOutcomeUnknown,
        busyAction: c.kycBusyAction,
        onAction: c.kycAction,
      ),
      FlowStep.checkout => _Checkout(c),
      FlowStep.confirm => _Confirm(c),
      FlowStep.authorize => _Authorize(c),
      FlowStep.payment => _Payment(c),
      FlowStep.receipt => _Receipt(c),
    };
  }
}

class _Overview extends StatelessWidget {
  const _Overview(this.c);
  final DemoCoordinator c;

  @override
  Widget build(BuildContext context) {
    final s = DemoStrings.of(context);
    final l10n = PaymentLocalizations.of(context);
    final theme = PaymentTheme.of(context);
    final text = Theme.of(context).textTheme;
    final flexible = c.config.flexibleAmount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PaymentBanner(
          tone: StatusTone.info,
          icon: Icons.science_outlined,
          title: s.simulated,
        ),
        const SizedBox(height: 16),
        if (c.hasUnresolvedAttempt || c.attempt != null) ...[
          PaymentBanner(
            tone: StatusTone.warning,
            icon: Icons.receipt_long_outlined,
            title: s.unresolvedTitle,
            message: s.unresolvedMessage,
            actions: [
              PaymentButton(
                onPressed: c.resumeAttempt,
                label: s.openPayment,
                variant: PaymentButtonVariant.secondary,
                width: PaymentWidth.hug,
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        PaymentSection(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product thumbnail: a plain muted tile. The demo has no product
              // photography, and a gradient would only decorate the gap.
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.surfaceMuted,
                  borderRadius: BorderRadius.circular(theme.radius * 0.75),
                ),
                child: Icon(
                  flexible ? Icons.savings_outlined : Icons.school_outlined,
                  size: 24,
                  color: theme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                flexible ? s.topUpTitle : s.productTitle,
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                s.productSubtitle,
                style: text.bodyMedium?.copyWith(color: theme.textSecondary),
              ),
              if (!flexible) ...[
                const SizedBox(height: 12),
                const AmountText(
                  Money.idr(100000),
                  variant: AmountTextVariant.display,
                ),
              ],
              const SizedBox(height: 8),
              InfoRow(
                label: s.identityStatus,
                value: c.config.kycRequired
                    ? PaymentBadge(
                        tone: c.kyc.status == VerificationStatus.verified
                            ? StatusTone.success
                            : StatusTone.neutral,
                        icon: c.kyc.status == VerificationStatus.verified
                            ? Icons.verified_outlined
                            : Icons.badge_outlined,
                        label: l10n.kycStatusTitle(c.kyc.status),
                      )
                    : Text(s.kycNotRequired, textAlign: TextAlign.end),
              ),
              const SizedBox(height: 12),
              PaymentButton(
                key: const Key('buy'),
                label: flexible ? s.topUpNow : s.buyNow,
                onPressed: c.beginPurchase,
              ),
            ],
          ),
        ),
        PaymentSection(
          title: s.yourAccount,
          child: PaymentList(
            children: [
              PaymentListItem(
                icon: Icons.receipt_long_outlined,
                title: s.transactions,
                onPressed: c.openHistory,
              ),
              PaymentListItem(
                icon: Icons.description_outlined,
                title: s.statement,
                onPressed: c.openStatement,
              ),
              PaymentListItem(
                icon: Icons.sell_outlined,
                title: s.fees,
                onPressed: c.openFees,
              ),
              PaymentListItem(
                icon: Icons.settings_outlined,
                title: s.accountSettings,
                onPressed: c.openAccountSettings,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KycIntro extends StatelessWidget {
  const _KycIntro(this.c);
  final DemoCoordinator c;

  @override
  Widget build(BuildContext context) {
    final s = DemoStrings.of(context);
    return VerificationIntro(
      requirements: [
        DataRequirement(
          title: s.reqIdentityTitle,
          purpose: s.reqIdentityPurpose,
        ),
        DataRequirement(title: s.reqIdTitle, purpose: s.reqIdPurpose),
        DataRequirement(title: s.reqSelfieTitle, purpose: s.reqSelfiePurpose),
      ],
      onOpenPolicy: () => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.policyOpened))),
      onContinue: c.acceptConsent,
    );
  }
}

class _Checkout extends StatelessWidget {
  const _Checkout(this.c);
  final DemoCoordinator c;

  @override
  Widget build(BuildContext context) {
    final s = DemoStrings.of(context);
    final quote = c.quote;
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (c.config.flexibleAmount) ...[
          PaymentSection(
            title: s.topUpTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PaymentCurrencyField(
                  key: const Key('amount'),
                  currency: 'IDR',
                  minimum: const Money.idr(10000),
                  maximum: const Money.idr(2000000),
                  onChanged: c.setAmount,
                ),
                const SizedBox(height: 12),
                PaymentButton(
                  key: const Key('get-quote'),
                  label: s.getQuote,
                  variant: PaymentButtonVariant.secondary,
                  busy: c.quoting,
                  onPressed: c.amount.isValid && c.selectedMethod != null
                      ? c.loadQuote
                      : null,
                ),
              ],
            ),
          ),
        ],
        if (c.quoteError != null) ...[
          PaymentBanner(
            tone: StatusTone.danger,
            announce: true,
            title: s.quoteFailedTitle,
            message: c.quoteError!.safeMessage,
            actions: [
              PaymentButton(
                key: const Key('retry-quote'),
                onPressed: c.quoting ? null : c.loadQuote,
                label: s.retry,
                variant: PaymentButtonVariant.secondary,
                width: PaymentWidth.hug,
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        // While a re-quote runs, the pinned button says "Updating total…"
        // and is busy; the summary is not dimmed, which would need
        // an offscreen layer over the whole card on every method switch.
        if (quote != null)
          PaymentSummary(quote: quote)
        else if (c.quoting)
          const PaymentSection(child: LoadingSkeleton(rows: 3, leading: false)),
        // Sections stack flush: their own padding gives the 24 dp gap.
        PaymentMethodPicker(
          methods: c.methods,
          selectedId: c.selectedMethodId,
          onChanged: c.selectMethod,
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, k) => !_checkoutTwoColumns(k.maxWidth)
          ? body
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: PaymentTheme.of(context).space(PaymentSpace.section),
              children: [
                Expanded(child: body),
                SizedBox(width: 360, child: OrderContext(c)),
              ],
            ),
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar(this.c, {required this.maxContentWidth});
  final DemoCoordinator c;

  /// The content's column cap, so the action ends where the content does.
  final double maxContentWidth;

  @override
  Widget build(BuildContext context) {
    final s = DemoStrings.of(context);
    final quote = c.quote;
    // The summary already shows the total twice, so the bar holds only the
    // action: compact at 200% text on a small phone (#64, #58).
    return PaymentActionBar(
      maxContentWidth: maxContentWidth,
      action: PaymentButton(
        key: const Key('review-order'),
        label: s.reviewAndPay,
        busy: c.quoting,
        busyLabel: PaymentLocalizations.of(context).updatingTotal,
        onPressed: quote != null && c.selectedMethod != null && !c.quoting
            ? c.reviewOrder
            : null,
      ),
    );
  }
}

class _Confirm extends StatelessWidget {
  const _Confirm(this.c);
  final DemoCoordinator c;

  @override
  Widget build(BuildContext context) {
    final s = DemoStrings.of(context);
    final error = c.submitError;
    return PaymentConfirmation(
      header: error == null
          ? null
          : PaymentBanner(
              tone: StatusTone.warning,
              announce: true,
              icon: Icons.lock_clock_outlined,
              title: error.category == HostErrorCategory.sessionExpired
                  ? s.sessionExpiredTitle
                  : s.quoteFailedTitle,
              message: error.safeMessage,
            ),
      quote: c.quote!,
      method: c.selectedMethod!,
      previousQuote: c.previousQuote,
      busy: c.confirming,
      footnote: s.confirmFootnote,
      onConfirm: c.confirm,
    );
  }
}

class _Authorize extends StatelessWidget {
  const _Authorize(this.c);
  final DemoCoordinator c;

  @override
  Widget build(BuildContext context) {
    final l10n = PaymentLocalizations.of(context);
    final theme = PaymentTheme.of(context);
    return AuthorizationPrompt(
      phase: c.authPhase,
      onStart: c.authorize,
      onBackToReview: c.backToReview,
      header: PaymentSection(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The one display amount, left-aligned under a caption rather
            // than squeezed into the end of a row.
            Text(
              l10n.totalLabel,
              style: TextStyle(
                fontSize: 13,
                height: 18 / 13,
                letterSpacing: 0,
                color: theme.textSecondary,
              ),
            ),
            SizedBox(height: theme.spacing * 0.5),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: AmountText(
                c.quote!.total,
                variant: AmountTextVariant.display,
              ),
            ),
            InfoRow(
              label: l10n.payWithTitle,
              valueText: c.selectedMethod?.label ?? '',
            ),
          ],
        ),
      ),
    );
  }
}

class _Payment extends StatelessWidget {
  const _Payment(this.c);
  final DemoCoordinator c;

  @override
  Widget build(BuildContext context) {
    final s = DemoStrings.of(context);
    final attempt = c.attempt;
    if (attempt == null) return const SizedBox.shrink();
    final instructions = attempt.snapshot?.instructions;
    final status = attempt.status;
    final support = _supportNotice(context, c);
    final canceling = c.cancelRequested && !(status?.isTerminal ?? false);
    return PaymentStatusView(
      header: support == null && !canceling
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                ?support,
                if (canceling)
                  PaymentBanner(
                    tone: StatusTone.info,
                    announce: true,
                    title: s.cancelRequestedTitle,
                    message: s.cancelRequestedMessage,
                  ),
              ],
            ),
      attempt: attempt,
      amount: c.attemptAmount,
      busyAction: c.busyAction,
      onAction: c.paymentAction,
      instructions: instructions != null && c.showInstructions
          ? PaymentInstructions(
              instructions: instructions,
              clock: c.host.clock,
              onCopyNumber: c.copy,
              onElapsed: c.onInstructionsElapsed,
            )
          : null,
      secondaryAction: status != null && status.isTerminal
          ? PaymentButton(
              key: const Key('done'),
              label: s.done,
              variant: PaymentButtonVariant.quiet,
              onPressed: c.finish,
            )
          : null,
    );
  }
}

class _Receipt extends StatelessWidget {
  const _Receipt(this.c);
  final DemoCoordinator c;

  @override
  Widget build(BuildContext context) {
    final s = DemoStrings.of(context);
    final receipt = c.receipt;
    if (receipt != null) {
      // "Done" ends the purchase, so it is the one primary (#49-1); sharing
      // stays with the receipt as a hug button.
      return PaymentFullPageView(
        title: s.stepReceipt,
        primaryAction: PaymentButton(
          key: const Key('receipt-done'),
          label: s.done,
          onPressed: c.finish,
        ),
        secondaryAction: PaymentButton(
          key: const Key('receipt-details'),
          label: s.viewDetails,
          variant: PaymentButtonVariant.quiet,
          onPressed: c.openCurrentDetail,
        ),
        child: PaymentReceipt(
          data: receipt,
          onShare: c.share,
          onCopyTransactionId: c.copy,
        ),
      );
    }
    return PaymentStatusView(
      header: c.receiptError == null
          ? null
          : PaymentBanner(
              tone: StatusTone.warning,
              announce: true,
              title: s.receiptLoadFailedTitle,
              message: s.receiptLoadFailedMessage,
              actions: [
                PaymentButton(
                  key: const Key('retry-receipt'),
                  onPressed: c.loadingReceipt ? null : c.loadReceipt,
                  label: s.retry,
                  variant: PaymentButtonVariant.secondary,
                  width: PaymentWidth.hug,
                ),
              ],
            ),
      attempt: c.attempt!,
      amount: c.attemptAmount,
      busyAction: c.loadingReceipt ? PaymentAction.viewReceipt : null,
      onAction: c.paymentAction,
    );
  }
}

/// Contact support was opened (simulated): shown above the step's content.
Widget? _supportNotice(BuildContext context, DemoCoordinator c) =>
    c.notice != 'support'
    ? null
    : PaymentBanner(
        tone: StatusTone.info,
        title: DemoStrings.of(context).supportOpened,
        announce: true,
      );

/// Host tools in a sheet, opened from the settings sheet's "Demo tools", so
/// they never sit in the step's content or between the content and its
/// pinned action (D62).
Future<void> _showDemoTools(
  BuildContext context, {
  required DemoCoordinator coordinator,
  required String scenarioLabel,
  required VoidCallback onRestart,
  required VoidCallback onBackground,
}) => showModalBottomSheet<void>(
  context: context,
  // Over the whole window, not inside the flow's own navigator (D93).
  useRootNavigator: true,
  isScrollControlled: true,
  showDragHandle: true,
  backgroundColor: devWorkbench(context),
  builder: (sheet) => _HostTools(
    coordinator: coordinator,
    scenarioLabel: scenarioLabel,
    // Restart re-keys the flow, so the sheet closes first.
    onRestart: () {
      Navigator.pop(sheet);
      onRestart();
    },
    onBackground: () {
      Navigator.pop(sheet);
      onBackground();
    },
  ),
);

class _HostTools extends StatelessWidget {
  const _HostTools({
    required this.coordinator,
    required this.scenarioLabel,
    required this.onRestart,
    required this.onBackground,
  });

  final DemoCoordinator coordinator;
  final String scenarioLabel;
  final VoidCallback onRestart;
  final VoidCallback onBackground;

  @override
  Widget build(BuildContext context) {
    final s = DemoStrings.of(context);
    final theme = PaymentTheme.of(context);
    final host = coordinator.host;
    final scaler = devScaler(context);
    final mono = devMono(theme.textPrimary);
    // Gallery workbench voice, not product styling: a grey fill and mono
    // text, so the sheet never reads as part of the purchase.
    return SafeArea(
      child: ListenableBuilder(
        listenable: Listenable.merge([coordinator, host.log]),
        builder: (context, _) {
          final entries = host.log.value;
          return ListView(
            key: const Key('host-tools'),
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Semantics(
                header: true,
                child: Text(
                  s.hostTools,
                  style: devMono(theme.textSecondary),
                  textScaler: scaler,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${s.activeScenario(scenarioLabel)} · ${s.account(coordinator.account)}',
                style: mono,
                textScaler: scaler,
              ),
              const SizedBox(height: 8),
              Text(
                s.hostStats(
                  coordinator.submitEvents,
                  host.attemptCount,
                  host.chargeCount,
                ),
                key: const Key('host-stats'),
                style: mono,
                textScaler: scaler,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    key: const Key('host-restart'),
                    onPressed: onRestart,
                    icon: const Icon(Icons.restart_alt),
                    label: Text(s.simulateRestart),
                  ),
                  OutlinedButton.icon(
                    key: const Key('host-background'),
                    onPressed: onBackground,
                    icon: const Icon(Icons.flip_to_back),
                    label: Text(s.simulateBackground),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (entries.isEmpty)
                Text(s.hostLogEmpty, style: mono, textScaler: scaler)
              else
                for (final e in entries.reversed.take(30))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      '${e.at.toIso8601String().substring(11, 19)}  ${e.message}',
                      style: mono,
                      textScaler: scaler,
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}

/// Widest content column for [step] in a flow screen [width] wide inside
/// its side safe-area insets (D53):
/// 640 dp, or 1040 dp for checkout's two columns from 840 dp of content
/// (Q1). The checkout bar takes the same cap, so its action ends where the
/// content does (#84).
double contentCap(double width, FlowStep step) =>
    step == FlowStep.checkout && _checkoutTwoColumns(width - 32) ? 1040 : 640;

// Takes available content width after the flow's outer gutters.
bool _checkoutTwoColumns(double width) => width >= 840;

/// Side inset that centres the content column in the flow screen [width]
/// wide inside its side safe-area insets, added to the 16 dp gutter (D53).
double listInset(double width, FlowStep step) {
  final content = width - 32;
  if (content < 600 - 32) return 0;
  return ((content - contentCap(width, step)) / 2).clamp(0, double.infinity);
}

/// AppBar caps its title at 1.34x text (Material's limit), on one line.
TextScaler _appBarTitleScaler(BuildContext context) =>
    MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.34);

/// One line of the app bar title at the current text size.
double _appBarTitleLine(BuildContext context) {
  final style = Theme.of(context).appBarTheme.titleTextStyle!;
  return _appBarTitleScaler(context).scale(style.fontSize!) * style.height!;
}

/// The width the app bar gives its title in a flow screen whose content is
/// [width] wide inside the side safe-area insets (the bar's own `SafeArea`
/// takes them): less the back button and [actions] 48 dp buttons, and the
/// two 16 dp title gaps. Beside the side rail [width] is already the
/// screen's, not the window's (#87).
double appBarTitleRoom(
  double width, {
  required bool leading,
  required int actions,
}) =>
    width -
    (leading ? kToolbarHeight : 0) -
    actions * kMinInteractiveDimension -
    NavigationToolbar.kMiddleSpacing * 2;

/// 1 when [title] fits on one line in [room], else 2. Breaks fall between
/// words; step titles are two words at most.
int _appBarTitleLines(
  BuildContext context,
  String title, {
  required double room,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: title,
      style: Theme.of(context).appBarTheme.titleTextStyle,
    ),
    textScaler: _appBarTitleScaler(context),
    textDirection: Directionality.of(context),
    maxLines: 1,
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width <= room ? 1 : 2;
}

/// Steps that fill the screen and pin their own footer (D62).
bool _isViewStep(FlowStep step) => switch (step) {
  FlowStep.signIn ||
  FlowStep.kycIntro ||
  FlowStep.kycIdentity ||
  FlowStep.kycDocuments ||
  FlowStep.kycReview ||
  FlowStep.kycStatus ||
  FlowStep.confirm ||
  FlowStep.authorize ||
  FlowStep.payment ||
  FlowStep.receipt ||
  FlowStep.history ||
  FlowStep.transactionDetail ||
  FlowStep.statement ||
  FlowStep.fees ||
  FlowStep.accountSettings => true,
  _ => false,
};

/// Steps whose page header carries the title, so the app bar has none.
bool _ownHeader(DemoCoordinator c, FlowStep step) => switch (step) {
  FlowStep.signIn ||
  FlowStep.kycIdentity ||
  FlowStep.kycDocuments ||
  FlowStep.kycReview ||
  FlowStep.history ||
  FlowStep.transactionDetail ||
  FlowStep.statement ||
  FlowStep.fees ||
  FlowStep.accountSettings => true,
  FlowStep.receipt => c.receipt != null,
  _ => false,
};

/// The payment flow, from KYC through the receipt: the app's tab bar is
/// hidden here so nothing competes with the pinned action (D62).
bool inPaymentFlow(FlowStep step) => switch (step) {
  FlowStep.kycIntro ||
  FlowStep.kycIdentity ||
  FlowStep.kycDocuments ||
  FlowStep.kycReview ||
  FlowStep.kycStatus ||
  FlowStep.checkout ||
  FlowStep.confirm ||
  FlowStep.authorize ||
  FlowStep.payment ||
  FlowStep.receipt => true,
  _ => false,
};

/// D84 extends D62 to pushed details; D93 keeps it for the flow's routes.
bool hidesTabBar(FlowStep step) =>
    inPaymentFlow(step) ||
    switch (step) {
      FlowStep.transactionDetail ||
      FlowStep.statement ||
      FlowStep.fees ||
      FlowStep.accountSettings => true,
      _ => false,
    };
