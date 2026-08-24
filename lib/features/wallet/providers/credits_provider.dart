import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firestore_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../domain/models/credit_model.dart';

final creditsProvider = NotifierProvider<CreditsNotifier, List<CreditModel>>(() {
  return CreditsNotifier();
});

class CreditsNotifier extends Notifier<List<CreditModel>> {
  StreamSubscription? _sub;

  @override
  List<CreditModel> build() {
    ref.watch(authStateProvider);
    _loadCredits();
    
    ref.onDispose(() {
      _sub?.cancel();
    });
    
    return [];
  }

  void _loadCredits() {
    _sub?.cancel();
    if (firestoreService.currentUserId == null) return;
    
    _sub = firestoreService.collectionStream('credits').listen((data) {
      final credits = data.map((e) => CreditModel.fromMap(e)).toList();
      credits.sort((a, b) => a.nextPaymentDate.compareTo(b.nextPaymentDate));
      state = credits;
    }, onError: (e) => print('Stream error: $e'));
  }

  void addCredit(CreditModel credit) {
    firestoreService.addDocument('credits', credit.toMap());
  }

  void removeCredit(String id) {
    firestoreService.deleteDocument('credits', id);
  }

  void updateCredit(CreditModel credit) {
    firestoreService.updateDocument('credits', credit.id, credit.toMap());
  }
}
