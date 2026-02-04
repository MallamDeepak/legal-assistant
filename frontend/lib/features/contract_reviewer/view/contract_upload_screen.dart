import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/services/api_service.dart';
import '../view/contract_review_screen.dart';

class ContractUploadScreen extends StatefulWidget {
  const ContractUploadScreen({Key? key}) : super(key: key);

  @override
  State<ContractUploadScreen> createState() => _ContractUploadScreenState();
}

class _ContractUploadScreenState extends State<ContractUploadScreen> {
  bool _loading = false;

  void _review() async {
    setState(() => _loading = true);

    final result = await FilePicker.platform.pickFiles(allowMultiple: false);
    if (result == null || result.files.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    if (!mounted) return;

    final file = result.files.single;
    final api = Provider.of<ApiService>(context, listen: false);
    final bytes = file.bytes;

    try {
      final resp = await api.reviewContract(file.name, bytes ?? Uint8List(0), 'en');
      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => ContractReviewScreen(
            text: resp['text'] ?? '',
            clauses: (resp['clauses'] as List?)?.map((e) => Map<String, String>.from(e as Map)).toList() ?? [],
          )));
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Review failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contract Reviewer')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          const Text('Upload contract (PDF)'),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _loading ? null : _review, child: _loading ? const CircularProgressIndicator() : const Text('Select & Review'))
        ]),
      ),
    );
  }
}
