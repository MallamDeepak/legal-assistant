import 'package:flutter/material.dart';
import 'fir_result_screen.dart';

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
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe the incident first.')),
      );
      return;
    }
    
    // Unfocus keyboard
    FocusScope.of(context).unfocus();

    setState(() => _loading = true);
    try {
      final resp = await widget.onSubmit(_language, text);
      if (!mounted) return;
      
      final sections = (resp['suggested_sections'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      final firText = resp['fir_text']?.toString() ?? '';
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FirResultScreen(firText: firText, sections: sections),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: const Text('New Incident Report')),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                         Row(
                           children: [
                             Container(
                               padding: const EdgeInsets.all(12),
                               decoration: BoxDecoration(
                                 color: Theme.of(context).colorScheme.primaryContainer,
                                 borderRadius: BorderRadius.circular(12),
                               ),
                               child: Icon(Icons.record_voice_over, color: Theme.of(context).colorScheme.onPrimaryContainer),
                             ),
                             const SizedBox(width: 16),
                             Expanded(
                               child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   Text("Describe Incident", style: Theme.of(context).textTheme.titleLarge),
                                   Text("Get prompt strict legal analysis and relevant sections.", style: Theme.of(context).textTheme.bodySmall),
                                 ],
                               ),
                             )
                           ],
                         ),
                         const SizedBox(height: 24),
                         DropdownButtonFormField<String>(
                          value: _language,
                          decoration: const InputDecoration(
                            labelText: 'Report Language',
                            prefixIcon: Icon(Icons.language),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'en', child: Text('English')),
                            DropdownMenuItem(value: 'hi', child: Text('Hindi')),
                          ],
                          onChanged: (v) => setState(() => _language = v ?? 'en'),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _controller,
                          maxLines: 6,
                          minLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Incident Details',
                            hintText: 'Describe what happened, where, and when...',
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _loading ? null : _submit,
                            icon: const Icon(Icons.auto_awesome),
                            label: const Text('Analyze Incident'),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_loading)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text("Analyzing Incident..."),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
