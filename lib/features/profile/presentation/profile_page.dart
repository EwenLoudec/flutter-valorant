import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/player_query.dart';
import '../providers/profile_providers.dart';
import 'match_history_section.dart';
import 'owned_skins_section.dart';
import 'player_header_card.dart';
import 'profile_section.dart';
import 'rank_card.dart';
import 'riot_id_form.dart';
import 'weapon_accuracy_section.dart';

/// The player's own page: Riot ID, rank, recent matches, aim and skins.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(playerSettingsProvider);
    final query = ref.watch(playerQueryProvider);
    final isConfigured = query != null && (settings.value?.isComplete ?? false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PROFIL'),
        actions: [
          if (isConfigured)
            IconButton(
              tooltip: 'Changer de compte',
              icon: const Icon(Icons.manage_accounts_outlined),
              onPressed: () => _openAccountEditor(context),
            ),
        ],
      ),
      body: settings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Paramètres illisibles : $error')),
        data: (_) => isConfigured ? _ProfileBody(query: query) : const _SetupBody(),
      ),
    );
  }
}

Future<void> _openAccountEditor(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.valorantSurface,
    shape: const RoundedRectangleBorder(),
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(sheetContext).viewInsets.bottom),
      child: SingleChildScrollView(
        child: RiotIdForm(onSaved: () => Navigator.of(sheetContext).pop()),
      ),
    ),
  );
}

class _SetupBody extends StatelessWidget {
  const _SetupBody();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RETROUVEZ VOTRE COMPTE',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.6),
          ),
          const SizedBox(height: 6),
          const Text(
            'Renseignez votre Riot ID pour afficher votre rang, vos dernières '
            'parties et votre précision arme par arme.',
            style: TextStyle(fontSize: 12.5, color: AppTheme.valorantMuted, height: 1.4),
          ),
          const SizedBox(height: 20),
          const RiotIdForm(),
          const SizedBox(height: 28),
          // The collection lives on the device, so it is worth showing even
          // before an account is linked.
          const OwnedSkinsSection(),
        ],
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.query});

  final PlayerQuery query;

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(playerAccountProvider(query));
    ref.invalidate(playerRankProvider(query));
    ref.invalidate(playerMatchesProvider(query));

    await Future.wait([
      ref.read(playerRankProvider(query).future),
      ref.read(playerMatchesProvider(query).future),
    ]).catchError((_) => const <Object>[]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      color: AppTheme.valorantRed,
      backgroundColor: AppTheme.valorantSurface,
      onRefresh: () => _refresh(ref),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          PlayerHeaderCard(query: query),
          const SizedBox(height: 20),
          ProfileSection(title: 'Rang compétitif', child: RankCard(query: query)),
          const SizedBox(height: 20),
          WeaponAccuracySection(query: query),
          const SizedBox(height: 20),
          MatchHistorySection(query: query),
          const SizedBox(height: 20),
          const OwnedSkinsSection(),
        ],
      ),
    );
  }
}
