import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/diagonal_cut_clipper.dart';
import '../../../core/widgets/fade_in_network_image.dart';
import '../../encyclopedia/domain/store_content.dart';
import '../../encyclopedia/domain/weapon.dart';
import '../../encyclopedia/presentation/weapons/weapon_category_style.dart';
import '../../encyclopedia/providers/encyclopedia_providers.dart';
import '../domain/economy.dart';

const _goodColor = Color(0xFF2FBF8F);

/// Buy-phase calculator: pick a weapon and a shield for the credits you have,
/// and see what is left for next round, win or lose.
class EconomyScreen extends ConsumerStatefulWidget {
  const EconomyScreen({super.key});

  @override
  ConsumerState<EconomyScreen> createState() => _EconomyScreenState();
}

class _EconomyScreenState extends ConsumerState<EconomyScreen> {
  EconomyPlan _plan = const EconomyPlan(credits: EconomyRules.startCredits);
  String? _weaponUuid;
  String? _gearUuid;

  void _update(EconomyPlan plan) => setState(() => _plan = plan);

  @override
  Widget build(BuildContext context) {
    final weapons = ref.watch(weaponsProvider).value ?? const <Weapon>[];
    final gear = ref.watch(gearProvider).value ?? const <Gear>[];
    final plan = _plan;

    return Scaffold(
      appBar: AppBar(title: const Text('ÉCONOMIE')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          _Panel(
            title: 'Tes crédits',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${plan.credits} ¤',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.valorantRed),
                ),
                Slider(
                  value: plan.credits.toDouble(),
                  max: EconomyRules.maxCredits.toDouble(),
                  divisions: EconomyRules.maxCredits ~/ 50,
                  activeColor: AppTheme.valorantRed,
                  label: '${plan.credits}',
                  onChanged: (value) => _update(plan.copyWith(credits: value.round())),
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final preset in const [800, 2000, 3900, 5000, 9000])
                      ActionChip(
                        label: Text('$preset'),
                        onPressed: () => _update(plan.copyWith(credits: preset)),
                        shape: const RoundedRectangleBorder(),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Panel(
            title: 'Arme',
            child: weapons.isEmpty
                ? const Text('Chargement des armes…', style: TextStyle(color: AppTheme.valorantMuted))
                : Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _Choice(
                        label: 'Aucune',
                        isSelected: _weaponUuid == null,
                        onTap: () => setState(() {
                          _weaponUuid = null;
                          _plan = plan.copyWith(weaponCost: 0);
                        }),
                      ),
                      for (final weapon in weapons)
                        if (weapon.cost > 0)
                          _Choice(
                            label: '${weapon.displayName} · ${weapon.cost}',
                            color: WeaponCategoryStyle.of(weapon.category).color,
                            isSelected: _weaponUuid == weapon.uuid,
                            onTap: () => setState(() {
                              _weaponUuid = weapon.uuid;
                              _plan = plan.copyWith(weaponCost: weapon.cost);
                            }),
                          ),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          _Panel(
            title: 'Bouclier',
            child: Column(
              children: [
                _GearRow(
                  name: 'Aucun',
                  description: 'Garder les crédits.',
                  cost: 0,
                  icon: null,
                  isSelected: _gearUuid == null,
                  onTap: () => setState(() {
                    _gearUuid = null;
                    _plan = plan.copyWith(shieldCost: 0);
                  }),
                ),
                for (final item in gear)
                  _GearRow(
                    name: item.displayName,
                    description: item.description,
                    cost: item.cost,
                    icon: item.displayIcon,
                    isSelected: _gearUuid == item.uuid,
                    onTap: () => setState(() {
                      _gearUuid = item.uuid;
                      _plan = plan.copyWith(shieldCost: item.cost);
                    }),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Panel(
            title: 'Utilitaire et round',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Compétences achetées : ${plan.utilityCost} ¤',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                Slider(
                  value: plan.utilityCost.toDouble(),
                  max: 1000,
                  divisions: 20,
                  activeColor: AppTheme.valorantRed,
                  label: '${plan.utilityCost}',
                  onChanged: (value) => _update(plan.copyWith(utilityCost: value.round())),
                ),
                _Stepper(
                  label: 'Kills prévus',
                  value: plan.kills,
                  max: 5,
                  onChanged: (value) => _update(plan.copyWith(kills: value)),
                ),
                _Stepper(
                  label: 'Manches perdues d\'affilée avant celle-ci',
                  value: plan.lossesBefore,
                  max: 4,
                  onChanged: (value) => _update(plan.copyWith(lossesBefore: value)),
                ),
                SwitchListTile(
                  value: plan.plantsSpike,
                  onChanged: (value) => _update(plan.copyWith(plantsSpike: value)),
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: AppTheme.valorantRed,
                  title: const Text('Spike posé (attaque)', style: TextStyle(fontSize: 12.5)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Summary(plan: plan),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.plan});

  final EconomyPlan plan;

  @override
  Widget build(BuildContext context) {
    final maxSpend = plan.maxSpendKeepingFullBuy;
    final isAffordable = plan.isAffordable;

    return ClipPath(
      clipper: const DiagonalCutClipper(cut: 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.valorantSurface,
          border: Border(left: BorderSide(color: isAffordable ? _goodColor : AppTheme.valorantRed, width: 3)),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isAffordable ? Icons.check_circle_outline : Icons.error_outline,
                  size: 18,
                  color: isAffordable ? _goodColor : AppTheme.valorantRed,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isAffordable
                        ? 'Achat possible : ${plan.spent} ¤ dépensés, ${plan.remaining} ¤ restants'
                        : 'Il manque ${-plan.remaining} ¤ pour cet achat',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _Projection(label: 'SI VICTOIRE', credits: plan.nextIfWin)),
                const SizedBox(width: 10),
                Expanded(child: _Projection(label: 'SI DÉFAITE', credits: plan.nextIfLoss)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              maxSpend == null
                  ? 'Même sans rien acheter, pas de full buy assuré au prochain round en cas de défaite.'
                  : 'Pour garder un full buy (${EconomyRules.fullBuy} ¤) même en cas de défaite, '
                        'dépense au plus $maxSpend ¤.',
              style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.4),
            ),
            const SizedBox(height: 8),
            const Text(
              'Règles standard : victoire 3 000, défaite 1 900 / 2 400 / 2 900 selon la série, '
              'kill 200, spike 300, plafond 9 000. Une défaite suppose que l\'arme est perdue.',
              style: TextStyle(fontSize: 10.5, color: AppTheme.valorantMuted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _Projection extends StatelessWidget {
  const _Projection({required this.label, required this.credits});

  final String label;
  final int credits;

  @override
  Widget build(BuildContext context) {
    final isFullBuy = credits >= EconomyRules.fullBuy;

    return Container(
      padding: const EdgeInsets.all(10),
      color: Colors.black26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppTheme.valorantMuted),
          ),
          const SizedBox(height: 4),
          Text('$credits ¤', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(
            isFullBuy ? 'Full buy' : 'Pas de full buy',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: isFullBuy ? _goodColor : AppTheme.valorantRed,
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 3, height: 14, color: AppTheme.valorantRed),
            const SizedBox(width: 8),
            Text(
              title.toUpperCase(),
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, letterSpacing: 0.8),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({required this.label, required this.isSelected, required this.onTap, this.color = Colors.white70});

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.04),
          border: Border.all(color: isSelected ? color : Colors.white24),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : Colors.white70,
          ),
        ),
      ),
    );
  }
}

class _GearRow extends StatelessWidget {
  const _GearRow({
    required this.name,
    required this.description,
    required this.cost,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String name;
  final String description;
  final int cost;
  final String? icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = this.icon;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.valorantRed.withValues(alpha: 0.12) : AppTheme.valorantSurface,
            border: Border.all(color: isSelected ? AppTheme.valorantRed : AppTheme.outlineDark),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 34,
                height: 34,
                child: icon == null
                    ? const Icon(Icons.shield_outlined, color: Colors.white24)
                    : FadeInNetworkImage(url: icon, fit: BoxFit.contain),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                    if (description.isNotEmpty)
                      Text(
                        description,
                        style: const TextStyle(fontSize: 10.5, color: AppTheme.valorantMuted, height: 1.35),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text('$cost ¤', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.label, required this.value, required this.max, required this.onChanged});

  final String label;
  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 12.5))),
        IconButton(
          tooltip: 'Moins',
          onPressed: value > 0 ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline, size: 20),
        ),
        SizedBox(
          width: 24,
          child: Text('$value', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900)),
        ),
        IconButton(
          tooltip: 'Plus',
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_circle_outline, size: 20),
        ),
      ],
    );
  }
}
