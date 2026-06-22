import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/publication.dart';

/// Screen showing full details of a single publication.
class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool _showFullAbstract = false;

  @override
  Widget build(BuildContext context) {
    final publication =
        ModalRoute.of(context)!.settings.arguments as Publication;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Publication Details'),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Title ───────────────────────────────────────────────────────
            Text(
              publication.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),

            // ─── Year & Citations chips ───────────────────────────────────────
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (publication.year > 0)
                  _InfoChip(
                    icon: Icons.calendar_month,
                    label: '${publication.year}',
                    color: colorScheme.primary,
                  ),
                _InfoChip(
                  icon: Icons.format_quote,
                  label: '${publication.citationCount} citations',
                  color: colorScheme.tertiary,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ─── Journal ─────────────────────────────────────────────────────
            if (publication.journalName != null) ...[
              _SectionRow(
                icon: Icons.library_books_outlined,
                iconColor: colorScheme.secondary,
                child: Text(
                  publication.journalName!,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            const Divider(),
            const SizedBox(height: 12),

            // ─── Authors ─────────────────────────────────────────────────────
            if (publication.authors.isNotEmpty) ...[
              Text(
                'Authors',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ...publication.authors.map(
                (author) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor:
                            colorScheme.primaryContainer,
                        child: Text(
                          author.isNotEmpty
                              ? author[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          author,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
            ],

            // ─── Abstract ────────────────────────────────────────────────────
            Text(
              'Abstract',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (publication.abstractText == null ||
                publication.abstractText!.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: colorScheme.onSurfaceVariant, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Abstract not available',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 250),
                crossFadeState: _showFullAbstract
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: Text(
                  publication.abstractText!,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                ),
                secondChild: Text(
                  publication.abstractText!,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                ),
              ),
              TextButton(
                onPressed: () =>
                    setState(() => _showFullAbstract = !_showFullAbstract),
                child: Text(_showFullAbstract ? 'Show less' : 'Show more'),
              ),
            ],

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // ─── DOI Button ──────────────────────────────────────────────────
            if (publication.doi != null && publication.doi!.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _launchDoi(context, publication.doi!),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open DOI Link'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _launchDoi(BuildContext context, String doi) async {
    final uriStr = doi.startsWith('http') ? doi : 'https://doi.org/$doi';
    final uri = Uri.tryParse(uriStr);

    final messenger = ScaffoldMessenger.of(context);

    if (uri == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Invalid DOI link')),
      );
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!mounted) return;

      if (!launched) {
        final fallback = await launchUrl(uri, mode: LaunchMode.inAppWebView);
        if (!mounted) return;
        if (!fallback) {
          messenger.showSnackBar(
            const SnackBar(content: Text('Could not open link in WebView')),
          );
        }
      }
    } catch (_) {
      if (!mounted) return;
      try {
        final fallback = await launchUrl(uri, mode: LaunchMode.inAppWebView);
        if (!mounted) return;
        if (!fallback) {
          messenger.showSnackBar(
            const SnackBar(content: Text('Could not open link in WebView')),
          );
        }
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(content: Text('Could not open link: $e')),
        );
      }
    }
  }
}

// ─── Helper widgets ───────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionRow extends StatelessWidget {
  const _SectionRow({
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  final IconData icon;
  final Color iconColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 10),
        Expanded(child: child),
      ],
    );
  }
}
