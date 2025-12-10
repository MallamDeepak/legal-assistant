import 'package:flutter/material.dart';

class FirResultScreen extends StatelessWidget {
  final String firText;
  final List<String> sections;
  const FirResultScreen({Key? key, this.firText = '', this.sections = const []}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generated FIR')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('FIR Text:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(firText),
          const SizedBox(height: 16),
          const Text('Suggested Sections:', style: TextStyle(fontWeight: FontWeight.bold)),
          ...sections.map((s) => Padding(padding: const EdgeInsets.symmetric(vertical: 4.0), child: Text(s))).toList()
        ]),
      ),
    );
  }
}
