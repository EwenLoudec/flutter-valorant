import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/valorant_input.dart';
import '../domain/player_query.dart';
import '../domain/player_settings.dart';
import '../providers/profile_providers.dart';

/// Riot ID, region and API key entry. Shown full page until a profile is
/// configured, then reopened in a sheet to edit it.
class RiotIdForm extends ConsumerStatefulWidget {
  const RiotIdForm({super.key, this.onSaved});

  final VoidCallback? onSaved;

  @override
  ConsumerState<RiotIdForm> createState() => _RiotIdFormState();
}

class _RiotIdFormState extends ConsumerState<RiotIdForm> {
  final _riotIdController = TextEditingController();
  final _apiKeyController = TextEditingController();

  ValorantRegion _region = ValorantRegion.eu;
  String? _riotIdError;
  String? _apiKeyError;
  bool _initialised = false;

  @override
  void dispose() {
    _riotIdController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  void _prefill(PlayerSettings settings) {
    if (_initialised) return;
    _initialised = true;

    _riotIdController.text = settings.riotId?.label ?? '';
    _apiKeyController.text = settings.apiKey;
    _region = settings.region;
  }

  Future<void> _submit() async {
    final riotId = RiotId.tryParse(_riotIdController.text);
    final apiKey = _apiKeyController.text.trim();

    setState(() {
      _riotIdError = riotId == null ? 'Format attendu : Pseudo#TAG' : null;
      _apiKeyError = apiKey.isEmpty ? 'Clé API requise pour interroger les serveurs Riot' : null;
    });
    if (riotId == null || apiKey.isEmpty) return;

    await ref
        .read(playerSettingsProvider.notifier)
        .save(PlayerSettings(riotId: riotId, region: _region, apiKey: apiKey));

    widget.onSaved?.call();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(playerSettingsProvider).value;
    if (settings != null) _prefill(settings);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ValorantFieldLabel('Riot ID'),
        TextField(
          controller: _riotIdController,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          decoration: valorantInputDecoration(hint: 'Pseudo#TAG', errorText: _riotIdError),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 16),
        ValorantFieldLabel('Région'),
        DropdownButtonFormField<String>(
          initialValue: _region.code,
          dropdownColor: AppTheme.valorantSurface,
          decoration: valorantInputDecoration(),
          items: [
            for (final region in ValorantRegion.all)
              DropdownMenuItem(
                value: region.code,
                child: Text('${region.label} (${region.code.toUpperCase()})'),
              ),
          ],
          onChanged: (code) => setState(() => _region = ValorantRegion.fromCode(code)),
        ),
        const SizedBox(height: 16),
        ValorantFieldLabel('Clé API HenrikDev'),
        TextField(
          controller: _apiKeyController,
          obscureText: true,
          autocorrect: false,
          decoration: valorantInputDecoration(hint: 'HDEV-…', errorText: _apiKeyError),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 6),
        const Text(
          'Les données de compte passent par api.henrikdev.xyz, qui demande une '
          'clé gratuite (Discord HenrikDev). Elle reste sur cet appareil.',
          style: TextStyle(fontSize: 11.5, color: AppTheme.valorantMuted, height: 1.4),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.valorantRed,
            foregroundColor: Colors.white,
            shape: const RoundedRectangleBorder(),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: const Text(
            'AFFICHER MON PROFIL',
            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.6),
          ),
        ),
        if (settings?.riotId != null) ...[
          const SizedBox(height: 4),
          TextButton(
            onPressed: () async {
              await ref.read(playerSettingsProvider.notifier).forgetRiotId();
              widget.onSaved?.call();
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.valorantMuted),
            child: const Text('Oublier ce compte'),
          ),
        ],
      ],
    );
  }
}
