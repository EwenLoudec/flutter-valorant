import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme/app_theme.dart';

/// video_player ships no implementation for Windows and Linux.
const _supportedPlatforms = {TargetPlatform.android, TargetPlatform.iOS, TargetPlatform.macOS};

bool get _isSoundSupported => kIsWeb || _supportedPlatforms.contains(defaultTargetPlatform);

/// Plays an official ability clip **without its picture** — the point of the
/// question is to recognise the sound alone.
class AbilitySoundPlayer extends StatefulWidget {
  const AbilitySoundPlayer({super.key, required this.url});

  final String url;

  @override
  State<AbilitySoundPlayer> createState() => _AbilitySoundPlayerState();
}

class _AbilitySoundPlayerState extends State<AbilitySoundPlayer> {
  VideoPlayerController? _controller;
  bool _isReady = false;
  bool _hasFailed = false;

  @override
  void initState() {
    super.initState();
    if (_isSoundSupported) _load();
  }

  Future<void> _load() async {
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller = controller;

    try {
      await controller.initialize();
      await controller.setVolume(1);
      if (mounted) setState(() => _isReady = true);
    } on Object {
      if (mounted) setState(() => _hasFailed = true);
    }
  }

  Future<void> _play() async {
    final controller = _controller;
    if (controller == null) return;

    await controller.seekTo(Duration.zero);
    await controller.play();
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(AbilitySoundPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url == widget.url) return;

    _controller?.dispose();
    _controller = null;
    _isReady = false;
    _hasFailed = false;
    if (_isSoundSupported) _load();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isSoundSupported) {
      return const _SoundNotice(message: 'Le son n\'est pas lisible sur cette plateforme — essaie sur mobile, macOS ou le web.');
    }
    if (_hasFailed) {
      return const _SoundNotice(message: 'Le clip n\'a pas pu être chargé. Réponds au jugé ou passe la question.');
    }

    final isPlaying = _controller?.value.isPlaying ?? false;

    return Column(
      children: [
        GestureDetector(
          onTap: _isReady ? _play : null,
          child: Container(
            height: 96,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.valorantRed.withValues(alpha: _isReady ? 0.12 : 0.05),
              border: Border.all(color: _isReady ? AppTheme.valorantRed : AppTheme.outlineDark),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isPlaying ? Icons.graphic_eq : Icons.volume_up_outlined,
                  size: 26,
                  color: _isReady ? AppTheme.valorantRed : Colors.white24,
                ),
                const SizedBox(width: 12),
                Text(
                  _isReady ? (isPlaying ? 'LECTURE…' : 'ÉCOUTER LE SON') : 'CHARGEMENT…',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                    color: _isReady ? AppTheme.valorantRed : Colors.white24,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Le clip est joué sans son image : seul le son compte.',
          style: TextStyle(fontSize: 11, color: AppTheme.valorantMuted),
        ),
      ],
    );
  }
}

class _SoundNotice extends StatelessWidget {
  const _SoundNotice({required this.message});

  final String message;

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
          const Icon(Icons.volume_off_outlined, size: 18, color: AppTheme.valorantMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 11.5, color: AppTheme.valorantMuted, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
