import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/henrik_api_client.dart';
import '../../../core/theme/app_theme.dart';

/// How to get the free HenrikDev key, with a button to the page that issues
/// it.
class HenrikKeyHelp extends StatelessWidget {
  const HenrikKeyHelp({super.key});

  Future<void> _open(BuildContext context) async {
    final opened = await launchUrl(HenrikApiClient.dashboardUri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir api.henrikdev.xyz/dashboard.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Les données de compte et le classement passent par api.henrikdev.xyz, qui demande une '
          'clé gratuite : connecte-toi sur son tableau de bord, ouvre « API Keys » puis « Generate '
          'New Key », et colle la clé ici. Elle reste sur cet appareil.',
          style: TextStyle(fontSize: 11.5, color: AppTheme.valorantMuted, height: 1.4),
        ),
        TextButton.icon(
          onPressed: () => _open(context),
          style: TextButton.styleFrom(foregroundColor: AppTheme.valorantRed, padding: EdgeInsets.zero),
          icon: const Icon(Icons.open_in_new, size: 16),
          label: const Text('OBTENIR UNE CLÉ GRATUITE', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}
