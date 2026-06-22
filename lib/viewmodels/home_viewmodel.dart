import 'package:flutter/foundation.dart';

import '../models/author_stat.dart';
import '../models/filter_options.dart';
import '../models/journal_stat.dart';
import '../models/publication.dart';
import '../models/trend_point.dart';
import '../services/analytics_service.dart';
import '../services/openalex_service.dart';

enum SearchStatus { idle, loading, loaded, error }

/// ViewModel for the Home screen (Search, Trends, Dashboard).
/// Manages search results, analytics data, and pagination.
class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    required OpenAlexService openAlexService,
    required AnalyticsService analyticsService,
  })  : _openAlexService = openAlexService,
        _analyticsService = analyticsService;

  final OpenAlexService _openAlexService;
  final AnalyticsService _analyticsService;

  // ─── State ─────────────────────────────────────────────────────────────────

  String _currentTopic = '';
  SearchStatus _status = SearchStatus.idle;
  String _errorMessage = '';

  List<Publication> _publications = [];
  int _totalCount = 0;
  int _currentPage = 1;
  bool _hasMore = false;
  bool _isLoadingMore = false;

  FilterOptions _filterOptions = const FilterOptions();

  List<TrendPoint> _trendData = [];
  List<JournalStat> _topJournals = [];
  List<AuthorStat> _topAuthors = [];
  List<Publication> _mustReadPapers = [];
  List<Publication> _risingPapers = [];
  List<String> _topicBreadcrumbs = [];

  // ─── Getters ───────────────────────────────────────────────────────────────

  String get currentTopic => _currentTopic;
  SearchStatus get status => _status;
  String get errorMessage => _errorMessage;
  List<Publication> get publications => List.unmodifiable(_publications);
  int get totalCount => _totalCount;
  int get currentPage => _currentPage;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;
  FilterOptions get filterOptions => _filterOptions;

  List<TrendPoint> get trendData => List.unmodifiable(_trendData);
  List<JournalStat> get topJournals => List.unmodifiable(_topJournals);
  List<AuthorStat> get topAuthors => List.unmodifiable(_topAuthors);
  List<Publication> get mustReadPapers => List.unmodifiable(_mustReadPapers);
  List<Publication> get risingPapers => List.unmodifiable(_risingPapers);
  List<String> get topicBreadcrumbs => List.unmodifiable(_topicBreadcrumbs);

  // ─── Computed Getters ──────────────────────────────────────────────────────

  int get mostActiveYear {
    if (_trendData.isEmpty) return 0;
    return _trendData.reduce((a, b) => a.count > b.count ? a : b).year;
  }

  String get topJournal =>
      _topJournals.isEmpty ? '-' : _topJournals.first.name;

  String get topAuthor => _topAuthors.isEmpty ? '-' : _topAuthors.first.name;

  double get avgCitation {
    if (_publications.isEmpty) return 0.0;
    final total =
        _publications.map((p) => p.citationCount).reduce((a, b) => a + b);
    return total / _publications.length;
  }

  Publication? get mostCitedPaper {
    if (_publications.isEmpty) return null;
    return _publications.reduce(
      (a, b) => a.citationCount > b.citationCount ? a : b,
    );
  }

  // ─── Methods ───────────────────────────────────────────────────────────────

  Future<void> search(String topic, {FilterOptions? options}) async {
    _currentTopic = topic.trim();
    if (options != null) {
      _filterOptions = options;
    }
    
    _status = SearchStatus.loading;
    _publications = [];
    _currentPage = 1;
    _hasMore = false;
    _errorMessage = '';
    notifyListeners();

    try {
      await Future.wait([
        _loadPublications(),
        _loadAnalytics(),
      ]);
      _status = SearchStatus.loaded;

      // Log to Analytics
      await _analyticsService.logSearch(_currentTopic);
    } catch (e) {
      _status = SearchStatus.error;
      _errorMessage = e.toString().replaceFirst(RegExp(r'^.*Exception: '), '');
    }

    notifyListeners();
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore || _status == SearchStatus.loading) return;

    _isLoadingMore = true;
    _currentPage++;
    notifyListeners();

    try {
      await _loadPublications();
    } catch (e) {
      _currentPage--;
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  void reset() {
    _currentTopic = '';
    _status = SearchStatus.idle;
    _errorMessage = '';
    _publications = [];
    _totalCount = 0;
    _currentPage = 1;
    _hasMore = false;
    _isLoadingMore = false;
    _filterOptions = const FilterOptions();
    _trendData = [];
    _topJournals = [];
    _topAuthors = [];
    _mustReadPapers = [];
    _risingPapers = [];
    _topicBreadcrumbs = [];
    notifyListeners();
  }

  // ─── Private helpers ───────────────────────────────────────────────────────

  Future<void> _loadPublications() async {
    final result = await _openAlexService.searchWorks(
      _currentTopic, 
      _currentPage,
      filterOptions: _filterOptions,
    );

    if (_currentPage == 1) {
      _publications = result.items;
    } else {
      _publications = [..._publications, ...result.items];
    }

    _totalCount = result.total;
    _hasMore = _publications.length < _totalCount;
  }

  Future<void> _loadAnalytics() async {
    final results = await Future.wait([
      _openAlexService.getTrendByYear(_currentTopic, filter: _filterOptions.toFilterParam()),
      _openAlexService.getTopJournals(_currentTopic, filter: _filterOptions.toFilterParam()),
      _openAlexService.getTopAuthors(_currentTopic, filter: _filterOptions.toFilterParam()),
      _openAlexService.getMustReadPapers(_currentTopic),
      _openAlexService.getRisingPapers(_currentTopic),
      _openAlexService.getTopicBreadcrumb(_currentTopic),
    ]);

    _trendData = results[0] as List<TrendPoint>;
    _topJournals = results[1] as List<JournalStat>;
    _topAuthors = results[2] as List<AuthorStat>;
    _mustReadPapers = results[3] as List<Publication>;
    _risingPapers = results[4] as List<Publication>;
    _topicBreadcrumbs = results[5] as List<String>;
  }
}
