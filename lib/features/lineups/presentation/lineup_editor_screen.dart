import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/valorant_input.dart';
import '../../encyclopedia/domain/game_map.dart';
import '../domain/lineup.dart';
import '../domain/lineup_media.dart';
import '../domain/resolved_lineup.dart';
import '../providers/lineups_providers.dart';
import 'ability_picker_sheet.dart';
import 'lineup_map_painter.dart';
import 'lineup_map_view.dart';
import 'lineup_media_field.dart';
import 'lineup_visuals.dart';

/// Places a spot by tapping the plan: first the throwing position, then the
/// target. Saving returns the spot's id to the caller.
class LineupEditorScreen extends ConsumerStatefulWidget {
  const LineupEditorScreen({super.key, required this.mapName, this.initial, this.asCopy = false});

  final String mapName;

  /// The spot being edited, or the bundled spot being duplicated.
  final Lineup? initial;
  final bool asCopy;

  @override
  ConsumerState<LineupEditorScreen> createState() => _LineupEditorScreenState();
}

class _LineupEditorScreenState extends ConsumerState<LineupEditorScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _positionController = TextEditingController();
  final _aimController = TextEditingController();
  final _demoUrlController = TextEditingController();

  late final String _draftId = widget.initial == null || widget.asCopy
      ? 'user-${DateTime.now().microsecondsSinceEpoch}'
      : widget.initial!.id;

  Offset? _from;
  Offset? _to;
  bool _isThrow = true;
  bool _isPlacingTarget = false;
  String? _agentName;
  String? _abilitySlot;
  String? _abilityName;
  LineupSide _side = LineupSide.attack;
  LineupDifficulty _difficulty = LineupDifficulty.medium;
  LineupThrow _throwStyle = LineupThrow.unspecified;
  List<LineupMedia> _media = const [];
  bool _isVerified = false;
  bool _isPrefilled = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _positionController.dispose();
    _aimController.dispose();
    _demoUrlController.dispose();
    super.dispose();
  }

  /// Turns the spot being edited into editable points — a bundled draft
  /// anchored on a callout becomes two movable points.
  void _prefill(GameMap map) {
    if (_isPrefilled) return;
    _isPrefilled = true;

    final initial = widget.initial;
    if (initial == null) return;

    final resolved = ResolvedLineup.resolve(initial, map);
    _from = resolved?.from;
    _to = resolved?.to;
    _isThrow = initial.isThrow;
    _agentName = initial.agentName;
    _abilitySlot = initial.abilitySlot;
    _abilityName = initial.abilityName;
    _side = initial.side;
    _difficulty = initial.difficulty;
    _throwStyle = initial.throwStyle;
    _isVerified = widget.asCopy ? false : initial.isVerified;
    // A copy starts without the original's files: they live under the id of
    // the spot they were attached to.
    _media = widget.asCopy ? const [] : initial.media;
    _titleController.text = widget.asCopy ? '${initial.title} (copie)' : initial.title;
    _descriptionController.text = initial.description;
    _positionController.text = initial.position;
    _aimController.text = initial.aim;
    _demoUrlController.text = initial.demoUrl ?? '';
  }

  Future<void> _pickMedia(LineupMediaRole role, LineupMediaKind kind) async {
    final store = ref.read(lineupMediaStoreProvider);
    if (!store.isSupported) {
      _warn('Les photos et vidéos s\'ajoutent depuis l\'app mobile.');
      return;
    }

    final picked = await store.pick(lineupId: _draftId, role: role, kind: kind);
    if (picked == null || !mounted) return;

    setState(() {
      _media = [
        for (final entry in _media)
          if (entry.role != role) entry,
        picked,
      ];
    });
  }

  void _removeMedia(LineupMediaRole role) {
    setState(() {
      _media = [
        for (final entry in _media)
          if (entry.role != role) entry,
      ];
    });
  }

  LineupMedia? _mediaFor(LineupMediaRole role) {
    for (final entry in _media) {
      if (entry.role == role) return entry;
    }
    return null;
  }

  void _placePoint(Offset position) {
    setState(() {
      if (_isThrow && _isPlacingTarget) {
        _to = position;
        return;
      }
      _from = position;
      // Chain naturally into placing the target on a fresh throw.
      if (_isThrow && _to == null) _isPlacingTarget = true;
    });
  }

  Future<void> _pickAbility() async {
    final choice = await showAbilityPicker(context, initialAgentName: _agentName);
    if (choice == null) return;

    setState(() {
      _agentName = choice.agent.displayName;
      _abilitySlot = choice.ability.slot;
      _abilityName = choice.ability.displayName;
    });
  }

  void _warn(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.valorantSurface),
    );
  }

  MapCallout? _nearestCallout(Offset point, GameMap map) {
    MapCallout? nearest;
    var nearestDistance = double.infinity;

    for (final callout in map.callouts) {
      final distance = (map.normalizedPosition(callout) - point).distance;
      if (distance >= nearestDistance) continue;
      nearestDistance = distance;
      nearest = callout;
    }
    return nearest;
  }

  /// Keeps the exact position, plus the closest callout so the spot reads as
  /// "A Main" in the lists.
  LineupAnchor _anchorFor(Offset point, GameMap map) {
    final callout = _nearestCallout(point, map);
    return LineupAnchor(
      x: point.dx,
      y: point.dy,
      calloutName: callout?.regionName,
      calloutRegion: callout?.superRegionName,
    );
  }

  /// Accepts a bare "youtube.com/..." as well as a full link.
  String? _demoUrl() {
    final raw = _demoUrlController.text.trim();
    if (raw.isEmpty) return null;
    return raw.startsWith('http') ? raw : 'https://$raw';
  }

  Future<void> _save(GameMap map) async {
    final from = _from;
    final agentName = _agentName;
    final abilitySlot = _abilitySlot;

    if (from == null) return _warn('Place d\'abord la position de lancer sur le plan.');
    if (agentName == null || abilitySlot == null) return _warn('Choisis l\'agent et la compétence.');
    if (_isThrow && _to == null) return _warn('Place le point visé, ou passe en mode placement.');

    final title = _titleController.text.trim();
    final lineup = Lineup(
      id: _draftId,
      mapName: widget.mapName,
      agentName: agentName,
      abilitySlot: abilitySlot,
      abilityName: _abilityName ?? '',
      side: _side,
      from: _anchorFor(from, map),
      to: _isThrow ? _anchorFor(_to!, map) : null,
      title: title.isEmpty ? '$agentName · ${_abilityName ?? ''}'.trim() : title,
      description: _descriptionController.text.trim(),
      difficulty: _difficulty,
      isVerified: _isVerified,
      position: _positionController.text.trim(),
      aim: _aimController.text.trim(),
      throwStyle: _throwStyle,
      media: _media,
      demoUrl: _demoUrl(),
      isBundled: false,
    );

    await ref.read(lineupsProvider.notifier).save(lineup);
    if (mounted) Navigator.of(context).pop(_draftId);
  }

  @override
  Widget build(BuildContext context) {
    final map = ref.watch(gameMapByNameProvider(widget.mapName));
    if (map == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('NOUVEAU SPOT')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    _prefill(map);

    final isEditing = widget.initial != null && !widget.asCopy;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'MODIFIER LE SPOT' : 'NOUVEAU SPOT'),
        actions: [
          TextButton(
            onPressed: () => _save(map),
            style: TextButton.styleFrom(foregroundColor: AppTheme.valorantRed),
            child: const Text('ENREGISTRER', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          LineupMapView(
            map: map,
            lineups: const [],
            onTapPosition: _placePoint,
            pendingFrom: _from,
            pendingTo: _isThrow ? _to : null,
          ),
          const SizedBox(height: 10),
          Text(
            _isThrow && _isPlacingTarget
                ? 'Touche le plan pour placer le POINT VISÉ (2).'
                : 'Touche le plan pour placer la POSITION DE LANCER (1).',
            style: const TextStyle(fontSize: 11.5, color: Colors.white70, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Pill(
                  label: '1 · Départ ${_from == null ? '' : '✓'}',
                  color: lineupSideColor(_side),
                  isSelected: !_isPlacingTarget,
                  onTap: () => setState(() => _isPlacingTarget = false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Pill(
                  label: '2 · Cible ${_to == null ? '' : '✓'}',
                  color: lineupSideColor(_side),
                  isSelected: _isThrow && _isPlacingTarget,
                  onTap: _isThrow ? () => setState(() => _isPlacingTarget = true) : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _Pill(
                  label: 'Trajectoire',
                  color: Colors.white70,
                  isSelected: _isThrow,
                  onTap: () => setState(() => _isThrow = true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Pill(
                  label: 'Placement seul',
                  color: Colors.white70,
                  isSelected: !_isThrow,
                  onTap: () => setState(() {
                    _isThrow = false;
                    _isPlacingTarget = false;
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const ValorantFieldLabel('Agent et compétence'),
          _AbilityField(
            agentName: _agentName,
            abilityName: _abilityName,
            abilitySlot: _abilitySlot,
            side: _side,
            onTap: _pickAbility,
          ),
          const SizedBox(height: 18),
          const ValorantFieldLabel('Camp'),
          Row(
            children: [
              for (final side in LineupSide.values) ...[
                Expanded(
                  child: _Pill(
                    label: side.label,
                    color: lineupSideColor(side),
                    isSelected: _side == side,
                    onTap: () => setState(() => _side = side),
                  ),
                ),
                if (side != LineupSide.values.last) const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 18),
          const ValorantFieldLabel('Difficulté'),
          Row(
            children: [
              for (final difficulty in LineupDifficulty.values) ...[
                Expanded(
                  child: _Pill(
                    label: difficulty.label,
                    color: Colors.white70,
                    isSelected: _difficulty == difficulty,
                    onTap: () => setState(() => _difficulty = difficulty),
                  ),
                ),
                if (difficulty != LineupDifficulty.values.last) const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 18),
          const ValorantFieldLabel('Titre'),
          TextField(
            controller: _titleController,
            decoration: valorantInputDecoration(hint: 'Molly post-plant A'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 26),
          const _StepHeader(index: 1, title: 'Se placer'),
          TextField(
            controller: _positionController,
            decoration: valorantInputDecoration(hint: 'Dos au mur du fond, aligné sur la caisse…'),
            maxLines: 2,
          ),
          const SizedBox(height: 10),
          LineupMediaField(
            role: LineupMediaRole.position,
            media: _mediaFor(LineupMediaRole.position),
            onPickPhoto: () => _pickMedia(LineupMediaRole.position, LineupMediaKind.photo),
            onRemove: () => _removeMedia(LineupMediaRole.position),
          ),
          const SizedBox(height: 26),
          const _StepHeader(index: 2, title: 'Viser'),
          TextField(
            controller: _aimController,
            decoration: valorantInputDecoration(hint: 'Viseur sur le coin du toit, juste au-dessus de…'),
            maxLines: 2,
          ),
          const SizedBox(height: 10),
          LineupMediaField(
            role: LineupMediaRole.aim,
            media: _mediaFor(LineupMediaRole.aim),
            onPickPhoto: () => _pickMedia(LineupMediaRole.aim, LineupMediaKind.photo),
            onRemove: () => _removeMedia(LineupMediaRole.aim),
          ),
          const SizedBox(height: 26),
          const _StepHeader(index: 3, title: 'Lancer'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final style in LineupThrow.values)
                if (style.isSpecified)
                  SizedBox(
                    width: 168,
                    child: _Pill(
                      label: style.label,
                      color: Colors.white70,
                      isSelected: _throwStyle == style,
                      onTap: () => setState(() => _throwStyle = style),
                    ),
                  ),
            ],
          ),
          const SizedBox(height: 26),
          const _StepHeader(index: 4, title: 'Résultat'),
          LineupMediaField(
            role: LineupMediaRole.result,
            media: _mediaFor(LineupMediaRole.result),
            onPickPhoto: () => _pickMedia(LineupMediaRole.result, LineupMediaKind.photo),
            onPickVideo: () => _pickMedia(LineupMediaRole.result, LineupMediaKind.video),
            onRemove: () => _removeMedia(LineupMediaRole.result),
          ),
          const SizedBox(height: 18),
          const ValorantFieldLabel('Vidéo de démo (lien)'),
          TextField(
            controller: _demoUrlController,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: valorantInputDecoration(hint: 'https://youtu.be/…'),
          ),
          const SizedBox(height: 18),
          const ValorantFieldLabel('Notes'),
          TextField(
            controller: _descriptionController,
            decoration: valorantInputDecoration(hint: 'Timing, variante, piège à éviter…'),
            maxLines: 3,
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: const Color(0xFF2FBF8F),
            value: _isVerified,
            onChanged: (value) => setState(() => _isVerified = value),
            title: const Text('Testé en jeu', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            subtitle: const Text(
              'Retire le badge « brouillon » une fois le spot vérifié.',
              style: TextStyle(fontSize: 11, color: AppTheme.valorantMuted),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => _save(map),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.valorantRed,
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('ENREGISTRER LE SPOT', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color, required this.isSelected, required this.onTap});

  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.04),
          border: Border.all(color: isSelected ? color : Colors.white24),
        ),
        child: Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
            color: isSelected
                ? color
                : isEnabled
                ? Colors.white54
                : Colors.white24,
          ),
        ),
      ),
    );
  }
}

class _AbilityField extends StatelessWidget {
  const _AbilityField({
    required this.agentName,
    required this.abilityName,
    required this.abilitySlot,
    required this.side,
    required this.onTap,
  });

  final String? agentName;
  final String? abilityName;
  final String? abilitySlot;
  final LineupSide side;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final agentName = this.agentName;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.valorantDark,
          border: Border.all(color: AppTheme.outlineDark),
        ),
        child: Row(
          children: [
            if (agentName == null)
              const Icon(Icons.add_circle_outline, color: Colors.white38)
            else
              LineupAbilityBadge(
                lineup: Lineup(
                  id: 'preview',
                  mapName: '',
                  agentName: agentName,
                  abilitySlot: abilitySlot ?? '',
                  abilityName: abilityName ?? '',
                  side: side,
                  from: const LineupAnchor(),
                  to: null,
                  title: '',
                  description: '',
                  difficulty: LineupDifficulty.medium,
                  isVerified: false,
                  isBundled: false,
                ),
                size: 38,
              ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                agentName == null ? 'Choisir un agent et sa compétence' : '$agentName · ${abilityName ?? ''}',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: agentName == null ? Colors.white38 : Colors.white,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.valorantMuted),
          ],
        ),
      ),
    );
  }
}


/// Numbered heading of one step of the guide.
class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.index, required this.title});

  final int index;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.valorantRed.withValues(alpha: 0.18),
              border: Border.all(color: AppTheme.valorantRed),
            ),
            child: Text(
              '$index',
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: AppTheme.valorantRed),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, letterSpacing: 0.8),
          ),
        ],
      ),
    );
  }
}
