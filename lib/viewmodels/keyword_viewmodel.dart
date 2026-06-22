import 'package:flutter/foundation.dart';

import '../models/author_stat.dart';
import '../models/journal_stat.dart';
import '../models/keyword.dart';
import '../models/publication.dart';
import '../models/trend_point.dart';
import '../models/filter_options.dart';
import '../services/analytics_service.dart';
import '../services/openalex_service.dart';
import '../services/remote_config_service.dart';

class KeywordViewModel extends ChangeNotifier {
  KeywordViewModel({
    required OpenAlexService openAlexService,
    required AnalyticsService analyticsService,
    required RemoteConfigService remoteConfigService,
  })  : _openAlexService = openAlexService,
        _analyticsService = analyticsService,
        _remoteConfigService = remoteConfigService;

  final OpenAlexService _openAlexService;
  final AnalyticsService _analyticsService;
  final RemoteConfigService _remoteConfigService;

  // ─── State for Keywords Search ─────────────────────────────────────────────

  bool _isSearching = false;
  String _searchErrorMessage = '';
  List<Keyword> _searchResults = [];

  bool get isSearching => _isSearching;
  String get searchErrorMessage => _searchErrorMessage;
  List<Keyword> get searchResults => List.unmodifiable(_searchResults);

  // ─── State for Keyword Details ─────────────────────────────────────────────

  bool _isLoadingDetails = false;
  String _detailsErrorMessage = '';
  
  List<TrendPoint> _trendData = [];
  List<JournalStat> _relatedJournals = [];
  List<AuthorStat> _topAuthors = [];
  List<Publication> _relatedPublications = [];

  bool get isLoadingDetails => _isLoadingDetails;
  String get detailsErrorMessage => _detailsErrorMessage;
  List<TrendPoint> get trendData => List.unmodifiable(_trendData);
  List<JournalStat> get relatedJournals => List.unmodifiable(_relatedJournals);
  List<AuthorStat> get topAuthors => List.unmodifiable(_topAuthors);
  List<Publication> get relatedPublications => List.unmodifiable(_relatedPublications);

  // ─── Methods ───────────────────────────────────────────────────────────────

  Future<void> searchKeywords(String query) async {
    _isSearching = true;
    _searchErrorMessage = '';
    notifyListeners();

    try {
      final limit = _remoteConfigService.maxKeywords;
      _searchResults = await _openAlexService.searchKeywords(query, limit: limit);
    } catch (e) {
      _searchErrorMessage = e.toString().replaceFirst(RegExp(r'^.*Exception: '), '');
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  Future<void> loadKeywordDetails(String keywordId, String keywordName) async {
    _isLoadingDetails = true;
    _detailsErrorMessage = '';
    _trendData = [];
    _relatedJournals = [];
    _topAuthors = [];
    _relatedPublications = [];
    notifyListeners();

    try {
      final filterId = keywordId.replaceFirst('https://openalex.org/', '');
      final filterOpts = FilterOptions(keywordId: filterId);
      final filterStr = filterOpts.toFilterParam();

      // Run multiple API calls concurrently
      final results = await Future.wait([
        _openAlexService.getTrendByYear('', filter: filterStr),
        _openAlexService.getTopJournals('', filter: filterStr),
        _openAlexService.getTopAuthors('', filter: filterStr),
        _openAlexService.getWorksByKeyword(filterId),
      ]);

      _trendData = results[0] as List<TrendPoint>;
      _relatedJournals = results[1] as List<JournalStat>;
      _topAuthors = results[2] as List<AuthorStat>;
      
      final worksResult = results[3] as ({List<Publication> items, int total});
      _relatedPublications = worksResult.items;

      await _analyticsService.logViewKeyword(keywordName);
    } catch (e) {
      _detailsErrorMessage = e.toString().replaceFirst(RegExp(r'^.*Exception: '), '');
    } finally {
      _isLoadingDetails = false;
      notifyListeners();
    }
  }
}
