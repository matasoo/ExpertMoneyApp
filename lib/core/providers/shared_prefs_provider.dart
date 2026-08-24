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
    ref.read(sharedPreferencesProvider).setBool('hasSeenOnboarding', value);
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

class HasSeenAnalyticsTutorialNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool('hasSeenAnalyticsTutorial') ?? false;
  }

  void set(bool value) {
    state = value;
    ref.read(sharedPreferencesProvider).setBool('hasSeenAnalyticsTutorial', value);
  }
}

final hasSeenAnalyticsTutorialProvider = NotifierProvider<HasSeenAnalyticsTutorialNotifier, bool>(() {
  return HasSeenAnalyticsTutorialNotifier();
});

class HasSeenWalletTutorialNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool('hasSeenWalletTutorial') ?? false;
  }

  void set(bool value) {
    state = value;
    ref.read(sharedPreferencesProvider).setBool('hasSeenWalletTutorial', value);
  }
}

final hasSeenWalletTutorialProvider = NotifierProvider<HasSeenWalletTutorialNotifier, bool>(() {
  return HasSeenWalletTutorialNotifier();
});

class HasSeenGoalsTutorialNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool('hasSeenGoalsTutorial') ?? false;
  }

  void set(bool value) {
    state = value;
    ref.read(sharedPreferencesProvider).setBool('hasSeenGoalsTutorial', value);
  }
}

final hasSeenGoalsTutorialProvider = NotifierProvider<HasSeenGoalsTutorialNotifier, bool>(() {
  return HasSeenGoalsTutorialNotifier();
});

