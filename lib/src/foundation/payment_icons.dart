import 'package:flutter/material.dart';

/// Fixed meanings for the kit icon vocabulary.
class PaymentIcons {
  const PaymentIcons._();

  /// Successful result.
  static const IconData success = Icons.check_circle_outline;

  /// Warning requiring attention.
  static const IconData warning = Icons.warning_amber_outlined;

  /// Error requiring recovery.
  static const IconData danger = Icons.error_outline;

  /// Informational or neutral message.
  static const IconData info = Icons.info_outline;

  /// Forward navigation; SDK matchTextDirection mirrors in RTL. Never swap by hand.
  static const IconData forward = Icons.chevron_right;

  /// External destination, handled by the host.
  static const IconData externalLink = Icons.open_in_new;

  /// Dismiss the current surface.
  static const IconData close = Icons.close;

  /// Copy action, handled by the host.
  static const IconData copy = Icons.copy_rounded;

  /// Copy completed.
  static const IconData copied = Icons.check;

  /// Content failed to load.
  static const IconData loadFailed = Icons.cloud_off_outlined;

  /// Search has no matches.
  static const IconData noMatches = Icons.search_off;

  /// Work in progress.
  static const IconData busy = Icons.hourglass_top_outlined;

  /// Content hidden.
  static const IconData hidden = Icons.lock_outline;
}
