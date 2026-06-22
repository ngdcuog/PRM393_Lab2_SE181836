import '../core/utils/abstract_parser.dart';

/// Represents a single academic publication (work) from OpenAlex.
class Publication {
  const Publication({
    required this.id,
    required this.title,
    required this.year,
    required this.citationCount,
    required this.authors,
    this.journalName,
    this.doi,
    this.abstractText,
    this.isOpenAccess = false,
    this.oaUrl,
    this.type = 'article',
    this.primaryTopic,
    this.field,
  });

  final String id;
  final String title;
  final int year;
  final int citationCount;
  final String? journalName;
  final String? doi;
  final String? abstractText;
  final List<String> authors;
  final bool isOpenAccess;
  final String? oaUrl;
  final String type;
  final String? primaryTopic;
  final String? field;

  factory Publication.fromJson(Map<String, dynamic> json) {
    // Parse authors from authorships array
    final authorships = (json['authorships'] as List? ?? []);
    final authors = authorships
        .map((a) {
          final author = a['author'];
          if (author == null) return null;
          return author['display_name']?.toString();
        })
        .whereType<String>()
        .toList();

    // Parse abstract from inverted index
    final invertedIndex = json['abstract_inverted_index'];
    String? abstractText;
    if (invertedIndex is Map<String, dynamic>) {
      abstractText = AbstractParser.parse(invertedIndex);
    }

    // Parse journal name from primary_location
    final primaryLocation = json['primary_location'];
    final source = primaryLocation is Map ? primaryLocation['source'] : null;
    final journalName =
        source is Map ? source['display_name']?.toString() : null;

    final primaryTopicNode = json['primary_topic'] as Map<String, dynamic>?;

    return Publication(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'No title',
      year: (json['publication_year'] as num?)?.toInt() ?? 0,
      citationCount: (json['cited_by_count'] as num?)?.toInt() ?? 0,
      doi: json['doi']?.toString(),
      journalName: journalName,
      abstractText: abstractText,
      authors: authors,
      isOpenAccess: json['open_access']?['is_oa'] ?? false,
      oaUrl: json['open_access']?['oa_url']?.toString(),
      type: json['type']?.toString() ?? 'article',
      primaryTopic: primaryTopicNode?['display_name']?.toString(),
      field: primaryTopicNode?['field']?['display_name']?.toString(),
    );
  }
}

