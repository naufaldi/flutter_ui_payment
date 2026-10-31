import 'package:flutter/material.dart';
import '../foundation/primitives.dart';
import '../foundation/payment_icons.dart';
import '../foundation/payment_theme.dart';
import '../foundation/payment_type.dart';
import '../foundation/payment_tokens.dart';
import '../foundation/payment_localizations.dart';
import '../foundation/kit_strings.dart';
import '../foundation/view_frame.dart';

/// Grouped host settings with a future-locked Save action.
class PaymentSettingsView extends StatelessWidget {
  const PaymentSettingsView({
    super.key,
    required this.title,
    required this.child,
    this.onSave,
    this.saveLabel,
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
      footer: onSave == null
          ? null
          : ViewFooter(
              primaryAction: PaymentButton(
                label: saveLabel ?? l.save,
                onPressed: onSave,
              ),
            ),
    );
  }
}
