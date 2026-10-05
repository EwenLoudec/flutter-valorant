import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/player_query.dart';
import '../domain/rank_history.dart';
import '../providers/profile_providers.dart';
import 'match_detail_screen.dart';
import 'profile_error.dart';
import 'profile_section.dart';

/// The elo of the recent competitive games as a curve, oldest on the left.
/// Touching the chart reads a game's rank and RR movement.
class RankHistorySection extends ConsumerWidget {
  const RankHistorySection({super.key, required this.query});

  final PlayerQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ProfileSection(
      title: 'Évolution du RR',
      child: ref
          .watch(playerRankHistoryProvider(query))
          .when(
            loading: () => const ProfileMessage.loading(text: 'Lecture de l\'historique RR…'),
            error: (error, _) => ProfileMessage(text: profileErrorText(error), icon: Icons.show_chart),
            data: (entries) {
              if (entries.length < 2) {
                return const ProfileMessage(
                  text: 'Pas assez de parties classées récentes pour tracer une courbe.',
                  icon: Icons.show_chart,
                );
              }
              return RankHistoryChart(entries: entries.reversed.toList());
            },
          ),
    );
  }
}

/// Line chart of [entries], given oldest first.
class RankHistoryChart extends StatefulWidget {
  const RankHistoryChart({super.key, required this.entries});

  final List<RankHistoryEntry> entries;

  @override
  State<RankHistoryChart> createState() => _RankHistoryChartState();
}

class _RankHistoryChartState extends State<RankHistoryChart> {
  static const _chartHeight = 150.0;

  int? _selected;

  void _select(double dx, double width) {
    final count = widget.entries.length;
    if (count == 0 || width <= 0) return;
    final index = (dx / width * (count - 1)).round().clamp(0, count - 1);
    if (index != _selected) setState(() => _selected = index);
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.entries;
    final first = entries.first;
    final last = entries.last;
    final balance = last.elo - first.elo;
    // A refresh can bring a shorter history than the one the finger was on.
    final selected = _selected;
    final selectedIndex = selected != null && selected < entries.length ? selected : null;
    final focus = selectedIndex == null ? last : entries[selectedIndex];

    return ProfileCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${focus.tierName.isEmpty ? 'Classé' : focus.tierName} · ${focus.rankedRating} RR',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                ),
              ),
              _ChangeBadge(value: selectedIndex == null ? balance : focus.lastChange),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            selectedIndex == null
                ? 'Bilan sur ${entries.length} parties classées'
                : [
                    if (focus.mapName.isNotEmpty) focus.mapName,
                    if (focus.date != null) formatMatchDate(focus.date!),
                  ].join(' · '),
            style: const TextStyle(fontSize: 11, color: AppTheme.valorantMuted),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: _chartHeight,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (details) => _select(details.localPosition.dx, width),
                  onHorizontalDragUpdate: (details) => _select(details.localPosition.dx, width),
                  child: CustomPaint(
                    size: Size(width, _chartHeight),
                    painter: _RankChartPainter(entries: entries, selected: selectedIndex),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Elo = palier × 100 + RR. Touche ou glisse sur la courbe pour lire une partie.',
            style: TextStyle(fontSize: 10.5, color: AppTheme.valorantMuted, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _ChangeBadge extends StatelessWidget {
  const _ChangeBadge({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    final color = value > 0
        ? matchWinColor
        : value < 0
        ? AppTheme.valorantRed
        : AppTheme.valorantMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      color: color.withValues(alpha: 0.16),
      child: Text(
        '${value > 0 ? '+' : ''}$value RR',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}

class _RankChartPainter extends CustomPainter {
  const _RankChartPainter({required this.entries, required this.selected});

  final List<RankHistoryEntry> entries;
  final int? selected;

  static const _leftGutter = 34.0;
  static const _verticalPadding = 8.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.length < 2) return;

    final elos = entries.map((entry) => entry.elo);
    var minElo = elos.reduce(math.min).toDouble();
    var maxElo = elos.reduce(math.max).toDouble();
    if (maxElo - minElo < 40) {
      final middle = (maxElo + minElo) / 2;
      minElo = middle - 20;
      maxElo = middle + 20;
    }

    final plotWidth = size.width - _leftGutter;
    final plotHeight = size.height - _verticalPadding * 2;

    Offset pointAt(int index) {
      final x = _leftGutter + plotWidth * index / (entries.length - 1);
      final ratio = (entries[index].elo - minElo) / (maxElo - minElo);
      return Offset(x, _verticalPadding + plotHeight * (1 - ratio));
    }

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..strokeWidth = 1;
    final labelStyle = TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.45), fontWeight: FontWeight.w700);

    for (final value in [maxElo, (maxElo + minElo) / 2, minElo]) {
      final ratio = (value - minElo) / (maxElo - minElo);
      final y = _verticalPadding + plotHeight * (1 - ratio);
      canvas.drawLine(Offset(_leftGutter, y), Offset(size.width, y), gridPaint);

      final painter = TextPainter(
        text: TextSpan(text: value.round().toString(), style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, Offset(0, y - painter.height / 2));
    }

    final path = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (var index = 1; index < entries.length; index++) {
      final point = pointAt(index);
      path.lineTo(point.dx, point.dy);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = AppTheme.valorantRed
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    final lastPoint = pointAt(entries.length - 1);
    _drawMarker(canvas, lastPoint);

    final selected = this.selected;
    if (selected != null) {
      final point = pointAt(selected);
      canvas.drawLine(
        Offset(point.dx, _verticalPadding),
        Offset(point.dx, size.height - _verticalPadding),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.35)
          ..strokeWidth = 1,
      );
      _drawMarker(canvas, point);
    }
  }

  void _drawMarker(Canvas canvas, Offset center) {
    canvas.drawCircle(center, 5, Paint()..color = AppTheme.valorantRed);
    canvas.drawCircle(
      center,
      5,
      Paint()
        ..color = AppTheme.valorantSurface
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _RankChartPainter oldDelegate) {
    return oldDelegate.selected != selected || !identical(oldDelegate.entries, entries);
  }
}
