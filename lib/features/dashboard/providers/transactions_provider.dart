import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firestore_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../domain/models/transaction.dart';

final transactionsProvider = NotifierProvider<TransactionsNotifier, List<TransactionModel>>(() {
  return TransactionsNotifier();
});

class TransactionsNotifier extends Notifier<List<TransactionModel>> {
  StreamSubscription? _sub;

  @override
  List<TransactionModel> build() {
    ref.watch(authStateProvider);
    _loadTransactions();
    
    // Automatically reload when user changes
    ref.onDispose(() {
      _sub?.cancel();
    });
    
    return [];
  }

  void _loadTransactions() {
    _sub?.cancel();
    if (firestoreService.currentUserId == null) return;
    
    _sub = firestoreService.collectionStream('transactions').listen((data) {
      final transactions = data.map((e) => TransactionModel.fromMap(e)).toList();
      transactions.sort((a, b) => b.date.compareTo(a.date));
      state = transactions;
    }, onError: (e) => print('Stream error: $e'));
  }

  void addTransaction(TransactionModel transaction) {
    firestoreService.addDocument('transactions', transaction.toMap());
  }

  void removeTransaction(String id) {
    firestoreService.deleteDocument('transactions', id);
  }

  double getTotalExpensesForCurrentMonth() {
    final now = DateTime.now();
    return state
        .where((t) => t.isExpense && t.date.month == now.month && t.date.year == now.year)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getTotalExpensesForToday() {
    final now = DateTime.now();
    return state
        .where((t) => t.isExpense && t.date.day == now.day && t.date.month == now.month && t.date.year == now.year)
        .fold(0.0, (sum, t) => sum + t.amount);
  }
}
