import 'package:flutter/material.dart';

/// Image.network that fades in once a frame is decoded, instead of popping
/// in abruptly, and falls back to a quiet placeholder on failure.
class FadeInNetworkImage extends StatelessWidget {
  const FadeInNetworkImage({super.key, required this.url, this.fit = BoxFit.cover, this.alignment = Alignment.center});

  final String url;
  final BoxFit fit;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: fit,
      alignment: alignment,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          child: child,
        );
      },
      errorBuilder: (context, error, stackTrace) => const ColoredBox(
        color: Colors.black26,
        child: Icon(Icons.image_not_supported_outlined, color: Colors.white24),
      ),
    );
  }
}
