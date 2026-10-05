import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/henrik_api_client.dart';
import '../../../core/theme/app_theme.dart';

/// How to get the free HenrikDev key: the dashboard signs in with Discord,
/// so both links are offered.
class HenrikKeyHelp extends StatelessWidget {
  const HenrikKeyHelp({super.key});

  Future<void> _open(BuildContext context, Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible d\'ouvrir ${uri.host}${uri.path}.')),
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
          'clé gratuite. 1. Rejoins le serveur Discord HenrikDev. 2. Ouvre le tableau de bord et '
          'connecte-toi avec ce compte Discord. 3. « API Keys » puis « Generate New Key ». '
          '4. Colle la clé ici : elle reste sur cet appareil.',
          style: TextStyle(fontSize: 11.5, color: AppTheme.valorantMuted, height: 1.4),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 16,
          children: [
            _LinkButton(
              icon: Icons.forum_outlined,
              label: 'REJOINDRE LE DISCORD',
              onPressed: () => _open(context, HenrikApiClient.discordUri),
            ),
            _LinkButton(
              icon: Icons.open_in_new,
              label: 'TABLEAU DE BORD',
              onPressed: () => _open(context, HenrikApiClient.dashboardUri),
            ),
          ],
        ),
      ],
    );
  }
}

class _LinkButton extends StatelessWidget {
  const _LinkButton({required this.icon, required this.label, required this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(foregroundColor: AppTheme.valorantRed, padding: EdgeInsets.zero),
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
    );
  }
}
