class DashboardData {
  const DashboardData({
    required this.topic,
    required this.totalPublications,
    required this.avgCitations,
    required this.topAuthor,
    required this.topJournal,
    required this.mostActiveYear,
  });

  final String topic;
  final int totalPublications;
  final double avgCitations;
  final String topAuthor;
  final String topJournal;
  final int mostActiveYear;
}
