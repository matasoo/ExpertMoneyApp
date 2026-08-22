import 'dart:convert';

class GoalModel {
  final String id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final double monthlyContribution;
  final String? targetDate;
  final int? colorValue;
  final bool isAutoDeduct;
  final int? autoDeductDay;

  GoalModel({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.monthlyContribution,
    this.targetDate,
    this.colorValue,
    this.isAutoDeduct = false,
    this.autoDeductDay,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'monthlyContribution': monthlyContribution,
      'targetDate': targetDate,
      'colorValue': colorValue,
      'isAutoDeduct': isAutoDeduct,
      'autoDeductDay': autoDeductDay,
    };
  }

  factory GoalModel.fromMap(Map<String, dynamic> map) {
    return GoalModel(
      id: map['id'],
      title: map['title'],
      targetAmount: map['targetAmount']?.toDouble() ?? 0.0,
      currentAmount: map['currentAmount']?.toDouble() ?? 0.0,
      monthlyContribution: map['monthlyContribution']?.toDouble() ?? 0.0,
      targetDate: map['targetDate'],
      colorValue: map['colorValue'],
      isAutoDeduct: map['isAutoDeduct'] ?? false,
      autoDeductDay: map['autoDeductDay'],
    );
  }

  String toJson() => json.encode(toMap());

  factory GoalModel.fromJson(String source) => GoalModel.fromMap(json.decode(source));

  GoalModel copyWith({
    String? id,
    String? title,
    double? targetAmount,
    double? currentAmount,
    double? monthlyContribution,
    String? targetDate,
    int? colorValue,
    bool? isAutoDeduct,
    int? autoDeductDay,
  }) {
    return GoalModel(
      id: id ?? this.id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      monthlyContribution: monthlyContribution ?? this.monthlyContribution,
      targetDate: targetDate ?? this.targetDate,
      colorValue: colorValue ?? this.colorValue,
      isAutoDeduct: isAutoDeduct ?? this.isAutoDeduct,
      autoDeductDay: autoDeductDay ?? this.autoDeductDay,
    );
  }
}
