import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/diagonal_cut_clipper.dart';
import '../../../../core/widgets/fade_in_network_image.dart';
import '../../../../core/widgets/inline_video_preview.dart';
import '../../domain/content_tier.dart';
import '../../domain/weapon_skin.dart';

class WeaponSkinsCarousel extends StatelessWidget {
  const WeaponSkinsCarousel({
    super.key,
    required this.skins,
    required this.contentTiers,
    required this.accentColor,
  });

  final List<WeaponSkin> skins;
  final Map<String, ContentTier> contentTiers;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 340,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.9),
        padEnds: false,
        itemCount: skins.length,
        itemBuilder: (context, index) {
          final skin = skins[index];
          final tier = contentTiers[skin.contentTierUuid];
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: _SkinCard(skin: skin, tierColor: tier?.color ?? accentColor, tierIcon: tier?.displayIcon),
          );
        },
      ),
    );
  }
}

class _SkinCard extends StatefulWidget {
  const _SkinCard({required this.skin, required this.tierColor, required this.tierIcon});

  final WeaponSkin skin;
  final Color tierColor;
  final String? tierIcon;

  @override
  State<_SkinCard> createState() => _SkinCardState();
}

class _SkinCardState extends State<_SkinCard> {
  int _levelIndex = 0;
  int _chromaIndex = 0;
  bool _playingVideo = false;

  void _selectLevel(int index) => setState(() {
    _levelIndex = index;
    _playingVideo = false;
  });

  void _selectChroma(int index) => setState(() {
    _chromaIndex = index;
    _playingVideo = false;
  });

  @override
  Widget build(BuildContext context) {
    final skin = widget.skin;
    final level = skin.levels.isNotEmpty ? skin.levels[_levelIndex] : null;
    final chroma = skin.chromas.isNotEmpty ? skin.chromas[_chromaIndex] : null;

    final usingChroma = _chromaIndex > 0 && chroma != null;
    final videoUrl = usingChroma ? chroma.streamedVideo : level?.streamedVideo;
    final imageUrl = usingChroma
        ? (chroma.fullRender ?? chroma.swatch ?? skin.displayIcon)
        : (level?.displayIcon ?? chroma?.fullRender ?? skin.displayIcon);

    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [BoxShadow(color: widget.tierColor.withValues(alpha: 0.3), blurRadius: 18, spreadRadius: -6)],
      ),
      child: ClipPath(
        clipper: const DiagonalCutClipper(cut: 16),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.valorantSurface,
            border: Border.all(color: widget.tierColor.withValues(alpha: 0.5)),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: videoUrl != null && !_playingVideo ? () => setState(() => _playingVideo = true) : null,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        child: _playingVideo && videoUrl != null
                            ? InlineVideoPreview(key: ValueKey(videoUrl), url: videoUrl)
                            : (imageUrl != null
                                  ? FadeInNetworkImage(key: ValueKey(imageUrl), url: imageUrl, fit: BoxFit.contain)
                                  : const SizedBox()),
                      ),
                      if (videoUrl != null && !_playingVideo)
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.55),
                            border: Border.all(color: widget.tierColor, width: 1.5),
                          ),
                          child: Icon(Icons.play_arrow_rounded, color: widget.tierColor, size: 26),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (widget.tierIcon != null) ...[
                    Image.network(
                      widget.tierIcon!,
                      width: 16,
                      height: 16,
                      color: widget.tierColor,
                      colorBlendMode: BlendMode.srcIn,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      skin.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ),
                ],
              ),
              if (skin.levels.length > 1) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final (i, _) in skin.levels.indexed)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _Pip(
                          label: '${i + 1}',
                          selected: i == _levelIndex,
                          color: widget.tierColor,
                          onTap: () => _selectLevel(i),
                        ),
                      ),
                    const Spacer(),
                    if (level != null)
                      Text(
                        level.levelLabel.toUpperCase(),
                        style: TextStyle(fontSize: 9.5, color: widget.tierColor, fontWeight: FontWeight.w700),
                      ),
                  ],
                ),
              ],
              if (skin.chromas.length > 1) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 26,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final (i, ch) in skin.chromas.indexed)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: _ChromaSwatch(
                            chroma: ch,
                            selected: i == _chromaIndex,
                            accent: widget.tierColor,
                            onTap: () => _selectChroma(i),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Pip extends StatelessWidget {
  const _Pip({required this.label, required this.selected, required this.color, required this.onTap});

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? color.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.05),
          border: Border.all(color: selected ? color : Colors.white24, width: selected ? 1.6 : 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            color: selected ? color : Colors.white54,
          ),
        ),
      ),
    );
  }
}

class _ChromaSwatch extends StatelessWidget {
  const _ChromaSwatch({required this.chroma, required this.selected, required this.accent, required this.onTap});

  final WeaponSkinChroma chroma;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 26,
        height: 26,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: selected ? accent : Colors.white24, width: selected ? 2 : 1),
        ),
        child: ClipOval(
          child: chroma.swatch != null
              ? Image.network(chroma.swatch!, fit: BoxFit.cover)
              : const ColoredBox(color: Colors.white12),
        ),
      ),
    );
  }
}
