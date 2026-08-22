import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firestore_service.dart';
import '../../auth/providers/auth_provider.dart';

final dailyBudgetProvider = NotifierProvider<DailyBudgetNotifier, double?>(() {
  return DailyBudgetNotifier();
});

class DailyBudgetNotifier extends Notifier<double?> {
  StreamSubscription? _sub;

  @override
  double? build() {
    ref.watch(authStateProvider);
    _loadBudget();
    
    ref.onDispose(() {
      _sub?.cancel();
    });
    
    return null;
  }

  void _loadBudget() {
    _sub?.cancel();
    if (firestoreService.currentUserId == null) return;
    
    _sub = firestoreService.userProfileStream().listen((data) {
      if (data != null && data.containsKey('dailyBudgetLimit')) {
        final val = (data['dailyBudgetLimit'] as num?)?.toDouble();
        state = (val != null && val > 0) ? val : null;
      } else {
        state = null;
      }
    }, onError: (e) => print('Stream error: $e'));
  }

  Future<void> setBudget(double budget) async {
    if (firestoreService.currentUserId == null) return;
    
    if (budget > 0) {
      await firestoreService.updateUserProfile({'dailyBudgetLimit': budget});
    } else {
      await firestoreService.updateUserProfile({'dailyBudgetLimit': null});
    }
  }
}
