import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/driba_colors.dart';

// ============================================
// THEME PROVIDER
// Manages appearance: accent color, theme mode,
// font scale, haptics, reduced motion, and more.
// Persists to SharedPreferences + Firestore.
// ============================================

/// All available accent color presets
class AccentPreset {
  final String id;
  final String name;
  final Color color;
  final Color colorLight;
  final String emoji;

  const AccentPreset({
    required this.id,
    required this.name,
    required this.color,
    required this.colorLight,
    required this.emoji,
  });
}

const List<AccentPreset> accentPresets = [
  AccentPreset(id: 'cyan',    name: 'Cyan',     color: Color(0xFF00E1FF), colorLight: Color(0xFF4DFFFF), emoji: '💎'),
  AccentPreset(id: 'violet',  name: 'Violet',   color: Color(0xFF8B5CF6), colorLight: Color(0xFFA78BFA), emoji: '💜'),
  AccentPreset(id: 'rose',    name: 'Rose',     color: Color(0xFFFF3D71), colorLight: Color(0xFFFF708D), emoji: '🌹'),
  AccentPreset(id: 'amber',   name: 'Amber',    color: Color(0xFFFFAA00), colorLight: Color(0xFFFFCC33), emoji: '🔥'),
  AccentPreset(id: 'emerald', name: 'Emerald',  color: Color(0xFF00D68F), colorLight: Color(0xFF36E8B0), emoji: '💚'),
  AccentPreset(id: 'sky',     name: 'Sky',      color: Color(0xFF00B4D8), colorLight: Color(0xFF48CAE4), emoji: '🌊'),
  AccentPreset(id: 'coral',   name: 'Coral',    color: Color(0xFFFF6B35), colorLight: Color(0xFFFF8F5E), emoji: '🧡'),
  AccentPreset(id: 'mint',    name: 'Mint',     color: Color(0xFF2DD4BF), colorLight: Color(0xFF5EEAD4), emoji: '🍃'),
  AccentPreset(id: 'pink',    name: 'Pink',     color: Color(0xFFEC4899), colorLight: Color(0xFFF472B6), emoji: '🌸'),
  AccentPreset(id: 'gold',    name: 'Gold',     color: Color(0xFFFFD700), colorLight: Color(0xFFFFE44D), emoji: '✨'),
];

/// Theme mode — only Dark and AMOLED for now (Glass OS design)
enum DribaThemeMode { dark, amoled }

/// Font scale presets
enum FontScale { small, normal, large, extraLarge }

extension FontScaleValue on FontScale {
  double get value {
    switch (this) {
      case FontScale.small: return 0.85;
      case FontScale.normal: return 1.0;
      case FontScale.large: return 1.15;
      case FontScale.extraLarge: return 1.3;
    }
  }

  String get label {
    switch (this) {
      case FontScale.small: return 'Small';
      case FontScale.normal: return 'Normal';
      case FontScale.large: return 'Large';
      case FontScale.extraLarge: return 'Extra Large';
    }
  }
}

/// Complete theme/appearance state
class ThemeState {
  final String accentId;
  final DribaThemeMode themeMode;
  final FontScale fontScale;
  final bool hapticsEnabled;
  final bool reducedMotion;
  final bool autoPlayMedia;
  final double blurIntensity; // 0.0 - 1.0

  const ThemeState({
    this.accentId = 'cyan',
    this.themeMode = DribaThemeMode.dark,
    this.fontScale = FontScale.normal,
    this.hapticsEnabled = true,
    this.reducedMotion = false,
    this.autoPlayMedia = true,
    this.blurIntensity = 1.0,
  });

  AccentPreset get accent =>
      accentPresets.firstWhere((p) => p.id == accentId,
          orElse: () => accentPresets.first);

  Color get accentColor => accent.color;
  Color get accentColorLight => accent.colorLight;

