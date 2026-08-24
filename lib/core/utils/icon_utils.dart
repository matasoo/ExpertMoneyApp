import 'package:flutter/material.dart';

class IconUtils {
  static IconData getIconData(String identifier, {IconData fallback = Icons.category}) {
    if (identifier.isEmpty) return fallback;
    
    // Try to parse as integer (MaterialIcons code point)
    final int? codePoint = int.tryParse(identifier);
    if (codePoint != null) {
      return IconData(codePoint, fontFamily: 'MaterialIcons');
    }

    // Legacy emoji mapping
    switch (identifier) {
      case '🍔': return Icons.restaurant;
      case '⛽': return Icons.local_gas_station;
      case '🎉': return Icons.celebration;
      case '🚌': return Icons.directions_bus;
      case '🏠': return Icons.home;
      case '✏️': return Icons.edit;
      case '🏦': return Icons.account_balance;
      case '💳': return Icons.credit_card;
      case '💵': return Icons.attach_money;
      case '💰': return Icons.savings;
      case '📱': return Icons.phone_iphone;
      case '🏛️': return Icons.account_balance;
      case '🔄': return Icons.autorenew;
      case '🎮': return Icons.sports_esports;
      case '🍿': return Icons.movie;
      case '👔': return Icons.work;
      case '🛒': return Icons.shopping_cart;
      case '🚗': return Icons.directions_car;
      case '⚡': return Icons.bolt;
      case '🎓': return Icons.school;
      case '⚕️': return Icons.local_hospital;
      default: return fallback;
    }
  }
}
