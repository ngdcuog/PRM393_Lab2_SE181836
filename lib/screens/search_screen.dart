import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../core/constants.dart';
import '../viewmodels/home_viewmodel.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/publication_card.dart';

/// Main search screen with a pinned search bar and scrollable results list.
/// The search bar + chips are always visible regardless of scroll position.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final provider = context.read<HomeViewModel>();
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      provider.loadMore();
    }
  }

  void _search(String topic) {
    if (topic.trim().isEmpty) return;
    _searchController.text = topic;
    context.read<HomeViewModel>().search(topic.trim());
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          // ─── Gradient Header (always visible) ──────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [colorScheme.primary, colorScheme.tertiary],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row
                    Row(
                      children: [
                        const Icon(Icons.science_outlined,
                            color: Colors.white70, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Journal Trend Analyzer',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ── Search bar (always pinned) ──────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            textInputAction: TextInputAction.search,
                            onSubmitted: _search,
                            style: const TextStyle(color: Colors.black87),
                            decoration: InputDecoration(
                              hintText: 'Search research topics...',
                              hintStyle:
                                  const TextStyle(color: Colors.black38),
                              prefixIcon: const Icon(Icons.search,
                                  color: Colors.black54),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () => _search(_searchController.text),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: colorScheme.primary,
                            padding: const EdgeInsets.all(14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Icon(Icons.search),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─── Suggested chips (always visible, below header) ────────────────
          Container(
            color: colorScheme.surface,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Suggested Topics',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: AppConstants.suggestedTopics.map((topic) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text(topic,
                              style: const TextStyle(fontSize: 12)),
                          avatar: const Icon(Icons.tag, size: 14),
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _search(topic),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ─── Scrollable results (only this part scrolls) ───────────────────
          Expanded(
            child: Consumer<HomeViewModel>(
              builder: (context, provider, _) {
                switch (provider.status) {
                  case SearchStatus.idle:
                    return const _EmptyState(
                      icon: Icons.travel_explore,
                      title: 'Search for a research topic',
                      subtitle:
                          'Explore thousands of academic publications\nand analyze research trends',
                    );

                  case SearchStatus.loading:
                    return ListView.builder(
                      itemCount: 8,
                      itemBuilder: (_, __) => const _ShimmerCard(),
                    );

                  case SearchStatus.error:
                    return _ErrorState(
                      message: provider.errorMessage,
                      onRetry: () => provider.search(provider.currentTopic),
                    );

                  case SearchStatus.loaded:
                    if (provider.publications.isEmpty) {
                      return const _EmptyState(
                        icon: Icons.search_off,
                        title: 'No results found',
                        subtitle: 'Try a different search term',
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () =>
                          provider.search(provider.currentTopic),
                      child: ListView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: provider.publications.length +
                            (provider.isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index < provider.publications.length) {
                            final pub = provider.publications[index];
                            return PublicationCard(
                              publication: pub,
                              onTap: () => Navigator.of(context)
                                  .pushNamed('/detail', arguments: pub),
                            );
                          }
                          // Load-more indicator
                          return const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        },
                      ),
                    );
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Consumer<HomeViewModel>(
        builder: (context, provider, _) {
          if (provider.currentTopic.isEmpty) return const SizedBox.shrink();
          
          final hasFilters = provider.filterOptions.openAccessOnly || 
                             provider.filterOptions.domainId != null || 
                             provider.filterOptions.sortBy != 'relevance_score:desc';

          return FloatingActionButton.extended(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const FilterBottomSheet(),
              );
            },
            icon: Icon(hasFilters ? Icons.filter_alt : Icons.filter_alt_outlined),
            label: const Text('Filters'),
          );
        },
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: colorScheme.primary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error State ──────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shimmer skeleton ─────────────────────────────────────────────────────────

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: colorScheme.surfaceContainerHighest,
      highlightColor: colorScheme.surface,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                  height: 16, width: double.infinity, color: Colors.white),
              const SizedBox(height: 8),
              Container(height: 14, width: 220, color: Colors.white),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(height: 24, width: 60, color: Colors.white),
                  const SizedBox(width: 8),
                  Container(height: 24, width: 90, color: Colors.white),
                  const SizedBox(width: 8),
                  Container(height: 24, width: 100, color: Colors.white),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
