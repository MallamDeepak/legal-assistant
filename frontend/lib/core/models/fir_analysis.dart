class FirAnalysis {
  final String extractedText;
  final List<String> detectedSections;

  FirAnalysis({required this.extractedText, required this.detectedSections});

  factory FirAnalysis.fromJson(Map<String, dynamic> json) {
    return FirAnalysis(
        extractedText: json['extracted_text'] ?? '',
        detectedSections: (json['detected_sections'] as List?)?.map((e) => e.toString()).toList() ?? []);
  }
}
