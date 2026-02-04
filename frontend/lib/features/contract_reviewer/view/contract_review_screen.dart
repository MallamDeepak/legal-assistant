import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

class ContractReviewScreen extends StatefulWidget {
  final String text;
  final List<Map<String, String>> clauses;
  const ContractReviewScreen({Key? key, this.text = '', this.clauses = const []}) : super(key: key);

  @override
  State<ContractReviewScreen> createState() => _ContractReviewScreenState();
}

class _ContractReviewScreenState extends State<ContractReviewScreen> {
  String _selectedFilter = 'All'; // All, High Risk, Flagged, Safe

  @override
  Widget build(BuildContext context) {
    // 1. Calculate Summary Stats
    int highRisk = 0;
    int flagged = 0;
    
    for (var c in widget.clauses) {
      final status = (c['status'] ?? '').toLowerCase();
      if (status == 'high-risk') highRisk++;
      else if (status == 'flagged') flagged++;
    }

    // 2. Filter Clauses
    final filteredClauses = widget.clauses.where((c) {
      if (_selectedFilter == 'All') return true;
      final status = (c['status'] ?? 'safe').toLowerCase();
      if (_selectedFilter == 'High Risk') return status == 'high-risk';
      if (_selectedFilter == 'Flagged') return status == 'flagged';
      if (_selectedFilter == 'Safe') return status != 'high-risk' && status != 'flagged';
      return true;
    }).toList();

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contract Analysis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy Summary',
            onPressed: () {
              _copySummaryToClipboard(highRisk, flagged);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: CustomScrollView(
          slivers: [
            // Dashboard
            SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(child: _buildSummaryCard(context, 'High Risk', highRisk, Colors.red)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildSummaryCard(context, 'Attention', flagged, Colors.orange)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildSummaryCard(context, 'Safe', widget.clauses.length - highRisk - flagged, Colors.green)),
                ],
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(top: 24)),
            
            // Filters
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', Colors.grey),
                    const SizedBox(width: 8),
                    _buildFilterChip('High Risk', Colors.red),
                    const SizedBox(width: 8),
                    _buildFilterChip('Flagged', Colors.orange),
                    const SizedBox(width: 8),
                    _buildFilterChip('Safe', Colors.green),
                  ],
                ),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(top: 16)),

            SliverToBoxAdapter(
              child: Text(
                'Clause Analysis (${filteredClauses.length})', 
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
              ),
            ),
             const SliverPadding(padding: EdgeInsets.only(top: 12)),

            // Clause List
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final c = filteredClauses[index];
                  return _buildClauseCard(context, c);
                },
                childCount: filteredClauses.length,
              ),
            ),
            
            // Bottom padding
            const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, Color color) {
    final isSelected = _selectedFilter == label;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          _selectedFilter = label;
        });
      },
      selectedColor: color.withOpacity(0.2),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: isSelected ? color : Theme.of(context).colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? color : Colors.grey.withOpacity(0.3)),
      ),
    );
  }

  void _copySummaryToClipboard(int highRisk, int flagged) {
    final sb = StringBuffer();
    sb.writeln("Contract Analysis Summary");
    sb.writeln("-------------------------");
    sb.writeln("High Risk Clauses: $highRisk");
    sb.writeln("Flagged Clauses: $flagged");
    sb.writeln("Total Clauses: ${widget.clauses.length}");
    sb.writeln("\nReview Details:");
    
    for (var c in widget.clauses) {
      final status = c['status']?.toUpperCase() ?? 'SAFE';
      if (status == 'HIGH-RISK') {
        sb.writeln("[$status] ${c['clause']?.trim()}");
      }
    }
    
    Clipboard.setData(ClipboardData(text: sb.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('High risk summary copied to clipboard')),
    );
  }

  Widget _buildSummaryCard(BuildContext context, String title, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(count.toString(), style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildClauseCard(BuildContext context, Map<String, String> clause) {
    final status = (clause['status'] ?? 'ok').toLowerCase();
    Color color;
    IconData icon;
    String label;

    if (status == 'high-risk') {
      color = Colors.red;
      icon = Icons.warning_amber_rounded;
      label = "High Risk";
    } else if (status == 'flagged') {
      color = Colors.orange;
      icon = Icons.info_outline;
      label = "Flagged";
    } else {
      color = Colors.green;
      icon = Icons.check_circle_outline;
      label = "Safe";
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      color: Theme.of(context).colorScheme.surface,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          (clause['clause'] ?? '').trim(),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        childrenPadding: const EdgeInsets.all(16),
        children: [
           Container(
             width: double.infinity,
             padding: const EdgeInsets.all(12),
             decoration: BoxDecoration(
               color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
               borderRadius: BorderRadius.circular(8)
             ),
             child: SelectableText(
               clause['clause'] ?? '',
               style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
             ),
           )
        ],
      ),
    );
  }
}
