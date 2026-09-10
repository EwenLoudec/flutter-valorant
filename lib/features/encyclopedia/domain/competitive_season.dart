class CompetitiveSeason {
  const CompetitiveSeason({required this.episodeName, required this.actName});

  final String episodeName;
  final String actName;

  String get label => '$episodeName · $actName';
}
