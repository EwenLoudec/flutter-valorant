import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/diagonal_cut_clipper.dart';
import '../domain/lineup_media.dart';

/// Shows one picture or clip of a spot, straight from the device.
class LineupMediaView extends StatelessWidget {
  const LineupMediaView({super.key, required this.media});

  final LineupMedia media;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || !File(media.path).existsSync()) {
      return const _MissingMedia();
    }

    return ClipPath(
      clipper: const DiagonalCutClipper(cut: 10),
      child: media.isVideo ? _LocalVideo(path: media.path) : Image.file(File(media.path), fit: BoxFit.cover),
    );
  }
}

class _MissingMedia extends StatelessWidget {
  const _MissingMedia();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      alignment: Alignment.center,
      decoration: BoxDecoration(border: Border.all(color: AppTheme.outlineDark)),
      child: const Text(
        'Média introuvable sur cet appareil',
        style: TextStyle(fontSize: 11.5, color: AppTheme.valorantMuted),
      ),
    );
  }
}

/// Tap to play or pause; loops so a short lineup clip can be watched over
/// and over while lining the throw up.
class _LocalVideo extends StatefulWidget {
  const _LocalVideo({required this.path});

  final String path;

  @override
  State<_LocalVideo> createState() => _LocalVideoState();
}

class _LocalVideoState extends State<_LocalVideo> {
  late final VideoPlayerController _controller = VideoPlayerController.file(File(widget.path));
  late final Future<void> _initialization = _controller.initialize().then((_) {
    _controller.setLooping(true);
    if (mounted) setState(() {});
  });

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _controller.value.isPlaying ? _controller.pause() : _controller.play());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const AspectRatio(
            aspectRatio: 16 / 9,
            child: ColoredBox(
              color: Colors.black26,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          );
        }

        return GestureDetector(
          onTap: _toggle,
          child: AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(_controller),
                if (!_controller.value.isPlaying)
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.55),
                      border: Border.all(color: Colors.white70),
                    ),
                    child: const Icon(Icons.play_arrow_rounded, size: 30),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: VideoProgressIndicator(
                    _controller,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(playedColor: AppTheme.valorantRed),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
