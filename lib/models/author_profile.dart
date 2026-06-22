class AuthorProfile {
  const AuthorProfile({
    required this.id,
    required this.name,
    this.institution,
    required this.worksCount,
    required this.citedByCount,
    required this.topTopics,
  });

  final String id;
  final String name;
  final String? institution;
  final int worksCount;
  final int citedByCount;
  final List<String> topTopics;

  factory AuthorProfile.fromJson(Map<String, dynamic> json) {
    final lastKnownInstitution = json['last_known_institution'];
    final institutionName = lastKnownInstitution is Map
        ? lastKnownInstitution['display_name']?.toString()
        : null;

    final topicsData = json['topics'] as List? ?? [];
    final topics = topicsData
        .take(5)
        .map((t) {
          final topicName = t['display_name']?.toString();
          return topicName;
        })
        .whereType<String>()
        .toList();

    return AuthorProfile(
      id: json['id']?.toString() ?? '',
      name: json['display_name']?.toString() ?? 'Unknown Author',
      institution: institutionName,
      worksCount: (json['works_count'] as num?)?.toInt() ?? 0,
      citedByCount: (json['cited_by_count'] as num?)?.toInt() ?? 0,
      topTopics: topics,
    );
  }
}
