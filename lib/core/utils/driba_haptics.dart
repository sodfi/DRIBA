import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';

// ============================================
// DRIBA HAPTICS
// Centralized haptic feedback that respects
// the user's haptics toggle in settings.
// Use this instead of HapticFeedback directly.
// ============================================

class DribaHaptics {
  final WidgetRef _ref;

  DribaHaptics(this._ref);

  bool get _enabled => _ref.read(hapticsEnabledProvider);

  /// Lightest tap — tab switches, selections
  void light() {
    if (_enabled) HapticFeedback.lightImpact();
  }

  /// Medium tap — button presses, follows
  void medium() {
    if (_enabled) HapticFeedback.mediumImpact();
  }

  /// Heavy tap — save, sign out, destructive
  void heavy() {
    if (_enabled) HapticFeedback.heavyImpact();
  }

  /// Selection tick — toggles, pickers
  void selection() {
    if (_enabled) HapticFeedback.selectionClick();
  }

  /// Vibrate pattern — errors, warnings
  void vibrate() {
    if (_enabled) HapticFeedback.vibrate();
  }
}

/// Static version for use outside of widget tree
/// (falls back to enabled = true when no ref available)
class DribaHapticsStatic {
  static bool _enabled = true;

  static void updateEnabled(bool enabled) {
    _enabled = enabled;
  }

  static void light() {
    if (_enabled) HapticFeedback.lightImpact();
  }

  static void medium() {
    if (_enabled) HapticFeedback.mediumImpact();
  }

  static void heavy() {
    if (_enabled) HapticFeedback.heavyImpact();
  }

  static void selection() {
    if (_enabled) HapticFeedback.selectionClick();
  }
}
