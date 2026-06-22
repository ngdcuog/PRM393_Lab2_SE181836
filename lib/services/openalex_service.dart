import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/constants.dart';
import '../core/exceptions.dart';
import '../models/author_profile.dart';
import '../models/author_stat.dart';
import '../models/filter_options.dart';
import '../models/journal_stat.dart';
import '../models/keyword.dart';
import '../models/publication.dart';
import '../models/trend_point.dart';

/// Service responsible for all HTTP communication with the OpenAlex API.
class OpenAlexService {
  OpenAlexService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  // ─── Private helper ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _get(
    String path,
    Map<String, String> params,
  ) async {
    params['mailto'] = AppConstants.mailto;

    final uri = Uri.parse('${AppConstants.baseUrl}$path')
        .replace(queryParameters: params);

    try {
      final response = await _client
          .get(
            uri,
            headers: {
              'User-Agent': 'JournalTrendAnalyzer/1.0 (mailto:${AppConstants.mailto})',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: AppConstants.requestTimeoutSeconds));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      if (response.statusCode == 429) {
        throw const OpenAlexException('Rate limit exceeded. Please wait.');
      }

      throw OpenAlexException('HTTP ${response.statusCode}');
    } on SocketException {
      throw const NetworkException(
        'No internet connection. Please check your network.',
      );
    } on TimeoutException {
      throw const NetworkException(
        'Request timed out. Please try again.',
      );
    }
  }

  // ─── Public API methods ────────────────────────────────────────────────────

  /// Search publications by [topic] with pagination.
  /// Returns a record with the list of items and the total result count.
  Future<({List<Publication> items, int total})> searchWorks(
    String topic,
    int page, {
    FilterOptions? filterOptions,
  }) async {
    final opts = filterOptions ?? const FilterOptions();

    final params = <String, String>{
      'per_page': '${AppConstants.perPage}',
      'page': '$page',
      'filter': opts.toFilterParam(),
    };

    if (topic.isNotEmpty) {
      params['search'] = topic;
      params['sort'] = opts.sortBy;
    } else {
      params['sort'] = opts.sortBy == 'relevance_score:desc' 
          ? 'cited_by_count:desc' 
          : opts.sortBy;
    }

    final data = await _get('/works', params);

    final results = (data['results'] as List? ?? []);
    final total = (data['meta']?['count'] as num?)?.toInt() ?? 0;

    return (
      items: results
          .whereType<Map<String, dynamic>>()
          .map(Publication.fromJson)
          .toList(),
      total: total,
    );
  }

  /// Fetch a single publication by its OpenAlex [workId].
  Future<Publication> getWork(String workId) async {
    // Strip the full URI prefix if present
    final id = workId.replaceFirst('https://openalex.org/', '');
    final data = await _get('/works/$id', {});
    return Publication.fromJson(data);
  }

  /// Fetch publication counts grouped by year for [topic] or [filter].
  /// Filters years between 1990 and the current year.
  Future<List<TrendPoint>> getTrendByYear(String topic, {String? filter}) async {
    final params = <String, String>{
      'group_by': 'publication_year',
      'per_page': '${AppConstants.trendPerPage}',
    };
    if (topic.isNotEmpty) params['search'] = topic;
    if (filter != null && filter.isNotEmpty) params['filter'] = filter;
    
    final data = await _get('/works', params);

    final groupBy = (data['group_by'] as List? ?? []);
    final currentYear = DateTime.now().year;

    return groupBy
        .whereType<Map<String, dynamic>>()
        .map(TrendPoint.fromGroupBy)
        .where(
          (t) => t.year >= AppConstants.minTrendYear && t.year <= currentYear,
        )
        .toList()
      ..sort((a, b) => a.year.compareTo(b.year));
  }

  /// Fetch top journals publishing on [topic] or [filter].
  Future<List<JournalStat>> getTopJournals(String topic, {String? filter, int? limit}) async {
    final params = <String, String>{
      'group_by': 'primary_location.source.id',
      'per_page': '${limit ?? AppConstants.analyticsPerPage}',
    };
    if (topic.isNotEmpty) params['search'] = topic;
    if (filter != null && filter.isNotEmpty) params['filter'] = filter;
    
    final data = await _get('/works', params);

    final groupBy = (data['group_by'] as List? ?? []);

    return groupBy
        .whereType<Map<String, dynamic>>()
        .map(
          (e) => JournalStat(
            id: e['key']?.toString() ?? '',
            name: e['key_display_name']?.toString() ?? 'Unknown',
            count: (e['count'] as num?)?.toInt() ?? 0,
          ),
        )
        .where((j) => j.name != 'Unknown')
        .toList();
  }

  /// Fetch top 10 authors publishing on [topic] or [filter].
  Future<List<AuthorStat>> getTopAuthors(String topic, {String? filter}) async {
    final params = <String, String>{
      'group_by': 'authorships.author.id',
      'per_page': '${AppConstants.analyticsPerPage}',
    };
    if (topic.isNotEmpty) params['search'] = topic;
    if (filter != null && filter.isNotEmpty) params['filter'] = filter;
    
    final data = await _get('/works', params);

    final groupBy = (data['group_by'] as List? ?? []);

    return groupBy
        .whereType<Map<String, dynamic>>()
        .map(
          (e) => AuthorStat(
            id: e['key']?.toString() ?? '',
            name: e['key_display_name']?.toString() ?? 'Unknown',
            count: (e['count'] as num?)?.toInt() ?? 0,
          ),
        )
        .where((a) => a.name != 'Unknown' && a.id.isNotEmpty)
        .toList();
  }

  /// Fetch Must-Read Papers (High citations, recent years, has abstract)
  Future<List<Publication>> getMustReadPapers(String topic) async {
    final data = await _get('/works', {
      'search': topic,
      'filter': 'publication_year:>2015,cited_by_count:>100,has_abstract:true',
      'sort': 'cited_by_count:desc',
      'per_page': '5',
    });
    final results = (data['results'] as List? ?? []);
    return results.whereType<Map<String, dynamic>>().map(Publication.fromJson).toList();
  }

  /// Fetch Rising Papers (Recent papers with high citations)
  Future<List<Publication>> getRisingPapers(String topic) async {
    final data = await _get('/works', {
      'search': topic,
      'filter': 'publication_year:>2021,cited_by_count:>50',
      'sort': 'cited_by_count:desc',
      'per_page': '5',
    });
    final results = (data['results'] as List? ?? []);
    return results.whereType<Map<String, dynamic>>().map(Publication.fromJson).toList();
  }

  /// Fetch Topic Breadcrumb (Hierarchy)
  Future<List<String>> getTopicBreadcrumb(String topic) async {
    final data = await _get('/topics', {
      'search': topic,
      'per_page': '1',
    });
    final results = (data['results'] as List? ?? []);
    if (results.isEmpty) return [];

    final item = results.first as Map<String, dynamic>;
    final breadcrumbs = <String>[];
    if (item['domain']?['display_name'] != null) breadcrumbs.add(item['domain']['display_name']);
    if (item['field']?['display_name'] != null) breadcrumbs.add(item['field']['display_name']);
    if (item['subfield']?['display_name'] != null) breadcrumbs.add(item['subfield']['display_name']);
    if (item['display_name'] != null) breadcrumbs.add(item['display_name']);

    return breadcrumbs;
  }

  /// Fetch Author Profile
  Future<AuthorProfile> getAuthorProfile(String authorId) async {
    final id = authorId.replaceFirst('https://openalex.org/', '');
    final data = await _get('/authors/$id', {});
    return AuthorProfile.fromJson(data);
  }

  /// Fetch Author's recent works
  Future<List<Publication>> getAuthorWorks(String authorId) async {
    final id = authorId.replaceFirst('https://openalex.org/', '');
    final data = await _get('/works', {
      'filter': 'author.id:$id',
      'sort': 'publication_year:desc',
      'per_page': '10',
    });
    final results = (data['results'] as List? ?? []);
    return results.whereType<Map<String, dynamic>>().map(Publication.fromJson).toList();
  }

  /// Search keywords from OpenAlex
  Future<List<Keyword>> searchKeywords(String query, {int? limit}) async {
    final params = <String, String>{'per_page': '${limit ?? 20}'};
    if (query.isNotEmpty) params['search'] = query;
    final data = await _get('/keywords', params);
    final results = (data['results'] as List? ?? []);
    return results.whereType<Map<String, dynamic>>().map(Keyword.fromJson).toList();
  }

  /// Get works by keyword
  Future<({List<Publication> items, int total})> getWorksByKeyword(String keywordId) async {
    final filterId = keywordId.replaceFirst('https://openalex.org/', '');
    return searchWorks('', 1, filterOptions: FilterOptions(keywordId: filterId));
  }
}
