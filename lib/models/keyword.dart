/// Represents a keyword entity from OpenAlex API.
class Keyword {
  const Keyword({
    required this.id,
    required this.displayName,
    required this.worksCount,
  });

  final String id;
  final String displayName;
  final int worksCount;

  factory Keyword.fromJson(Map<String, dynamic> json) {
    return Keyword(
      id: json['id']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? 'Unknown',
      worksCount: (json['works_count'] as num?)?.toInt() ?? 0,
    );
  }
}
