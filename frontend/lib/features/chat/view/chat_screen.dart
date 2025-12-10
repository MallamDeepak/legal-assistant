// imports
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/api_service.dart';
import '../../fir_analyzer/view/fir_upload_screen.dart';
import '../../contract_reviewer/view/contract_upload_screen.dart';

class ChatMessage {
  final String text;
  final bool fromUser;

  const ChatMessage({required this.text, this.fromUser = false});
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.insert(0, ChatMessage(text: text, fromUser: true));
      _loading = true;
      _controller.clear();
    });

    final api = Provider.of<ApiService>(context, listen: false);
    try {
      final resp = await api.generateIncident('en', text);
      final sections = (resp['suggested_sections'] as List?)?.join(', ') ?? '';
      final firText = resp['fir_text'] ?? '';
      final reply = 'Suggested sections: $sections\n\nFIR:\n$firText';
      if (!mounted) return;
      setState(() {
        _messages.insert(0, ChatMessage(text: reply, fromUser: false));
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      // Provide a friendly, actionable error message when the backend is unreachable
      final err = e.toString();
      String userMessage;
      if (err.toLowerCase().contains('connection') || err.toLowerCase().contains('refused')) {
        userMessage = 'Cannot reach the backend service at http://localhost:8000.\n\n'
            'Please ensure the backend is running. Start it with:\n'
            '  cd D:\\project\\legal-assistant-complete\\backend\n'
            '  python -m venv .venv\n'
            '  . .venv\\Scripts\\Activate.ps1\n'
            '  pip install -r requirements.txt\n'
            '  uvicorn app.main:app --reload --host 0.0.0.0 --port 8000\n\n'
            'If your backend runs on a different host/port, update the API base URL in the app.';
      } else {
        userMessage = 'Error: $err';
      }

      setState(() {
        _messages.insert(0, ChatMessage(text: userMessage, fromUser: false));
        _loading = false;
      });
    }
  }

  Widget _pillButton(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(shape: StadiumBorder(), backgroundColor: Colors.purple[50], foregroundColor: Colors.purple[800], elevation: 2, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
        child: Text(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Legal Assistant Chat')),
      body: Column(children: [
        // Quick action pills
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(children: [
            const SizedBox.shrink(),
            _pillButton('Incident Reporter', () => Navigator.pushNamed(context, '/incident')),
            _pillButton('FIR Analyzer', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FirUploadScreen()))),
            _pillButton('Contract Reviewer', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContractUploadScreen()))),
          ]),
        ),

        const Divider(height: 1),

        Expanded(
          child: ListView.builder(
            reverse: true,
            padding: const EdgeInsets.all(12.0),
            itemCount: _messages.length,
            itemBuilder: (_, i) {
              final m = _messages[i];
              return Align(
                alignment: m.fromUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6.0),
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(color: m.fromUser ? Colors.blue[200] : Colors.grey[200], borderRadius: BorderRadius.circular(12)),
                  child: Text(m.text),
                ),
              );
            },
          ),
        ),

        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Row(children: [
            Expanded(
                child: TextField(
              controller: _controller,
              decoration: const InputDecoration(hintText: 'Describe an incident or ask a question...'),
              minLines: 1,
              maxLines: 4,
            )),
            const SizedBox(width: 8),
            _loading
                ? const Padding(padding: EdgeInsets.all(12.0), child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator()))
                : IconButton(onPressed: _sendMessage, icon: const Icon(Icons.send))
          ]),
        )
      ]),
    );
  }
}
