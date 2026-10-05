import 'dart:math';

import '../../encyclopedia/domain/agent.dart';
import '../../encyclopedia/domain/rank_tier.dart';
import '../../encyclopedia/domain/weapon.dart';
import 'agent_quiz.dart';
import 'daily_challenge.dart';

/// Multiple-choice runs on the rest of the catalogue: weapons, ranks, and the
/// daily challenge mixing everything. They reuse the agent quiz's question
/// shape and screen.
abstract final class CatalogQuiz {
  static const questionCount = 10;

  /// Weapons recognised by their silhouette, or by one of their skins.
  static AgentQuizRound weapons({
    required List<Weapon> weapons,
    int count = questionCount,
    Random? random,
  }) {
    final shuffler = random ?? Random();
    final playable = [for (final weapon in weapons) if (weapon.displayIcon != null) weapon];
    if (playable.length < 4) return const AgentQuizRound(questions: []);

    final names = [for (final weapon in playable) weapon.displayName];
    final withSkins = [for (final weapon in playable) if (weapon.skinPreviews.isNotEmpty) weapon];

    final questions = <AgentQuestion>[];
    final seen = <String>{};
    for (var attempt = 0; questions.length < count && attempt < count * 12; attempt++) {
      final askSkin = attempt.isOdd && withSkins.isNotEmpty;
      final AgentQuestion question;
      if (askSkin) {
        final weapon = withSkins[shuffler.nextInt(withSkins.length)];
        final skin = weapon.skinPreviews[shuffler.nextInt(weapon.skinPreviews.length)];
        question = AgentQuestion(
          kind: AgentQuestionKind.weaponSkin,
          imageUrl: skin.displayIcon,
          choices: AgentQuizRound.choicesFor(weapon.displayName, names, shuffler),
          answer: weapon.displayName,
          subject: skin.displayName,
        );
      } else {
        final weapon = playable[shuffler.nextInt(playable.length)];
        question = AgentQuestion(
          kind: AgentQuestionKind.weaponSilhouette,
          imageUrl: weapon.displayIcon,
          choices: AgentQuizRound.choicesFor(weapon.displayName, names, shuffler),
          answer: weapon.displayName,
          subject: weapon.displayName,
        );
      }
      if (seen.add('${question.kind.name}|${question.subject}')) questions.add(question);
    }
    return AgentQuizRound(questions: questions);
  }

  /// Ranks recognised by their emblem.
  static AgentQuizRound ranks({
    required List<RankTier> tiers,
    int count = questionCount,
    Random? random,
  }) {
    final shuffler = random ?? Random();
    final playable = <String, RankTier>{
      for (final tier in tiers)
        if (tier.largeIcon != null && tier.tierName.isNotEmpty) tier.tierName: tier,
    };
    if (playable.length < 4) return const AgentQuizRound(questions: []);

    final names = playable.keys.toList();
    final picked = [...playable.values]..shuffle(shuffler);

    return AgentQuizRound(
      questions: [
        for (final tier in picked.take(count))
          AgentQuestion(
            kind: AgentQuestionKind.rankIcon,
            imageUrl: tier.largeIcon,
            choices: AgentQuizRound.choicesFor(tier.tierName, names, shuffler),
            answer: tier.tierName,
            subject: tier.tierName,
          ),
      ],
    );
  }

  /// The day's ten questions: agents first (the listening pair has to stay
  /// together), then weapons and ranks. The draw only depends on [date].
  static AgentQuizRound daily({
    required DateTime date,
    required List<Agent> agents,
    required List<Weapon> weapons,
    required List<RankTier> tiers,
    Map<String, Map<String, String>> soundsByAgent = const {},
  }) {
    final random = DailyChallenge.randomFor(date);

    final weaponRound = CatalogQuiz.weapons(weapons: weapons, count: 2, random: random);
    final rankRound = CatalogQuiz.ranks(tiers: tiers, count: 2, random: random);
    final agentCount = DailyChallenge.questionCount - weaponRound.questions.length - rankRound.questions.length;
    final agentRound = AgentQuizRound.create(
      agents: agents,
      soundsByAgent: soundsByAgent,
      questionCount: agentCount,
      random: random,
    );

    return AgentQuizRound(
      questions: [...agentRound.questions, ...weaponRound.questions, ...rankRound.questions],
    );
  }
}
