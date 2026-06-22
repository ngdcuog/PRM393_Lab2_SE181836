import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/journal_viewmodel.dart';
import 'journal_detail_screen.dart';

class JournalsScreen extends StatefulWidget {
  const JournalsScreen({super.key});

  @override
  State<JournalsScreen> createState() => _JournalsScreenState();
}

class _JournalsScreenState extends State<JournalsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JournalViewModel>().loadTopJournals();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Top Journals'),
      ),
      body: Consumer<JournalViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.isLoadingJournals) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.journalsErrorMessage.isNotEmpty) {
            return Center(
              child: Text(
                viewModel.journalsErrorMessage,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            );
          }

          if (viewModel.topJournals.isEmpty) {
            return const Center(child: Text('No journals found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: viewModel.topJournals.length,
            itemBuilder: (context, index) {
              final journal = viewModel.topJournals[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Text('${index + 1}'),
                  ),
                  title: Text(
                    journal.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${journal.count} publications'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => JournalDetailScreen(
                          journalId: journal.id,
                          journalName: journal.name,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
