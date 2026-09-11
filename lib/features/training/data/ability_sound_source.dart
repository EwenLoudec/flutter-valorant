import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// The ability clips that actually carry an audio track. Roughly half of
/// playvalorant.com's clips are silent, so the sound question would fall on
/// a mute video without this list — rebuild it with
/// `dart run scripts/scan_ability_sounds.dart`.
class AbilitySoundSource {
  static const assetPath = 'assets/data/ability_sounds.json';

  /// Agent uuid -> ability name in upper case -> clip url.
  Future<Map<String, Map<String, String>>> getSoundsByAgent() async {
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw.replaceFirst('﻿', '')) as Map<String, dynamic>;

    return {
      for (final agent in decoded.entries)
        agent.key: {
          for (final clip in (agent.value as Map<String, dynamic>).entries)
            clip.key: clip.value as String,
        },
    };
  }
}
