import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/diagonal_cut_clipper.dart';
import '../../../core/widgets/valorant_input.dart';
import '../domain/crosshair.dart';
import '../providers/tools_providers.dart';

/// A few starting points to try, written for this app.
const _examples = [
  SavedCrosshair(name: 'Par défaut', code: '0;P'),
  SavedCrosshair(name: 'Croix fine verte', code: '0;P;c;1;h;0;0l;4;0o;2;0a;1;0f;0;1b;0'),
  SavedCrosshair(name: 'Point cyan', code: '0;P;c;5;h;1;d;1;z;3;0b;0;1b;0'),
  SavedCrosshair(name: 'Croix rose épaisse', code: '0;P;c;6;h;1;t;1;0t;3;0l;5;0o;1;0a;1;1b;0'),
];

/// Paste a crosshair code from the game's settings, see it drawn, and keep
/// the ones worth keeping.
class CrosshairScreen extends ConsumerStatefulWidget {
  const CrosshairScreen({super.key});

  @override
  ConsumerState<CrosshairScreen> createState() => _CrosshairScreenState();
}

enum _Background {
  dark('Sombre', Color(0xFF1B2229)),
  light('Clair', Color(0xFFD9D4C7)),
  sky('Ciel', Color(0xFF7FA7C9));

  const _Background(this.label, this.color);

  final String label;
  final Color color;
}

class _CrosshairScreenState extends ConsumerState<CrosshairScreen> {
  final _controller = TextEditingController(text: _examples[1].code);
  _Background _background = _Background.dark;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _load(String code) {
    _controller.text = code;
    setState(() {});
  }

  Future<void> _save(Crosshair crosshair) async {
    final name = await showDialog<String>(context: context, builder: (_) => const _NameDialog());
    if (name == null) return;

    final trimmed = name.trim();
    await ref
        .read(savedCrosshairsProvider.notifier)
        .add(SavedCrosshair(name: trimmed.isEmpty ? 'Réticule' : trimmed, code: _controller.text.trim()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Réticule enregistré.')));
    }
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _controller.text.trim()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code copié : colle-le dans Paramètres → Réticule → Importer.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final crosshair = Crosshair.tryParse(_controller.text);
    final saved = ref.watch(savedCrosshairsProvider).value ?? const <SavedCrosshair>[];

    return Scaffold(
      appBar: AppBar(title: const Text('RÉTICULE')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          TextField(
            controller: _controller,
            maxLines: 2,
            minLines: 1,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5),
            decoration: valorantInputDecoration(
              hint: 'Code du réticule, ex. 0;P;c;1;h;0;…',
              errorText: crosshair == null && _controller.text.trim().isNotEmpty
                  ? 'Ce n\'est pas un code de réticule (il commence par « 0; »).'
                  : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          ClipPath(
            clipper: const DiagonalCutClipper(cut: 12),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: ColoredBox(
                color: _background.color,
                child: crosshair == null
                    ? const Center(child: Icon(Icons.gps_off, color: Colors.white24, size: 40))
                    : CustomPaint(painter: CrosshairPainter(crosshair: crosshair)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final background in _Background.values)
                ChoiceChip(
                  label: Text(background.label),
                  selected: _background == background,
                  onSelected: (_) => setState(() => _background = background),
                  shape: const RoundedRectangleBorder(),
                ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Aperçu agrandi : chaque pixel du jeu (en 1080p) est dessiné plus gros pour être lisible.',
            style: TextStyle(fontSize: 10.5, color: AppTheme.valorantMuted, height: 1.4),
          ),
          if (crosshair != null) ...[
            const SizedBox(height: 10),
            _Details(crosshair: crosshair),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _save(crosshair),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.valorantRed,
                      shape: const RoundedRectangleBorder(),
                    ),
                    icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                    label: const Text('ENREGISTRER', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _copy,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: AppTheme.outlineDark),
                      shape: const RoundedRectangleBorder(),
                    ),
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('COPIER', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 22),
          _ListTitle('Mes réticules (${saved.length})'),
          const SizedBox(height: 8),
          if (saved.isEmpty)
            const Text(
              'Aucun réticule enregistré. Colle un code, puis ENREGISTRER.',
              style: TextStyle(fontSize: 12, color: AppTheme.valorantMuted),
            )
          else
            for (final entry in saved)
              _SavedRow(
                crosshair: entry,
                onTap: () => _load(entry.code),
                onDelete: () => ref.read(savedCrosshairsProvider.notifier).remove(entry),
              ),
          const SizedBox(height: 18),
          const _ListTitle('Exemples'),
          const SizedBox(height: 8),
          for (final example in _examples) _SavedRow(crosshair: example, onTap: () => _load(example.code)),
        ],
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.crosshair});

  final Crosshair crosshair;

  @override
  Widget build(BuildContext context) {
    final colorIndex = Crosshair.presetColors.indexOf(crosshair.color);
    final colorName = colorIndex == -1 ? 'Personnalisée' : Crosshair.presetColorNames[colorIndex];
    String lines(CrosshairLines lines) => lines.isVisible
        ? 'longueur ${_format(lines.length)}, épaisseur ${_format(lines.thickness)}, '
              'écart ${_format(lines.offset)}, opacité ${_format(lines.opacity)}'
        : 'masquées';

    return Text(
      'Couleur : $colorName · contours ${crosshair.hasOutlines ? 'oui' : 'non'} · '
      'point central ${crosshair.hasCenterDot ? 'oui' : 'non'}\n'
      'Lignes intérieures : ${lines(crosshair.inner)}\n'
      'Lignes extérieures : ${lines(crosshair.outer)}',
      style: const TextStyle(fontSize: 11.5, color: Colors.white70, height: 1.5),
    );
  }

  static String _format(double value) =>
      value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
}

class _ListTitle extends StatelessWidget {
  const _ListTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 3, height: 14, color: AppTheme.valorantRed),
        const SizedBox(width: 8),
        Text(text.toUpperCase(), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
      ],
    );
  }
}

