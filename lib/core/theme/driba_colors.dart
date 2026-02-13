import 'package:flutter/material.dart';

/// Driba OS Color Palette
/// Glass OS Design System - Premium, Dark, Immersive
class DribaColors {
  DribaColors._();

  // ============================================
  // BACKGROUND COLORS
  // ============================================
  
  /// Deep space background - the canvas
  static const Color background = Color(0xFF050B14);
  
  /// Slightly lighter for layering
  static const Color backgroundLight = Color(0xFF0A1628);
  
  /// Surface color for cards
  static const Color surface = Color(0xFF0F1C2E);
  
  /// Elevated surface
  static const Color surfaceElevated = Color(0xFF152238);

  // ============================================
  // GLASS COLORS
  // ============================================
  
  /// Glass fill - very subtle white
  static const Color glassFill = Color(0x0DFFFFFF); // 5% white
  
  /// Glass fill hover state
  static const Color glassFillHover = Color(0x1AFFFFFF); // 10% white
  
  /// Glass fill active state
  static const Color glassFillActive = Color(0x26FFFFFF); // 15% white
  
  /// Glass border
  static const Color glassBorder = Color(0x1AFFFFFF); // 10% white
  
  /// Glass border highlight
  static const Color glassBorderHighlight = Color(0x33FFFFFF); // 20% white

  // ============================================
  // PRIMARY ACCENT - Cyan/Teal (Futuristic)
  // ============================================
  
  /// Primary brand color
  static const Color primary = Color(0xFF00E1FF);
  
  /// Primary with opacity variations
  static const Color primary80 = Color(0xCC00E1FF);
  static const Color primary60 = Color(0x9900E1FF);
  static const Color primary40 = Color(0x6600E1FF);
  static const Color primary20 = Color(0x3300E1FF);
  static const Color primary10 = Color(0x1A00E1FF);
  
  /// Primary glow for shadows
  static const Color primaryGlow = Color(0x4D00E1FF);

  // ============================================
  // SECONDARY ACCENT - Magenta/Pink
  // ============================================
  
  /// Secondary accent for highlights
  static const Color secondary = Color(0xFFFF2E93);
  
  /// Secondary variations
  static const Color secondary80 = Color(0xCCFF2E93);
  static const Color secondary60 = Color(0x99FF2E93);
  static const Color secondary40 = Color(0x66FF2E93);
  static const Color secondary20 = Color(0x33FF2E93);
  
  /// Secondary glow
  static const Color secondaryGlow = Color(0x4DFF2E93);

  // ============================================
  // TERTIARY ACCENT - Purple (Premium)
  // ============================================
  
  /// Tertiary for special elements
  static const Color tertiary = Color(0xFF8B5CF6);
  
  /// Tertiary variations
  static const Color tertiary60 = Color(0x998B5CF6);
  static const Color tertiary20 = Color(0x338B5CF6);

  // ============================================
  // SEMANTIC COLORS
  // ============================================
  
  /// Success green
  static const Color success = Color(0xFF00D68F);
  static const Color successGlow = Color(0x4D00D68F);
  
  /// Warning amber
  static const Color warning = Color(0xFFFFAA00);
  static const Color warningGlow = Color(0x4DFFAA00);
  
  /// Error red
  static const Color error = Color(0xFFFF3D71);
  static const Color errorGlow = Color(0x4DFF3D71);
  
  /// Info blue
  static const Color info = Color(0xFF0095FF);
  static const Color infoGlow = Color(0x4D0095FF);

  // ============================================
  // TEXT COLORS
  // ============================================
  
  /// Primary text - bright white
  static const Color textPrimary = Color(0xFFFFFFFF);
  
  /// Secondary text - muted
  static const Color textSecondary = Color(0xB3FFFFFF); // 70% white
  
  /// Tertiary text - subtle
  static const Color textTertiary = Color(0x80FFFFFF); // 50% white
  
  /// Disabled text
  static const Color textDisabled = Color(0x4DFFFFFF); // 30% white
  
  /// Inverse text for light backgrounds
  static const Color textInverse = Color(0xFF050B14);

  // ============================================
  // GRADIENT DEFINITIONS
  // ============================================
  
