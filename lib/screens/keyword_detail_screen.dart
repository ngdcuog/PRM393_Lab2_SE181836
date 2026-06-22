import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/keyword_viewmodel.dart';
import '../widgets/publication_card.dart';
import 'journal_detail_screen.dart' as import_journal_detail;

class KeywordDetailScreen extends StatefulWidget {
  const KeywordDetailScreen({
    super.key,
    required this.keywordId,
    required this.keywordName,
  });

  final String keywordId;
  final String keywordName;

  @override
  State<KeywordDetailScreen> createState() => _KeywordDetailScreenState();
}

class _KeywordDetailScreenState extends State<KeywordDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<KeywordViewModel>().loadKeywordDetails(
            widget.keywordId,
            widget.keywordName,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.keywordName),
      ),
      body: Consumer<KeywordViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.isLoadingDetails) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.detailsErrorMessage.isNotEmpty) {
            return Center(
              child: Text(
                viewModel.detailsErrorMessage,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              _buildSectionHeader('Trend by Year'),
              SliverToBoxAdapter(child: _buildTrendChart(context, viewModel)),
              
              _buildSectionHeader('Top Authors'),
              _buildAuthorsList(context, viewModel),

              _buildSectionHeader('Related Journals'),
              _buildJournalsList(context, viewModel),

              _buildSectionHeader('Related Publications'),
              _buildPublicationsList(context, viewModel),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildTrendChart(BuildContext context, KeywordViewModel viewModel) {
    if (viewModel.trendData.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: Text('No trend data available.')),
      );
    }

    final data = viewModel.trendData;
    final maxCount = data.map((e) => e.count).reduce((a, b) => a > b ? a : b).toDouble();

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 46,
                interval: maxCount > 0 ? (maxCount / 4).ceilToDouble() : 1,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox.shrink();
                  if (value > maxCount * 1.1) return const SizedBox.shrink(); // Hide top label to prevent cutting off
                  final label = value >= 1000
                      ? '${(value / 1000).toStringAsFixed(0)}K'
                      : value.toInt().toString();
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      label,
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value % 2 != 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      value.toInt().toString(),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: data.first.year.toDouble(),
          maxX: data.last.year.toDouble(),
          minY: 0,
          maxY: maxCount * 1.2,
          lineBarsData: [
            LineChartBarData(
              spots: data.map((e) => FlSpot(e.year.toDouble(), e.count.toDouble())).toList(),
              isCurved: true,
              color: Theme.of(context).colorScheme.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Theme.of(context).colorScheme.primary.withAlpha(50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthorsList(BuildContext context, KeywordViewModel viewModel) {
    if (viewModel.topAuthors.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('No top authors available.')),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final author = viewModel.topAuthors[index];
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(author.name),
            trailing: const Icon(Icons.chevron_right, size: 20),
            subtitle: Text('${author.count} pubs'),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/author',
                arguments: author.id,
              );
            },
          );
        },
        childCount: viewModel.topAuthors.length,
      ),
    );
  }

  Widget _buildJournalsList(BuildContext context, KeywordViewModel viewModel) {
    if (viewModel.relatedJournals.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('No related journals available.')),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final journal = viewModel.relatedJournals[index];
          return ListTile(
            leading: const Icon(Icons.library_books),
            title: Text(journal.name),
            trailing: const Icon(Icons.chevron_right, size: 20),
            subtitle: Text('${journal.count} pubs'),
            onTap: () {
              // Navigate to JournalDetailScreen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => import_journal_detail.JournalDetailScreen(
                    journalId: journal.id,
                    journalName: journal.name,
                  ),
                ),
              );
            },
          );
        },
        childCount: viewModel.relatedJournals.length,
      ),
    );
  }

  Widget _buildPublicationsList(BuildContext context, KeywordViewModel viewModel) {
    if (viewModel.relatedPublications.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('No related publications available.')),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => PublicationCard(
            publication: viewModel.relatedPublications[index],
            onTap: () {
              Navigator.pushNamed(
                context,
                '/detail',
                arguments: viewModel.relatedPublications[index],
              );
            },
          ),
          childCount: viewModel.relatedPublications.length,
        ),
      ),
    );
  }
}
