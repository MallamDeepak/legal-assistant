import 'package:flutter/material.dart';

class ContractReviewScreen extends StatelessWidget {
  final String text;
  final List<Map<String, String>> clauses;
  const ContractReviewScreen({Key? key, this.text = '', this.clauses = const []}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contract Review')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          const Text('Contract Text:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(text),
          const SizedBox(height: 16),
          const Text('Clauses:', style: TextStyle(fontWeight: FontWeight.bold)),
          ...clauses.map((c) => ListTile(title: Text(c['clause'] ?? ''), trailing: Text(c['status'] ?? ''))).toList()
        ]),
      ),
    );
  }
}
