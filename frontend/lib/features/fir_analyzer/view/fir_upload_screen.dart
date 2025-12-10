import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/services/api_service.dart';
import '../view/fir_analysis_screen.dart';

class FirUploadScreen extends StatefulWidget {
  const FirUploadScreen({Key? key}) : super(key: key);

  @override
  State<FirUploadScreen> createState() => _FirUploadScreenState();
}

class _FirUploadScreenState extends State<FirUploadScreen> {
  bool _loading = false;

  void _analyze() async {
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
      final resp = await api.analyzeFIR(file.name, bytes ?? Uint8List(0));
      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => FirAnalysisScreen(
          extractedText: resp['extracted_text'] ?? '',
          sections: (resp['detected_sections'] as List?)?.map((e) => e.toString()).toList() ?? [])));
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Analyze failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FIR Analyzer')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          const Text('Upload FIR (image or PDF)'),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _loading ? null : _analyze, child: _loading ? const CircularProgressIndicator() : const Text('Select & Analyze'))
        ]),
      ),
    );
  }
}
