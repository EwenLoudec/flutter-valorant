import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Square, dark text-field styling shared by the app's forms.
InputDecoration valorantInputDecoration({String? hint, String? errorText}) {
  const border = OutlineInputBorder(
    borderRadius: BorderRadius.zero,
    borderSide: BorderSide(color: AppTheme.outlineDark),
  );

  return InputDecoration(
    hintText: hint,
    errorText: errorText,
    isDense: true,
    filled: true,
    fillColor: AppTheme.valorantDark,
    hintStyle: const TextStyle(color: Colors.white24),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    border: border,
    enabledBorder: border,
    focusedBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: AppTheme.valorantRed),
    ),
  );
}

/// Small uppercase caption sitting above a field.
class ValorantFieldLabel extends StatelessWidget {
  const ValorantFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: Colors.white70,
        ),
      ),
    );
  }
}
