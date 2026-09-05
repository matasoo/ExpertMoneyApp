import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import '../../../core/providers/shared_prefs_provider.dart';

final appLockFeatureEnabledProvider = NotifierProvider<AppLockFeatureEnabledNotifier, bool>(() {
  return AppLockFeatureEnabledNotifier();
});

class AppLockFeatureEnabledNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(AppLockNotifier._appLockEnabledKey) ?? false;
  }

  void setEnabled(bool value) {
    state = value;
  }
}

final appLockProvider = NotifierProvider<AppLockNotifier, bool>(() {
  return AppLockNotifier();
});

class AppLockNotifier extends Notifier<bool> {
  final LocalAuthentication _auth = LocalAuthentication();
  
  // Key for storing if the user has enabled the lock feature
  static const String _appLockEnabledKey = 'app_lock_enabled';
  
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final isEnabled = prefs.getBool(_appLockEnabledKey) ?? false;
    
    // If it's enabled, the app starts in a locked state
    return isEnabled;
  }

  Future<void> toggleAppLock(bool enable) async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (enable) {
      // Try to authenticate before enabling
      final authenticated = await authenticate();
      if (authenticated) {
        await prefs.setBool(_appLockEnabledKey, true);
        ref.read(appLockFeatureEnabledProvider.notifier).setEnabled(true);
      }
    } else {
      // Authenticate before disabling for security
      final authenticated = await authenticate();
      if (authenticated) {
        await prefs.setBool(_appLockEnabledKey, false);
        ref.read(appLockFeatureEnabledProvider.notifier).setEnabled(false);
        state = false;
      }
    }
  }

  bool isAppLockEnabled() {
    final prefs = ref.read(sharedPreferencesProvider);
    return prefs.getBool(_appLockEnabledKey) ?? false;
  }

  Future<bool> authenticate() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

      if (!canAuthenticate) {
        // If device has no security, just unlock
        state = false;
        return true;
      }

      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Please authenticate to access your finances',
      );

      if (didAuthenticate) {
        state = false; // Unlocked
      }
      return didAuthenticate;
    } on PlatformException catch (e) {
      print('Error authenticating: $e');
      return false;
    }
  }

  void lockApp() {
    if (isAppLockEnabled()) {
      state = true;
    }
  }
}
