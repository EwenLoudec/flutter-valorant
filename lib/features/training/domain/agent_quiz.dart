import 'dart:math';

import '../../encyclopedia/domain/agent.dart';

/// What a question shows and what it asks for.
enum AgentQuestionKind {
  portrait('Quel est cet agent ?'),
  abilityIcon('Quelle est cette compétence ?'),
  abilityOwner('À quel agent appartient cette compétence ?'),
  abilityDescription('De quelle compétence parle cette description ?'),
  soundOwner('À quel agent appartient cette capacité ?'),
  abilitySound('Et quelle est cette capacité ?');

  const AgentQuestionKind(this.prompt);

  final String prompt;
}

/// One question: something to look at or listen to, and four answers.
class AgentQuestion {
  const AgentQuestion({
    required this.kind,
    required this.choices,
    required this.answer,
    this.imageUrl,
    this.soundUrl,
    this.text,
    this.subject,
  });

  final AgentQuestionKind kind;
  final List<String> choices;
  final String answer;

  /// Portrait or ability icon to display.
  final String? imageUrl;

  /// Official ability clip, played without its picture.
  final String? soundUrl;

  /// Official description, for the text question.
  final String? text;

  /// Who the question was about, shown when revealing the answer.
  final String? subject;

  String get prompt => kind.prompt;

  /// What the reveal is allowed to name. The listening pair asks which
  /// ability right after asking whose it is, so spelling it out on the first
  /// answer would hand the second one over.
  String? get revealSubject {
    if (kind != AgentQuestionKind.soundOwner) return subject;
    return subject?.split(' · ').first;
  }
}

/// A ten-question run mixing every kind of question.
class AgentQuizRound {
  const AgentQuizRound({required this.questions});

  static const pointsPerQuestion = 100;
  static const defaultQuestionCount = 10;

  /// Builds a run from the catalogue. [soundsByAgent] maps an agent uuid to
  /// its ability clips, keyed by the ability name in upper case.
  factory AgentQuizRound.create({
    required List<Agent> agents,
    Map<String, Map<String, String>> soundsByAgent = const {},
    int questionCount = defaultQuestionCount,
    Random? random,
  }) {
    final shuffler = random ?? Random();
    final playable = [for (final agent in agents) if (agent.displayIcon != null) agent];
    if (playable.length < 4) return const AgentQuizRound(questions: []);

    // A builder yields one question, or two for the sound pair.
    final builders = <List<AgentQuestion> Function()>[
      () => [?_portrait(playable, shuffler)],
      () => [?_abilityIcon(playable, shuffler)],
      () => [?_abilityOwner(playable, shuffler)],
      () => [?_abilityDescription(playable, shuffler)],
      () => _soundPair(playable, soundsByAgent, shuffler),
    ];

    final questions = <AgentQuestion>[];
    final seen = <String>{};

    // Round-robin over the kinds so a run never turns into ten portraits,
    // and never asks the same thing twice.
    for (var attempt = 0; questions.length < questionCount && attempt < questionCount * 12; attempt++) {
      final batch = builders[attempt % builders.length]();
      if (batch.isEmpty) continue;
      // The sound pair goes in whole or not at all: the second question
      // refers to the clip of the first.
      if (questions.length + batch.length > questionCount) continue;

      final signature = '${batch.first.kind.name}|${batch.first.answer}|${batch.first.subject}';
      if (!seen.add(signature)) continue;

      questions.addAll(batch);
    }

    return AgentQuizRound(questions: questions);
  }

  final List<AgentQuestion> questions;

  int get maxScore => questions.length * pointsPerQuestion;

  static AgentQuestion? _portrait(List<Agent> agents, Random shuffler) {
    final agent = agents[shuffler.nextInt(agents.length)];

    return AgentQuestion(
      kind: AgentQuestionKind.portrait,
      imageUrl: agent.fullPortrait ?? agent.displayIcon,
      choices: _choices(agent.displayName, [for (final other in agents) other.displayName], shuffler),
      answer: agent.displayName,
      subject: agent.displayName,
    );
  }

  static AgentQuestion? _abilityIcon(List<Agent> agents, Random shuffler) {
    final pick = _pickAbility(agents, shuffler, needsIcon: true);
    if (pick == null) return null;

    return AgentQuestion(
      kind: AgentQuestionKind.abilityIcon,
      imageUrl: pick.ability.displayIcon,
      choices: _choices(pick.ability.displayName, _abilityNames(agents), shuffler),
      answer: pick.ability.displayName,
      subject: '${pick.agent.displayName} · ${pick.ability.displayName}',
    );
  }