  /// Background colors adjust for AMOLED
  Color get background =>
      themeMode == DribaThemeMode.amoled ? Colors.black : DribaColors.background;

  Color get surface => themeMode == DribaThemeMode.amoled
      ? const Color(0xFF050505)
      : DribaColors.surface;

  ThemeState copyWith({
    String? accentId,
    DribaThemeMode? themeMode,
    FontScale? fontScale,
    bool? hapticsEnabled,
    bool? reducedMotion,
    bool? autoPlayMedia,
    double? blurIntensity,
  }) {
    return ThemeState(
      accentId: accentId ?? this.accentId,
      themeMode: themeMode ?? this.themeMode,
      fontScale: fontScale ?? this.fontScale,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      autoPlayMedia: autoPlayMedia ?? this.autoPlayMedia,
      blurIntensity: blurIntensity ?? this.blurIntensity,
    );
  }

  Map<String, dynamic> toMap() => {
        'accentId': accentId,
        'themeMode': themeMode.index,
        'fontScale': fontScale.index,
        'hapticsEnabled': hapticsEnabled,
        'reducedMotion': reducedMotion,
        'autoPlayMedia': autoPlayMedia,
        'blurIntensity': blurIntensity,
      };

  factory ThemeState.fromMap(Map<String, dynamic> map) {
    return ThemeState(
      accentId: map['accentId'] as String? ?? 'cyan',
      themeMode: DribaThemeMode.values[map['themeMode'] as int? ?? 0],
      fontScale: FontScale.values[map['fontScale'] as int? ?? 1],
      hapticsEnabled: map['hapticsEnabled'] as bool? ?? true,
      reducedMotion: map['reducedMotion'] as bool? ?? false,
      autoPlayMedia: map['autoPlayMedia'] as bool? ?? true,
      blurIntensity: (map['blurIntensity'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

/// Riverpod notifier for theme state
class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier() : super(const ThemeState()) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString('driba_theme');
      if (json != null) {
        state = ThemeState.fromMap(
            Map<String, dynamic>.from(jsonDecode(json) as Map));
      }
    } catch (_) {}
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('driba_theme', jsonEncode(state.toMap()));
    } catch (_) {}
  }

  void setAccent(String accentId) {
    state = state.copyWith(accentId: accentId);
    _saveToPrefs();
  }

  void setThemeMode(DribaThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _saveToPrefs();
  }

  void setFontScale(FontScale scale) {
    state = state.copyWith(fontScale: scale);
    _saveToPrefs();
  }

  void toggleHaptics() {
    state = state.copyWith(hapticsEnabled: !state.hapticsEnabled);
    _saveToPrefs();
  }

  void toggleReducedMotion() {
    state = state.copyWith(reducedMotion: !state.reducedMotion);
    _saveToPrefs();
  }

  void toggleAutoPlayMedia() {
    state = state.copyWith(autoPlayMedia: !state.autoPlayMedia);
    _saveToPrefs();
  }

  void setBlurIntensity(double value) {
    state = state.copyWith(blurIntensity: value.clamp(0.0, 1.0));
    _saveToPrefs();
  }

  void resetToDefaults() {
    state = const ThemeState();
    _saveToPrefs();
  }
}

/// Global theme provider
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>(
  (ref) => ThemeNotifier(),
);

/// Convenience providers
final accentColorProvider = Provider<Color>((ref) {
  return ref.watch(themeProvider).accentColor;
});

final accentColorLightProvider = Provider<Color>((ref) {
  return ref.watch(themeProvider).accentColorLight;
});

final fontScaleProvider = Provider<double>((ref) {
  return ref.watch(themeProvider).fontScale.value;
});

final hapticsEnabledProvider = Provider<bool>((ref) {
  return ref.watch(themeProvider).hapticsEnabled;
});

final reducedMotionProvider = Provider<bool>((ref) {
  return ref.watch(themeProvider).reducedMotion;
});