class _SavedRow extends StatelessWidget {
  const _SavedRow({required this.crosshair, required this.onTap, this.onDelete});

  final SavedCrosshair crosshair;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final parsed = Crosshair.tryParse(crosshair.code);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: AppTheme.valorantSurface,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  color: const Color(0xFF1B2229),
                  child: parsed == null ? null : CustomPaint(painter: CrosshairPainter(crosshair: parsed)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(crosshair.name, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                      Text(
                        crosshair.code,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10, color: AppTheme.valorantMuted, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
                if (onDelete != null)
                  IconButton(
                    tooltip: 'Supprimer',
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 19, color: Colors.white38),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Draws [crosshair] centred, scaled so it fills a good part of the canvas.
class CrosshairPainter extends CustomPainter {
  const CrosshairPainter({required this.crosshair});

  final Crosshair crosshair;

  @override
  void paint(Canvas canvas, Size size) {
    final extent = math.max(crosshair.extent, 4.0);
    final scale = math.min((math.min(size.width, size.height) * 0.42) / extent, 8.0);

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(scale);

    final rects = <Rect>[
      for (final lines in [crosshair.inner, crosshair.outer])
        if (lines.isVisible && lines.thickness > 0) ..._linesRects(lines),
    ];
    final opacities = <double>[
      for (final lines in [crosshair.inner, crosshair.outer])
        if (lines.isVisible && lines.thickness > 0) ...List.filled(_linesRects(lines).length, lines.opacity),
    ];

    final dot = crosshair.hasCenterDot && crosshair.centerDotThickness > 0
        ? Rect.fromCenter(
            center: Offset.zero,
            width: crosshair.centerDotThickness,
            height: crosshair.centerDotThickness,
          )
        : null;

    if (crosshair.hasOutlines && crosshair.outlineThickness > 0) {
      final outline = Paint()..color = Colors.black.withValues(alpha: crosshair.outlineOpacity);
      for (final rect in [...rects, ?dot]) {
        canvas.drawRect(rect.inflate(crosshair.outlineThickness), outline);
      }
    }

    for (final (index, rect) in rects.indexed) {
      canvas.drawRect(rect, Paint()..color = crosshair.color.withValues(alpha: opacities[index]));
    }
    if (dot != null) {
      canvas.drawRect(dot, Paint()..color = crosshair.color.withValues(alpha: crosshair.centerDotOpacity));
    }

    canvas.restore();
  }

  static List<Rect> _linesRects(CrosshairLines lines) {
    final thickness = lines.thickness;
    final rects = <Rect>[];
    if (lines.length > 0) {
      rects
        ..add(Rect.fromLTWH(lines.offset, -thickness / 2, lines.length, thickness))
        ..add(Rect.fromLTWH(-lines.offset - lines.length, -thickness / 2, lines.length, thickness));
    }
    if (lines.verticalLength > 0) {
      rects
        ..add(Rect.fromLTWH(-thickness / 2, -lines.offset - lines.verticalLength, thickness, lines.verticalLength))
        ..add(Rect.fromLTWH(-thickness / 2, lines.offset, thickness, lines.verticalLength));
    }
    return rects;
  }

  @override
  bool shouldRepaint(covariant CrosshairPainter oldDelegate) => !identical(oldDelegate.crosshair, crosshair);
}

/// Asks for the name to save a crosshair under. It owns its controller, so
/// the field is never left with a disposed one during the closing animation.
class _NameDialog extends StatefulWidget {
  const _NameDialog();

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.valorantSurface,
      title: const Text('Enregistrer le réticule', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: valorantInputDecoration(hint: 'Nom (ex. Mon réticule Vandal)'),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          style: TextButton.styleFrom(foregroundColor: AppTheme.valorantRed),
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
