import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../models/dashboard_data.dart';
import '../services/analytics_service.dart';
import '../services/crashlytics_service.dart';
import '../services/messaging_service.dart';
import '../services/pdf_export_service.dart';
import '../services/remote_config_service.dart';

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel({
    required AnalyticsService analyticsService,
    required CrashlyticsService crashlyticsService,
    required MessagingService messagingService,
    required PdfExportService pdfExportService,
    required RemoteConfigService remoteConfigService,
  })  : _analyticsService = analyticsService,
        _crashlyticsService = crashlyticsService,
        _messagingService = messagingService,
        _pdfExportService = pdfExportService,
        _remoteConfigService = remoteConfigService {
    _init();
  }

  final AnalyticsService _analyticsService;
  final CrashlyticsService _crashlyticsService;
  final MessagingService _messagingService;
  final PdfExportService _pdfExportService;
  final RemoteConfigService _remoteConfigService;

  StreamSubscription? _messagingSub;

  List<RemoteMessage> get notifications => List.unmodifiable(_messagingService.notificationHistory);

  bool _isExporting = false;
  String _exportUrl = '';
  String _exportError = '';

  bool get isExporting => _isExporting;
  String get exportUrl => _exportUrl;
  String get exportError => _exportError;

  int get maxJournalsDisplayed => _remoteConfigService.maxJournals;
  int get maxKeywordsDisplayed => _remoteConfigService.maxKeywords;

  void _init() {
    _messagingSub = _messagingService.onMessage.listen((message) {
      notifyListeners();
    });
    
    // Print token to console for instant testing via Firebase Console
    _messagingService.getToken().then((token) {
      debugPrint('====================================');
      debugPrint('FCM TEST TOKEN: $token');
      debugPrint('====================================');
    });
  }

  @override
  void dispose() {
    _messagingSub?.cancel();
    super.dispose();
  }

  Future<void> logLogout() async {
    await _analyticsService.logLogout();
  }

  Future<void> exportDashboardAsPdf() async {
    _isExporting = true;
    _exportUrl = '';
    _exportError = '';
    notifyListeners();

    try {
      const mockData = DashboardData(
        topic: 'Artificial Intelligence',
        totalPublications: 1500,
        avgCitations: 24.5,
        topAuthor: 'John Doe',
        topJournal: 'Nature AI',
        mostActiveYear: 2023,
      );
      _exportUrl = await _pdfExportService.exportDashboardAsPdf(mockData);
      await _analyticsService.logExportPdf(mockData.topic);
    } catch (e) {
      _exportError = e.toString().replaceFirst(RegExp(r'^.*Exception: '), '');
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }

  Future<void> refreshRemoteConfig() async {
    await _remoteConfigService.refresh();
    notifyListeners();
  }

  void triggerHandledException() {
    try {
      throw Exception('This is a handled test exception from Profile');
    } catch (e, stack) {
      _crashlyticsService.logHandledException(e, stack, reason: 'Test Handled Exception');
    }
  }

  void triggerTestCrash() {
    _crashlyticsService.triggerTestCrash();
  }
}
