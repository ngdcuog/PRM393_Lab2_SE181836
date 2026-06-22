/// Options for filtering search results from OpenAlex
class FilterOptions {
  const FilterOptions({
    this.domainId,
    this.fieldId,
    this.sourceId,
    this.keywordId,
    this.yearFrom,
    this.yearTo,
    this.openAccessOnly = false,
    this.sortBy = 'relevance_score:desc',
  });

  final String? domainId;
  final String? fieldId;
  final String? sourceId;
  final String? keywordId;
  final int? yearFrom;
  final int? yearTo;
  final bool openAccessOnly;
  final String sortBy; // e.g., 'cited_by_count:desc', 'publication_year:desc'

  FilterOptions copyWith({
    String? domainId,
    String? fieldId,
    String? sourceId,
    String? keywordId,
    int? yearFrom,
    int? yearTo,
    bool? openAccessOnly,
    String? sortBy,
  }) {
    return FilterOptions(
      domainId: domainId ?? this.domainId,
      fieldId: fieldId ?? this.fieldId,
      sourceId: sourceId ?? this.sourceId,
      keywordId: keywordId ?? this.keywordId,
      yearFrom: yearFrom ?? this.yearFrom,
      yearTo: yearTo ?? this.yearTo,
      openAccessOnly: openAccessOnly ?? this.openAccessOnly,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  /// Convert options into the 'filter' parameter string format expected by OpenAlex
  String toFilterParam() {
    final parts = <String>[];
    
    // Default filter for app context
    parts.add('type:article');

    if (domainId != null) {
      parts.add('primary_topic.domain.id:$domainId');
    }
    
    if (fieldId != null) {
      parts.add('primary_topic.field.id:$fieldId');
    }
    
    if (sourceId != null) {
      parts.add('primary_location.source.id:$sourceId');
    }
    
    if (keywordId != null) {
      parts.add('keywords.id:$keywordId');
    }
    
    if (yearFrom != null && yearTo != null) {
      parts.add('publication_year:$yearFrom-$yearTo');
    } else if (yearFrom != null) {
      parts.add('publication_year:>$yearFrom');
    } else if (yearTo != null) {
      parts.add('publication_year:<$yearTo');
    }
    
    if (openAccessOnly) {
      parts.add('is_oa:true');
    }
    
    return parts.join(',');
  }
}
