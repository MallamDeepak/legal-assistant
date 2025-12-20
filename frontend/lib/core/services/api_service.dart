import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;

  ApiService({required this.baseUrl});



  Future<Map<String, dynamic>> generateIncident(String language, String text) async {
    final url = Uri.parse('$baseUrl/incident/analyze');
    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'language': language, 'text': text}),
    ).timeout(const Duration(seconds: 120));
    if (resp.statusCode == 200) {
      return json.decode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    }
    throw Exception('Incident analyze failed: ${resp.statusCode} ${resp.body}');
  }

  Future<String> chat(String message, String language) async {
    final url = Uri.parse('$baseUrl/chat/');
    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'message': message, 'language': language}),
    ).timeout(const Duration(seconds: 120));
    if (resp.statusCode == 200) {
      final data = json.decode(utf8.decode(resp.bodyBytes));
      return data['reply'] ?? ''; 
    }
    throw Exception('Chat failed: ${resp.statusCode} ${resp.body}');
  }

  /// Upload a FIR image/PDF and get analysis back.
  /// `filename` should include an extension (e.g. 'fir.jpg'), `bytes` are the file contents.
  Future<Map<String, dynamic>> analyzeFIR(String filename, Uint8List bytes, String language) async {
    final url = Uri.parse('$baseUrl/fir/analyze?language=$language');
    final request = http.MultipartRequest('POST', url);
    request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));

    final streamed = await request.send().timeout(const Duration(seconds: 120));
    final resp = await http.Response.fromStream(streamed);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return json.decode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    }
    throw Exception('Failed to analyze FIR: ${resp.statusCode} ${resp.body}');
  }

  /// Upload a contract file (image/pdf/text) and receive clause analysis.
  Future<Map<String, dynamic>> reviewContract(String filename, Uint8List bytes, String language) async {
    final url = Uri.parse('$baseUrl/contract/review?language=$language');
    final request = http.MultipartRequest('POST', url);
    request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));

    final streamed = await request.send().timeout(const Duration(seconds: 120));
    final resp = await http.Response.fromStream(streamed);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return json.decode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    }
    throw Exception('Failed to review contract: ${resp.statusCode} ${resp.body}');
  }

}
