import 'package:flutter/material.dart';

/// The exact 5 allowed lifecycle statuses for an insurance claim in Insure-Plus:
/// Submitted, UnderReview, MoreInfoRequired, Approved, Rejected.
enum ClaimStatus {
  submitted,
  underReview,
  moreInfoRequired,
  approved,
  rejected;

  /// String value matching the Firestore and shared standard exact naming.
  String get value {
    switch (this) {
      case ClaimStatus.submitted:
        return 'Submitted';
      case ClaimStatus.underReview:
        return 'UnderReview';
      case ClaimStatus.moreInfoRequired:
        return 'MoreInfoRequired';
      case ClaimStatus.approved:
        return 'Approved';
      case ClaimStatus.rejected:
        return 'Rejected';
    }
  }

  /// Parses a string into a [ClaimStatus].
  static ClaimStatus fromString(String val) {
    final clean = val.trim().replaceAll(' ', '').toLowerCase();
    switch (clean) {
      case 'submitted':
        return ClaimStatus.submitted;
      case 'underreview':
        return ClaimStatus.underReview;
      case 'moreinforequired':
      case 'moreinfo':
        return ClaimStatus.moreInfoRequired;
      case 'approved':
        return ClaimStatus.approved;
      case 'rejected':
        return ClaimStatus.rejected;
      default:
        return ClaimStatus.submitted;
    }
  }
}

/// Extension providing beginner-friendly display helpers for each status.
extension ClaimStatusExtension on ClaimStatus {
  /// User-friendly label for UI presentation.
  String get label {
    switch (this) {
      case ClaimStatus.submitted:
        return 'Submitted';
      case ClaimStatus.underReview:
        return 'Under Review';
      case ClaimStatus.moreInfoRequired:
        return 'More Info Required';
      case ClaimStatus.approved:
        return 'Approved';
      case ClaimStatus.rejected:
        return 'Rejected';
    }
  }

  /// Primary color associated with the status.
  Color get color {
    switch (this) {
      case ClaimStatus.submitted:
        return Colors.orange;
      case ClaimStatus.underReview:
        return Colors.blue;
      case ClaimStatus.moreInfoRequired:
        return Colors.deepPurple;
      case ClaimStatus.approved:
        return Colors.green;
      case ClaimStatus.rejected:
        return Colors.red;
    }
  }

  /// Light background tint color for badges and chips.
  Color get backgroundColor {
    switch (this) {
      case ClaimStatus.submitted:
        return const Color(0xFFFFF3E0); // Light Orange
      case ClaimStatus.underReview:
        return const Color(0xFFE3F2FD); // Light Blue
      case ClaimStatus.moreInfoRequired:
        return const Color(0xFFEDE7F6); // Light Purple
      case ClaimStatus.approved:
        return const Color(0xFFE8F5E9); // Light Green
      case ClaimStatus.rejected:
        return const Color(0xFFFFEBEE); // Light Red
    }
  }

  /// Icon representing the status.
  IconData get icon {
    switch (this) {
      case ClaimStatus.submitted:
        return Icons.hourglass_top_rounded;
      case ClaimStatus.underReview:
        return Icons.search_rounded;
      case ClaimStatus.moreInfoRequired:
        return Icons.help_outline_rounded;
      case ClaimStatus.approved:
        return Icons.check_circle_outline_rounded;
      case ClaimStatus.rejected:
        return Icons.cancel_outlined;
    }
  }
}
