import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/diagonal_cut_clipper.dart';
import '../../encyclopedia/domain/game_map.dart';
import '../domain/match_detail.dart';
import 'match_detail_screen.dart';

/// Where the player's kills and deaths happened, on the tactical minimap.
/// Tapping a marker tells which round and which weapon.
class MatchKillMap extends StatefulWidget {
  const MatchKillMap({super.key, required this.map, required this.kills, required this.puuid});

  final GameMap map;
  final List<MatchKill> kills;
  final String puuid;

  @override
  State<MatchKillMap> createState() => _MatchKillMapState();
}

class _KillMarker {
  const _KillMarker({required this.kill, required this.position, required this.isKill});

  final MatchKill kill;
  final Offset position;

  /// True when the player got the kill, false when they died.
  final bool isKill;
}

class _MatchKillMapState extends State<MatchKillMap> {
  /// A tap this close (in fractions of the map) selects a marker.
  static const _hitRadius = 0.05;

  _KillMarker? _selected;

  List<_KillMarker> get _markers => [
    for (final kill in widget.kills)
      if (kill.hasLocation && (kill.killerPuuid == widget.puuid || kill.victimPuuid == widget.puuid))
        _KillMarker(
          kill: kill,
          position: widget.map.normalizedPoint(kill.victimX!, kill.victimY!),
          isKill: kill.killerPuuid == widget.puuid && kill.victimPuuid != widget.puuid,
        ),
  ];

  void _handleTap(Offset normalized, List<_KillMarker> markers) {
    _KillMarker? closest;
    var closestDistance = _hitRadius;
    for (final marker in markers) {
      final distance = (marker.position - normalized).distance;
      if (distance > closestDistance) continue;
      closestDistance = distance;
      closest = marker;
    }
    setState(() => _selected = closest);
  }

  @override
  Widget build(BuildContext context) {
    final markers = _markers;
    final killCount = markers.where((marker) => marker.isKill).length;
    final deathCount = markers.length - killCount;
    final selected = _selected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipPath(
          clipper: const DiagonalCutClipper(cut: 14),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.valorantSurface,
              border: Border.all(color: AppTheme.outlineDark),
            ),
            child: AspectRatio(
              aspectRatio: 1,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = constraints.biggest;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (details) => _handleTap(
                      Offset(details.localPosition.dx / size.width, details.localPosition.dy / size.height),
                      markers,
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          widget.map.displayIcon!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Icon(Icons.image_not_supported_outlined, color: Colors.white24),
                          ),
                        ),
                        CustomPaint(painter: _KillPainter(markers: markers, selected: selected)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const _Dot(color: matchWinColor),
            const SizedBox(width: 5),
            Text('Tes kills ($killCount)', style: const TextStyle(fontSize: 11, color: Colors.white70)),
            const SizedBox(width: 14),
            const _Dot(color: AppTheme.valorantRed),
            const SizedBox(width: 5),
            Text('Tes morts ($deathCount)', style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          selected == null
              ? 'Touche un point pour voir la manche et l\'arme.'
              : 'Manche ${selected.kill.round + 1} · '
                    '${selected.isKill ? 'tu élimines ${selected.kill.victimName}' : '${selected.kill.killerName} t\'élimine'}'
                    '${selected.kill.weaponName.isEmpty ? '' : ' · ${selected.kill.weaponName}'}',
          style: const TextStyle(fontSize: 11.5, color: Colors.white70, height: 1.4),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _KillPainter extends CustomPainter {
  const _KillPainter({required this.markers, required this.selected});

  final List<_KillMarker> markers;
  final _KillMarker? selected;

  @override
  void paint(Canvas canvas, Size size) {
    final ring = Paint()
      ..color = AppTheme.valorantSurface
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final marker in markers) {
      final center = Offset(marker.position.dx * size.width, marker.position.dy * size.height);
      final isSelected = identical(marker.kill, selected?.kill);
      final radius = isSelected ? 7.0 : 4.5;
      final fill = Paint()..color = marker.isKill ? matchWinColor : AppTheme.valorantRed;

      canvas.drawCircle(center, radius, fill);
      canvas.drawCircle(center, radius, ring);
      if (isSelected) {
        canvas.drawCircle(
          center,
          radius + 4,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _KillPainter oldDelegate) =>
      oldDelegate.markers.length != markers.length || !identical(oldDelegate.selected?.kill, selected?.kill);
}
