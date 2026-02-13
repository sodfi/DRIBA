import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/driba_colors.dart';

// ============================================
// DRIBA PAGE TRANSITIONS
// Custom route transitions for premium feel.
// Fade-slide, scale, shared-axis, modal.
// ============================================

/// Standard page push — slide up + fade
class DribaPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  DribaPageRoute({required this.page})
      : super(
          pageBuilder: (_, __, ___) => page,
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            return FadeTransition(
              opacity: curvedAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.06),
                  end: Offset.zero,
                ).animate(curvedAnimation),
                child: child,
              ),
            );
          },
        );
}

/// Modal-style — slide up from bottom with scale
class DribaModalRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  DribaModalRoute({required this.page})
      : super(
          opaque: false,
          pageBuilder: (_, __, ___) => page,
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            return FadeTransition(
              opacity: Tween<double>(begin: 0, end: 1).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: const Interval(0, 0.5, curve: Curves.easeOut),
                ),
              ),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.15),
                  end: Offset.zero,
                ).animate(curvedAnimation),
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.95, end: 1.0).animate(curvedAnimation),
                  child: child,
                ),
              ),
            );
          },
        );
}

/// Scale + fade — for detail screens, profiles
class DribaScaleRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Alignment scaleAlignment;

  DribaScaleRoute({
    required this.page,
    this.scaleAlignment = Alignment.center,
  }) : super(
          pageBuilder: (_, __, ___) => page,
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );

            return FadeTransition(
              opacity: curvedAnimation,
              child: ScaleTransition(
                alignment: scaleAlignment,
                scale: Tween<double>(begin: 0.92, end: 1.0).animate(curvedAnimation),
                child: child,
              ),
            );
          },
        );
}

/// Shared axis — horizontal slide (for tab-like navigation)
class DribaSharedAxisRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final bool forward;

  DribaSharedAxisRoute({
    required this.page,
    this.forward = true,
  }) : super(
          pageBuilder: (_, __, ___) => page,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final direction = forward ? 1.0 : -1.0;
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );

            return FadeTransition(
              opacity: curvedAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(0.1 * direction, 0),
                  end: Offset.zero,
                ).animate(curvedAnimation),
                child: child,
              ),
            );
          },
        );
}

/// Fade only — minimal transition
class DribaFadeRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  DribaFadeRoute({required this.page})
      : super(
          pageBuilder: (_, __, ___) => page,
          transitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, _, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
}

// ── NAVIGATION HELPERS ────────────────────────

extension DribaNavigator on BuildContext {
  /// Push with default Driba transition
  Future<T?> push<T>(Widget page) {
    return Navigator.of(this).push<T>(DribaPageRoute(page: page));
  }

  /// Push modal-style
  Future<T?> pushModal<T>(Widget page) {
    return Navigator.of(this).push<T>(DribaModalRoute(page: page));
  }

  /// Push with scale
  Future<T?> pushScale<T>(Widget page, {Alignment alignment = Alignment.center}) {
    return Navigator.of(this).push<T>(DribaScaleRoute(page: page, scaleAlignment: alignment));
  }

  /// Push with shared axis
  Future<T?> pushAxis<T>(Widget page, {bool forward = true}) {
    return Navigator.of(this).push<T>(DribaSharedAxisRoute(page: page, forward: forward));
  }

  /// Push fade only
  Future<T?> pushFade<T>(Widget page) {
    return Navigator.of(this).push<T>(DribaFadeRoute(page: page));
  }

  /// Replace with Driba transition
  Future<T?> pushReplacement<T, TO>(Widget page) {
    return Navigator.of(this).pushReplacement<T, TO>(DribaPageRoute(page: page));
  }

  /// Pop
  void pop<T>([T? result]) => Navigator.of(this).pop(result);
}
