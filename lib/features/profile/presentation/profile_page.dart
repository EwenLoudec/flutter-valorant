import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/diagonal_cut_clipper.dart';
import '../../../core/widgets/flame_backdrop.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/staggered_fade_slide.dart';
import '../domain/player_query.dart';
import '../providers/profile_providers.dart';
import 'collection_tools_section.dart';
import 'featured_store_section.dart';
import 'match_history_section.dart';
import 'overview_lists.dart';
import 'overview_sections.dart';
import 'owned_skins_section.dart';
import 'player_stats_section.dart';
import 'profile_hero.dart';
import 'rank_history_section.dart';
import 'riot_id_form.dart';
import 'season_sections.dart';

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
      child: SingleChildScrollView(child: RiotIdForm(onSaved: () => Navigator.of(sheetContext).pop())),
    ),
  );
}

/// Before any account: only the search, styled like the account header so
/// the page feels the same once the profile appears.
class _SetupBody extends StatelessWidget {
  const _SetupBody();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        ClipPath(
          clipper: const DiagonalCutClipper(cut: 16),
          child: Container(
            decoration: const BoxDecoration(
              color: AppTheme.valorantSurface,
              border: Border(bottom: BorderSide(color: Color(0xFFFF7A2F), width: 3)),
            ),
            child: Stack(
              children: [
                const Positioned.fill(child: FlameBackdrop(intensity: 0.9)),
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xE60F1923), Color(0x660F1923)],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.search, size: 20, color: Color(0xFFFF7A2F)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'TROUVE TON COMPTE',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Ton Riot ID et ton serveur suffisent : rang, RR, statistiques, armes, cartes, '
                        'agents et dernières parties.',
                        style: TextStyle(fontSize: 12.5, color: Colors.white70, height: 1.4),
                      ),
                      const SizedBox(height: 18),
                      const RiotIdForm(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The pages of an account, as tabs under the header.
enum ProfileTab {
  overview('Aperçu', Icons.insights),
  matches('Parties', Icons.history),
  weapons('Armes', Icons.gps_fixed),
  maps('Cartes', Icons.map_outlined),
  agents('Agents', Icons.person_outline),
  store('Boutique', Icons.storefront_outlined),
  collection('Collection', Icons.collections_bookmark_outlined);

  const ProfileTab(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// An account's page, tracker style: who and what rank first, then one tab
/// at a time, so the page stays short and easy to read.
class _ProfileBody extends ConsumerStatefulWidget {
  const _ProfileBody({required this.query});

  final PlayerQuery query;

  @override
  ConsumerState<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends ConsumerState<_ProfileBody> {
  ProfileTab _tab = ProfileTab.overview;

  PlayerQuery get query => widget.query;

  Future<void> _refresh() async {
    ref.invalidate(playerAccountProvider(query));
    ref.invalidate(playerRankProvider(query));
    ref.invalidate(playerMatchesProvider(query));
    ref.invalidate(playerRankHistoryProvider(query));
    ref.invalidate(storedMatchesProvider(query));
    if (_tab == ProfileTab.store) ref.invalidate(featuredStoreProvider);

    await Future.wait([ref.read(playerRankProvider(query).future), ref.read(playerMatchesProvider(query).future)])
        .catchError((_) => const <Object>[]);
  }

  void _select(ProfileTab tab) => setState(() => _tab = tab);

  List<Widget> _sectionsOf(ProfileTab tab) {
    return switch (tab) {
      ProfileTab.overview => [
        SeasonOverviewSection(query: query),
        RankHistorySection(query: query),
        OverviewStatsSection(query: query),
        SessionSection(query: query),
        TopWeaponsSection(query: query, limit: 3, onSeeAll: () => _select(ProfileTab.weapons)),
        SeasonAgentsSection(query: query, limit: 3, onSeeAll: () => _select(ProfileTab.agents)),
        RolesSection(query: query),
        SidesSection(query: query),
      ],
      ProfileTab.matches => [MatchHistorySection(query: query)],
      ProfileTab.weapons => [TopWeaponsSection(query: query, limit: 20)],
      ProfileTab.maps => [
        SeasonMapsSection(query: query),
        TopMapsSection(query: query, limit: 20, title: 'Cartes · dernières parties, tous modes'),
      ],
      ProfileTab.agents => [
        SeasonAgentsSection(query: query),
        TopAgentsSection(query: query, limit: 20, title: 'Agents · dernières parties, tous modes'),
        RolesSection(query: query),
      ],
      ProfileTab.store => [const FeaturedStoreSection()],
      ProfileTab.collection => [const OwnedSkinsSection(), const CollectionToolsSection()],
    };
  }

  @override
  Widget build(BuildContext context) {
    final sections = _sectionsOf(_tab);
    final reduceMotion = motionDisabled(context);

    return RefreshIndicator(
      color: AppTheme.valorantRed,
      backgroundColor: AppTheme.valorantSurface,
      onRefresh: _refresh,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            sliver: SliverToBoxAdapter(child: ProfileHero(query: query)),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(selected: _tab, onSelected: _select),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
            sliver: SliverToBoxAdapter(
              child: AnimatedSwitcher(
                duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeIn,
                layoutBuilder: (current, previous) =>
                    Stack(alignment: Alignment.topCenter, children: [...previous, ?current]),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween(begin: const Offset(0, 0.03), end: Offset.zero).animate(animation),
                    child: child,
                  ),
                ),
                child: Column(
                  key: ValueKey(_tab),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (index, section) in sections.indexed) ...[
                      if (index > 0) const SizedBox(height: 22),
                      StaggeredFadeSlide(index: index, step: const Duration(milliseconds: 60), child: section),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The tabs, pinned under the app bar once the header has scrolled away.
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  _TabBarDelegate({required this.selected, required this.onSelected});

  final ProfileTab selected;
  final ValueChanged<ProfileTab> onSelected;

  static const _height = 54.0;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.valorantDark,
        border: Border(
          bottom: BorderSide(color: overlapsContent || shrinkOffset > 0 ? AppTheme.outlineDark : Colors.transparent),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 9, 16, 9),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final tab in ProfileTab.values) ...[
              if (tab.index > 0) const SizedBox(width: 6),
              _TabChip(tab: tab, isSelected: tab == selected, onTap: () => onSelected(tab)),
            ],
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => oldDelegate.selected != selected;
}

class _TabChip extends StatelessWidget {
  const _TabChip({required this.tab, required this.isSelected, required this.onTap});

  final ProfileTab tab;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final duration = motionDisabled(context) ? Duration.zero : const Duration(milliseconds: 220);

    return Semantics(
      selected: isSelected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: ClipPath(
          clipper: const DiagonalCutClipper(cut: 7),
          child: AnimatedContainer(
            duration: duration,
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              gradient: isSelected ? fireGradient : null,
              color: isSelected ? null : AppTheme.valorantSurface,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(tab.icon, size: 15, color: isSelected ? Colors.white : Colors.white60),
                const SizedBox(width: 6),
                Text(
                  tab.label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.7,
                    color: isSelected ? Colors.white : Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
