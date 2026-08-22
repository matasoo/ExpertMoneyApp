import 'package:flutter_riverpod/flutter_riverpod.dart';

final privacyProvider = NotifierProvider<PrivacyNotifier, bool>(() {
  return PrivacyNotifier();
});

class PrivacyNotifier extends Notifier<bool> {
  @override
  bool build() {
    return false; // Default is visible
  }

  void togglePrivacy() {
    state = !state;
  }
}
