/// Validation result from backend Validator
/// Mirrors backend ValidationResult from domain.py
class ValidationResult {
  final bool isValid;
  final List<String> violations;
  final List<String> warnings;
  final double score;
  final Map<String, dynamic>? details;

  const ValidationResult({
    required this.isValid,
    required this.violations,
    required this.warnings,
    required this.score,
    this.details,
  });

  /// Create from JSON
  factory ValidationResult.fromJson(Map<String, dynamic> json) {
    return ValidationResult(
      isValid: json['is_valid'] as bool,
      violations: (json['violations'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      warnings: (json['warnings'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      score: (json['score'] as num).toDouble(),
      details: json['details'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'is_valid': isValid,
      'violations': violations,
      'warnings': warnings,
      'score': score,
      'details': details,
    };
  }

  /// Score as percentage
  String get scorePercentage => '${(score * 100).toStringAsFixed(0)}%';

  /// Star rating (0-5 stars)
  int get starRating => (score * 5).round();

  /// Quality label
  String get qualityLabel {
    if (score >= 0.8) return 'Excellent';
    if (score >= 0.6) return 'Good';
    if (score >= 0.4) return 'Fair';
    return 'Needs Improvement';
  }

  /// Has any issues
  bool get hasIssues => violations.isNotEmpty || warnings.isNotEmpty;

  @override
  String toString() =>
      'ValidationResult(valid: $isValid, score: $score, issues: ${violations.length + warnings.length})';
}