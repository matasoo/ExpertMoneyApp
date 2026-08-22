import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firestore_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../domain/models/account.dart';

final accountsProvider = NotifierProvider<AccountsNotifier, List<AccountModel>>(() {
  return AccountsNotifier();
});

class AccountsNotifier extends Notifier<List<AccountModel>> {
  StreamSubscription? _sub;

  @override
  List<AccountModel> build() {
    ref.watch(authStateProvider);
    _loadAccounts();
    
    ref.onDispose(() {
      _sub?.cancel();
    });
    
    return [];
  }

  void _loadAccounts() {
    _sub?.cancel();
    if (firestoreService.currentUserId == null) return;
    
    _sub = firestoreService.collectionStream('accounts').listen((data) {
      final accounts = data.map((item) => AccountModel.fromMap(item)).toList();
      state = accounts;
    }, onError: (e) => print('Stream error: $e'));
  }

  Future<void> addAccount(AccountModel account) async {
    await firestoreService.addDocument('accounts', account.toMap());
  }

  Future<void> removeAccount(String id) async {
    await firestoreService.deleteDocument('accounts', id);
  }

  Future<void> updateAccountBalance(String id, double changeAmount, {required bool isExpense}) async {
    final a = state.firstWhere((element) => element.id == id);
    final newBalance = isExpense ? a.balance - changeAmount : a.balance + changeAmount;
    await firestoreService.updateDocument('accounts', id, {
      'balance': newBalance,
    });
  }
}
