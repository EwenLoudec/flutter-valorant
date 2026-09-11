import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../../core/theme/app_theme.dart';

/// Plays the pinned demo inside the app, through YouTube's own player — the
/// creator keeps their views and their attribution, and the spot can be
/// watched without leaving the fiche.
class LineupDemoPlayer extends StatefulWidget {
  const LineupDemoPlayer({super.key, required this.url, this.title});

  final String url;
  final String? title;

  @override
  State<LineupDemoPlayer> createState() => _LineupDemoPlayerState();
}

class _LineupDemoPlayerState extends State<LineupDemoPlayer> {
  YoutubePlayerController? _controller;

  @override
  void initState() {
    super.initState();
    final videoId = YoutubePlayerController.convertUrlToId(widget.url);
    if (videoId == null) return;

    _controller = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: false,
      params: const YoutubePlayerParams(showFullscreenButton: true, showControls: true),
    );
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final title = widget.title;

    if (controller == null) {
      return const _NotPlayable();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(border: Border.all(color: AppTheme.outlineDark)),
          child: YoutubePlayer(controller: controller, aspectRatio: 16 / 9),
        ),
        if (title != null && title.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: AppTheme.valorantMuted, height: 1.4),
          ),
        ],
      ],
    );
  }
}

class _NotPlayable extends StatelessWidget {
  const _NotPlayable();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: AppTheme.outlineDark)),
      child: const Text(
        'Ce lien n\'est pas une vidéo YouTube : utilise le bouton pour l\'ouvrir.',
        style: TextStyle(fontSize: 11.5, color: AppTheme.valorantMuted),
      ),
    );
  }
}
