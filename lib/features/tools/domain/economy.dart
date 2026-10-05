import 'dart:math' as math;

/// The standard credit rules of a bomb-mode round.
abstract final class EconomyRules {
  static const maxCredits = 9000;
  static const startCredits = 800;
  static const winReward = 3000;
  static const killReward = 200;
  static const plantReward = 300;

  /// A rifle with heavy shields: the bar for a full buy.
  static const fullBuy = 3900;

  /// The loss bonus grows with the losing streak: 1 900, then 2 400, then
  /// 2 900 from the third loss in a row.
  static int lossReward(int consecutiveLosses) {
    if (consecutiveLosses <= 1) return 1900;
    if (consecutiveLosses == 2) return 2400;
    return 2900;
  }
}

/// What the player plans to buy this round, and what they expect from it.
class EconomyPlan {
  const EconomyPlan({
    required this.credits,
    this.weaponCost = 0,
    this.shieldCost = 0,
    this.utilityCost = 0,
    this.kills = 0,
    this.plantsSpike = false,
    this.lossesBefore = 0,
  });

  final int credits;
  final int weaponCost;
  final int shieldCost;
  final int utilityCost;

  /// Kills expected this round.
  final int kills;

  /// Attackers earn a bonus when the spike goes down, even on a lost round.
  final bool plantsSpike;

  /// Rounds lost in a row before this one.
  final int lossesBefore;

  int get spent => weaponCost + shieldCost + utilityCost;
  int get remaining => credits - spent;
  bool get isAffordable => remaining >= 0;

  int get _bonuses => kills * EconomyRules.killReward + (plantsSpike ? EconomyRules.plantReward : 0);

  /// Credits at the start of next round if this one is won.
  int get nextIfWin => _cap(math.max(remaining, 0) + EconomyRules.winReward + _bonuses);

  /// Credits at the start of next round if this one is lost — assuming the
  /// weapon is lost with it.
  int get nextIfLoss => _cap(math.max(remaining, 0) + EconomyRules.lossReward(lossesBefore + 1) + _bonuses);

  /// The most that can be spent now while keeping a full buy for next round
  /// even after a loss. Null when no saving makes it possible.
  int? get maxSpendKeepingFullBuy {
    final guaranteed = EconomyRules.lossReward(lossesBefore + 1) + _bonuses;
    final spendable = credits + guaranteed - EconomyRules.fullBuy;
    if (spendable < 0) return null;
    return math.min(spendable, credits);
  }

  static int _cap(int value) => math.min(value, EconomyRules.maxCredits);

  EconomyPlan copyWith({
    int? credits,
    int? weaponCost,
    int? shieldCost,
    int? utilityCost,
    int? kills,
    bool? plantsSpike,
    int? lossesBefore,
  }) {
    return EconomyPlan(
      credits: credits ?? this.credits,
      weaponCost: weaponCost ?? this.weaponCost,
      shieldCost: shieldCost ?? this.shieldCost,
      utilityCost: utilityCost ?? this.utilityCost,
      kills: kills ?? this.kills,
      plantsSpike: plantsSpike ?? this.plantsSpike,
      lossesBefore: lossesBefore ?? this.lossesBefore,
    );
  }
}
