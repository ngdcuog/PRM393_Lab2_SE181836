import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:journal_trend_analyzer/main.dart';
import 'package:journal_trend_analyzer/services/analytics_service.dart';
import 'package:journal_trend_analyzer/services/openalex_service.dart';
import 'package:journal_trend_analyzer/viewmodels/home_viewmodel.dart';

void main() {
  testWidgets('App launches and shows bottom navigation bar',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<OpenAlexService>(create: (_) => OpenAlexService()),
          Provider<AnalyticsService>(create: (_) => AnalyticsService()),
          ChangeNotifierProxyProvider2<OpenAlexService, AnalyticsService, HomeViewModel>(
            create: (context) => HomeViewModel(
              openAlexService: context.read<OpenAlexService>(),
              analyticsService: context.read<AnalyticsService>(),
            ),
            update: (_, openAlex, analytics, previous) =>
                previous ?? HomeViewModel(
                  openAlexService: openAlex,
                  analyticsService: analytics,
                ),
          ),
        ],
        child: const JournalTrendApp(),
      ),
    );

    // Verify the app starts with bottom navigation bar present
    expect(find.byType(NavigationBar), findsOneWidget);
    // Verify Search tab is initially selected
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Trends'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
  });
}
