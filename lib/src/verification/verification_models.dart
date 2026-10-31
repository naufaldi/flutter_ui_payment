import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Business status of identity verification, decided only by the host.
enum VerificationStatus {
  notStarted,
  inReview,
  actionRequired,
  verified,
  rejected,
  expired;

  static VerificationStatus? tryParse(String? value) {
    for (final status in values) {
      if (status.name == value) return status;
    }
    return null;
  }
}

/// Next steps the host allows for the current verification state.
enum VerificationAction {
  start,
  fixDetails,
  checkStatus,
  contactSupport,
  continueToPayment,
}

/// Status snapshot. Holds no document bytes and no full identity data.
@immutable
class VerificationSnapshot {
  const VerificationSnapshot({
    required this.status,
    this.requestId,
    this.safeReason,
    this.fieldsToFix = const {},
    this.allowedActions = const {},
    this.updatedAt,
  });

  final VerificationStatus status;
  final String? requestId;
  final String? safeReason;

  /// Keys of [IdentityFieldSpec]s or [DocumentRequirement]s to correct.
  final Set<String> fieldsToFix;
  final Set<VerificationAction> allowedActions;
  final DateTime? updatedAt;
}

/// One item of data the host asks for, with the reason shown before consent.
@immutable
class DataRequirement {
  const DataRequirement({required this.title, required this.purpose});

  final String title;
  final String purpose;
}

/// A host-defined identity field. Validation rules belong to the host; the
/// form only runs them and shows their messages.
@immutable
class IdentityFieldSpec {
  const IdentityFieldSpec({
    required this.key,
    required this.label,
    this.hint,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.inputFormatters = const [],
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints = const [],
    this.maskInReview = false,
  });

  final String key;
  final String label;
  final String? hint;

  /// Returns an error message, or null when valid. Required-ness is part of
  /// the host rule.
  final String? Function(String value)? validator;
  final TextInputType keyboardType;
  final List<TextInputFormatter> inputFormatters;
  final TextCapitalization textCapitalization;
  final List<String> autofillHints;

  /// Review screens show only the last four characters.
  final bool maskInReview;
}

/// Host-defined limits for one document slot.
@immutable
class DocumentRequirement {
  const DocumentRequirement({
    required this.key,
    required this.label,
    required this.acceptedTypes,
    required this.maxBytes,
    this.acceptedTypesLabel,
  });

  final String key;
  final String label;

  /// MIME types the host accepts. A matching type is not proof the document
  /// is valid; the host still validates the content server-side.
  final Set<String> acceptedTypes;
  final int maxBytes;

  /// Human label such as "JPG or PNG".
  final String? acceptedTypesLabel;
}

/// Metadata of a file the host selected. Bytes stay with the host.
@immutable
class DocumentFile {
  const DocumentFile({
    required this.name,
    required this.mimeType,
    required this.sizeBytes,
  });

  final String name;
  final String mimeType;
  final int sizeBytes;
}

enum DocumentIssueKind {
  permissionDenied,
  permissionPermanentlyDenied,
  tooLarge,
  unsupportedType,
  uploadInterrupted,
  rejectedByHost,
}

@immutable
class DocumentIssue {
  const DocumentIssue(
    this.kind, {
    this.safeMessage,
    this.canRetry = true,
    this.canOpenSettings = false,
  });

  final DocumentIssueKind kind;
  final String? safeMessage;
  final bool canRetry;

  /// Host capability: it can open the OS settings for this permission.
  final bool canOpenSettings;
}

enum DocumentSlotPhase { empty, uploading, uploaded, failed }

/// Rendered state of one document slot. [requestId] lets the host ignore
/// results from uploads that a newer selection replaced.
@immutable
class DocumentSlotState {
  const DocumentSlotState.empty() : this._(DocumentSlotPhase.empty);

  const DocumentSlotState.uploading(
    DocumentFile file, {
    required String requestId,
    double? progress,
  }) : this._(
         DocumentSlotPhase.uploading,
         file: file,
         requestId: requestId,
         progress: progress,
       );

  const DocumentSlotState.uploaded(
    DocumentFile file, {
    required String requestId,
  }) : this._(DocumentSlotPhase.uploaded, file: file, requestId: requestId);

  const DocumentSlotState.failed(
    DocumentIssue issue, {
    DocumentFile? file,
    String? requestId,
  }) : this._(
         DocumentSlotPhase.failed,
         issue: issue,
         file: file,
         requestId: requestId,
       );

  const DocumentSlotState._(
    this.phase, {
    this.file,
    this.requestId,
    this.progress,
    this.issue,
  });

  final DocumentSlotPhase phase;
  final DocumentFile? file;
  final String? requestId;
  final double? progress;
  final DocumentIssue? issue;
}

/// Checks a file against host limits before upload. Passing this check does
/// not mean the document is genuine.
DocumentIssue? checkDocumentLimits(
  DocumentRequirement requirement,
  DocumentFile file,
) {
  if (!requirement.acceptedTypes.contains(file.mimeType)) {
    return const DocumentIssue(DocumentIssueKind.unsupportedType);
  }
  if (file.sizeBytes > requirement.maxBytes) {
    return const DocumentIssue(DocumentIssueKind.tooLarge);
  }
  return null;
}