  static AgentQuestion? _abilityOwner(List<Agent> agents, Random shuffler) {
    final pick = _pickAbility(agents, shuffler, needsIcon: true);
    if (pick == null) return null;

    return AgentQuestion(
      kind: AgentQuestionKind.abilityOwner,
      imageUrl: pick.ability.displayIcon,
      choices: _choices(pick.agent.displayName, [for (final other in agents) other.displayName], shuffler),
      answer: pick.agent.displayName,
      subject: '${pick.agent.displayName} · ${pick.ability.displayName}',
    );
  }

  static AgentQuestion? _abilityDescription(List<Agent> agents, Random shuffler) {
    final pick = _pickAbility(agents, shuffler, needsDescription: true);
    if (pick == null) return null;

    return AgentQuestion(
      kind: AgentQuestionKind.abilityDescription,
      text: _hideNames(pick.ability.description, pick.ability.displayName, pick.agent.displayName),
      choices: _choices(pick.ability.displayName, _abilityNames(agents), shuffler),
      answer: pick.ability.displayName,
      subject: '${pick.agent.displayName} · ${pick.ability.displayName}',
    );
  }

  /// One clip, two questions in a row: whose ability is it, then which one.
  static List<AgentQuestion> _soundPair(
    List<Agent> agents,
    Map<String, Map<String, String>> soundsByAgent,
    Random shuffler,
  ) {
    if (soundsByAgent.isEmpty) return const [];

    // The clip map is keyed by the upper-cased ability name, and Riot renames
    // one now and then: keep only the agents whose clips still match an
    // ability, so a stale entry costs a clip and never the whole question.
    final playable = <Agent, Map<String, AgentAbility>>{};
    for (final agent in agents) {
      final sounds = soundsByAgent[agent.uuid];
      if (sounds == null) continue;

      final matched = {
        for (final ability in agent.abilities)
          if (sounds.containsKey(ability.displayName.toUpperCase())) ability.displayName.toUpperCase(): ability,
      };
      if (matched.isNotEmpty) playable[agent] = matched;
    }
    if (playable.isEmpty) return const [];

    final agent = playable.keys.elementAt(shuffler.nextInt(playable.length));
    final abilities = playable[agent]!;
    final name = abilities.keys.elementAt(shuffler.nextInt(abilities.length));
    final ability = abilities[name]!;

    final soundUrl = soundsByAgent[agent.uuid]![name];
    final subject = '${agent.displayName} · ${ability.displayName}';

    return [
      AgentQuestion(
        kind: AgentQuestionKind.soundOwner,
        soundUrl: soundUrl,
        choices: _choices(agent.displayName, [for (final other in agents) other.displayName], shuffler),
        answer: agent.displayName,
        subject: subject,
      ),
      AgentQuestion(
        kind: AgentQuestionKind.abilitySound,
        soundUrl: soundUrl,
        choices: _choices(ability.displayName, _abilityNames(agents), shuffler),
        answer: ability.displayName,
        subject: subject,
      ),
    ];
  }

  static ({Agent agent, AgentAbility ability})? _pickAbility(
    List<Agent> agents,
    Random shuffler, {
    bool needsIcon = false,
    bool needsDescription = false,
  }) {
    for (var attempt = 0; attempt < 20; attempt++) {
      final agent = agents[shuffler.nextInt(agents.length)];
      final abilities = [
        for (final ability in agent.abilities)
          if (ability.slot != 'Passive' &&
              (!needsIcon || ability.displayIcon != null) &&
              (!needsDescription || ability.description.length > 40))
            ability,
      ];
      if (abilities.isEmpty) continue;

      return (agent: agent, ability: abilities[shuffler.nextInt(abilities.length)]);
    }
    return null;
  }

  static List<String> _abilityNames(List<Agent> agents) {
    return [
      for (final agent in agents)
        for (final ability in agent.abilities)
          if (ability.slot != 'Passive') ability.displayName,
    ];
  }

  /// Four distinct options, the right one among them.
  static List<String> _choices(String answer, List<String> pool, Random shuffler) {
    final others = pool.toSet()..remove(answer);
    final decoys = others.toList()..shuffle(shuffler);

    return [answer, ...decoys.take(3)]..shuffle(shuffler);
  }

  /// Riot's descriptions sometimes spell the ability or the agent out — that
  /// would hand the answer over.
  static String _hideNames(String description, String abilityName, String agentName) {
    var text = description;
    for (final name in [abilityName, agentName]) {
      text = text.replaceAll(RegExp(RegExp.escape(name), caseSensitive: false), '…');
    }
    return text;
  }
}
