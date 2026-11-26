import 'package:flutter/material.dart';

import '../models/medical_claim_status.dart';

// Theme colors for Medical Claims screens
class MedicalClaimsColors {

  static const Color navy = Color(0xFF13365B);
  static const Color navyDark = Color(0xFF102A43);
  static const Color accentBlue = Color(0xFF2563EB);
  static const Color softBlue = Color(0xFFEDF3FC);
  static const Color softBlueBorder = Color(0xFFD6E4F9);
  static const Color canvas = Color(0xFFF7F9FC);
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFE2E8F0);
  static const Color dashedBorder = Color(0xFFCBD5E1);

  static const Color textPrimary = Color(0xFF102A43);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  static const Color successBg = Color(0xFFE6F6EC);
  static const Color successFg = Color(0xFF15803D);

  static const Color pendingBg = Color(0xFFFEF3C7);
  static const Color pendingFg = Color(0xFFB45309);

  static const Color infoReqBg = Color(0xFFFFEDD5);
  static const Color infoReqFg = Color(0xFFC2410C);

  static const Color rejectedBg = Color(0xFFFEE2E2);
  static const Color rejectedFg = Color(0xFFB91C1C);
}

ThemeData buildMedicalClaimsFigmaTheme(BuildContext context) {
  final base = Theme.of(context);
  final scheme = ColorScheme.fromSeed(
    seedColor: MedicalClaimsColors.navy,
    primary: MedicalClaimsColors.navy,
    secondary: MedicalClaimsColors.accentBlue,
    surface: MedicalClaimsColors.surface,
  );

  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: MedicalClaimsColors.canvas,
    appBarTheme: const AppBarTheme(
      backgroundColor: MedicalClaimsColors.canvas,
      foregroundColor: MedicalClaimsColors.navy,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: MedicalClaimsColors.navy,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: MedicalClaimsColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: MedicalClaimsColors.border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: MedicalClaimsColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      hintStyle: const TextStyle(
        color: MedicalClaimsColors.textMuted,
        fontSize: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: MedicalClaimsColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: MedicalClaimsColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: MedicalClaimsColors.accentBlue,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: MedicalClaimsColors.rejectedFg),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: MedicalClaimsColors.rejectedFg,
          width: 1.5,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: MedicalClaimsColors.navy,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
  );
}

class MedicalStatusBadge extends StatelessWidget {
  const MedicalStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  final MedicalClaimStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (status) {
      MedicalClaimStatus.submitted => (
        MedicalClaimsColors.pendingBg,
        MedicalClaimsColors.pendingFg,
      ),
      MedicalClaimStatus.underReview => (
        MedicalClaimsColors.pendingBg,
        MedicalClaimsColors.pendingFg,
      ),
      MedicalClaimStatus.moreInfoRequired => (
        MedicalClaimsColors.infoReqBg,
        MedicalClaimsColors.infoReqFg,
      ),
      MedicalClaimStatus.approved => (
        MedicalClaimsColors.successBg,
        MedicalClaimsColors.successFg,
      ),
      MedicalClaimStatus.rejected => (
        MedicalClaimsColors.rejectedBg,
        MedicalClaimsColors.rejectedFg,
      ),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: foreground,
          fontSize: compact ? 11.5 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

String formatLkr(num amount) {
  final isNegative = amount < 0;
  final fixed = amount.abs().toStringAsFixed(2);
  final parts = fixed.split('.');
  final whole = parts[0];
  final fraction = parts[1];

  final buffer = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    final reverseIndex = whole.length - i;
    if (i > 0 && reverseIndex % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(whole[i]);
  }

  return '${isNegative ? '-' : ''}LKR ${buffer.toString()}.$fraction';
}

String formatFigmaDate(DateTime date, {bool includeYear = true}) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final local = date.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = months[local.month - 1];
  return includeYear ? '$day $month ${local.year}' : '$day $month';
}
