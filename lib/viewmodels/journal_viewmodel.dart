import 'package:flutter/foundation.dart';

import '../models/filter_options.dart';
import '../models/journal_stat.dart';
import '../models/publication.dart';
import '../services/analytics_service.dart';
import '../services/openalex_service.dart';
import '../services/remote_config_service.dart';

class JournalViewModel extends ChangeNotifier {
  JournalViewModel({
    required OpenAlexService openAlexService,
    required AnalyticsService analyticsService,
    required RemoteConfigService remoteConfigService,
  })  : _openAlexService = openAlexService,
        _analyticsService = analyticsService,
        _remoteConfigService = remoteConfigService;

  final OpenAlexService _openAlexService;
  final AnalyticsService _analyticsService;
  final RemoteConfigService _remoteConfigService;

  // ─── State for Journals List ───────────────────────────────────────────────

  bool _isLoadingJournals = false;
  String _journalsErrorMessage = '';
  List<JournalStat> _topJournals = [];

  bool get isLoadingJournals => _isLoadingJournals;
  String get journalsErrorMessage => _journalsErrorMessage;
  List<JournalStat> get topJournals => List.unmodifiable(_topJournals);

  // ─── State for Journal Details ─────────────────────────────────────────────

  bool _isLoadingDetails = false;
  String _detailsErrorMessage = '';
  List<Publication> _journalPublications = [];
  int _totalPublications = 0;
  int _totalCitations = 0;
  double _avgCitations = 0.0;

  bool get isLoadingDetails => _isLoadingDetails;
  String get detailsErrorMessage => _detailsErrorMessage;
  List<Publication> get journalPublications =>
      List.unmodifiable(_journalPublications);
  int get totalPublications => _totalPublications;
  int get totalCitations => _totalCitations;
  double get avgCitations => _avgCitations;

  // ─── Methods ───────────────────────────────────────────────────────────────

  Future<void> loadTopJournals() async {
    if (_topJournals.isNotEmpty) return; // Cache basic
    _isLoadingJournals = true;
    _journalsErrorMessage = '';
    notifyListeners();

    try {
      // Pass type:article filter to get overall top journals that actually publish articles
      final limit = _remoteConfigService.maxJournals;
      _topJournals = await _openAlexService.getTopJournals('', filter: const FilterOptions().toFilterParam(), limit: limit);
    } catch (e) {
      _journalsErrorMessage = e.toString().replaceFirst(RegExp(r'^.*Exception: '), '');
    } finally {
      _isLoadingJournals = false;
      notifyListeners();
    }
  }

  Future<void> loadJournalDetails(String journalId, String journalName) async {
    _isLoadingDetails = true;
    _detailsErrorMessage = '';
    _journalPublications = [];
    _totalPublications = 0;
    _totalCitations = 0;
    _avgCitations = 0.0;
    notifyListeners();

    try {
      // Fetch works for this specific journal ID
      // Example ID format from group_by is the full URL, but FilterOptions handles the id part if needed,
      // or openalex handles the full URL. We pass the raw ID.
      final filterId = journalId.replaceFirst('https://openalex.org/', '');
      
      final result = await _openAlexService.searchWorks(
        '',
        1,
        filterOptions: FilterOptions(sourceId: filterId),
      );

      _journalPublications = result.items;
      _totalPublications = result.total;

      // Calculate citations from loaded items (Top 25)
      if (_journalPublications.isNotEmpty) {
        _totalCitations = _journalPublications.fold(
          0,
          (sum, pub) => sum + pub.citationCount,
        );
        _avgCitations = _totalCitations / _journalPublications.length;
      }

      await _analyticsService.logViewJournal(journalName);
    } catch (e) {
      _detailsErrorMessage = e.toString().replaceFirst(RegExp(r'^.*Exception: '), '');
    } finally {
      _isLoadingDetails = false;
      notifyListeners();
    }
  }
}
