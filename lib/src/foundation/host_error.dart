import 'package:flutter/foundation.dart';

/// Structured error categories a host adapter maps provider failures into.
///
/// Raw exceptions and provider payloads never reach widgets; only a category
/// and an optional message the host has decided is safe to show.
enum HostErrorCategory {
  /// The request may not have reached the server.
  network,

  /// The request was sent but no answer arrived; its outcome is unknown.
  timeout,
  validation,
  sessionExpired,
  notAllowed,
  conflict,

  /// The server answered with data the adapter could not trust.
  invalidResponse,
  unavailable,
  unknown,
}

@immutable
class HostError {
  const HostError(this.category, {this.safeMessage, this.retryable = true});

  final HostErrorCategory category;

  /// Copy approved by the host for end users, or null to use the default.
  final String? safeMessage;
  final bool retryable;

  /// Whether the server may have acted on the request. Callers must not
  /// treat these as failures.
  bool get outcomeUnknown => category == HostErrorCategory.timeout;

  @override
  bool operator ==(Object other) =>
      other is HostError &&
      other.category == category &&
      other.safeMessage == safeMessage &&
      other.retryable == retryable;

  @override
  int get hashCode => Object.hash(category, safeMessage, retryable);

  @override
  String toString() => 'HostError($category)';
}
