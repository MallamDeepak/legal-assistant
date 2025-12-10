class ClauseAnalysis {
  final String clause;
  final String status;

  ClauseAnalysis({required this.clause, required this.status});

  factory ClauseAnalysis.fromJson(Map<String, dynamic> json) {
    return ClauseAnalysis(clause: json['clause'] ?? '', status: json['status'] ?? '');
  }
}

class ContractAnalysis {
  final String text;
  final List<ClauseAnalysis> clauses;

  ContractAnalysis({required this.text, required this.clauses});

  factory ContractAnalysis.fromJson(Map<String, dynamic> json) {
    return ContractAnalysis(
      text: json['text'] ?? '',
      clauses: (json['clauses'] as List?)?.map((e) => ClauseAnalysis.fromJson(e)).toList() ?? [],
    );
  }
}
