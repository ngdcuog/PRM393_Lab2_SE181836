import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/filter_options.dart';
import '../viewmodels/home_viewmodel.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late FilterOptions _currentOptions;

  static const _domains = [
    {'id': '1', 'name': 'Life Sciences'},
    {'id': '2', 'name': 'Social Sciences'},
    {'id': '3', 'name': 'Physical Sciences'},
    {'id': '4', 'name': 'Health Sciences'},
  ];

  @override
  void initState() {
    super.initState();
    _currentOptions = context.read<HomeViewModel>().filterOptions;
  }

  void _apply() {
    final provider = context.read<HomeViewModel>();
    provider.search(provider.currentTopic, options: _currentOptions);
    Navigator.of(context).pop();
  }

  void _reset() {
    setState(() {
      _currentOptions = const FilterOptions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 32),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Advanced Filters',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: _reset,
                  child: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Open Access Toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Open Access Only', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Show only freely available papers'),
              value: _currentOptions.openAccessOnly,
              onChanged: (val) {
                setState(() {
                  _currentOptions = _currentOptions.copyWith(openAccessOnly: val);
                });
              },
            ),

            const Divider(),

            // Year Range Selection
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Publication Year', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    '${_currentOptions.yearFrom ?? 1990} - ${_currentOptions.yearTo ?? DateTime.now().year}',
                    style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            RangeSlider(
              min: 1990,
              max: DateTime.now().year.toDouble(),
              divisions: DateTime.now().year - 1990,
              labels: RangeLabels(
                (_currentOptions.yearFrom ?? 1990).toString(),
                (_currentOptions.yearTo ?? DateTime.now().year).toString(),
              ),
              values: RangeValues(
                (_currentOptions.yearFrom ?? 1990).toDouble(),
                (_currentOptions.yearTo ?? DateTime.now().year).toDouble(),
              ),
              onChanged: (values) {
                setState(() {
                  _currentOptions = _currentOptions.copyWith(
                    yearFrom: values.start.toInt(),
                    yearTo: values.end.toInt(),
                  );
                });
              },
            ),

            const Divider(),

            // Domain Selection
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Domain', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            Wrap(
              spacing: 8,
              children: _domains.map((d) {
                final isSelected = _currentOptions.domainId == d['id'];
                return ChoiceChip(
                  label: Text(d['name']!),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _currentOptions = _currentOptions.copyWith(
                        domainId: selected ? d['id'] : null,
                      );
                    });
                  },
                );
              }).toList(),
            ),

            const Divider(height: 32),

            // Sort By
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('Sort By', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            InputDecorator(
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _currentOptions.sortBy,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'relevance_score:desc', child: Text('Relevance (Default)')),
                    DropdownMenuItem(value: 'cited_by_count:desc', child: Text('Most Cited')),
                    DropdownMenuItem(value: 'publication_year:desc', child: Text('Newest First')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _currentOptions = _currentOptions.copyWith(sortBy: val);
                      });
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 32),

            FilledButton(
              onPressed: _apply,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Apply Filters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