  /// Primary gradient (horizontal)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF00B4D8)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  
  /// Secondary gradient
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, Color(0xFFFF6B9D)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  
  /// Premium gradient (purple to pink)
  static const LinearGradient premiumGradient = LinearGradient(
    colors: [tertiary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// Content fade gradient (for text over media)
  static const LinearGradient contentFadeGradient = LinearGradient(
    colors: [Colors.transparent, Color(0xE6050B14)],
    stops: [0.0, 1.0],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  /// Glass gradient (subtle)
  static const LinearGradient glassGradient = LinearGradient(
    colors: [Color(0x1AFFFFFF), Color(0x0DFFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ============================================
  // SCREEN-SPECIFIC ACCENT COLORS
  // ============================================
  
  static const Map<String, Color> screenAccents = {
    'feed': primary,
    'chat': Color(0xFF00D68F),      // Green for messages
    'food': Color(0xFFFF6B35),       // Orange for food
    'commerce': Color(0xFFFFD700),   // Gold for commerce
    'travel': Color(0xFF00B4D8),     // Ocean blue for travel
    'health': Color(0xFF00D68F),     // Green for health
    'news': Color(0xFFFF3D71),       // Red for news/alerts
    'learn': Color(0xFF8B5CF6),      // Purple for learning
    'movies': Color(0xFFFF2E93),     // Pink for entertainment
    'local': Color(0xFFFFAA00),      // Amber for local
    'utility': primary,
  };
  
  /// Get accent color for a screen
  static Color getScreenAccent(String screenId) {
    return screenAccents[screenId.toLowerCase()] ?? primary;
  }
}

/// Glass blur intensities
class DribaBlur {
  DribaBlur._();
  
  static const double light = 10.0;
  static const double medium = 20.0;
  static const double heavy = 40.0;
  static const double intense = 60.0;
}

/// Standard border radius values
class DribaBorderRadius {
  DribaBorderRadius._();
  
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double pill = 100.0;
  static const double circle = 999.0;
}

/// Standard spacing values
class DribaSpacing {
  DribaSpacing._();
  
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double huge = 48.0;
}

/// Animation durations
class DribaDurations {
  DribaDurations._();
  
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration slower = Duration(milliseconds: 500);
  static const Duration deliberate = Duration(milliseconds: 600);
  static const Duration dramatic = Duration(milliseconds: 800);
  static const Duration pageTransition = Duration(milliseconds: 350);
}

/// Animation curves
class DribaCurves {
  DribaCurves._();
  
  /// Default ease for most animations
  static const Curve defaultCurve = Curves.easeOutCubic;
  
  /// For elements entering the screen
  static const Curve enter = Curves.easeOutBack;
  
  /// For elements exiting the screen
  static const Curve exit = Curves.easeInCubic;
  
  /// For bouncy, playful animations
  static const Curve bounce = Curves.elasticOut;
  
  /// For smooth scrolling
  static const Curve scroll = Curves.easeOutQuart;
  
  /// For attention-grabbing pulses
  static const Curve pulse = Curves.easeInOutSine;
  
  /// For slide-to-action reveals
  static const Curve reveal = Curves.easeOutExpo;
}

/// Shadow definitions
class DribaShadows {
  DribaShadows._();
  
  /// Subtle shadow for glass elements
  static List<BoxShadow> glass = [
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
  
  /// Glow shadow with primary color
  static List<BoxShadow> primaryGlow = [
    BoxShadow(
      color: DribaColors.primaryGlow,
      blurRadius: 20,
      spreadRadius: -5,
    ),
  ];
  
  /// Glow shadow with secondary color
  static List<BoxShadow> secondaryGlow = [
    BoxShadow(
      color: DribaColors.secondaryGlow,
      blurRadius: 20,
      spreadRadius: -5,
    ),
  ];
  
  /// Elevated card shadow
  static List<BoxShadow> elevated = [
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      blurRadius: 30,
      offset: const Offset(0, 15),
    ),
  ];
  
  /// Inner glow for active states
  static List<BoxShadow> innerGlow(Color color) => [
    BoxShadow(
      color: color.withOpacity(0.3),
      blurRadius: 15,
      spreadRadius: -8,
    ),
  ];
}
