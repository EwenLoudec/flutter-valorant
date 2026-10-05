import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:valorant_companion/features/encyclopedia/domain/agent.dart';
import 'package:valorant_companion/features/training/domain/agent_quiz.dart';

Agent _agent(String name, {bool withIcons = true}) {
  return Agent(
    uuid: 'uuid-$name',
    displayName: name,
    description: 'Description de $name',
    roleName: 'Duelliste',
    displayIcon: 'https://example.test/$name.png',
    fullPortrait: 'https://example.test/$name-full.png',
    backgroundGradientColors: const [],
    abilities: [
      for (final slot in ['Ability1', 'Ability2', 'Grenade', 'Ultimate'])
        AgentAbility(
          slot: slot,
          displayName: '$name $slot',
          description: 'ÉQUIPEZ-vous de $name $slot puis TIREZ pour déclencher un effet redoutable.',
          displayIcon: withIcons ? 'https://example.test/$name-$slot.png' : null,
        ),
      const AgentAbility(slot: 'Passive', displayName: 'Passif', description: 'Toujours actif'),
    ],
  );
}

List<Agent> _roster() => [for (final name in ['Sova', 'Viper', 'Jett', 'Omen', 'Sage', 'Raze']) _agent(name)];

Map<String, Map<String, String>> _sounds() => {
  'uuid-Sova': {'SOVA ABILITY2': 'https://example.test/sova.mp4'},
  'uuid-Viper': {'VIPER GRENADE': 'https://example.test/viper.mp4'},
};

/// Every ability of every agent has a clip.
Map<String, Map<String, String>> _manySounds() => {
  for (final agent in _roster())
    agent.uuid: {
      for (final ability in agent.abilities) ability.displayName.toUpperCase(): 'https://example.test/${ability.displayName}.mp4',
    },
};

