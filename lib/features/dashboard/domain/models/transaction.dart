import 'dart:convert';
import 'package:flutter/material.dart';

enum TransactionCategory {
  food,
  transport,
  utilities,
  entertainment,
  shopping,
  salary,
  other
}

class TransactionModel {
  final String id;
  final String title;
  final String storeName;
  final double amount;
  final DateTime date;
  final TransactionCategory category;
  final String? customCategoryName;
  final bool isExpense;
  final String? accountId;

  TransactionModel({
    required this.id,
    required this.title,
    required this.storeName,
    required this.amount,
    required this.date,
    required this.category,
    this.customCategoryName,
    required this.isExpense,
    this.accountId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'storeName': storeName,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category.name,
      'customCategoryName': customCategoryName,
      'isExpense': isExpense,
      'accountId': accountId,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      storeName: map['storeName'] ?? '',
      amount: map['amount']?.toDouble() ?? 0.0,
      date: DateTime.parse(map['date']),
      category: TransactionCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => TransactionCategory.other,
      ),
      customCategoryName: map['customCategoryName'],
      isExpense: map['isExpense'] ?? true,
      accountId: map['accountId'],
    );
  }

  String toJson() => json.encode(toMap());

  factory TransactionModel.fromJson(String source) => TransactionModel.fromMap(json.decode(source));

  IconData get icon {
    switch (category) {
      case TransactionCategory.food:
        return Icons.restaurant;
      case TransactionCategory.transport:
        return Icons.directions_car;
      case TransactionCategory.utilities:
        return Icons.bolt;
      case TransactionCategory.entertainment:
        return Icons.movie;
      case TransactionCategory.shopping:
        return Icons.shopping_bag;
      case TransactionCategory.salary:
        return Icons.account_balance;
      case TransactionCategory.other:
        return Icons.more_horiz;
    }
  }
}
