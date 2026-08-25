import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import 'dart:async';
import '../../features/setup/presentation/setup_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/premium/presentation/premium_paywall_screen.dart';
import '../providers/shared_prefs_provider.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../../features/security/presentation/app_lock_screen.dart';
import '../../features/security/providers/app_lock_provider.dart';
final hasCompletedSetupProvider = NotifierProvider<HasCompletedSetupNotifier, bool>(() {
  return HasCompletedSetupNotifier();
});

class HasCompletedSetupNotifier extends Notifier<bool> {
  StreamSubscription? _sub;

  @override
  bool build() {
    final user = ref.watch(authStateProvider).value; // Rebuild when user logs in/out
    final prefs = ref.watch(sharedPreferencesProvider);
    
    ref.onDispose(() => _sub?.cancel());
    _sub?.cancel();
    
    final userId = user?.uid;
    if (userId == null) return false;

    // Attempt to listen to firestore if logged in, but don't block build
    Future.microtask(() {
      _sub = firestoreService.userProfileStream().listen(
        (data) {
          if (data != null && data['hasCompletedSetup'] == true) {
            if (!state) {
              state = true;
              prefs.setBool('hasCompletedSetup_$userId', true);
            }
          }
        },
        onError: (error) {
          // Ignore permission-denied errors (e.g. when account is deleted but auth token is still cached)
          print('Error listening to user profile: $error');
        }
      );
    });

    return prefs.getBool('hasCompletedSetup_$userId') ?? false;
  }

  Future<void> completeSetup() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final userId = firestoreService.currentUserId;
    if (userId != null) {
      await prefs.setBool('hasCompletedSetup_$userId', true);
      await firestoreService.updateUserProfile({'hasCompletedSetup': true});
    }
    state = true;
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final isUserLoggedIn = authState.value != null;
  final hasSeenOnboarding = ref.watch(hasSeenOnboardingProvider);
  final hasCompletedSetup = ref.watch(hasCompletedSetupProvider);

  final isAppLocked = ref.watch(appLockProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isGoingToLogin = state.uri.toString() == '/login';
      final isGoingToRegister = state.uri.toString() == '/register';
      final isGoingToOnboarding = state.uri.toString() == '/onboarding';
      final isGoingToSetup = state.uri.toString() == '/setup';
      final isGoingToAppLock = state.uri.toString() == '/app-lock';

      // 1. If user is logged in and HAS completed setup
      if (isUserLoggedIn && hasCompletedSetup) {
        if (isGoingToLogin || isGoingToRegister || isGoingToOnboarding || isGoingToSetup || (!isAppLocked && isGoingToAppLock)) {
          return '/'; // Go to Dashboard
        }
        if (isAppLocked && !isGoingToAppLock) {
          return '/app-lock';
        }
        return null; // Proceed
      }

      // 2. If user is logged in but HAS NOT completed setup
      if (isUserLoggedIn && !hasCompletedSetup) {
        if (!isGoingToSetup) {
          return '/setup';
        }
        return null; // Let them stay on /setup
      }

      // 3. If user is NOT logged in
      if (!isUserLoggedIn) {
        if (!hasSeenOnboarding) {
          if (!isGoingToOnboarding) return '/onboarding';
          return null;
        } else {
          if (!isGoingToLogin && !isGoingToRegister) return '/login';
          return null;
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/app-lock',
        builder: (context, state) => const AppLockScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/setup',
        builder: (context, state) => const SetupScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ProfileScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Trying negative offset since the positive one apparently slid left-to-right for the user on Web
            const begin = Offset(-1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeOutCubic;

            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/paywall',
        name: 'paywall',
        builder: (context, state) => const PremiumPaywallScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const DashboardScreen(),
      ),
    ],
  );
});
