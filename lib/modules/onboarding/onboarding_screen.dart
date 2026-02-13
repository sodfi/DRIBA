import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/driba_colors.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/animations/driba_animations.dart';
import '../../core/providers/app_state.dart';
import '../../main_shell.dart';

/// Onboarding Screen
/// Users select their screens (worlds) during first launch
/// Creates their Digital Twin profile in Firestore
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<String> _selectedScreens = [];
  bool _isLoading = false;
  int _currentPage = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _toggleScreen(String screenId) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedScreens.contains(screenId)) {
        _selectedScreens.remove(screenId);
      } else {
        _selectedScreens.add(screenId);
      }
    });
  }

  Future<void> _completeOnboarding() async {
    if (_selectedScreens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one screen'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    HapticFeedback.heavyImpact();
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Create user profile with Digital Twin
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'enabledScreens': _selectedScreens,
          'onboardingComplete': true,
          'digitalTwinStatus': 'initializing',
          'createdAt': FieldValue.serverTimestamp(),
          'profile': {
            'displayName': 'Driba User',
            'bio': '',
            'avatar': '',
          },
          'settings': {
            'notifications': true,
            'darkMode': true,
            'language': 'en',
          },
        }, SetOptions(merge: true));
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const MainShell(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DribaColors.background,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topRight,
                radius: 2,
                colors: [
                  DribaColors.primary.withOpacity(0.15),
                  DribaColors.background,
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(),
                
                // Page indicator
                _buildPageIndicator(),
                
                // Content
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    children: [
                      _buildWelcomePage(),
                      _buildScreenSelectionPage(),
                    ],
                  ),
                ),
                
                // Bottom button
                _buildBottomButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(DribaSpacing.lg),
      child: Row(
        children: [
          // Logo
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: DribaColors.premiumGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'D',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: DribaSpacing.md),
          const Text(
            'DRIBA',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DribaSpacing.lg),
      child: Row(
        children: List.generate(2, (index) {
          final isActive = index == _currentPage;
          return AnimatedContainer(
            duration: DribaDurations.fast,
            width: isActive ? 32 : 8,
            height: 8,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: isActive
                  ? DribaColors.primary
                  : DribaColors.glassFillActive,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(DribaSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: DribaSpacing.xxl),
          
          // Main title
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _controller.value,
                child: Transform.translate(
                  offset: Offset(0, 30 * (1 - _controller.value)),
                  child: child,
                ),
              );
            },
            child: const Text(
              'Design Your\nDigital Life',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                height: 1.1,
              ),
            ),
          ),
          
          const SizedBox(height: DribaSpacing.xl),
          
          // Description
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final delay = 0.2;
              final progress = ((_controller.value - delay) / (1 - delay))
                  .clamp(0.0, 1.0);
              return Opacity(
                opacity: progress,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - progress)),
                  child: child,
                ),
              );
            },
            child: Text(
              'One app to replace them all. Choose your screens, '
              'build your world, and take control of your digital experience.',
              style: TextStyle(
                fontSize: 16,
                color: DribaColors.textSecondary,
                height: 1.6,
              ),
            ),
          ),
          
          const Spacer(),
          
          // Feature highlights
          _buildFeatureList(),
        ],
      ),
    );
  }

  Widget _buildFeatureList() {
    final features = [
      ('No middlemen', 'Keep 100% of what you earn'),
      ('Your screens', 'Choose what matters to you'),
      ('AI everywhere', 'Invisible help, always there'),
    ];

    return Column(
      children: features.asMap().entries.map((entry) {
        final index = entry.key;
        final feature = entry.value;
        
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = 0.3 + (index * 0.1);
            final progress = ((_controller.value - delay) / (1 - delay))
                .clamp(0.0, 1.0);
            return Opacity(
              opacity: progress,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - progress)),
                child: child,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: DribaSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: DribaColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: DribaColors.primary,
                  ),
                ),
                const SizedBox(width: DribaSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature.$1,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        feature.$2,
                        style: TextStyle(
                          fontSize: 13,
                          color: DribaColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildScreenSelectionPage() {
    // Filter out 'feed' as it's always included
    final availableScreens = allScreens.where((s) => s.id != 'feed').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(DribaSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose Your\nScreens',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: DribaSpacing.md),
              Text(
                'Select the worlds you want to explore. '
                'You can always add or remove screens later.',
                style: TextStyle(
                  color: DribaColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: DribaSpacing.lg),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: DribaSpacing.md,
              crossAxisSpacing: DribaSpacing.md,
              childAspectRatio: 0.85,
            ),
            itemCount: availableScreens.length,
            itemBuilder: (context, index) {
              final screen = availableScreens[index];
              final isSelected = _selectedScreens.contains(screen.id);
              final color = Color(screen.color);
              
              return _ScreenCard(
                screen: screen,
                isSelected: isSelected,
                color: color,
                onTap: () => _toggleScreen(screen.id),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        DribaSpacing.lg,
        DribaSpacing.md,
        DribaSpacing.lg,
        DribaSpacing.lg + MediaQuery.of(context).padding.bottom,
      ),
      child: _currentPage == 0
          ? SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  _pageController.nextPage(
                    duration: DribaDurations.normal,
                    curve: DribaCurves.defaultCurve,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: DribaColors.primary,
                  foregroundColor: DribaColors.textInverse,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DribaBorderRadius.pill),
                  ),
                ),
                child: const Text(
                  'Get Started',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            )
          : SlideToActionButton(
              label: 'Slide to enter Driba',
              completedLabel: 'Welcome!',
              onComplete: _completeOnboarding,
            ),
    );
  }
}

class _ScreenCard extends StatefulWidget {
  final ScreenConfig screen;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _ScreenCard({
    required this.screen,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ScreenCard> createState() => _ScreenCardState();
}

class _ScreenCardState extends State<_ScreenCard> {
  bool _isPressed = false;

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'restaurant': return Icons.restaurant_outlined;
      case 'shopping_bag': return Icons.shopping_bag_outlined;
      case 'flight': return Icons.flight_outlined;
      case 'favorite': return Icons.favorite_outline;
      case 'newspaper': return Icons.newspaper_outlined;
      case 'school': return Icons.school_outlined;
      case 'movie': return Icons.movie_outlined;
      case 'place': return Icons.place_outlined;
      case 'music_note': return Icons.music_note_outlined;
      case 'sports_esports': return Icons.sports_esports_outlined;
      case 'sports_soccer': return Icons.sports_soccer_outlined;
      default: return Icons.grid_view_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: DribaDurations.fast,
        transform: Matrix4.identity()..scale(_isPressed ? 0.95 : 1.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(DribaBorderRadius.lg),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AnimatedContainer(
              duration: DribaDurations.fast,
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? widget.color.withOpacity(0.2)
                    : DribaColors.glassFill,
                borderRadius: BorderRadius.circular(DribaBorderRadius.lg),
                border: Border.all(
                  color: widget.isSelected
                      ? widget.color
                      : DribaColors.glassBorder,
                  width: widget.isSelected ? 2 : 1,
                ),
                boxShadow: widget.isSelected
                    ? [
                        BoxShadow(
                          color: widget.color.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: -5,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: DribaDurations.fast,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(
                        widget.isSelected ? 0.3 : 0.1,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getIconData(widget.screen.icon),
                      color: widget.isSelected
                          ? widget.color
                          : DribaColors.textSecondary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: DribaSpacing.sm),
                  Text(
                    widget.screen.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: widget.isSelected
                          ? widget.color
                          : DribaColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (widget.isSelected)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Icon(
                        Icons.check_circle,
                        color: widget.color,
                        size: 16,
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
