import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/player_query.dart';
import '../domain/weapon_accuracy.dart';
import '../providers/profile_providers.dart';
import 'profile_error.dart';
import 'profile_section.dart';

const _headshotColor = AppTheme.valorantRed;
const _bodyshotColor = Color(0xFF8A99A8);
const _legshotColor = Color(0xFF3F4A54);

/// Head / body / leg shot split over the loaded matches, overall then weapon
/// by weapon.
class WeaponAccuracySection extends ConsumerWidget {
  const WeaponAccuracySection({super.key, required this.query});

  /// Weapons below this many recorded shots say more about noise than aim.
  static const _minimumShots = 5;
  static const _maximumWeapons = 8;

  final PlayerQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ProfileSection(
      title: 'Précision · $matchHistorySize dernières parties',
      child: ref
          .watch(weaponAccuracyProvider(query))
          .when(
            loading: () => const ProfileMessage.loading(text: 'Calcul des tirs…'),
            error: (error, _) => ProfileMessage(text: profileErrorText(error), icon: Icons.gps_off),
            data: _buildBody,
          ),
    );
  }

  Widget _buildBody(List<WeaponAccuracy> weapons) {
    final overall = WeaponAccuracy.overall(weapons);
    if (overall == null) {
      return const ProfileMessage(
        text: 'Aucun tir enregistré sur les parties chargées.',
        icon: Icons.gps_off,
      );
    }

    final detailed = weapons.where((weapon) => weapon.total >= _minimumShots).take(_maximumWeapons).toList();

    return Column(
      children: [
        _OverallCard(overall: overall),
        if (detailed.isNotEmpty) ...[
          const SizedBox(height: 8),
          ProfileCard(
            child: Column(
              children: [
                for (final (index, weapon) in detailed.indexed) ...[
                  if (index > 0) const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1)),
                  _WeaponRow(weapon: weapon),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _OverallCard extends StatelessWidget {
  const _OverallCard({required this.overall});

  final WeaponAccuracy overall;

  @override
  Widget build(BuildContext context) {
    return ProfileCard(
      accentColor: _headshotColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                overall.headshotPercent.toStringAsFixed(1),
                style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, height: 1),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 3, left: 2),
                child: Text('%', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _headshotColor)),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'DE TIRS À LA TÊTE',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white70, letterSpacing: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ShotBar(accuracy: overall),
          const SizedBox(height: 10),
          Row(
            children: [
              _Legend(color: _headshotColor, label: 'Tête', count: overall.headshots),
              const SizedBox(width: 14),
              _Legend(color: _bodyshotColor, label: 'Corps', count: overall.bodyshots),
              const SizedBox(width: 14),
              _Legend(color: _legshotColor, label: 'Jambes', count: overall.legshots),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeaponRow extends StatelessWidget {
  const _WeaponRow({required this.weapon});

  final WeaponAccuracy weapon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                weapon.weaponName.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, letterSpacing: 0.4),
              ),
            ),
            Text(
              '${weapon.headshotPercent.toStringAsFixed(1)} %',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: _headshotColor),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _ShotBar(accuracy: weapon),
        const SizedBox(height: 4),
        Text(
          '${weapon.total} tirs · ${weapon.matchCount} partie(s)',
          style: const TextStyle(fontSize: 10.5, color: AppTheme.valorantMuted),
        ),
      ],
    );
  }
}

class _ShotBar extends StatelessWidget {
  const _ShotBar({required this.accuracy});

  final WeaponAccuracy accuracy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 6,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final total = accuracy.total == 0 ? 1 : accuracy.total;

          return Row(
            children: [
              Container(width: width * accuracy.headshots / total, color: _headshotColor),
              Container(width: width * accuracy.bodyshots / total, color: _bodyshotColor),
              Container(width: width * accuracy.legshots / total, color: _legshotColor),
            ],
          );
        },
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label, required this.count});

  final Color color;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, color: color),
        const SizedBox(width: 5),
        Text(
          '$label $count',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white70),
        ),
      ],
    );
  }
}
