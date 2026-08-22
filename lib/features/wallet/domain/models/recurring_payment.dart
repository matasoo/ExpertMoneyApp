import 'dart:convert';

enum PaymentInterval {
  weekly,
  monthly,
  yearly,
}

class RecurringPaymentModel {
  final String id;
  final String name;
  final double amount;
  final String icon;
  final PaymentInterval interval;
  final DateTime nextPaymentDate;
  final DateTime startDate;
  final String? accountId;

  RecurringPaymentModel({
    required this.id,
    required this.name,
    required this.amount,
    required this.icon,
    required this.interval,
    required this.nextPaymentDate,
    required this.startDate,
    this.accountId,
  });

  double get totalPaidSoFar {
    final now = DateTime.now();
    if (now.isBefore(startDate)) return 0.0;
    
    int occurrences = 0;
    DateTime current = startDate;
    
    while (current.isBefore(now) || current.isAtSameMomentAs(now)) {
      occurrences++;
      if (interval == PaymentInterval.weekly) {
        current = current.add(const Duration(days: 7));
      } else if (interval == PaymentInterval.monthly) {
        current = DateTime(current.year, current.month + 1, current.day);
      } else if (interval == PaymentInterval.yearly) {
        current = DateTime(current.year + 1, current.month, current.day);
      }
    }
    
    return amount * occurrences;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'icon': icon,
      'interval': interval.name,
      'nextPaymentDate': nextPaymentDate.toIso8601String(),
      'startDate': startDate.toIso8601String(),
      'accountId': accountId,
    };
  }

  factory RecurringPaymentModel.fromMap(Map<String, dynamic> map) {
    return RecurringPaymentModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      amount: map['amount']?.toDouble() ?? 0.0,
      icon: map['icon'] ?? '🔄',
      interval: PaymentInterval.values.firstWhere((e) => e.name == map['interval'], orElse: () => PaymentInterval.monthly),
      nextPaymentDate: DateTime.parse(map['nextPaymentDate']),
      startDate: map['startDate'] != null ? DateTime.parse(map['startDate']) : DateTime.parse(map['nextPaymentDate']),
      accountId: map['accountId'],
    );
  }

  String toJson() => json.encode(toMap());

  factory RecurringPaymentModel.fromJson(String source) => RecurringPaymentModel.fromMap(json.decode(source));
}
