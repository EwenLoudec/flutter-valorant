import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/lineup_media.dart';
import 'lineup_media_view.dart';

/// Picks the picture (and, for the result, the clip) of one step of a spot,
/// and shows what is already attached.
class LineupMediaField extends StatelessWidget {
  const LineupMediaField({
    super.key,
    required this.role,
    required this.media,
    required this.onPickPhoto,
    required this.onRemove,
    this.onPickVideo,
  });

  final LineupMediaRole role;
  final LineupMedia? media;
  final VoidCallback onPickPhoto;
  final VoidCallback? onPickVideo;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final media = this.media;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (media != null) ...[
          LineupMediaView(media: media),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Expanded(
              child: _PickButton(
                icon: Icons.photo_camera_back_outlined,
                label: media == null ? 'Photo ${role.label.toLowerCase()}' : 'Remplacer la photo',
                onPressed: onPickPhoto,
              ),
            ),
            if (onPickVideo != null) ...[
              const SizedBox(width: 8),
              Expanded(
                child: _PickButton(
                  icon: Icons.videocam_outlined,
                  label: 'Vidéo',
                  onPressed: onPickVideo!,
                ),
              ),
            ],
            if (media != null)
              IconButton(
                tooltip: 'Retirer',
                onPressed: onRemove,
                icon: const Icon(Icons.close, size: 18, color: AppTheme.valorantMuted),
              ),
          ],
        ),
      ],
    );
  }
}

class _PickButton extends StatelessWidget {
  const _PickButton({required this.icon, required this.label, required this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white70,
        side: const BorderSide(color: AppTheme.outlineDark),
        shape: const RoundedRectangleBorder(),
        padding: const EdgeInsets.symmetric(vertical: 11),
      ),
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
      ),
    );
  }
}
