import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/crosshair_store.dart';
import '../domain/crosshair.dart';

final crosshairStoreProvider = Provider<CrosshairStore>((ref) => CrosshairStore());

/// The saved crosshairs, most recently added first.
class SavedCrosshairsNotifier extends AsyncNotifier<List<SavedCrosshair>> {
  @override
  Future<List<SavedCrosshair>> build() => ref.read(crosshairStoreProvider).load();

  Future<void> add(SavedCrosshair crosshair) async {
    final current = [...?state.value]..removeWhere((entry) => entry.code == crosshair.code);
    await _commit([crosshair, ...current]);
  }

  Future<void> remove(SavedCrosshair crosshair) async {
    final current = [...?state.value]..removeWhere((entry) => entry.code == crosshair.code);
    await _commit(current);
  }

  Future<void> _commit(List<SavedCrosshair> crosshairs) async {
    state = AsyncData(crosshairs);
    await ref.read(crosshairStoreProvider).save(crosshairs);
  }
}

final savedCrosshairsProvider = AsyncNotifierProvider<SavedCrosshairsNotifier, List<SavedCrosshair>>(
  SavedCrosshairsNotifier.new,
);
