import 'package:flutter/material.dart';
import '../foundation/primitives.dart';
import '../foundation/payment_icons.dart';
import '../foundation/payment_theme.dart';
import '../foundation/payment_type.dart';
import '../foundation/payment_localizations.dart';
import '../foundation/kit_strings.dart';
import '../foundation/view_frame.dart';
import '../controls/button_group.dart';
import '../controls/actions.dart';
import '../layout/content.dart';
import '../overlay/sheets.dart';

/// Supplemental explanation presented separately in a focus view.
@immutable
class PaymentSignInLearnMore {
  const PaymentSignInLearnMore({
    required this.label,
    required this.title,
    required this.builder,
  });

  /// Label supplied by the host.
  final String label;

  /// Title supplied by the host.
  final String title;

  /// Builder supplied by the host.
  final WidgetBuilder builder;
}

/// External sign-in entry point with no credential input or free content slot.
class PaymentSignInView extends StatefulWidget {
  const PaymentSignInView({
    super.key,
    required this.primaryAction,
    this.title,
    this.description,
    this.brand,
    this.learnMore,
    this.secondaryAction,
    this.legalLinks = const [],
    this.footnote,
    this.errorText,
  });

  /// Primaryaction supplied by the host.
  final PaymentButton primaryAction;

  /// Title supplied by the host.
  final String? title;

  /// Description supplied by the host.
  final String? description;

  /// Brand supplied by the host.
  final Widget? brand;

  /// Learnmore supplied by the host.
  final PaymentSignInLearnMore? learnMore;

  /// Secondaryaction supplied by the host.
  final PaymentButton? secondaryAction;

  /// Legallinks supplied by the host.
  final List<PaymentLink> legalLinks;

  /// Footnote supplied by the host.
  final String? footnote;

  /// Errortext supplied by the host.
  final String? errorText;
  @override
  State<PaymentSignInView> createState() => _PaymentSignInViewState();
}

class _PaymentSignInViewState extends State<PaymentSignInView> {
  /// _errorfocus=focusnode() supplied by the host.
  final _errorFocus = FocusNode();
  void focusError() {
    if (widget.errorText != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _errorFocus.requestFocus();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    focusError();
  }

  @override
  void didUpdateWidget(covariant PaymentSignInView old) {
    super.didUpdateWidget(old);
    if (old.errorText != widget.errorText) focusError();
  }

  @override
  void dispose() {
    _errorFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;

    /// Type=paymenttype.of(context) supplied by the host.
    final type = PaymentType.of(context);

    /// L=paymentlocalizations.of(context) supplied by the host.
    final l = PaymentLocalizations.of(context);
    assert(
      w.brand == null || w.brand is PaymentImage || w.brand is PaymentIcon,
    );
    assert(
      w.secondaryAction?.variant != PaymentButtonVariant.primary &&
          w.secondaryAction?.variant != PaymentButtonVariant.destructive,
    );
    return ViewFrame(
      header: const SizedBox.shrink(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: PaymentTheme.of(context).spacing * 2,
            children: [
              if (w.brand != null)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: SizedBox.square(dimension: 48, child: w.brand),
                ),
              Semantics(
                header: true,
                child: Text(w.title ?? l.signInTitle, style: type.title),
              ),
              if (w.description != null)
                Text(w.description!, style: type.bodyFor(context)),
              if (w.learnMore != null)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: PaymentLink(
                    label: w.learnMore!.label,
                    onPressed: () => showPaymentFocusView<void>(
                      context,
                      builder: (_) => PaymentFocusView(
                        title: w.learnMore!.title,
                        child: Builder(builder: w.learnMore!.builder),
                      ),
                    ),
                  ),
                ),
              if (w.errorText != null)
                Focus(
                  focusNode: _errorFocus,
                  child: PaymentBanner(
                    tone: StatusTone.danger,
                    title: w.errorText!,
                    announce: true,
                  ),
                ),
              PaymentButtonGroup(
                direction: Axis.vertical,
                children: [w.primaryAction, ?w.secondaryAction],
              ),
              if (w.legalLinks.isNotEmpty)
                Wrap(
                  spacing: PaymentTheme.of(context).spacing * 2,
                  children: w.legalLinks,
                ),
              if (w.footnote != null) Text(w.footnote!, style: type.caption),
            ],
          ),
        ),
      ),
    );
  }
}
