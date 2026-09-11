import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../theme/app_theme.dart';

/// Platforms video_player actually ships an implementation for. On Windows
/// and Linux there is none, and a clip that silently renders nothing looks
/// exactly like a missing video — so it says so instead.
const _supportedPlatforms = {TargetPlatform.android, TargetPlatform.iOS, TargetPlatform.macOS};

bool get _isVideoSupported => kIsWeb || _supportedPlatforms.contains(defaultTargetPlatform);

/// Autoplaying, muted, looping video preview — the same treatment
/// playvalorant.com gives its own ability preview clips.
class InlineVideoPreview extends StatefulWidget {
  const InlineVideoPreview({super.key, required this.url});

  final String url;

  @override
  State<InlineVideoPreview> createState() => _InlineVideoPreviewState();
}

class _InlineVideoPreviewState extends State<InlineVideoPreview> {
  VideoPlayerController? _controller;
  Future<void>? _initialization;

  @override
  void initState() {
    super.initState();
    if (_isVideoSupported) _start();
  }

  void _start() {
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller = controller;
    _initialization = controller.initialize().then((_) {
      controller
        ..setLooping(true)
        ..setVolume(0)
        ..play();
    });
  }

  Future<void> _retry() async {
    await _controller?.dispose();
    setState(_start);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVideoSupported) {
      return const _VideoNotice(
        message: 'Aperçu vidéo indisponible sur cette plateforme — lance l\'app sur mobile, macOS ou le web.',
      );
    }

    final controller = _controller;
    if (controller == null) return const SizedBox();

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

        if (snapshot.hasError || controller.value.hasError) {
          return _VideoNotice(
            message: 'Le clip n\'a pas pu être chargé (réseau ou lien expiré).',
            onRetry: _retry,
          );
        }

        return AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: VideoPlayer(controller),
        );
      },
    );
  }
}

/// Explains why there is no picture, instead of leaving a black rectangle.
class _VideoNotice extends StatelessWidget {
  const _VideoNotice({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black26,
        border: Border.all(color: AppTheme.outlineDark),
      ),
      child: Row(
        children: [
          const Icon(Icons.videocam_off_outlined, size: 18, color: AppTheme.valorantMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 11.5, color: AppTheme.valorantMuted, height: 1.4),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.valorantRed,
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('RÉESSAYER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
            ),
        ],
      ),
    );
  }
}
