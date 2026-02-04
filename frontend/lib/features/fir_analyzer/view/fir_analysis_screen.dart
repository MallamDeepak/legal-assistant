import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FirAnalysisScreen extends StatelessWidget {
  final String extractedText;
  final List<String> sections;
  const FirAnalysisScreen({Key? key, this.extractedText = '', this.sections = const []}) : super(key: key);

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FIR Analysis'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('Sharing not implemented')),
              );
            },
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _copyToClipboard(context, extractedText),
        icon: const Icon(Icons.copy_all),
        label: const Text('Copy Analysis'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (sections.isNotEmpty) ...[
              _buildSectionHeader(context, 'Detected Legal Sections', Icons.gavel),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12.0,
                runSpacing: 12.0,
                children: sections.map((s) {
                  return Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bookmark_border, size: 16, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          s,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface, 
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
            ],

            _buildSectionHeader(context, 'Extracted Content', Icons.description_outlined),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              color: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: theme.colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(children: [
                 Container(
                   width: double.infinity,
                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                   decoration: BoxDecoration(
                     color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                     borderRadius: const BorderRadius.only(
                       topLeft: Radius.circular(16),
                       topRight: Radius.circular(16),
                     ),
                   ),
                   child: Row(
                     mainAxisAlignment: MainAxisAlignment.end,
                     children: [
                       TextButton.icon(
                         onPressed: () => _copyToClipboard(context, extractedText),
                         icon: const Icon(Icons.copy, size: 16),
                         label: const Text('Copy Text'),
                         style: TextButton.styleFrom(
                           visualDensity: VisualDensity.compact,
                           textStyle: const TextStyle(fontSize: 12),
                         ),
                       ),
                     ],
                   ),
                 ),
                 Padding(
                   padding: const EdgeInsets.all(20),
                   child: SelectableText(
                    extractedText,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
                   ),
                 ),
              ]),
            ),
             const SizedBox(height: 80),
          ]),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
