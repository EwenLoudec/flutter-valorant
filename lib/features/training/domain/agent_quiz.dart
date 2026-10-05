import 'dart:math';

import '../../encyclopedia/domain/agent.dart';

/// What a question shows and what it asks for.
enum AgentQuestionKind {
  portrait('Quel est cet agent ?'),
  abilityIcon('Quelle est cette compétence ?'),
  abilityOwner('À quel agent appartient cette compétence ?'),
  abilityDescription('De quelle compétence parle cette description ?'),
  soundOwner('À quel agent appartient ce son ?'),
  abilitySound('Quelle capacité entends-tu ?'),
  weaponSilhouette('Quelle est cette arme ?'),
  weaponSkin('À quelle arme appartient ce skin ?'),
  rankIcon('Quel est ce rang ?');

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

  /// What the reveal names once answered. Each clip is played only once in a
  /// run, so naming the agent and the ability gives nothing away.
  String? get revealSubject => subject;
}

const _accents = {
  'À': 'A', 'Â': 'A', 'Ä': 'A', 'Ç': 'C', 'É': 'E', 'È': 'E', 'Ê': 'E', 'Ë': 'E', //
  'Î': 'I', 'Ï': 'I', 'Ô': 'O', 'Ö': 'O', 'Ù': 'U', 'Û': 'U', 'Ü': 'U', 'Œ': 'OE',
};

/// The form an ability name and a clip key are compared in: upper case,
/// without accents, without a key prefix such as "X - ", and without the
/// plural s, so "X - Ronce barbelée" finds "Ronces barbelées".
String soundKey(String name) {
  final plain = name.toUpperCase().split('').map((letter) => _accents[letter] ?? letter).join();
  return plain
      .replaceFirst(RegExp(r'^[A-Z]\s*-\s+'), '')
      .replaceAll(RegExp('[’`]'), "'")
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .map((word) => word.length > 3 && word.endsWith('S') ? word.substring(0, word.length - 1) : word)
      .join(' ');
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

    final clipsByAgent = _playableClips(playable, soundsByAgent);
    // Every listening question plays its own clip: never twice the same one
    // in a run.
    final playedClips = <String>{};

    final builders = <AgentQuestion? Function()>[
      () => _portrait(playable, shuffler),
      () => _abilityIcon(playable, shuffler),
      () => _soundQuestion(AgentQuestionKind.soundOwner, playable, clipsByAgent, playedClips, shuffler),
      () => _abilityOwner(playable, shuffler),
      () => _abilityDescription(playable, shuffler),
      () => _soundQuestion(AgentQuestionKind.abilitySound, playable, clipsByAgent, playedClips, shuffler),
    ];

    final questions = <AgentQuestion>[];
    final seen = <String>{};

    // Round-robin over the kinds so a run never turns into ten portraits,
    // and never asks the same thing twice.
    for (var attempt = 0; questions.length < questionCount && attempt < questionCount * 12; attempt++) {
      final question = builders[attempt % builders.length]();
      if (question == null) continue;

      final signature = '${question.kind.name}|${question.answer}|${question.subject}';
      if (!seen.add(signature)) continue;

      final soundUrl = question.soundUrl;
      if (soundUrl != null) playedClips.add(soundUrl);
      questions.add(question);
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

  /// The clips of each agent that still match one of its abilities. The clip
  /// map is keyed by the upper-cased ability name, and Riot renames one now
  /// and then; names are compared loosely (accents, a key prefix, plurals),
  /// so a stale entry costs a clip and never the whole question.
  static Map<Agent, Map<AgentAbility, String>> _playableClips(
    List<Agent> agents,
    Map<String, Map<String, String>> soundsByAgent,
  ) {
    final playable = <Agent, Map<AgentAbility, String>>{};
    for (final agent in agents) {
      final sounds = soundsByAgent[agent.uuid];
      if (sounds == null) continue;

      final byKey = {for (final clip in sounds.entries) soundKey(clip.key): clip.value};
      final matched = <AgentAbility, String>{};
      for (final ability in agent.abilities) {
        final url = byKey[soundKey(ability.displayName)];
        if (url != null) matched[ability] = url;
      }
      if (matched.isNotEmpty) playable[agent] = matched;
    }
    return playable;
  }

  /// A listening question on a clip the run has not played yet: whose
  /// ability it is, or which ability it is.
  static AgentQuestion? _soundQuestion(
    AgentQuestionKind kind,
    List<Agent> agents,
    Map<Agent, Map<AgentAbility, String>> clipsByAgent,
    Set<String> playedClips,
    Random shuffler,
  ) {
    final fresh = [
      for (final MapEntry(key: agent, value: clips) in clipsByAgent.entries)
        for (final MapEntry(key: ability, value: url) in clips.entries)
          if (!playedClips.contains(url)) (agent: agent, ability: ability, url: url),
    ];
    if (fresh.isEmpty) return null;

    final pick = fresh[shuffler.nextInt(fresh.length)];
    final isOwner = kind == AgentQuestionKind.soundOwner;
    final answer = isOwner ? pick.agent.displayName : pick.ability.displayName;

    return AgentQuestion(
      kind: kind,
      soundUrl: pick.url,
      choices: isOwner
          ? _choices(answer, [for (final other in agents) other.displayName], shuffler)
          : _choices(answer, _abilityNames(agents), shuffler),
      answer: answer,
      subject: '${pick.agent.displayName} · ${pick.ability.displayName}',
    );
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

  /// Four distinct options, the right one among them — shared with the other
  /// catalogue quizzes.
  static List<String> choicesFor(String answer, List<String> pool, Random shuffler) =>
      _choices(answer, pool, shuffler);

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