void main() {
  group('AgentQuizRound.create', () {
    test('pose dix questions, quatre choix chacune, la bonne dedans', () {
      final round = AgentQuizRound.create(
        agents: _roster(),
        soundsByAgent: _sounds(),
        random: Random(1),
      );

      expect(round.questions, hasLength(AgentQuizRound.defaultQuestionCount));
      expect(round.maxScore, 1000);

      for (final question in round.questions) {
        expect(question.choices, hasLength(4));
        expect(question.choices, contains(question.answer));
        expect(question.choices.toSet().length, 4, reason: 'pas deux fois la même proposition');
      }
    });

    test('mélange les types de questions', () {
      final round = AgentQuizRound.create(
        agents: _roster(),
        soundsByAgent: _sounds(),
        random: Random(2),
      );
      final kinds = {for (final question in round.questions) question.kind};

      expect(kinds.length, greaterThanOrEqualTo(4));
      expect(kinds, contains(AgentQuestionKind.abilitySound));
    });

    test('ne repose jamais deux fois la même question', () {
      final round = AgentQuizRound.create(
        agents: _roster(),
        soundsByAgent: _sounds(),
        random: Random(3),
      );
      final signatures = [
        for (final question in round.questions) '${question.kind.name}|${question.answer}|${question.subject}',
      ];

      expect(signatures.toSet().length, signatures.length);
    });

    test('varie d\'une partie à l\'autre', () {
      final draws = <String>{};

      for (var seed = 0; seed < 10; seed++) {
        final round = AgentQuizRound.create(
          agents: _roster(),
          soundsByAgent: _sounds(),
          random: Random(seed),
        );
        draws.add([for (final question in round.questions) '${question.kind.name}:${question.answer}'].join('/'));
      }

      expect(draws.length, greaterThan(5));
    });

    test('masque le nom de la compétence dans sa description', () {
      final round = AgentQuizRound.create(
        agents: _roster(),
        soundsByAgent: const {},
        random: Random(4),
      );
      final described = round.questions.where((q) => q.kind == AgentQuestionKind.abilityDescription);

      expect(described, isNotEmpty);
      for (final question in described) {
        expect(
          question.text!.toLowerCase(),
          isNot(contains(question.answer.toLowerCase())),
          reason: 'la description ne doit pas donner la réponse',
        );
      }
    });

    test('se passe des sons quand il n\'y en a pas', () {
      final round = AgentQuizRound.create(
        agents: _roster(),
        random: Random(5),
      );
      final kinds = {for (final question in round.questions) question.kind};

      expect(round.questions, hasLength(AgentQuizRound.defaultQuestionCount));
      expect(kinds, isNot(contains(AgentQuestionKind.soundOwner)));
      expect(kinds, isNot(contains(AgentQuestionKind.abilitySound)));
    });

    test('joue un nouvel extrait à chaque question sonore, jamais deux fois le même', () {
      var heard = 0;
      final kinds = <AgentQuestionKind>{};

      for (var seed = 0; seed < 12; seed++) {
        final questions = AgentQuizRound.create(
          agents: _roster(),
          soundsByAgent: _manySounds(),
          random: Random(seed),
        ).questions;
        final clips = [
          for (final question in questions)
            if (question.soundUrl != null) question.soundUrl!,
        ];

        heard += clips.length;
        expect(clips.toSet(), hasLength(clips.length), reason: 'un extrait déjà joué ne revient pas');
        for (final question in questions.where((q) => q.soundUrl != null)) {
          kinds.add(question.kind);
          final [agent, ability] = question.subject!.split(' · ');
          expect(question.answer, question.kind == AgentQuestionKind.soundOwner ? agent : ability);
        }
      }

      expect(heard, greaterThan(12));
      expect(kinds, {AgentQuestionKind.soundOwner, AgentQuestionKind.abilitySound});
    });

    test('s\'arrête de poser des questions sonores quand les extraits sont épuisés', () {
      final round = AgentQuizRound.create(
        agents: _roster(),
        soundsByAgent: {
          'uuid-Sova': {'SOVA ABILITY2': 'https://example.test/sova.mp4'},
        },
        random: Random(4),
      );
      final clips = round.questions.where((q) => q.soundUrl != null);

      expect(round.questions, hasLength(AgentQuizRound.defaultQuestionCount));
      expect(clips, hasLength(1));
    });

    test('révèle l\'agent et la capacité après la réponse', () {
      final round = AgentQuizRound.create(
        agents: _roster(),
        soundsByAgent: _sounds(),
        random: Random(1),
      );

      for (final question in round.questions) {
        expect(question.revealSubject, question.subject);
      }
    });

    test('ignore un extrait dont la compétence a été renommée', () {
      final round = AgentQuizRound.create(
        agents: _roster(),
        soundsByAgent: {
          // Un nom que plus aucune compétence ne porte : la manche sonore doit
          // se rabattre sur les extraits encore valides, pas disparaître.
          'uuid-Jett': {'ANCIEN NOM': 'https://example.test/perime.mp4'},
          ..._sounds(),
        },
        random: Random(0),
      );
      final heard = round.questions.where((q) => q.kind == AgentQuestionKind.soundOwner);

      expect(heard, isNotEmpty);
      for (final question in heard) {
        expect(question.soundUrl, isNot('https://example.test/perime.mp4'));
      }
    });

    test('fait écouter un extrait, sans rien montrer', () {
      final round = AgentQuizRound.create(
        agents: _roster(),
        soundsByAgent: _sounds(),
        random: Random(7),
      );
      final heard = round.questions.where(
        (q) => q.kind == AgentQuestionKind.soundOwner || q.kind == AgentQuestionKind.abilitySound,
      );

      expect(heard, isNotEmpty);
      for (final question in heard) {
        expect(question.soundUrl, isNotNull);
        expect(question.imageUrl, isNull, reason: 'la réponse doit venir de l\'oreille');
      }
    });

    test('renonce si le roster est trop maigre', () {
      final round = AgentQuizRound.create(agents: [_agent('Sova')], random: Random(6));

      expect(round.questions, isEmpty);
      expect(round.maxScore, 0);
    });
  });
  group('soundKey', () {
    test('ignore les accents, le préfixe de touche et le pluriel', () {
      expect(soundKey('Évolution'), soundKey('EVOLUTION'));
      expect(soundKey('Transfert dimensionnel'), soundKey('X - TRANSFERT DIMENSIONNEL'));
      expect(soundKey('Ronces barbelées'), soundKey('RONCE BARBELÉE'));
      expect(soundKey("Jardin d’acier"), soundKey("JARDIN D'ACIER"));
      expect(soundKey('M-Pulsion'), 'M-PULSION');
      expect(soundKey('Vortex'), isNot(soundKey('Intercepteur')));
    });

    test('un extrait renommé par Riot reste joué', () {
      final round = AgentQuizRound.create(
        agents: _roster(),
        soundsByAgent: {
          'uuid-Sova': {'X - SOVA ULTIMATES': 'https://example.test/renomme.mp4'},
        },
        random: Random(3),
      );
      final heard = round.questions.where((q) => q.soundUrl != null).toList();
      expect(heard, hasLength(1));
      expect(heard.single.soundUrl, 'https://example.test/renomme.mp4');
      expect(heard.single.subject, 'Sova · Sova Ultimate');
    });
  });

  test('chaque extrait du jeu de données a une piste lisible', () async {
    final data = jsonDecode(File('assets/data/ability_sounds.json').readAsStringSync()) as Map<String, dynamic>;
    for (final clips in data.values) {
      for (final entry in (clips as Map<String, dynamic>).entries) {
        expect(entry.key, isNot(matches(RegExp(r'^[A-Z] - '))), reason: 'clé sans préfixe de touche');
        expect(Uri.parse(entry.value as String).scheme, 'https');
      }
    }
  });
}
