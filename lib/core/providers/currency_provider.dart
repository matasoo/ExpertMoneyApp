import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';
import '../../features/auth/providers/auth_provider.dart';

final currencyProvider = NotifierProvider<CurrencyNotifier, String>(() {
  return CurrencyNotifier();
});

class CurrencyNotifier extends Notifier<String> {
  StreamSubscription? _sub;

  @override
  String build() {
    ref.watch(authStateProvider); // Rebuild when user logs in/out
    _loadCurrency();
    
    ref.onDispose(() {
      _sub?.cancel();
    });
    
    return '\$'; // Default to USD
  }

  void _loadCurrency() {
    _sub?.cancel();
    if (firestoreService.currentUserId == null) return;
    
    _sub = firestoreService.userProfileStream().listen((data) {
      if (data != null && data.containsKey('currency')) {
        final val = data['currency'] as String?;
        if (val != null && val.isNotEmpty) {
          state = val;
        }
      }
    }, onError: (e) => print('Stream error: $e'));
  }

  Future<void> setCurrency(String newCurrency) async {
    state = newCurrency; // Update UI instantly
    
    if (firestoreService.currentUserId == null) return;
    
    try {
      await firestoreService.updateUserProfile({'currency': newCurrency});
    } catch (e) {
      print('Error saving currency to Firestore: $e');
    }
  }
}
