import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firestore_service.dart';
import '../../auth/providers/auth_provider.dart';

class FixedCost {
  final String name;
  final double amount;
  FixedCost(this.name, this.amount);

  Map<String, dynamic> toMap() => {'name': name, 'amount': amount};
  factory FixedCost.fromMap(Map<String, dynamic> map) => FixedCost(map['name'] ?? '', map['amount']?.toDouble() ?? 0.0);
}

class SetupState {
  final double monthlyIncome;
  final bool isVariableIncome;
  final double savingsRate;
  final List<FixedCost> fixedCosts;
  final String mainGoal;

  SetupState({
    this.monthlyIncome = 3200,
    this.isVariableIncome = false,
    this.savingsRate = 0.2,
    this.fixedCosts = const [],
    this.mainGoal = 'Emergency fund',
  });

  SetupState copyWith({
    double? monthlyIncome,
    bool? isVariableIncome,
    double? savingsRate,
    List<FixedCost>? fixedCosts,
    String? mainGoal,
  }) {
    return SetupState(
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      isVariableIncome: isVariableIncome ?? this.isVariableIncome,
      savingsRate: savingsRate ?? this.savingsRate,
      fixedCosts: fixedCosts ?? this.fixedCosts,
      mainGoal: mainGoal ?? this.mainGoal,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'monthlyIncome': monthlyIncome,
      'isVariableIncome': isVariableIncome,
      'savingsRate': savingsRate,
      'fixedCosts': fixedCosts.map((c) => c.toMap()).toList(),
      'mainGoal': mainGoal,
    };
  }

  factory SetupState.fromMap(Map<String, dynamic> map) {
    return SetupState(
      monthlyIncome: map['monthlyIncome']?.toDouble() ?? 3200,
      isVariableIncome: map['isVariableIncome'] ?? false,
      savingsRate: map['savingsRate']?.toDouble() ?? 0.2,
      fixedCosts: (map['fixedCosts'] as List<dynamic>?)?.map((e) => FixedCost.fromMap(e)).toList() ?? [],
      mainGoal: map['mainGoal'] ?? 'Emergency fund',
    );
  }

  double get totalFixedCosts => fixedCosts.fold(0, (sum, cost) => sum + cost.amount);
  double get autoSaveAmount => isVariableIncome ? 0 : monthlyIncome * savingsRate;
  double get freeToBudget => isVariableIncome ? 0 : monthlyIncome - autoSaveAmount - totalFixedCosts;
}

class SetupNotifier extends Notifier<SetupState> {
  StreamSubscription? _sub;

  @override
  SetupState build() {
    ref.watch(authStateProvider);
    _loadSetupData();
    
    ref.onDispose(() {
      _sub?.cancel();
    });
    
    return SetupState(
      fixedCosts: [
        FixedCost('Rent / mortgage', 0),
        FixedCost('Utilities & bills', 0),
        FixedCost('Subscriptions', 0),
      ],
    );
  }

  void _loadSetupData() {
    _sub?.cancel();
    if (firestoreService.currentUserId == null) return;
    
    _sub = firestoreService.userProfileStream().listen((data) {
      if (data != null && data.containsKey('setupData')) {
        state = SetupState.fromMap(data['setupData']);
      }
    }, onError: (e) => print('Stream error: $e'));
  }

  Future<void> _saveToFirestore() async {
    if (firestoreService.currentUserId != null) {
      await firestoreService.updateUserProfile({
        'setupData': state.toMap(),
      });
    }
  }

  void setIncome(double income) { state = state.copyWith(monthlyIncome: income, isVariableIncome: false); _saveToFirestore(); }
  void setVariableIncome(bool value) { state = state.copyWith(isVariableIncome: value); _saveToFirestore(); }
  void setSavingsRate(double rate) { state = state.copyWith(savingsRate: rate); _saveToFirestore(); }
  void addFixedCost(FixedCost cost) { state = state.copyWith(fixedCosts: [...state.fixedCosts, cost]); _saveToFirestore(); }
  void removeFixedCost(FixedCost cost) { state = state.copyWith(fixedCosts: state.fixedCosts.where((c) => c != cost).toList()); _saveToFirestore(); }
  void editFixedCost(FixedCost oldCost, double newAmount) {
    final index = state.fixedCosts.indexOf(oldCost);
    if (index == -1) return;
    final newList = List<FixedCost>.from(state.fixedCosts);
    newList[index] = FixedCost(oldCost.name, newAmount);
    state = state.copyWith(fixedCosts: newList);
    _saveToFirestore();
  }
  void setMainGoal(String goal) { state = state.copyWith(mainGoal: goal); _saveToFirestore(); }
}

final setupProvider = NotifierProvider<SetupNotifier, SetupState>(() => SetupNotifier());
