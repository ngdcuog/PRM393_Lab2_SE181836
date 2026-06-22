import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/pdf_export_service.dart' as import_pdf;
import '../models/dashboard_data.dart' as import_dashboard;
import '../viewmodels/home_viewmodel.dart';
import '../widgets/trend_bar_chart.dart';

/// Screen displaying publication trend analysis for the searched topic.
class TrendScreen extends StatelessWidget {
  const TrendScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeViewModel>(
      builder: (context, provider, _) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        // Idle state
        if (provider.status == SearchStatus.idle) {
          return Scaffold(
            appBar: AppBar(title: const Text('Trend Analysis')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.trending_up,
                        size: 72, color: colorScheme.primary.withValues(alpha: 0.4)),
                    const SizedBox(height: 16),
                    Text(
                      'Search a topic to see trends',
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

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Trend Analysis',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
          body: () {
            if (provider.status == SearchStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.status == SearchStatus.error) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64, color: colorScheme.error),
                      const SizedBox(height: 16),
                      Text(
                        provider.errorMessage,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              );
            }

            if (provider.trendData.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bar_chart,
                        size: 72, color: colorScheme.outline),
                    const SizedBox(height: 16),
                    Text(
                      'No trend data available',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }

            final totalPapers =
                provider.trendData.map((t) => t.count).reduce((a, b) => a + b);

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ─── Topic Breadcrumbs ─────────────────────────────────────────
                if (provider.topicBreadcrumbs.isNotEmpty) ...[
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: provider.topicBreadcrumbs.asMap().entries.map((entry) {
                      final isLast = entry.key == provider.topicBreadcrumbs.length - 1;
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            entry.value,
                            style: TextStyle(
                              fontSize: 12,
                              color: isLast ? colorScheme.primary : colorScheme.onSurfaceVariant,
                              fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          if (!isLast)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(Icons.chevron_right, size: 14, color: colorScheme.onSurfaceVariant),
                            ),
                        ],
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // ─── Chart card ───────────────────────────────────────────────
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 12),
                          child: Text(
                            'Publications per Year',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        TrendBarChart(data: provider.trendData),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _Legend(
                                color: colorScheme.primary, label: 'Publications'),
                            const SizedBox(width: 16),
                            const _Legend(color: Colors.amber, label: 'Peak year'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ─── Stats row ────────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.star_rounded,
                        title: 'Peak Year',
                        value: provider.mostActiveYear > 0
                            ? '${provider.mostActiveYear}'
                            : '-',
                        color: Colors.amber,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.article_outlined,
                        title: 'Total Papers',
                        value: _formatCount(totalPapers),
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ─── Must-Read Papers ──────────────────────────────────────────
                if (provider.mustReadPapers.isNotEmpty) ...[
                  Text(
                    'Must-Read Papers',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ...provider.mustReadPapers
                      .take(5)
                      .toList()
                      .asMap()
                      .entries
                      .map((entry) {
                    final rank = entry.key + 1;
                    final pub = entry.value;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: rank == 1
                              ? Colors.amber
                              : colorScheme.primaryContainer,
                          child: Text(
                            '$rank',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: rank == 1
                                  ? Colors.white
                                  : colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        title: Text(
                          pub.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${pub.citationCount} citations · ${pub.year} ${pub.isOpenAccess ? '· 🔓 OA' : ''}',
                          style: TextStyle(
                              color: colorScheme.onSurfaceVariant, fontSize: 12),
                        ),
                        onTap: () =>
                            Navigator.of(context).pushNamed('/detail', arguments: pub),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                ],

                // ─── Rising Papers ─────────────────────────────────────────────
                if (provider.risingPapers.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.local_fire_department, color: Colors.deepOrange, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Rising Papers (Trending)',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...provider.risingPapers
                      .take(5)
                      .toList()
                      .map((pub) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        title: Text(
                          pub.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${pub.citationCount} citations · ${pub.year}',
                          style: TextStyle(
                              color: colorScheme.onSurfaceVariant, fontSize: 12),
                        ),
                        trailing: const Icon(Icons.trending_up, color: Colors.green),
                        onTap: () =>
                            Navigator.of(context).pushNamed('/detail', arguments: pub),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                ],

                // ─── Key Authors ───────────────────────────────────────────────
                if (provider.topAuthors.isNotEmpty) ...[
                  Text(
                    'Key Authors to Follow',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 140,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: provider.topAuthors.length > 5 ? 5 : provider.topAuthors.length,
                      itemBuilder: (context, index) {
                        final author = provider.topAuthors[index];
                        return Container(
                          width: 120,
                          margin: const EdgeInsets.only(right: 12),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                Navigator.of(context).pushNamed('/author', arguments: author.id);
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: colorScheme.tertiaryContainer,
                                      child: Text(
                                        author.name.substring(0, 1).toUpperCase(),
                                        style: TextStyle(
                                          color: colorScheme.onTertiaryContainer,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      author.name,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            );
          }(),
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
