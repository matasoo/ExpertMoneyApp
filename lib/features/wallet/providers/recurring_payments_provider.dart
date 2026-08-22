import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firestore_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../domain/models/recurring_payment.dart';

final recurringPaymentsProvider = NotifierProvider<RecurringPaymentsNotifier, List<RecurringPaymentModel>>(() {
  return RecurringPaymentsNotifier();
});

class RecurringPaymentsNotifier extends Notifier<List<RecurringPaymentModel>> {
  StreamSubscription? _sub;

  @override
  List<RecurringPaymentModel> build() {
    ref.watch(authStateProvider);
    _loadPayments();
    
    ref.onDispose(() {
      _sub?.cancel();
    });
    
    return [];
  }

  void _loadPayments() {
    _sub?.cancel();
    if (firestoreService.currentUserId == null) return;
    
    _sub = firestoreService.collectionStream('recurring_payments').listen((data) {
      final payments = data.map((e) => RecurringPaymentModel.fromMap(e)).toList();
      payments.sort((a, b) => a.nextPaymentDate.compareTo(b.nextPaymentDate));
      state = payments;
    }, onError: (e) => print('Stream error: $e'));
  }

  void addPayment(RecurringPaymentModel payment) {
    firestoreService.addDocument('recurring_payments', payment.toMap());
  }

  void removePayment(String id) {
    firestoreService.deleteDocument('recurring_payments', id);
  }
}
