import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Autoplaying, muted, looping video preview — the same treatment
/// playvalorant.com gives its own ability preview clips.
class InlineVideoPreview extends StatefulWidget {
  const InlineVideoPreview({super.key, required this.url});

  final String url;

  @override
  State<InlineVideoPreview> createState() => _InlineVideoPreviewState();
}

class _InlineVideoPreviewState extends State<InlineVideoPreview> {
  late final VideoPlayerController _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
  late final Future<void> _initialization = _controller.initialize().then((_) {
    _controller
      ..setLooping(true)
      ..setVolume(0)
      ..play();
  });

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
        return AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        );
      },
    );
  }
}
