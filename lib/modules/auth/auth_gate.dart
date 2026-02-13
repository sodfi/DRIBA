import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/driba_colors.dart';
import 'auth_providers.dart';
import 'auth_screen.dart';
import 'personalization_screen.dart';

// ============================================
// AUTH GATE
//
// Root widget that routes users:
// 1. Not signed in → AuthScreen
// 2. Signed in, no onboarding → PersonalizationScreen
// 3. Signed in + onboarded → MainShell (via builder)
//
// Usage in main.dart:
//   AuthGate(mainApp: const MainShell())
// ============================================

class AuthGate extends ConsumerWidget {
  /// The main app widget to show after auth + onboarding
  final Widget mainApp;

  const AuthGate({super.key, required this.mainApp});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          // Not signed in → show auth screen
          return const AuthScreen();
        }

        // Signed in → check onboarding status
        return _OnboardingGate(user: user, mainApp: mainApp);
      },
      loading: () => const _SplashScreen(),
      error: (_, __) => const AuthScreen(),
    );
  }
}

/// Inner gate that checks onboarding completion
class _OnboardingGate extends ConsumerWidget {
  final User user;
  final Widget mainApp;

  const _OnboardingGate({required this.user, required this.mainApp});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboarding = ref.watch(hasCompletedOnboardingProvider);

    return onboarding.when(
      data: (completed) {
        if (completed) {
          return mainApp;
        }
        return const PersonalizationScreen();
      },
      loading: () => const _SplashScreen(),
      error: (_, __) => mainApp, // Fail open
    );
  }
}

/// Splash screen shown during auth state loading
class _SplashScreen extends StatefulWidget {
  const _SplashScreen();

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.6, curve: Curves.easeOutBack),
      ),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.4, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DribaColors.background,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, __) => Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: DribaColors.primaryGradient,
                      borderRadius: BorderRadius.circular(DribaBorderRadius.xl),
                      boxShadow: [
                        BoxShadow(
                          color: DribaColors.primary.withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'D',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: DribaSpacing.xl),
                  const Text(
                    'driba',
                    style: TextStyle(
                      color: DribaColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: DribaSpacing.xxxl),
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: DribaColors.primary.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
