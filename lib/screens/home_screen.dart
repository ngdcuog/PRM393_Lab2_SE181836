import 'package:flutter/material.dart';

import 'dashboard_screen.dart';
import 'search_screen.dart';
import 'trend_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Journal Trend Analyzer'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.search), text: 'Search'),
              Tab(icon: Icon(Icons.trending_up), text: 'Trends'),
              Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            SearchScreen(),
            TrendScreen(),
            DashboardScreen(),
          ],
        ),
      ),
    );
  }
}
