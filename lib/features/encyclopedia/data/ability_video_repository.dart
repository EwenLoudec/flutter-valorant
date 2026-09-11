import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Ability preview clips aren't exposed by valorant-api.com. This repository
/// reads a bundled, pre-scraped map (agent uuid -> ABILITY NAME -> mp4 url)
/// built from playvalorant.com's own official agent pages, so the app never
/// has to fetch that site at runtime (which the browser would block via CORS
/// anyway). Re-run scripts/scrape_ability_videos.ps1 to refresh it.
class AbilityVideoRepository {
  Future<Map<String, Map<String, String>>> getVideosByAgent() async {
    final raw = await rootBundle.loadString('assets/data/ability_videos.json');
    // Windows PowerShell writes a BOM in front of its UTF-8 output, and
    // jsonDecode chokes on it — which silently emptied every ability video.
    final decoded = jsonDecode(raw.replaceFirst('﻿', '')) as Map<String, dynamic>;

    return decoded.map(
      (agentUuid, abilities) => MapEntry(
        agentUuid,
        (abilities as Map<String, dynamic>).map((name, url) => MapEntry(name, url as String)),
      ),
    );
  }
}
