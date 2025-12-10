import 'package:flutter/material.dart';

class FirAnalysisScreen extends StatelessWidget {
  final String extractedText;
  final List<String> sections;
  const FirAnalysisScreen({Key? key, this.extractedText = '', this.sections = const []}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FIR Analysis')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Extracted Text:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(extractedText),
          const SizedBox(height: 16),
          const Text('Detected Sections:', style: TextStyle(fontWeight: FontWeight.bold)),
          ...sections.map((s) => Padding(padding: const EdgeInsets.symmetric(vertical: 4.0), child: Text(s))).toList()
        ]),
      ),
    );
  }
}
