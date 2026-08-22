import 'dart:convert';

class AccountModel {
  final String id;
  final String name;
  final double balance;
  final int? colorValue;
  final String? icon;

  AccountModel({
    required this.id,
    required this.name,
    required this.balance,
    this.colorValue,
    this.icon,
  });

  AccountModel copyWith({
    String? id,
    String? name,
    double? balance,
    int? colorValue,
    String? icon,
  }) {
    return AccountModel(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      colorValue: colorValue ?? this.colorValue,
      icon: icon ?? this.icon,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'colorValue': colorValue,
      'icon': icon,
    };
  }

  factory AccountModel.fromMap(Map<String, dynamic> map) {
    return AccountModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      balance: map['balance']?.toDouble() ?? 0.0,
      colorValue: map['colorValue']?.toInt(),
      icon: map['icon'],
    );
  }

  String toJson() => json.encode(toMap());

  factory AccountModel.fromJson(String source) => AccountModel.fromMap(json.decode(source));
}
