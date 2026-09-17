import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firestore_service.dart';

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
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
          throw 'Incorrect email or password.';
        } else if (e.code == 'invalid-email') {
          throw 'The email address is invalid.';
        } else if (e.code == 'user-disabled') {
          throw 'This account has been disabled.';
        } else {
          throw 'Login error: ${e.message}';
        }
      } catch (e) {
        throw 'An unexpected error occurred.';
      }
    });
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        if (kIsWeb) {
          final googleProvider = GoogleAuthProvider();
          googleProvider.addScope('email');
          await FirebaseAuth.instance.signInWithPopup(googleProvider);
        } else {
          final GoogleSignInAccount googleUser = await GoogleSignIn.instance.authenticate();
          final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
          
          final AuthCredential credential = GoogleAuthProvider.credential(
            idToken: googleAuth.idToken,
            accessToken: null,
          );
          await FirebaseAuth.instance.signInWithCredential(credential);
        }
      } on FirebaseAuthException catch (e) {
        throw 'Google login error: ${e.message}';
      } on Exception catch (e) {
        if (e.toString().contains('canceled')) rethrow;
        throw 'An unexpected error occurred with Google Sign In.';
      }
    });
  }

  Future<void> signInWithApple() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        final appleProvider = AppleAuthProvider();
        appleProvider.addScope('email');
        appleProvider.addScope('name');
        if (kIsWeb) {
          await FirebaseAuth.instance.signInWithPopup(appleProvider);
        } else {
          await FirebaseAuth.instance.signInWithProvider(appleProvider);
        }
      } on FirebaseAuthException catch (e) {
        throw 'Apple login error: ${e.message}';
      } catch (e) {
        throw 'An unexpected error occurred with Apple Sign In.';
      }
    });
  }

  Future<void> registerWithEmail(String email, String password, String name) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        await cred.user?.updateDisplayName(name);
        
        try {
          // Force token refresh to ensure Cloud Functions SDK picks it up immediately
          await cred.user?.getIdToken(true);
          await FirebaseFunctions.instance.httpsCallable('sendVerificationCode').call();
        } catch (e) {
          print('Error calling sendVerificationCode: $e');
          // We shouldn't fail registration if email sending fails, but we could handle it better
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          throw 'An account already exists with this email address.';
        } else if (e.code == 'invalid-email') {
          throw 'The email address is invalid.';
        } else if (e.code == 'weak-password') {
          throw 'The password is too weak. Please choose a stronger password.';
        } else {
          throw 'Registration error: ${e.message}';
        }
      } catch (e) {
        throw 'An unexpected error occurred.';
      }
    });
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await FirebaseAuth.instance.signOut();
    });
  }

  Future<void> resetPassword(String email) async {
    state = const AsyncLoading();
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
      state = const AsyncData(null);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        state = AsyncError('No account found with this email.', StackTrace.current);
      } else if (e.code == 'invalid-email') {
        state = AsyncError('The email address is invalid.', StackTrace.current);
      } else {
        state = AsyncError('Error: ${e.message}', StackTrace.current);
      }
      rethrow;
    } catch (e, st) {
      state = AsyncError('An unexpected error occurred.', st);
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    state = const AsyncLoading();
    try {
      // Delete all associated Firestore data before deleting the Auth record
      await firestoreService.deleteUserAccountData();
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
