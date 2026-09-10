import '../domain/map_composition.dart';

/// Curated, hand-maintained data — valorant-api.com has no endpoint for
/// competitive map rotation or team-composition meta. The competitive pool
/// and compositions below reflect community stats (valohub.co, thespike.gg)
/// as of patch 12.10 / Season V26 Act 5 (September 2026) and will drift out
/// of date as Riot rotates maps and the meta shifts — refresh periodically.
class MapMetaEntry {
  const MapMetaEntry({required this.inCompetitivePool, required this.metaComposition});

  final bool inCompetitivePool;
  final MapComposition metaComposition;
}

const Map<String, MapMetaEntry> kMapMetaData = {
  'Ascent': MapMetaEntry(
    inCompetitivePool: true,
    metaComposition: MapComposition(
      winRatePercent: 57.3,
      agents: [
        CompositionAgent('Omen', 'Contrôleur'),
        CompositionAgent('Jett', 'Duelliste'),
        CompositionAgent('Sova', 'Initiateur'),
        CompositionAgent('Killjoy', 'Sentinelle'),
        CompositionAgent('KAY/O', 'Initiateur'),
      ],
    ),
  ),
  'Bind': MapMetaEntry(
    inCompetitivePool: false,
    metaComposition: MapComposition(
      winRatePercent: 57,
      agents: [
        CompositionAgent('Brimstone', 'Contrôleur'),
        CompositionAgent('Raze', 'Duelliste'),
        CompositionAgent('Skye', 'Initiateur'),
        CompositionAgent('Sage', 'Sentinelle'),
        CompositionAgent('Fade', 'Initiateur'),
      ],
    ),
  ),
  'Breeze': MapMetaEntry(
    inCompetitivePool: false,
    metaComposition: MapComposition(
      winRatePercent: 57.5,
      agents: [
        CompositionAgent('Viper', 'Contrôleur'),
        CompositionAgent('Jett', 'Duelliste'),
        CompositionAgent('Sova', 'Initiateur'),
        CompositionAgent('Killjoy', 'Sentinelle'),
        CompositionAgent('KAY/O', 'Initiateur'),
      ],
    ),
  ),
  'Split': MapMetaEntry(
    inCompetitivePool: true,
    metaComposition: MapComposition(
      winRatePercent: 56.8,
      agents: [
        CompositionAgent('Omen', 'Contrôleur'),
        CompositionAgent('Raze', 'Duelliste'),
        CompositionAgent('Breach', 'Initiateur'),
        CompositionAgent('Cypher', 'Sentinelle'),
        CompositionAgent('Sage', 'Sentinelle'),
      ],
    ),
  ),
  'Fracture': MapMetaEntry(
    inCompetitivePool: false,
    metaComposition: MapComposition(
      winRatePercent: 56.5,
      agents: [
        CompositionAgent('Brimstone', 'Contrôleur'),
        CompositionAgent('Neon', 'Duelliste'),
        CompositionAgent('Breach', 'Initiateur'),
        CompositionAgent('Cypher', 'Sentinelle'),
        CompositionAgent('Fade', 'Initiateur'),
      ],
    ),
  ),
  'Pearl': MapMetaEntry(
    inCompetitivePool: false,
    metaComposition: MapComposition(
      winRatePercent: 56.5,
      agents: [
        CompositionAgent('Viper', 'Contrôleur'),
        CompositionAgent('Jett', 'Duelliste'),
        CompositionAgent('Fade', 'Initiateur'),
        CompositionAgent('Killjoy', 'Sentinelle'),
        CompositionAgent('KAY/O', 'Initiateur'),
      ],
    ),
  ),
  'Lotus': MapMetaEntry(
    inCompetitivePool: true,
    metaComposition: MapComposition(
      winRatePercent: 56.8,
      agents: [
        CompositionAgent('Omen', 'Contrôleur'),
        CompositionAgent('Raze', 'Duelliste'),
        CompositionAgent('Fade', 'Initiateur'),
        CompositionAgent('Killjoy', 'Sentinelle'),
        CompositionAgent('Gekko', 'Initiateur'),
      ],
    ),
  ),
  'Sunset': MapMetaEntry(
    inCompetitivePool: true,
    metaComposition: MapComposition(
      winRatePercent: 57.2,
      agents: [
        CompositionAgent('Clove', 'Contrôleur'),
        CompositionAgent('Neon', 'Duelliste'),
        CompositionAgent('Gekko', 'Initiateur'),
        CompositionAgent('Cypher', 'Sentinelle'),
        CompositionAgent('Phoenix', 'Duelliste'),
      ],
    ),
  ),
  'Abyss': MapMetaEntry(
    inCompetitivePool: true,
    metaComposition: MapComposition(
      winRatePercent: 56,
      agents: [
        CompositionAgent('Omen', 'Contrôleur'),
        CompositionAgent('Jett', 'Duelliste'),
        CompositionAgent('Fade', 'Initiateur'),
        CompositionAgent('Killjoy', 'Sentinelle'),
        CompositionAgent('Clove', 'Contrôleur'),
      ],
    ),
  ),
  'Haven': MapMetaEntry(
    inCompetitivePool: true,
    metaComposition: MapComposition(
      winRatePercent: 56.8,
      agents: [
        CompositionAgent('Omen', 'Contrôleur'),
        CompositionAgent('Jett', 'Duelliste'),
        CompositionAgent('Sova', 'Initiateur'),
        CompositionAgent('Killjoy', 'Sentinelle'),
        CompositionAgent('Breach', 'Initiateur'),
      ],
    ),
  ),
  'Icebox': MapMetaEntry(
    inCompetitivePool: false,
    metaComposition: MapComposition(
      winRatePercent: 57,
      agents: [
        CompositionAgent('Viper', 'Contrôleur'),
        CompositionAgent('Jett', 'Duelliste'),
        CompositionAgent('Sova', 'Initiateur'),
        CompositionAgent('Sage', 'Sentinelle'),
        CompositionAgent('Killjoy', 'Sentinelle'),
      ],
    ),
  ),
  'Summit': MapMetaEntry(
    inCompetitivePool: true,
    metaComposition: MapComposition(
      winRatePercent: 55,
      agents: [
        CompositionAgent('Omen', 'Contrôleur'),
        CompositionAgent('Raze', 'Duelliste'),
        CompositionAgent('Sova', 'Initiateur'),
        CompositionAgent('Killjoy', 'Sentinelle'),
        CompositionAgent('Sage', 'Sentinelle'),
      ],
    ),
  ),
  'Corrode': MapMetaEntry(
    inCompetitivePool: false,
    metaComposition: MapComposition(
      winRatePercent: 56.5,
      agents: [
        CompositionAgent('Viper', 'Contrôleur'),
        CompositionAgent('Waylay', 'Duelliste'),
        CompositionAgent('Gekko', 'Initiateur'),
        CompositionAgent('Deadlock', 'Sentinelle'),
        CompositionAgent('Clove', 'Contrôleur'),
      ],
    ),
  ),
};
