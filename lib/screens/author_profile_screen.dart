import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/author_profile.dart';
import '../models/publication.dart';
import '../services/openalex_service.dart';
import '../widgets/publication_card.dart';

class AuthorProfileScreen extends StatefulWidget {
  const AuthorProfileScreen({super.key, required this.authorId});

  final String authorId;

  @override
  State<AuthorProfileScreen> createState() => _AuthorProfileScreenState();
}

class _AuthorProfileScreenState extends State<AuthorProfileScreen> {
  bool _isLoading = true;
  String? _error;
  AuthorProfile? _profile;
  List<Publication> _recentWorks = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final service = context.read<OpenAlexService>();
      final results = await Future.wait([
        service.getAuthorProfile(widget.authorId),
        service.getAuthorWorks(widget.authorId),
      ]);
      setState(() {
        _profile = results[0] as AuthorProfile;
        _recentWorks = results[1] as List<Publication>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Author Profile')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: colorScheme.error),
              const SizedBox(height: 16),
              Text(_error ?? 'Failed to load profile'),
              TextButton(onPressed: _fetchData, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final profile = _profile!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Author Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Text(
                    profile.name.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  profile.name,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                if (profile.institution != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    profile.institution!,
                    style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Stats
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  label: 'Publications',
                  value: profile.worksCount.toString(),
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatBox(
                  label: 'Citations',
                  value: profile.citedByCount.toString(),
                  color: Colors.amber.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Topics
          if (profile.topTopics.isNotEmpty) ...[
            Text('Top Topics', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: profile.topTopics.map((topic) {
                return Chip(
                  label: Text(topic, style: const TextStyle(fontSize: 12)),
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  side: BorderSide.none,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Recent Works
          Text('Recent Publications', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (_recentWorks.isEmpty)
            const Text('No recent publications found.')
          else
            ..._recentWorks.map((pub) {
              return PublicationCard(
                publication: pub,
                onTap: () {
                  Navigator.of(context).pushNamed('/detail', arguments: pub);
                },
              );
            }),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color),
          ),
        ],
      ),
    );
  }
}
