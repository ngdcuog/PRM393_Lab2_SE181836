import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/keyword_viewmodel.dart';
import 'keyword_detail_screen.dart';

class KeywordsScreen extends StatefulWidget {
  const KeywordsScreen({super.key});

  @override
  State<KeywordsScreen> createState() => _KeywordsScreenState();
}

class _KeywordsScreenState extends State<KeywordsScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Load some trending keywords by default (empty query)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<KeywordViewModel>().searchKeywords('');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<KeywordViewModel>().searchKeywords(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keywords'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search keywords...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Consumer<KeywordViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.isSearching) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.searchErrorMessage.isNotEmpty) {
            return Center(
              child: Text(
                viewModel.searchErrorMessage,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            );
          }

          if (viewModel.searchResults.isEmpty) {
            return const Center(child: Text('No keywords found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: viewModel.searchResults.length,
            itemBuilder: (context, index) {
              final keyword = viewModel.searchResults[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: const Icon(Icons.tag),
                  ),
                  title: Text(
                    keyword.displayName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${keyword.worksCount} related publications'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => KeywordDetailScreen(
                          keywordId: keyword.id,
                          keywordName: keyword.displayName,
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
