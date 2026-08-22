import 'dart:convert';

class CreditModel {
  final String id;
  final String name;
  final double totalAmount;
  final double paidAmount;
  final double monthlyContribution;
  final String icon;
  final DateTime nextPaymentDate;
  final String? accountId;

  CreditModel({
    required this.id,
    required this.name,
    required this.totalAmount,
    required this.paidAmount,
    required this.monthlyContribution,
    required this.icon,
    required this.nextPaymentDate,
    this.accountId,
  });

  double get progress => totalAmount > 0 ? (paidAmount / totalAmount).clamp(0.0, 1.0) : 0.0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'monthlyContribution': monthlyContribution,
      'icon': icon,
      'nextPaymentDate': nextPaymentDate.toIso8601String(),
      'accountId': accountId,
    };
  }

  factory CreditModel.fromMap(Map<String, dynamic> map) {
    return CreditModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      totalAmount: map['totalAmount']?.toDouble() ?? 0.0,
      paidAmount: map['paidAmount']?.toDouble() ?? 0.0,
      monthlyContribution: map['monthlyContribution']?.toDouble() ?? 0.0,
      icon: map['icon'] ?? '🏦',
      nextPaymentDate: DateTime.parse(map['nextPaymentDate']),
      accountId: map['accountId'],
    );
  }

  String toJson() => json.encode(toMap());

  factory CreditModel.fromJson(String source) => CreditModel.fromMap(json.decode(source));
}
