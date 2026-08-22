import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

class HasSeenOnboardingNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool('hasSeenOnboarding') ?? false;
  }

  void set(bool value) {
    state = value;
  }
}

final hasSeenOnboardingProvider = NotifierProvider<HasSeenOnboardingNotifier, bool>(() {
  return HasSeenOnboardingNotifier();
});

class IsUserLoggedInNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool('isUserLoggedIn') ?? false;
  }

  void set(bool value) {
    state = value;
  }
}

final isUserLoggedInProvider = NotifierProvider<IsUserLoggedInNotifier, bool>(() {
  return IsUserLoggedInNotifier();
});
