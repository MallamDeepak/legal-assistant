import 'package:flutter/material.dart';
import '../../../../app/routes/app_routes.dart';

class IncidentFormScreen extends StatefulWidget {
  final Future<Map<String, dynamic>> Function(String, String) onSubmit;
  const IncidentFormScreen({Key? key, required this.onSubmit}) : super(key: key);

  @override
  State<IncidentFormScreen> createState() => _IncidentFormScreenState();
}

class _IncidentFormScreenState extends State<IncidentFormScreen> {
  final _controller = TextEditingController();
  String _language = 'en';
  bool _loading = false;

  void _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _loading = true);
    final resp = await widget.onSubmit(_language, text);
    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.pushNamed(
      context,
      AppRoutes.firResult,
      arguments: {
        'queryText': text,
        'language': _language,
        'sourceEndpoint': resp['source_endpoint'] ?? '',
        'firText': resp['fir_text'] ?? '',
        'sections': resp['suggested_sections'] ?? const [],
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Incident Reporter')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          DropdownButton<String>(
            value: _language,
            items: const [DropdownMenuItem(value: 'en', child: Text('English')), DropdownMenuItem(value: 'hi', child: Text('Hindi'))],
            onChanged: (v) => setState(() => _language = v ?? 'en'),
          ),
          const SizedBox(height: 12),
          TextField(controller: _controller, maxLines: 6, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Describe the incident...')),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _loading ? null : _submit, child: _loading ? const CircularProgressIndicator() : const Text('Generate FIR'))
        ]),
      ),
    );
  }
}
