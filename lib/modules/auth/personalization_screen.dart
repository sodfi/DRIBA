import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/driba_colors.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/animations/driba_animations.dart';
import '../../core/providers/app_state.dart';
import 'auth_providers.dart';

/// Personalization Screen — 3-step post-signup flow
/// Step 0: Choose your screens (worlds)
/// Step 1: Pick your interests
/// Step 2: Welcome + launch
class PersonalizationScreen extends ConsumerStatefulWidget {
  const PersonalizationScreen({super.key});

  @override
  ConsumerState<PersonalizationScreen> createState() =>
      _PersonalizationScreenState();
}

class _PersonalizationScreenState extends ConsumerState<PersonalizationScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _entranceController;

  static const Color _accent = DribaColors.primary;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _entranceController = AnimationController(
      vsync: this,
      duration: DribaDurations.slow,
    )..forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    HapticFeedback.mediumImpact();
    _pageController.animateToPage(
      step,
      duration: DribaDurations.normal,
      curve: DribaCurves.defaultCurve,
    );
  }

  Future<void> _finish() async {
    HapticFeedback.heavyImpact();
    final notifier = ref.read(personalizationProvider.notifier);
    await notifier.complete();

    if (mounted) {
      // Navigate to main app — AuthGate will handle this
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(personalizationProvider);
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: DribaColors.background,
      body: Column(
        children: [
          SizedBox(height: topPad + DribaSpacing.lg),

          // Progress bar
          _buildProgress(state.currentStep),

          // Pages
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) {
                ref.read(personalizationProvider.notifier);
                // Sync step externally if needed
              },
              children: [
                _ScreenPicker(
                  selectedScreens: state.selectedScreens,
                  onToggle: ref.read(personalizationProvider.notifier).toggleScreen,
                  entranceController: _entranceController,
                ),
                _InterestPicker(
                  selectedInterests: state.selectedInterests,
                  onToggle: ref.read(personalizationProvider.notifier).toggleInterest,
                ),
                _WelcomeStep(isLoading: state.isLoading),
              ],
            ),
          ),

          // Bottom bar
          _buildBottomBar(state, bottomPad),
        ],
      ),
    );
  }

  // ── Progress ────────────────────────────────
  Widget _buildProgress(int step) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DribaSpacing.xxl,
        vertical: DribaSpacing.md,
      ),
      child: Row(
        children: List.generate(3, (i) {
          final isActive = i <= step;
          return Expanded(
            child: Container(
              height: 3,
              margin: EdgeInsets.only(right: i < 2 ? DribaSpacing.sm : 0),
              decoration: BoxDecoration(
                color: isActive ? _accent : DribaColors.glassFillActive,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Bottom Bar ──────────────────────────────
  Widget _buildBottomBar(PersonalizationState state, double bottomPad) {
    final step = state.currentStep;
    final canProceed = step == 0
        ? state.selectedScreens.length >= 2
        : step == 1
            ? state.selectedInterests.length >= 3
            : true;

    return Container(
      padding: EdgeInsets.fromLTRB(
        DribaSpacing.xl, DribaSpacing.lg, DribaSpacing.xl, bottomPad + DribaSpacing.lg,
      ),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: DribaColors.glassBorder)),
      ),
      child: Row(
        children: [
          // Back
          if (step > 0)
            GlassCircleButton(
              size: 48,
              onTap: () {
                ref.read(personalizationProvider.notifier).prevStep();
                _goToStep(step - 1);
              },
              child: const Icon(Icons.arrow_back_ios_new,
                  color: DribaColors.textSecondary, size: 18),
            ),
          if (step > 0) const SizedBox(width: DribaSpacing.md),

          // Info
          Expanded(
            child: Text(
              step == 0
                  ? '${state.selectedScreens.length} screens selected (min 2)'
                  : step == 1
                      ? '${state.selectedInterests.length} interests (min 3)'
                      : 'You\'re all set!',
              style: TextStyle(
                color: DribaColors.textTertiary,
                fontSize: 13,
              ),
            ),
          ),

          // Next / Finish
          GestureDetector(
            onTap: canProceed
                ? () {
                    if (step < 2) {
                      ref.read(personalizationProvider.notifier).nextStep();
                      _goToStep(step + 1);
                    } else {
                      _finish();
                    }
                  }
                : null,
            child: AnimatedContainer(
              duration: DribaDurations.fast,
              padding: const EdgeInsets.symmetric(
                horizontal: DribaSpacing.xxl,
                vertical: DribaSpacing.md,
              ),
              decoration: BoxDecoration(
                gradient: canProceed ? DribaColors.primaryGradient : null,
                color: canProceed ? null : DribaColors.glassFillActive,
                borderRadius: BorderRadius.circular(DribaBorderRadius.pill),
                boxShadow: canProceed ? DribaShadows.primaryGlow : null,
              ),
              child: state.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      step < 2 ? 'Next' : 'Let\'s Go!',
                      style: TextStyle(
                        color: canProceed
                            ? Colors.white
                            : DribaColors.textDisabled,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// STEP 0: SCREEN PICKER
// ============================================

class _ScreenPicker extends StatelessWidget {
  final List<String> selectedScreens;
  final void Function(String) onToggle;
  final AnimationController entranceController;

  const _ScreenPicker({
    required this.selectedScreens,
    required this.onToggle,
    required this.entranceController,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DribaSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: DribaSpacing.xxl),
          const Text(
            'Choose Your\nWorlds',
            style: TextStyle(
              color: DribaColors.textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: DribaSpacing.sm),
          Text(
            'Each screen is a world of content. Pick at least 2.',
            style: TextStyle(
              color: DribaColors.textTertiary,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: DribaSpacing.xxl),
          Expanded(
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.9,
                crossAxisSpacing: DribaSpacing.md,
                mainAxisSpacing: DribaSpacing.md,
              ),
              itemCount: allScreens.length,
              itemBuilder: (context, index) {
                final screen = allScreens[index];
                final isSelected = selectedScreens.contains(screen.id);
                final accentColor = Color(screen.color);

                return AnimatedBuilder(
                  animation: entranceController,
                  builder: (_, child) {
                    final delay = (index * 0.04).clamp(0.0, 0.5);
                    final progress =
                        ((entranceController.value - delay) / (1 - delay))
                            .clamp(0.0, 1.0);
                    return Opacity(
                      opacity: Curves.easeOut.transform(progress),
                      child: Transform.scale(
                        scale: 0.8 + 0.2 * Curves.easeOut.transform(progress),
                        child: child,
                      ),
                    );
                  },
                  child: _ScreenTile(
                    name: screen.name,
                    icon: _iconForScreen(screen.icon),
                    color: accentColor,
                    isSelected: isSelected,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onToggle(screen.id);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForScreen(String iconName) {
    final map = {
      'home': Icons.home_outlined,
      'restaurant': Icons.restaurant_outlined,
      'shopping_bag': Icons.shopping_bag_outlined,
      'flight': Icons.flight_outlined,
      'favorite': Icons.favorite_outline,
      'newspaper': Icons.newspaper_outlined,
      'school': Icons.school_outlined,
      'movie': Icons.movie_outlined,
      'place': Icons.place_outlined,
      'music_note': Icons.music_note_outlined,
      'sports_esports': Icons.sports_esports_outlined,
      'sports_soccer': Icons.sports_soccer_outlined,
      'account_balance': Icons.account_balance_outlined,
      'directions_car': Icons.directions_car_outlined,
      'pets': Icons.pets_outlined,
      'home_work': Icons.home_work_outlined,
      'checkroom': Icons.checkroom_outlined,
      'face': Icons.face_outlined,
      'weekend': Icons.weekend_outlined,
      'event': Icons.event_outlined,
      'child_care': Icons.child_care_outlined,
    };
    return map[iconName] ?? Icons.grid_view_outlined;
  }
}

class _ScreenTile extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ScreenTile({
    required this.name,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: DribaDurations.fast,
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.15)
              : DribaColors.glassFill,
          borderRadius: BorderRadius.circular(DribaBorderRadius.xl),
          border: Border.all(
            color: isSelected ? color : DribaColors.glassBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 12,
                    spreadRadius: -4,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: DribaDurations.fast,
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withOpacity(0.2)
                    : DribaColors.glassFillActive,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? color : DribaColors.textTertiary,
                size: 22,
              ),
            ),
            const SizedBox(height: DribaSpacing.sm),
            Text(
              name,
              style: TextStyle(
                color: isSelected ? color : DribaColors.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (isSelected) ...[
              const SizedBox(height: 2),
              Icon(Icons.check_circle, color: color, size: 16),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================
// STEP 1: INTEREST PICKER
// ============================================

class _InterestPicker extends StatelessWidget {
  final List<String> selectedInterests;
  final void Function(String) onToggle;

  const _InterestPicker({
    required this.selectedInterests,
    required this.onToggle,
  });

  static const _interests = [
    ('Technology', Icons.computer, DribaColors.primary),
    ('Design', Icons.palette, DribaColors.secondary),
    ('Business', Icons.business, Color(0xFFFFD700)),
    ('Travel', Icons.flight, Color(0xFF00B4D8)),
    ('Food & Cooking', Icons.restaurant, Color(0xFFFF6B35)),
    ('Fitness', Icons.fitness_center, DribaColors.success),
    ('Photography', Icons.camera_alt, DribaColors.tertiary),
    ('Music', Icons.music_note, Color(0xFF1DB954)),
    ('Fashion', Icons.checkroom, DribaColors.secondary),
    ('Art', Icons.brush, Color(0xFFFFAA00)),
    ('Reading', Icons.menu_book, DribaColors.tertiary),
    ('Gaming', Icons.sports_esports, Color(0xFF9146FF)),
    ('Science', Icons.science, DribaColors.primary),
    ('Film', Icons.movie, Color(0xFFFF2E93)),
    ('Sustainability', Icons.eco, DribaColors.success),
    ('Startups', Icons.rocket_launch, Color(0xFFFF6B35)),
    ('Marketing', Icons.campaign, Color(0xFFFFD700)),
    ('Wellness', Icons.spa, Color(0xFF00D68F)),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DribaSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: DribaSpacing.xxl),
          const Text(
            'What Are You\nInto?',
            style: TextStyle(
              color: DribaColors.textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: DribaSpacing.sm),
          Text(
            'Pick at least 3. This helps us personalize your feed.',
            style: TextStyle(
              color: DribaColors.textTertiary,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: DribaSpacing.xxl),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Wrap(
                spacing: DribaSpacing.sm,
                runSpacing: DribaSpacing.sm,
                children: _interests.map((interest) {
                  final name = interest.$1;
                  final icon = interest.$2;
                  final color = interest.$3;
                  final isSelected = selectedInterests.contains(name);

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onToggle(name);
                    },
                    child: AnimatedContainer(
                      duration: DribaDurations.fast,
                      padding: const EdgeInsets.symmetric(
                        horizontal: DribaSpacing.lg,
                        vertical: DribaSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withOpacity(0.15)
                            : DribaColors.glassFill,
                        borderRadius:
                            BorderRadius.circular(DribaBorderRadius.pill),
                        border: Border.all(
                          color: isSelected ? color : DribaColors.glassBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icon,
                            size: 18,
                            color: isSelected
                                ? color
                                : DribaColors.textTertiary,
                          ),
                          const SizedBox(width: DribaSpacing.sm),
                          Text(
                            name,
                            style: TextStyle(
                              color: isSelected
                                  ? color
                                  : DribaColors.textSecondary,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: DribaSpacing.xs),
                            Icon(Icons.check, color: color, size: 16),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// STEP 2: WELCOME
// ============================================

class _WelcomeStep extends StatelessWidget {
  final bool isLoading;

  const _WelcomeStep({required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DribaSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated logo
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: DribaColors.primaryGradient,
              borderRadius: BorderRadius.circular(DribaBorderRadius.xxl),
              boxShadow: [
                BoxShadow(
                  color: DribaColors.primary.withOpacity(0.4),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'D',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),

          const SizedBox(height: DribaSpacing.xxxl),

          const Text(
            'You\'re Ready',
            style: TextStyle(
              color: DribaColors.textPrimary,
              fontSize: 36,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: DribaSpacing.md),

          Text(
            'Your Driba world is set up.\nOne app. Every screen. Zero fees.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: DribaColors.textTertiary,
              fontSize: 16,
              height: 1.5,
            ),
          ),

          const SizedBox(height: DribaSpacing.xxxl),

          // Feature highlights
          _FeatureRow(
            icon: Icons.auto_awesome,
            text: 'AI powers everything behind the scenes',
            color: DribaColors.primary,
          ),
          const SizedBox(height: DribaSpacing.lg),
          _FeatureRow(
            icon: Icons.money_off,
            text: '0% transaction fees — you keep 100%',
            color: DribaColors.success,
          ),
          const SizedBox(height: DribaSpacing.lg),
          _FeatureRow(
            icon: Icons.grid_view_rounded,
            text: 'Add or remove screens anytime',
            color: DribaColors.tertiary,
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _FeatureRow({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: DribaSpacing.md),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: DribaColors.textSecondary,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}
