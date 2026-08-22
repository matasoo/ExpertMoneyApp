import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firestore_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../domain/models/budget.dart';

final budgetsProvider = NotifierProvider<BudgetsNotifier, List<BudgetModel>>(() {
  return BudgetsNotifier();
});

class BudgetsNotifier extends Notifier<List<BudgetModel>> {
  StreamSubscription? _sub;

  @override
  List<BudgetModel> build() {
    ref.watch(authStateProvider);
    _loadBudgets();
    
    ref.onDispose(() {
      _sub?.cancel();
    });
    
    return [];
  }

  void _loadBudgets() {
    _sub?.cancel();
    if (firestoreService.currentUserId == null) return;
    
    _sub = firestoreService.collectionStream('budgets').listen((data) {
      final budgets = data.map((e) => BudgetModel.fromMap(e)).toList();
      state = budgets;
    }, onError: (e) => print('Stream error: $e'));
  }

  Future<void> addBudget(BudgetModel budget) async {
    await firestoreService.addDocument('budgets', budget.toMap());
  }

  Future<void> updateBudgetCurrentSpent(String id, double additionalSpent) async {
    final b = state.firstWhere((element) => element.id == id);
    await firestoreService.updateDocument('budgets', id, {
      'currentSpent': b.currentSpent + additionalSpent,
    });
  }

  Future<void> updateBudget(BudgetModel updatedBudget) async {
    await firestoreService.updateDocument('budgets', updatedBudget.id, updatedBudget.toMap());
  }

  Future<void> removeBudget(String id) async {
    await firestoreService.deleteDocument('budgets', id);
  }
}
