import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/analytics_service.dart';
import 'services/auth_service.dart';
import 'services/crashlytics_service.dart';
import 'services/messaging_service.dart';
import 'services/openalex_service.dart';
import 'services/pdf_export_service.dart';
import 'services/remote_config_service.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/home_viewmodel.dart';
import 'viewmodels/journal_viewmodel.dart';
import 'viewmodels/keyword_viewmodel.dart';
import 'viewmodels/profile_viewmodel.dart';
import 'navigation/main_navigation.dart';
import 'screens/login_screen.dart';
import 'screens/detail_screen.dart';
import 'screens/author_profile_screen.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final messagingService = MessagingService();
  await messagingService.initialize();

  final crashlyticsService = CrashlyticsService();
  await crashlyticsService.initialize();

  final remoteConfigService = RemoteConfigService();
  await remoteConfigService.initialize();

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProxyProvider<AuthService, AuthViewModel>(
          create: (context) => AuthViewModel(authService: context.read<AuthService>()),
          update: (_, authService, previous) =>
              previous ?? AuthViewModel(authService: authService),
        ),
        Provider<OpenAlexService>(create: (_) => OpenAlexService()),
        Provider<AnalyticsService>(create: (_) => AnalyticsService()),
        Provider<CrashlyticsService>.value(value: crashlyticsService),
        Provider<MessagingService>.value(value: messagingService),
        Provider<PdfExportService>(create: (_) => PdfExportService()),
        Provider<RemoteConfigService>.value(value: remoteConfigService),
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
        ChangeNotifierProxyProvider3<OpenAlexService, AnalyticsService, RemoteConfigService, JournalViewModel>(
          create: (context) => JournalViewModel(
            openAlexService: context.read<OpenAlexService>(),
            analyticsService: context.read<AnalyticsService>(),
            remoteConfigService: context.read<RemoteConfigService>(),
          ),
          update: (_, openAlex, analytics, config, previous) =>
              previous ?? JournalViewModel(
                openAlexService: openAlex,
                analyticsService: analytics,
                remoteConfigService: config,
              ),
        ),
        ChangeNotifierProxyProvider3<OpenAlexService, AnalyticsService, RemoteConfigService, KeywordViewModel>(
          create: (context) => KeywordViewModel(
            openAlexService: context.read<OpenAlexService>(),
            analyticsService: context.read<AnalyticsService>(),
            remoteConfigService: context.read<RemoteConfigService>(),
          ),
          update: (_, openAlex, analytics, config, previous) =>
              previous ?? KeywordViewModel(
                openAlexService: openAlex,
                analyticsService: analytics,
                remoteConfigService: config,
              ),
        ),
        ChangeNotifierProxyProvider5<AnalyticsService, CrashlyticsService, MessagingService, PdfExportService, RemoteConfigService, ProfileViewModel>(
          create: (context) => ProfileViewModel(
            analyticsService: context.read<AnalyticsService>(),
            crashlyticsService: context.read<CrashlyticsService>(),
            messagingService: context.read<MessagingService>(),
            pdfExportService: context.read<PdfExportService>(),
            remoteConfigService: context.read<RemoteConfigService>(),
          ),
          update: (_, analytics, crashlytics, messaging, pdf, config, previous) =>
              previous ?? ProfileViewModel(
                analyticsService: analytics,
                crashlyticsService: crashlytics,
                messagingService: messaging,
                pdfExportService: pdf,
                remoteConfigService: config,
              ),
        ),
      ],
      child: const JournalTrendApp(),
    ),
  );
}

class JournalTrendApp extends StatelessWidget {
  const JournalTrendApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Journal Trend Analyzer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 2,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            return const MainNavigation();
          }
          return const LoginScreen();
        },
      ),
      routes: {
        '/detail': (context) => const DetailScreen(),
        '/author': (context) => AuthorProfileScreen(
              authorId: ModalRoute.of(context)!.settings.arguments as String,
            ),
      },
    );
  }
}
