import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/valorant_input.dart';
import '../domain/lineup.dart';
import '../domain/lineup_transfer.dart';
import '../providers/lineups_providers.dart';

/// Copies [lineups] as text, ready to paste to a teammate.
Future<void> copyLineupsToClipboard(BuildContext context, List<Lineup> lineups) async {
  if (lineups.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Aucun spot à exporter : crée ou duplique d\'abord un spot.')),
    );
    return;
  }
  await Clipboard.setData(ClipboardData(text: LineupTransfer.export(lineups)));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        '${lineups.length} spot${lineups.length > 1 ? 's' : ''} copié${lineups.length > 1 ? 's' : ''} : '
        'colle le texte à un coéquipier, il l\'importe depuis l\'onglet Lineups. '
        'Les photos restent sur ton appareil.',
      ),
    ),
  );
}

/// Paste an export and add its spots to the player's own.
class LineupImportDialog extends ConsumerStatefulWidget {
  const LineupImportDialog({super.key});

  @override
  ConsumerState<LineupImportDialog> createState() => _LineupImportDialogState();
}

class _LineupImportDialogState extends ConsumerState<LineupImportDialog> {
  final _controller = TextEditingController();
  String? _error;
  bool _isImporting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || !mounted) return;
    setState(() {
      _controller.text = text;
      _error = null;
    });
  }

  Future<void> _import() async {
    final existing = ref.read(lineupsProvider).value ?? const <Lineup>[];
    final LineupImportResult result;
    try {
      result = LineupTransfer.import(_controller.text, existingIds: {for (final lineup in existing) lineup.id});
    } on LineupImportException catch (error) {
      setState(() => _error = error.message);
      return;
    }

    setState(() => _isImporting = true);
    await ref.read(lineupsProvider.notifier).addAll(result.lineups);
    if (!mounted) return;
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.valorantSurface,
      title: const Text('Importer des spots', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Colle ici le texte exporté depuis l\'app (onglet Lineups → Exporter).',
              style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.4),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _controller,
              minLines: 4,
              maxLines: 8,
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
              decoration: valorantInputDecoration(hint: '{ "format": "valorant-companion-lineups", … }', errorText: _error),
              // Rebuilds the Importer button as text comes in.
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _paste,
                icon: const Icon(Icons.content_paste, size: 16),
                label: const Text('Coller le presse-papiers'),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
        TextButton(
          onPressed: _isImporting || _controller.text.trim().isEmpty ? null : _import,
          style: TextButton.styleFrom(foregroundColor: AppTheme.valorantRed),
          child: const Text('Importer'),
        ),
      ],
    );
  }
}

/// Opens the import dialog and reports what came in.
Future<void> importLineups(BuildContext context) async {
  final result = await showDialog<LineupImportResult>(context: context, builder: (_) => const LineupImportDialog());
  if (result == null || !context.mounted) return;

  final count = result.lineups.length;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        '$count spot${count > 1 ? 's' : ''} importé${count > 1 ? 's' : ''}'
        '${result.skipped > 0 ? ', ${result.skipped} illisible${result.skipped > 1 ? 's' : ''} ignoré${result.skipped > 1 ? 's' : ''}' : ''}.',
      ),
    ),
  );
}
