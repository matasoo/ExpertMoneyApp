import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';
import '../../features/auth/providers/auth_provider.dart';

final premiumProvider = NotifierProvider<PremiumNotifier, bool>(() {
  return PremiumNotifier();
});

class PremiumNotifier extends Notifier<bool> {
  StreamSubscription? _profileSub;

  @override
  bool build() {
    // Listen to auth changes without triggering a full rebuild of this provider
    ref.listen(authStateProvider, (previous, next) {
      if (next.value != null) {
        _subscribeToProfile();
      } else {
        _profileSub?.cancel();
        state = true; // TEMPORARY: Give premium to everyone
      }
    });

    // Initial subscription
    _subscribeToProfile();
    
    return true; // TEMPORARY: Give premium to everyone
  }

  void _subscribeToProfile() {
    _profileSub?.cancel();
    _profileSub = firestoreService.userProfileStream().listen((profile) {
      // TEMPORARY: Give premium to everyone
      state = true;
      
      /* Original Logic:
      if (profile != null && profile.containsKey('isPremium')) {
        state = profile['isPremium'] == true;
      } else {
        state = false;
      }
      */
    }, onError: (e) => print('Stream error: $e'));
  }

  Future<void> upgradeToPremium() async {
    await Future.delayed(const Duration(seconds: 2));
    await firestoreService.updateUserProfile({'isPremium': true});
  }
}
