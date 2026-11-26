import 'package:flutter/material.dart';

class ClaimScaffold extends StatelessWidget {
  const ClaimScaffold({super.key, required this.title, required this.body});

  final String title;
  final Widget body;

  static const navy = Color(0xFF12385F);
  static const canvas = Color(0xFFF2F5FA);

  @override
  Widget build(BuildContext context) {
    final colors = ColorScheme.fromSeed(seedColor: navy)
        .copyWith(primary: navy, surface: Colors.white, onSurface: navy);
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: colors,
        scaffoldBackgroundColor: canvas,
        appBarTheme: const AppBarTheme(
          backgroundColor: canvas,
          foregroundColor: navy,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: navy,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: body,
          ),
        ),
      ),
    );
  }
}
