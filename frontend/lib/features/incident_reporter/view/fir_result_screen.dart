import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/api_service.dart';


class SuggestedSectionItem {
  final String sectionId;
  final String title;
  final double? confidence;

  const SuggestedSectionItem({required this.sectionId, this.title = '', this.confidence});

  factory SuggestedSectionItem.fromDynamic(dynamic e) {
    if (e is Map) {
      final map = Map<String, dynamic>.from(e);
      final id = (map['section_id'] ?? map['sectionId'] ?? '').toString();
      final title = (map['title'] ?? '').toString();
      final conf = map['confidence'];
      return SuggestedSectionItem(
        sectionId: id,
        title: title,
        confidence: conf is num ? conf.toDouble() : null,
      );
    }
    return SuggestedSectionItem(sectionId: e.toString());
  }
}

class FirResultScreen extends StatelessWidget {
  final String firText;
  final List<SuggestedSectionItem> sections;
  final String queryText;
  final String language;
  final String sourceEndpoint;

  const FirResultScreen({
    Key? key,
    this.firText = '',
    this.sections = const [],
    this.queryText = '',
    this.language = 'en',
    this.sourceEndpoint = '',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args = (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?) ?? const {};
    final effectiveFirText = (args['firText'] ?? firText).toString();
    final effectiveQueryText = (args['queryText'] ?? queryText).toString();
    final effectiveLanguage = (args['language'] ?? language).toString();
    final effectiveSourceEndpoint = (args['sourceEndpoint'] ?? sourceEndpoint).toString();

    final rawSections = (args['sections'] as List?) ?? sections;
    final effectiveSections = rawSections
        .map((e) => e is SuggestedSectionItem ? e : SuggestedSectionItem.fromDynamic(e))
        .where((e) => e.sectionId.trim().isNotEmpty)
        .toList(growable: false);

    Future<void> logSelection(String selectedId) async {
      final api = Provider.of<ApiService>(context, listen: false);
      final suggestedIds = effectiveSections.map((s) => s.sectionId).toList(growable: false);
      await api.logSectionSelection(
        queryText: effectiveQueryText,
        suggestedSections: suggestedIds,
        selectedSectionIds: [selectedId],
        language: effectiveLanguage,
        sourceEndpoint: effectiveSourceEndpoint,
        metadata: {
          'ui': 'fir_result_screen',
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Generated FIR')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('FIR Text:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: Text(effectiveFirText),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Suggested Sections (tap to select):', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: ListView.builder(
              itemCount: effectiveSections.length,
              itemBuilder: (context, index) {
                final s = effectiveSections[index];
                final subtitleParts = <String>[];
                if (s.title.trim().isNotEmpty) subtitleParts.add(s.title.trim());
                if (s.confidence != null) subtitleParts.add('confidence: ${s.confidence!.toStringAsFixed(2)}');
                final subtitle = subtitleParts.isEmpty ? null : subtitleParts.join(' • ');

                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.sectionId),
                  subtitle: subtitle == null ? null : Text(subtitle),
                  onTap: () async {
                    try {
                      await logSelection(s.sectionId);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Selected: ${s.sectionId} (logged)')),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to log selection: $e')),
                      );
                    }
                  },
                );
              },
            ),
          )
        ]),
      ),
    );
  }
}
