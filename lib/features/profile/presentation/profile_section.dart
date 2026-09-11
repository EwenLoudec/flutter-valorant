import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/diagonal_cut_clipper.dart';

/// A titled block of the profile page, with the red tick the rest of the app
/// uses to head its sections.
class ProfileSection extends StatelessWidget {
  const ProfileSection({super.key, required this.title, required this.child, this.action});

  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 3, height: 14, color: AppTheme.valorantRed),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, letterSpacing: 0.8),
              ),
            ),
            ?action,
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

/// The angled dark surface used by every card of the profile.
class ProfileCard extends StatelessWidget {
  const ProfileCard({
    super.key,
    required this.child,
    this.accentColor,
    this.padding = const EdgeInsets.all(14),
  });

  final Widget child;
  final Color? accentColor;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final accentColor = this.accentColor;

    return ClipPath(
      clipper: const DiagonalCutClipper(cut: 10),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.valorantSurface,
          border: accentColor == null ? null : Border(left: BorderSide(color: accentColor, width: 3)),
        ),
        padding: padding,
        child: child,
      ),
    );
  }
}

/// Loading / empty / error placeholder, kept inside its own section so one
/// failing request never blanks the whole profile.
class ProfileMessage extends StatelessWidget {
  const ProfileMessage({super.key, required this.text, this.icon, this.isLoading = false});

  const ProfileMessage.loading({super.key, this.text = 'Chargement…'}) : icon = null, isLoading = true;

  final String text;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ProfileCard(
      child: Row(
        children: [
          if (isLoading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.valorantRed),
            )
          else
            Icon(icon ?? Icons.info_outline, size: 16, color: AppTheme.valorantMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 12.5, color: Colors.white70)),
          ),
        ],
      ),
    );
  }
}
