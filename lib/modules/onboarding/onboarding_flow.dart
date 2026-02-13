import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/driba_colors.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/animations/driba_animations.dart';
import '../../core/providers/app_state.dart';
import '../../main.dart'; // for prefs

// ============================================
// ONBOARDING FLOW — Frictionless
//
// No auth required. Saves preferences locally.
// Step 0: Welcome
// Step 1: Pick your screens (worlds)
// Step 2: Pick interests
// After → anonymous auth → straight to feed
// ============================================

class OnboardingFlow extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const OnboardingFlow({super.key, required this.onComplete});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _entranceController;

  int _currentStep = 0;
  final List<String> _selectedScreens = [];
  final List<String> _selectedInterests = [];
  bool _isLoading = false;

  static const _interests = [
    ('Technology', Icons.computer, 0xFF8B5CF6),
    ('Food & Cooking', Icons.restaurant, 0xFFFF6B35),
    ('Travel', Icons.flight, 0xFF00B4D8),
    ('Health & Fitness', Icons.favorite, 0xFF00D68F),
    ('Fashion & Style', Icons.checkroom, 0xFFFFD700),
    ('Science', Icons.science, 0xFF00E1FF),
    ('Business', Icons.business_center, 0xFF10B981),
    ('Art & Design', Icons.palette, 0xFFFFAA00),
    ('Music', Icons.music_note, 0xFF1DB954),
    ('Gaming', Icons.sports_esports, 0xFF9146FF),
    ('Sports', Icons.sports_soccer, 0xFFFF3D71),
    ('Photography', Icons.camera_alt, 0xFFFF6B35),
    ('Movies & TV', Icons.movie, 0xFFE50914),
    ('Books', Icons.menu_book, 0xFF8B5CF6),
    ('Environment', Icons.eco, 0xFF2DD4BF),
  ];

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
    setState(() => _currentStep = step);
  }

  Future<void> _finish() async {
    HapticFeedback.heavyImpact();
    setState(() => _isLoading = true);

    // Save to SharedPreferences (local, no auth needed)
    await prefs.setBool('onboarding_complete', true);
    await prefs.setStringList('selected_screens', _selectedScreens);
    await prefs.setStringList('selected_interests', _selectedInterests);

    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: DribaColors.background,
      body: Column(
        children: [
          SizedBox(height: topPad + DribaSpacing.lg),
          _buildProgress(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildWelcome(),
                _buildScreenPicker(),
                _buildInterestPicker(),
              ],
            ),
          ),
          _buildBottomBar(bottomPad),
        ],
      ),
    );
  }

  // ── Progress Bar ──────────────────────────
  Widget _buildProgress() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DribaSpacing.xxl,
        vertical: DribaSpacing.md,
      ),
      child: Row(
        children: List.generate(3, (i) {
          final isActive = i <= _currentStep;
          return Expanded(
            child: Container(
              height: 3,
              margin: EdgeInsets.only(right: i < 2 ? DribaSpacing.sm : 0),
              decoration: BoxDecoration(
                color: isActive ? DribaColors.primary : DribaColors.glassFillActive,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Step 0: Welcome ───────────────────────
  Widget _buildWelcome() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DribaSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
          const SizedBox(height: DribaSpacing.xxl),
          const Text(
            'Welcome to\nDriba',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: DribaColors.textPrimary,
              fontSize: 36,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: DribaSpacing.lg),
          Text(
            'Your super-app for everything.\nLet\'s personalize your experience.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: DribaColors.textTertiary,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 1: Screen Picker ─────────────────
  Widget _buildScreenPicker() {
    // Only show optional screens for selection; standard screens are always enabled
    final optionalScreens = allScreens.where((s) => !s.isStandard).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DribaSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: DribaSpacing.xxl),
          const Text(
            'Add Extra\nWorlds',
            style: TextStyle(
              color: DribaColors.textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: DribaSpacing.sm),
          Text(
            'You already have 8 core screens. Add more if you want.',
            style: TextStyle(color: DribaColors.textTertiary, fontSize: 15),
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
              itemCount: optionalScreens.length,
              itemBuilder: (context, index) {
                final screen = optionalScreens[index];
                final isSelected = _selectedScreens.contains(screen.id);
                final color = Color(screen.color);

                return _ScreenTile(
                  name: screen.name,
                  icon: _iconForScreen(screen.icon),
                  color: color,
                  isSelected: isSelected,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      if (isSelected) {
                        _selectedScreens.remove(screen.id);
                      } else {
                        _selectedScreens.add(screen.id);
                      }
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 2: Interest Picker ───────────────
  Widget _buildInterestPicker() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DribaSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: DribaSpacing.xxl),
          const Text(
            'What Interests\nYou?',
            style: TextStyle(
              color: DribaColors.textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: DribaSpacing.sm),
          Text(
            'Pick at least 3. This helps us curate your feed.',
            style: TextStyle(color: DribaColors.textTertiary, fontSize: 15),
          ),
          const SizedBox(height: DribaSpacing.xxl),
          Expanded(
            child: Wrap(
              spacing: DribaSpacing.sm,
              runSpacing: DribaSpacing.sm,
              children: _interests.map((interest) {
                final isSelected = _selectedInterests.contains(interest.$1);
                final color = Color(interest.$3);

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      if (isSelected) {
                        _selectedInterests.remove(interest.$1);
                      } else {
                        _selectedInterests.add(interest.$1);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: DribaDurations.fast,
                    padding: const EdgeInsets.symmetric(
                      horizontal: DribaSpacing.lg,
                      vertical: DribaSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? color.withOpacity(0.15) : DribaColors.glassFill,
                      borderRadius: BorderRadius.circular(DribaBorderRadius.pill),
                      border: Border.all(
                        color: isSelected ? color : DribaColors.glassBorder,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(interest.$2, size: 18,
                          color: isSelected ? color : DribaColors.textSecondary),
                        const SizedBox(width: DribaSpacing.sm),
                        Text(
                          interest.$1,
                          style: TextStyle(
                            color: isSelected ? color : DribaColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Bar ────────────────────────────
  Widget _buildBottomBar(double bottomPad) {
    final canProceed = _currentStep == 0
        ? true // Welcome — always can proceed
        : _currentStep == 1
            ? true // Optional screens — can skip
            : _selectedInterests.length >= 3; // Interests — min 3

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
          if (_currentStep > 0)
            GestureDetector(
              onTap: () => _goToStep(_currentStep - 1),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: DribaColors.glassFill,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: DribaColors.glassBorder),
                ),
                child: const Icon(Icons.arrow_back_ios_new,
                    color: DribaColors.textSecondary, size: 18),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: DribaSpacing.md),

          // Info
          Expanded(
            child: Text(
              _currentStep == 0
                  ? ''
                  : _currentStep == 1
                      ? '${_selectedScreens.length} extra screens selected'
                      : '${_selectedInterests.length} interests (min 3)',
              style: TextStyle(color: DribaColors.textTertiary, fontSize: 13),
            ),
          ),

          // Next / Skip / Finish
          GestureDetector(
            onTap: canProceed
                ? () {
                    if (_currentStep < 2) {
                      _goToStep(_currentStep + 1);
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
              child: _isLoading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      _currentStep == 0
                          ? 'Get Started'
                          : _currentStep == 1
                              ? (_selectedScreens.isEmpty ? 'Skip' : 'Next')
                              : 'Let\'s Go!',
                      style: TextStyle(
                        color: canProceed ? Colors.white : DribaColors.textDisabled,
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

  IconData _iconForScreen(String iconName) {
    const map = {
      'school': Icons.school_outlined,
      'brush': Icons.brush_outlined,
      'music_note': Icons.music_note_outlined,
      'sports_esports': Icons.sports_esports_outlined,
      'fitness_center': Icons.fitness_center_outlined,
      'account_balance': Icons.account_balance_outlined,
      'favorite': Icons.favorite_outline,
    };
    return map[iconName] ?? Icons.grid_view_outlined;
  }
}

// ── Screen Tile ──────────────────────────────
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
          color: isSelected ? color.withOpacity(0.15) : DribaColors.glassFill,
          borderRadius: BorderRadius.circular(DribaBorderRadius.xl),
          border: Border.all(
            color: isSelected ? color : DribaColors.glassBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 12, spreadRadius: -4)]
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
                color: isSelected ? color.withOpacity(0.2) : DribaColors.glassFillActive,
                borderRadius: BorderRadius.circular(DribaBorderRadius.lg),
              ),
              child: Icon(icon, color: isSelected ? color : DribaColors.textSecondary, size: 24),
            ),
            const SizedBox(height: DribaSpacing.sm),
            Text(
              name,
              style: TextStyle(
                color: isSelected ? color : DribaColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
