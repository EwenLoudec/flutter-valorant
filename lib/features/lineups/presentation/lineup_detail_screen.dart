import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/lineup.dart';
import '../domain/lineup_media.dart';
import '../domain/resolved_lineup.dart';
import '../providers/lineups_providers.dart';
import 'lineup_demo_player.dart';
import 'lineup_editor_screen.dart';
import 'lineup_map_painter.dart';
import 'lineup_map_view.dart';
import 'lineup_steps.dart';
import 'lineup_zoom_view.dart';
import 'lineup_visuals.dart';

/// One spot, read like a guide: the trajectory on the plan, then where to
/// stand, what to aim at, how to throw, and what it gives.
class LineupDetailScreen extends ConsumerWidget {
  const LineupDetailScreen({super.key, required this.mapName, required this.lineupId});

  final String mapName;
  final String lineupId;

  ResolvedLineup? _find(List<ResolvedLineup> lineups) {
    for (final entry in lineups) {
      if (entry.lineup.id == lineupId) return entry;
    }
    return null;
  }

  Future<void> _edit(BuildContext context, Lineup lineup, {required bool asCopy}) async {
    final savedId = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => LineupEditorScreen(mapName: mapName, initial: lineup, asCopy: asCopy),
      ),
    );
    if (asCopy && savedId != null && context.mounted) Navigator.of(context).pop();
  }

  Future<void> _open(BuildContext context, Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir le lien.')),
      );
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Lineup lineup) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.valorantSurface,
        title: const Text('Supprimer ce spot ?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: Text('« ${lineup.title} » sera retiré de tes spots.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.valorantRed),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(lineupsProvider.notifier).delete(lineup.id);
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final map = ref.watch(gameMapByNameProvider(mapName));
    final resolved = _find(ref.watch(resolvedLineupsProvider(mapName)));

    if (map == null || resolved == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('SPOT')),
        body: const Center(child: Text('Ce spot n\'existe plus.')),
      );
    }

    final lineup = resolved.lineup;
    final target = lineup.to;
    final demoUrl = lineup.demoUrl;

    return Scaffold(
      appBar: AppBar(
        title: Text(lineup.title.toUpperCase()),
        actions: [
          if (!lineup.isBundled)
            IconButton(
              tooltip: 'Supprimer',
              onPressed: () => _delete(context, ref, lineup),
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          LineupMapView(map: map, lineups: [resolved], selectedId: lineup.id),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LineupAbilityBadge(lineup: lineup, size: 52),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${lineup.agentName} · ${lineup.abilityName}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      target == null
                          ? 'À poser : ${lineup.from.label}'
                          : 'Depuis ${lineup.from.label} → ${target.label}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.valorantMuted),
                    ),
                    const SizedBox(height: 8),
                    Wrap(spacing: 6, runSpacing: 6, children: lineupTags(lineup)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LineupAbilityCard(lineup: lineup),
          const SizedBox(height: 14),
          LineupCompleteness(
            lineup: lineup,
            onComplete: () => _edit(context, lineup, asCopy: lineup.isBundled),
          ),
          const SizedBox(height: 20),
          const _SectionTitle('La lineup pas à pas'),
          const SizedBox(height: 12),
          LineupStep(
            index: 1,
            title: LineupMediaRole.position.label,
            body: lineup.position,
            emptyHint: 'Position exacte pas encore notée. Le zoom ci-dessous donne le coin de '
                'carte ; ajoute ta capture pour la position au pas près.',
            media: lineup.mediaFor(LineupMediaRole.position),
            fallback: LineupZoomView(
              map: map,
              focus: resolved.from,
              other: resolved.to,
              color: lineupSideColor(lineup.side),
              label: 'Départ · ${lineup.from.label}',
              isTarget: false,
            ),
          ),
          LineupStep(
            index: 2,
            title: LineupMediaRole.aim.label,
            body: lineup.aim,
            emptyHint: target == null
                ? 'Rien à viser : cet utilitaire se pose sur place.'
                : 'Point de visée pas encore noté : ajoute le repère et la capture.',
            media: lineup.mediaFor(LineupMediaRole.aim),
            fallback: resolved.to == null
                ? null
                : LineupZoomView(
                    map: map,
                    focus: resolved.to!,
                    other: resolved.from,
                    color: lineupSideColor(lineup.side),
                    label: 'Cible · ${target?.label ?? ''}',
                    isTarget: true,
                  ),
          ),
          LineupStep(
            index: 3,
            title: 'Lancer',
            body: lineup.throwStyle.isSpecified
                ? '${lineup.throwStyle.label}${lineup.throwStyle.hint.isEmpty ? '' : ' — ${lineup.throwStyle.hint}'}'
                : '',
            emptyHint: 'Type de lancer à préciser (simple, clic droit, saut-lancer…).',
            media: null,
          ),
          LineupStep(
            index: 4,
            title: 'Résultat',
            body: lineup.mediaFor(LineupMediaRole.result) != null || lineup.mediaFor(LineupMediaRole.demo) != null
                ? 'Ce que donne le lancer :'
                : '',
            emptyHint: 'Aucune photo ni vidéo du résultat pour l\'instant.',
            media: lineup.mediaFor(LineupMediaRole.result) ?? lineup.mediaFor(LineupMediaRole.demo),
          ),
          if (lineup.description.isNotEmpty) ...[
            const _SectionTitle('Notes'),
            const SizedBox(height: 8),
            Text(lineup.description, style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.white70)),
            const SizedBox(height: 20),
          ],
          const _SectionTitle('Voir le lancer'),
          const SizedBox(height: 10),
          if (demoUrl != null) ...[
            LineupDemoPlayer(url: demoUrl, title: lineup.demoTitle),
            const SizedBox(height: 6),
            const Text(
              'Vidéo de la communauté, lue ici via le lecteur YouTube. Elle couvre cet agent '
              '— parfois plusieurs cartes : repère le lancer qui correspond à ce spot, puis '
              'épingle ta propre vidéo si tu en trouves une plus précise.',
              style: TextStyle(fontSize: 11, color: AppTheme.valorantMuted, height: 1.4),
            ),
            const SizedBox(height: 10),
            _ActionButton(
              icon: Icons.open_in_new,
              label: 'OUVRIR SUR YOUTUBE',
              isSecondary: true,
              onPressed: () => _open(context, Uri.parse(demoUrl)),
            ),
            const SizedBox(height: 8),
          ],
          _ActionButton(
            icon: Icons.search,
            label: 'CHERCHER DES DÉMOS VIDÉO',
            isSecondary: true,
            onPressed: () => _open(context, lineup.demoSearchUri),
          ),
          const SizedBox(height: 8),
          _ActionButton(
            icon: Icons.travel_explore,
            label: 'LINEUPS DE ${lineup.mapName.toUpperCase()} EN LIGNE',
            isSecondary: true,
            onPressed: () => _open(context, lineup.mapLineupsUri),
          ),
          const SizedBox(height: 6),
          const Text(
            'Les visuels des guides existants appartiennent à leurs auteurs : l\'app t\'y '
            'emmène plutôt que de les recopier. Épingle la bonne vidéo dans la fiche, ou '
            'ajoute tes propres captures depuis la galerie.',
            style: TextStyle(fontSize: 11, color: AppTheme.valorantMuted, height: 1.4),
          ),
          const SizedBox(height: 22),
          if (lineup.isBundled)
            _ActionButton(
              icon: Icons.copy_all_outlined,
              label: 'DUPLIQUER ET COMPLÉTER',
              onPressed: () => _edit(context, lineup, asCopy: true),
            )
          else
            _ActionButton(
              icon: Icons.edit_outlined,
              label: 'MODIFIER CE SPOT',
              onPressed: () => _edit(context, lineup, asCopy: false),
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 3, height: 14, color: AppTheme.valorantRed),
        const SizedBox(width: 8),
        Text(
          text.toUpperCase(),
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, letterSpacing: 0.8),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isSecondary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isSecondary;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5, fontSize: isSecondary ? 12 : 13);

    if (isSecondary) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white70,
          side: const BorderSide(color: AppTheme.outlineDark),
          shape: const RoundedRectangleBorder(),
          padding: const EdgeInsets.symmetric(vertical: 13),
        ),
        icon: Icon(icon, size: 18),
        label: Text(label, style: style),
      );
    }

    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppTheme.valorantRed,
        foregroundColor: Colors.white,
        shape: const RoundedRectangleBorder(),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label, style: style),
    );
  }
}
