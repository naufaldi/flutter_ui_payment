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

  /// Title supplied by the host.
  final String title;

  /// Child supplied by the host.
  final Widget child;

  /// Onsave supplied by the host.
  final Future<void> Function()? onSave;

  /// Savelabel supplied by the host.
  final String? saveLabel;

  /// Statusmessage supplied by the host.
  final String? statusMessage;

  /// Statustone supplied by the host.
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
          : Align(
              alignment: AlignmentDirectional.centerEnd,
              child: PaymentButton(
                label: saveLabel ?? l.save,
                width: PaymentWidth.hug,
                onPressed: onSave,
              ),
            ),
    );
  }
}
