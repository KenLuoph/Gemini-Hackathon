/// Budget information model
/// Mirrors backend BudgetInfo from domain.py
class BudgetInfo {
  final double amount;
  final String currency;
  final String category;

  const BudgetInfo({
    required this.amount,
    required this.currency,
    required this.category,
  });

  /// Create from JSON
  factory BudgetInfo.fromJson(Map<String, dynamic> json) {
    return BudgetInfo(
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      category: json['category'] as String? ?? 'general',
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'currency': currency,
      'category': category,
    };
  }

  /// Formatted amount with currency symbol
  String get formatted {
    final symbol = _getCurrencySymbol(currency);
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  /// Category display name
  String get categoryLabel {
    switch (category.toLowerCase()) {
      case 'food':
        return '🍽️ Food';
      case 'transport':
        return '🚗 Transport';
      case 'entertainment':
        return '🎭 Entertainment';
      case 'accommodation':
        return '🏨 Accommodation';
      default:
        return '💰 General';
    }
  }

  String _getCurrencySymbol(String code) {
    switch (code.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      default:
        return code;
    }
  }

  @override
  String toString() => 'BudgetInfo($formatted, $category)';
}