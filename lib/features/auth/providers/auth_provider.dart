import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

class AuthController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // Initial state is null (void)
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    });
  }

  Future<void> registerWithEmail(String email, String password, String name) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await cred.user?.updateDisplayName(name);
    });
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await FirebaseAuth.instance.signOut();
    });
  }

  Future<void> deleteAccount() async {
    state = const AsyncLoading();
    try {
      // Note: A robust system would also delete Firestore data via Cloud Functions 
      // or batched writes here before deleting the Auth record.
      await FirebaseAuth.instance.currentUser?.delete();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow; // Rethrow so the UI can catch it and show the SnackBar
    }
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(() {
  return AuthController();
});
