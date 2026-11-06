import 'package:flutter/material.dart';
import '../foundation/button_copy.dart';
import '../foundation/primitives.dart';
import '../foundation/payment_icons.dart';
import '../foundation/payment_theme.dart';
import '../foundation/payment_type.dart';
import '../foundation/payment_tokens.dart';
import '../foundation/payment_localizations.dart';
import '../foundation/view_frame.dart';

/// Grouped host settings with a future-locked Save action.
class PaymentSettingsView extends StatelessWidget {
  const PaymentSettingsView({
    super.key,
    required this.title,
    required this.child,
    this.onSave,
    this.saveLabel,
    this.saveDisabledReason,
    this.statusMessage,
    this.statusTone = StatusTone.neutral,
  });

  /// Heading displayed above the content.
  final String title;

  /// Body content owned by the host.
  final Widget child;

  /// Saves settings; repeated activation waits for completion.
  final Future<void> Function()? onSave;

  /// Save button label; defaults to the localized Save.
  final String? saveLabel;

  /// Keeps Save visible and disabled with this explanation when [onSave] is null.
  /// Ignored when [onSave] is provided. With both null, Save is hidden.
  final String? saveDisabledReason;

  /// Result of the most recent save.
  final String? statusMessage;

  /// Semantic tone of the save result.
  final StatusTone statusTone;
  @override
  Widget build(BuildContext context) {
    final l = PaymentLocalizations.of(context);
    return ViewFrame(
      header: ViewHeader(
        title: title,
        below: statusMessage == null
            ? null
            : Semantics(
                liveRegion: true,
                child: Row(
                  spacing: PaymentTheme.of(context).space(PaymentSpace.inline),
                  children: [
                    PaymentIcon.tone(statusTone),
                    Flexible(
                      child: Text(
                        statusMessage!,
                        style: PaymentType.of(context).caption,
                      ),
                    ),
                  ],
                ),
              ),
      ),
      body: child,
      footer: onSave == null && saveDisabledReason == null
          ? null
          : _footer(context, l),
    );
  }

  Widget _footer(BuildContext context, PaymentLocalizations l) {
    final save = PaymentButton(label: saveLabel ?? l.save, onPressed: onSave);
    final reason = onSave == null ? saveDisabledReason : null;
    if (reason == null) return ViewFooter(primaryAction: save);
    // A screen reader that moves straight to Save hears why it is disabled:
    // the reason is the button's hint, and the visible caption is excluded
    // so it is not read twice (D119).
    return DisabledButtonHint(
      hint: reason,
      child: ViewFooter(
        footer: ExcludeSemantics(
          child: Text(reason, style: PaymentType.of(context).caption),
        ),
        primaryAction: save,
      ),
    );
  }
}
