import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;

  ApiService({required this.baseUrl});

  Future<Map<String, dynamic>> generateIncident(String language, String text) async {
    final url = Uri.parse('$baseUrl/incident/generate');
    final resp = await http.post(url,
        headers: {'Content-Type': 'application/json'}, body: json.encode({'language': language, 'text': text}));
    return json.decode(resp.body) as Map<String, dynamic>;
  }

  /// Upload a FIR image/PDF and get analysis back.
  /// `filename` should include an extension (e.g. 'fir.jpg'), `bytes` are the file contents.
  Future<Map<String, dynamic>> analyzeFIR([String? filename, Uint8List? bytes]) async {
    // If no file is provided, return a local stub to keep UI flows working during development.
    if (filename == null || bytes == null) {
      return {
        'extracted_text': '(stub) no file provided',
        'detected_sections': ['IPC 379'],
        'entities': {}
      };
    }
    final url = Uri.parse('$baseUrl/fir/analyze');
    final request = http.MultipartRequest('POST', url);
    request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));

    final streamed = await request.send();
    final resp = await http.Response.fromStream(streamed);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return json.decode(resp.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to analyze FIR: ${resp.statusCode} ${resp.body}');
  }

  /// Upload a contract file (image/pdf/text) and receive clause analysis.
  Future<Map<String, dynamic>> reviewContract([String? filename, Uint8List? bytes]) async {
    if (filename == null || bytes == null) {
      return {
        'text': '(stub) no file provided',
        'clauses': [
          {'clause': 'Sample clause', 'status': 'ok'}
        ]
      };
    }
    final url = Uri.parse('$baseUrl/contract/review');
    final request = http.MultipartRequest('POST', url);
    request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));

    final streamed = await request.send();
    final resp = await http.Response.fromStream(streamed);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return json.decode(resp.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to review contract: ${resp.statusCode} ${resp.body}');
  }
}
