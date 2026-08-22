import 'dart:convert';

class BudgetModel {
  final String id;
  final String category;
  final String icon;
  final double limitAmount;
  final double currentSpent;
  final String resetPeriod; // "Monthly" or "Weekly"

  BudgetModel({
    required this.id,
    required this.category,
    required this.icon,
    required this.limitAmount,
    this.currentSpent = 0.0,
    required this.resetPeriod,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'icon': icon,
      'limitAmount': limitAmount,
      'currentSpent': currentSpent,
      'resetPeriod': resetPeriod,
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'] ?? '',
      category: map['category'] ?? '',
      icon: map['icon'] ?? '',
      limitAmount: map['limitAmount']?.toDouble() ?? 0.0,
      currentSpent: map['currentSpent']?.toDouble() ?? 0.0,
      resetPeriod: map['resetPeriod'] ?? 'Monthly',
    );
  }

  String toJson() => json.encode(toMap());

  factory BudgetModel.fromJson(String source) => BudgetModel.fromMap(json.decode(source));

  BudgetModel copyWith({
    String? id,
    String? category,
    String? icon,
    double? limitAmount,
    double? currentSpent,
    String? resetPeriod,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      limitAmount: limitAmount ?? this.limitAmount,
      currentSpent: currentSpent ?? this.currentSpent,
      resetPeriod: resetPeriod ?? this.resetPeriod,
    );
  }
}
