import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/home_viewmodel.dart';
import '../widgets/stat_summary_card.dart';

/// Dashboard screen showing aggregated statistics for the searched topic.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeViewModel>(
      builder: (context, provider, _) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        if (provider.status == SearchStatus.idle) {
          return Scaffold(
            appBar: AppBar(title: const Text('Research Dashboard')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.dashboard_outlined,
                        size: 72,
                        color: colorScheme.primary.withValues(alpha: 0.4)),
                    const SizedBox(height: 16),
                    Text(
                      'Search a topic to see dashboard',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (provider.status == SearchStatus.loading) {
          return Scaffold(
            appBar: AppBar(title: const Text('Research Dashboard')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final avgCitation =
            provider.avgCitation.toStringAsFixed(2);
        final mostActiveYear = provider.mostActiveYear > 0
            ? '${provider.mostActiveYear}'
            : '-';

        // OA Stats
        final totalPubs = provider.publications.length;
        final oaCount = provider.publications.where((p) => p.isOpenAccess).length;
        final oaPercent = totalPubs > 0 ? (oaCount / totalPubs * 100).toStringAsFixed(1) : '0';
        final oaLabel = '$oaPercent% OA';

        // Research Compass
        String compassStatus = 'Stable';
        Color compassColor = Colors.grey;
        if (provider.trendData.length >= 2) {
          final lastYear = provider.trendData[provider.trendData.length - 1];
          final prevYear = provider.trendData[provider.trendData.length - 2];
          if (lastYear.count > prevYear.count) {
            compassStatus = '🔥 HOT';
            compassColor = Colors.deepOrange;
          } else if (lastYear.count < prevYear.count) {
            compassStatus = '❄️ Cooling';
            compassColor = Colors.blue;
          }
        } else if (provider.trendData.isNotEmpty) {
           compassStatus = '🔥 HOT';
           compassColor = Colors.deepOrange;
        }

        final cards = [
          _CardData(
            icon: '🧭',
            label: 'Research Compass',
            value: compassStatus,
            color: compassColor,
          ),
          _CardData(
            icon: '🔓',
            label: 'Open Access',
            value: oaLabel,
            color: Colors.green,
          ),
          _CardData(
            icon: '📄',
            label: 'Total Publications',
            value: _formatCount(provider.totalCount),
            color: colorScheme.primary,
          ),
          _CardData(
            icon: '⭐',
            label: 'Avg Citations',
            value: avgCitation,
            color: Colors.amber.shade700,
          ),
          _CardData(
            icon: '📅',
            label: 'Most Active Year',
            value: mostActiveYear,
            color: colorScheme.tertiary,
          ),
          _CardData(
            icon: '📰',
            label: 'Top Journal',
            value: provider.topJournal,
            color: Colors.teal,
          ),
        ];

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Research Dashboard',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                if (provider.currentTopic.isNotEmpty)
                  Text(
                    provider.currentTopic,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ─── Stats grid ─────────────────────────────────────────────────
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.0,
                ),
                itemCount: cards.length,
                itemBuilder: (context, index) {
                  final card = cards[index];
                  return StatSummaryCard(
                    icon: card.icon,
                    label: card.label,
                    value: card.value,
                    color: card.color,
                  );
                },
              ),

              const SizedBox(height: 24),

              // ─── Top Authors ─────────────────────────────────────────────────
              _SectionHeader(
                icon: Icons.people_outline,
                title: 'Top 5 Authors',
                color: colorScheme.secondary,
              ),
              const SizedBox(height: 10),
              if (provider.topAuthors.isEmpty)
                const _EmptySection(label: 'No author data available')
              else
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    children: provider.topAuthors
                        .take(5)
                        .toList()
                        .asMap()
                        .entries
                        .map((entry) {
                      final rank = entry.key + 1;
                      final author = entry.value;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: rank == 1
                              ? colorScheme.primary
                              : colorScheme.primaryContainer,
                          radius: 18,
                          child: Text(
                            '$rank',
                            style: TextStyle(
                              color: rank == 1
                                  ? colorScheme.onPrimary
                                  : colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        title: Text(
                          author.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${author.count}',
                            style: TextStyle(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

              const SizedBox(height: 24),

              // ─── Top Journals ─────────────────────────────────────────────────
              const _SectionHeader(
                icon: Icons.library_books_outlined,
                title: 'Top 5 Journals',
                color: Colors.teal,
              ),
              const SizedBox(height: 10),
              if (provider.topJournals.isEmpty)
                const _EmptySection(label: 'No journal data available')
              else
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    children: provider.topJournals
                        .take(5)
                        .toList()
                        .asMap()
                        .entries
                        .map((entry) {
                      final rank = entry.key + 1;
                      final journal = entry.value;
                      final maxCount = provider.topJournals.first.count;
                      final fraction = maxCount > 0
                          ? journal.count / maxCount
                          : 0.0;

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: rank == 1
                                      ? Colors.teal
                                      : colorScheme.surfaceContainerHighest,
                                  child: Text(
                                    '$rank',
                                    style: TextStyle(
                                      color: rank == 1
                                          ? Colors.white
                                          : colorScheme.onSurface,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    journal.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13),
                                  ),
                                ),
                                Text(
                                  '${journal.count}',
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            LinearProgressIndicator(
                              value: fraction,
                              backgroundColor:
                                  colorScheme.surfaceContainerHighest,
                              color: Colors.teal,
                              borderRadius: BorderRadius.circular(4),
                              minHeight: 6,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(0)}k';
    return '$count';
  }
}

// ─── Helper classes ───────────────────────────────────────────────────────────

class _CardData {
  const _CardData({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final String icon;
  final String label;
  final String value;
  final Color color;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}
