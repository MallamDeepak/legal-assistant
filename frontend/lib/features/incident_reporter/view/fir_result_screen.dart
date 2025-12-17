import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FirResultScreen extends StatelessWidget {
  final String firText;
  final List<String> sections;
  const FirResultScreen({Key? key, this.firText = '', this.sections = const []}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generated FIR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy FIR',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: firText));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('FIR copied to clipboard!')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('FIR Text:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          SelectableText(firText, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 24),
          const Divider(),
          const Text('Suggested Sections (Raw ID List):', style: TextStyle(fontWeight: FontWeight.bold)),
          ...sections.map((s) => Padding(padding: const EdgeInsets.symmetric(vertical: 4.0), child: Text(s))).toList()
        ]),
      ),
    );
  }
}
