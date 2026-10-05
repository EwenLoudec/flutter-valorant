import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/valorant_input.dart';
import '../domain/player_query.dart';
import '../domain/player_settings.dart';
import '../providers/profile_providers.dart';
import 'missing_api_key_notice.dart';

/// Riot ID and region entry. Shown full page until a profile is configured,
/// then reopened in a sheet to edit it. The HenrikDev key comes with the
/// build, so there is nothing else to type.
class RiotIdForm extends ConsumerStatefulWidget {
  const RiotIdForm({super.key, this.onSaved});

  final VoidCallback? onSaved;

  @override
  ConsumerState<RiotIdForm> createState() => _RiotIdFormState();
}

class _RiotIdFormState extends ConsumerState<RiotIdForm> {
  final _riotIdController = TextEditingController();

  ValorantRegion _region = ValorantRegion.eu;
  String? _riotIdError;
  bool _initialised = false;

  @override
  void dispose() {
    _riotIdController.dispose();
    super.dispose();
  }

  void _prefill(PlayerSettings settings) {
    if (_initialised) return;
    _initialised = true;

    _riotIdController.text = settings.riotId?.label ?? '';
    _region = settings.region;
  }

  Future<void> _submit() async {
    final riotId = RiotId.tryParse(_riotIdController.text);

    setState(() => _riotIdError = riotId == null ? 'Format attendu : Pseudo#TAG' : null);
    if (riotId == null) return;

    final current = ref.read(playerSettingsProvider).value ?? const PlayerSettings();
    await ref
        .read(playerSettingsProvider.notifier)
        .save(PlayerSettings(riotId: riotId, region: _region, apiKey: current.apiKey));

    widget.onSaved?.call();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(playerSettingsProvider).value;
    if (settings != null) _prefill(settings);
    final hasKey = settings?.apiKey.isNotEmpty ?? true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ValorantFieldLabel('Riot ID'),
        TextField(
          controller: _riotIdController,
          textInputAction: TextInputAction.done,
          autocorrect: false,
          decoration: valorantInputDecoration(hint: 'Pseudo#TAG', errorText: _riotIdError),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 16),
        ValorantFieldLabel('Région'),
        DropdownButtonFormField<String>(
          initialValue: _region.code,
          isExpanded: true,
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
        if (!hasKey) ...[
          const SizedBox(height: 16),
          const MissingApiKeyNotice(),
        ],
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
