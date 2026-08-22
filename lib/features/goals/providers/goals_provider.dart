import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firestore_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../domain/models/goal.dart';

final goalsProvider = NotifierProvider<GoalsNotifier, List<GoalModel>>(() {
  return GoalsNotifier();
});

class GoalsNotifier extends Notifier<List<GoalModel>> {
  StreamSubscription? _sub;

  @override
  List<GoalModel> build() {
    ref.watch(authStateProvider);
    _loadGoals();
    
    ref.onDispose(() {
      _sub?.cancel();
    });
    
    return [];
  }

  void _loadGoals() {
    _sub?.cancel();
    if (firestoreService.currentUserId == null) return;
    
    _sub = firestoreService.collectionStream('goals').listen((data) {
      final goals = data.map((e) => GoalModel.fromMap(e)).toList();
      state = goals;
    }, onError: (e) => print('Stream error: $e'));
  }

  Future<void> addGoal(GoalModel goal) async {
    await firestoreService.addDocument('goals', goal.toMap());
  }

  Future<void> updateGoalCurrentAmount(String id, double newAmount) async {
    await firestoreService.updateDocument('goals', id, {
      'currentAmount': newAmount,
    });
  }

  Future<void> updateGoal(GoalModel updatedGoal) async {
    await firestoreService.updateDocument('goals', updatedGoal.id, updatedGoal.toMap());
  }

  Future<void> removeGoal(String id) async {
    await firestoreService.deleteDocument('goals', id);
  }
}
