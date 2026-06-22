import 'package:firebase_analytics/firebase_analytics.dart';

/// Service responsible for logging events to Firebase Analytics.
class AnalyticsService {
  final _analytics = FirebaseAnalytics.instance;

  Future<void> logSearch(String keyword) =>
      _analytics.logEvent(name: 'search_topic', parameters: {'keyword': keyword});

  Future<void> logViewPublication(String title, int year) =>
      _analytics.logEvent(name: 'view_publication', parameters: {
        'publication_title': title,
        'publication_year': year,
      });

  Future<void> logViewJournal(String name) =>
      _analytics.logEvent(name: 'view_journal', parameters: {'journal_name': name});

  Future<void> logViewKeyword(String keyword) =>
      _analytics.logEvent(name: 'view_keyword', parameters: {'keyword': keyword});

  Future<void> logExportPdf(String topic) =>
      _analytics.logEvent(name: 'export_pdf', parameters: {'topic': topic});

  Future<void> logLogin() => _analytics.logEvent(name: 'login');
  
  Future<void> logLogout() => _analytics.logEvent(name: 'logout');
}
