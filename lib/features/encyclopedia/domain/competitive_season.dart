class CompetitiveSeason {
  const CompetitiveSeason({required this.episodeName, required this.actName, this.actUuid});

  final String episodeName;
  final String actName;

  /// The act's uuid, which match histories carry as their season id.
  final String? actUuid;

  String get label => '$episodeName · $actName';
}
