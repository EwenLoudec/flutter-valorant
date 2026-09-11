import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mybmw/features/encyclopedia/domain/agent.dart';
import 'package:mybmw/features/training/domain/agent_quiz.dart';

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

    test('enchaîne le propriétaire puis la capacité sur le même extrait', () {
      var pairs = 0;

      for (var seed = 0; seed < 12; seed++) {
        final questions = AgentQuizRound.create(
          agents: _roster(),
          soundsByAgent: _sounds(),
          random: Random(seed),
        ).questions;

        for (var index = 0; index < questions.length; index++) {
          final question = questions[index];
          if (question.kind != AgentQuestionKind.soundOwner) continue;

          pairs++;
          expect(index + 1, lessThan(questions.length), reason: 'la paire ne doit jamais être coupée');

          final next = questions[index + 1];
          expect(next.kind, AgentQuestionKind.abilitySound);
          expect(next.soundUrl, question.soundUrl, reason: 'les deux questions écoutent le même extrait');
          expect(next.subject, question.subject);

          // D'abord à qui, ensuite laquelle.
          expect(question.answer, question.subject!.split(' · ').first);
          expect(next.answer, question.subject!.split(' · ').last);
        }
      }

      expect(pairs, greaterThan(0));
    });

    test('ne vend pas la mèche en révélant le propriétaire', () {
      final round = AgentQuizRound.create(
        agents: _roster(),
        soundsByAgent: _sounds(),
        random: Random(1),
      );
      final owners = round.questions.where((q) => q.kind == AgentQuestionKind.soundOwner);

      expect(owners, isNotEmpty);
      for (final question in owners) {
        // La question suivante demande justement le nom de la capacité.
        expect(question.revealSubject, question.answer);
        expect(question.subject, isNot(question.revealSubject));
      }

      for (final question in round.questions.where((q) => q.kind != AgentQuestionKind.soundOwner)) {
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
}
