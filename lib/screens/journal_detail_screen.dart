import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/journal_viewmodel.dart';
import '../widgets/publication_card.dart';

class JournalDetailScreen extends StatefulWidget {
  const JournalDetailScreen({
    super.key,
    required this.journalId,
    required this.journalName,
  });

  final String journalId;
  final String journalName;

  @override
  State<JournalDetailScreen> createState() => _JournalDetailScreenState();
}

class _JournalDetailScreenState extends State<JournalDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JournalViewModel>().loadJournalDetails(
            widget.journalId,
            widget.journalName,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.journalName),
      ),
      body: Consumer<JournalViewModel>(
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
              SliverToBoxAdapter(
                child: _buildStatsHeader(context, viewModel),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text(
                    'Top Publications',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              if (viewModel.journalPublications.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('No publications available.')),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => PublicationCard(
                        publication: viewModel.journalPublications[index],
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/detail',
                            arguments: viewModel.journalPublications[index],
                          );
                        },
                      ),
                      childCount: viewModel.journalPublications.length,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsHeader(BuildContext context, JournalViewModel viewModel) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              context,
              'Publications',
              '${viewModel.totalPublications}',
              Icons.article,
            ),
            _buildStatItem(
              context,
              'Citations (Top)',
              '${viewModel.totalCitations}',
              Icons.format_quote,
            ),
            _buildStatItem(
              context,
              'Avg Citations',
              viewModel.avgCitations.toStringAsFixed(1),
              Icons.analytics,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(icon, color: colorScheme.primary, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
