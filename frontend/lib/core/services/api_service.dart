import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;

  ApiService({required this.baseUrl});

  Map<String, dynamic> _decodeJson(http.Response resp) {
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return json.decode(resp.body) as Map<String, dynamic>;
    }
    throw Exception('HTTP ${resp.statusCode}: ${resp.body}');
  }

  Future<Map<String, dynamic>> generateIncident(String language, String text) async {
    final url = Uri.parse('$baseUrl/incident/generate');
    final resp = await http.post(url,
        headers: {'Content-Type': 'application/json'}, body: json.encode({'language': language, 'text': text}));
    return _decodeJson(resp);
  }

  Future<Map<String, dynamic>> ragFirDraft({required String language, required String text, int topK = 5}) async {
    final url = Uri.parse('$baseUrl/rag/fir-draft');
    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'language': language, 'text': text, 'top_k': topK}),
    );
    return _decodeJson(resp);
  }

  /// Generates a FIR draft, preferring RAG when available.
  /// Falls back to `/incident/generate` if RAG is not configured.
  ///
  /// Returns a unified shape:
  /// - `fir_text`: String
  /// - `suggested_sections`: List<{section_id, title?, confidence?}>
  /// - `source_endpoint`: String
  Future<Map<String, dynamic>> generateFirDraft({required String language, required String text, int topK = 5}) async {
    try {
      final rag = await ragFirDraft(language: language, text: text, topK: topK);
      final raw = (rag['suggested_sections'] as List?) ?? const [];
      final normalized = raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(growable: false);
      return {
        'fir_text': rag['fir_text'] ?? '',
        'suggested_sections': normalized,
        'source_endpoint': '/rag/fir-draft',
      };
    } catch (_) {
      final baseline = await generateIncident(language, text);
      final raw = (baseline['suggested_sections'] as List?) ?? const [];
      final normalized = raw
          .map((e) => {
                'section_id': e.toString(),
                'title': '',
                'confidence': null,
              })
          .toList(growable: false);
      return {
        'fir_text': baseline['fir_text'] ?? '',
        'suggested_sections': normalized,
        'source_endpoint': '/incident/generate',
      };
    }
  }

  Future<void> logSectionSelection({
    required String queryText,
    required List<String> suggestedSections,
    required List<String> selectedSectionIds,
    required String language,
    required String sourceEndpoint,
    Map<String, dynamic>? metadata,
  }) async {
    final url = Uri.parse('$baseUrl/signals/section-selection');
    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'query_text': queryText,
        'suggested_sections': suggestedSections,
        'selected_section_ids': selectedSectionIds,
        'language': language,
        'source_endpoint': sourceEndpoint,
        'metadata': metadata ?? {},
      }),
    );

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Failed to log signal: ${resp.statusCode} ${resp.body}');
    }
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
