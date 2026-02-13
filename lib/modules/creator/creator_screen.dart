import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/driba_colors.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/animations/driba_animations.dart';
import '../../core/providers/app_state.dart';

/// Creator Hub - Unified content creation screen
/// Casual mode: Quick post to feed
/// Pro mode: AI-powered campaigns across channels
class CreatorScreen extends ConsumerStatefulWidget {
  const CreatorScreen({super.key});

  @override
  ConsumerState<CreatorScreen> createState() => _CreatorScreenState();
}

class _CreatorScreenState extends ConsumerState<CreatorScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  late AnimationController _entranceController;
  
  bool _isProMode = false;
  bool _isLoading = false;
  List<String> _selectedCategories = ['feed'];
  List<String> _selectedChannels = [];
  String _aiStyle = 'professional';

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      duration: DribaDurations.slow,
      vsync: this,
    );
    _entranceController.forward();
  }

  @override
  void dispose() {
    _textController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  void _toggleCategory(String category) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      } else {
        _selectedCategories.add(category);
      }
    });
  }

  void _toggleChannel(String channel) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedChannels.contains(channel)) {
        _selectedChannels.remove(channel);
      } else {
        _selectedChannels.add(channel);
      }
    });
  }

  Future<void> _post() async {
    if (_textController.text.isEmpty) return;
    
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);
    
    // Simulate posting
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      Navigator.pop(context);
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
                center: Alignment.topCenter,
                radius: 1.5,
                colors: [
                  DribaColors.primary.withOpacity(0.1),
                  DribaColors.background,
                ],
              ),
            ),
          ),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(),
                
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(DribaSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Media picker
                        _buildMediaPicker(),
                        
                        const SizedBox(height: DribaSpacing.xl),
                        
                        // Text input
                        _buildTextInput(),
                        
                        const SizedBox(height: DribaSpacing.xl),
                        
                        // Category selection
                        _buildCategorySection(),
                        
                        const SizedBox(height: DribaSpacing.xl),
                        
                        // Pro mode toggle
                        _buildProModeToggle(),
                        
                        // Pro mode options
                        if (_isProMode) ...[
                          const SizedBox(height: DribaSpacing.xl),
                          _buildProModeOptions(),
                        ],
                        
                        const SizedBox(height: 100), // Space for button
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom action button
          Positioned(
            left: DribaSpacing.lg,
            right: DribaSpacing.lg,
            bottom: MediaQuery.of(context).padding.bottom + DribaSpacing.lg,
            child: _buildPostButton(),
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
          GlassCircleButton(
            size: 44,
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.close,
              color: DribaColors.textPrimary,
              size: 22,
            ),
          ),
          const SizedBox(width: DribaSpacing.md),
          const Expanded(
            child: Text(
              'CREATE',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                color: DribaColors.textSecondary,
              ),
            ),
          ),
          // AI assist button
          GlassCircleButton(
            size: 44,
            selectedColor: DribaColors.tertiary,
            onTap: () {
              HapticFeedback.lightImpact();
              // Open AI suggestions
            },
            child: const Icon(
              Icons.auto_awesome,
              color: DribaColors.tertiary,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPicker() {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        final progress = Curves.easeOut.transform(_entranceController.value);
        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - progress)),
            child: child,
          ),
        );
      },
      child: GlassContainer(
        height: 200,
        borderRadius: BorderRadius.circular(DribaBorderRadius.xl),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: DribaColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_photo_alternate_outlined,
                  color: DribaColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: DribaSpacing.md),
              const Text(
                'Add Photo or Video',
                style: TextStyle(
                  color: DribaColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: DribaSpacing.xs),
              Text(
                'Tap to browse or drag & drop',
                style: TextStyle(
                  color: DribaColors.textTertiary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextInput() {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        final delay = 0.1;
        final progress = (((_entranceController.value - delay) / (1 - delay)))
            .clamp(0.0, 1.0);
        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - progress)),
            child: child,
          ),
        );
      },
      child: GlassContainer(
        padding: const EdgeInsets.all(DribaSpacing.lg),
        borderRadius: BorderRadius.circular(DribaBorderRadius.xl),
        child: TextField(
          controller: _textController,
          style: const TextStyle(
            color: DribaColors.textPrimary,
            fontSize: 16,
          ),
          maxLines: 5,
          minLines: 3,
          decoration: InputDecoration(
            hintText: 'What\'s on your mind? Tell your story...',
            hintStyle: TextStyle(
              color: DribaColors.textTertiary,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    final categories = [
      ('feed', 'Feed', Icons.home_outlined),
      ('food', 'Food', Icons.restaurant_outlined),
      ('commerce', 'Commerce', Icons.shopping_bag_outlined),
      ('learn', 'Learn', Icons.school_outlined),
      ('travel', 'Travel', Icons.flight_outlined),
      ('health', 'Health', Icons.favorite_outline),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Categories',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: DribaColors.textSecondary,
          ),
        ),
        const SizedBox(height: DribaSpacing.md),
        Wrap(
          spacing: DribaSpacing.sm,
          runSpacing: DribaSpacing.sm,
          children: categories.map((cat) {
            final isSelected = _selectedCategories.contains(cat.$1);
            return GlassPill(
              label: cat.$2,
              icon: cat.$3,
              isSelected: isSelected,
              onTap: () => _toggleCategory(cat.$1),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildProModeToggle() {
    return GlassContainer(
      padding: const EdgeInsets.all(DribaSpacing.lg),
      borderRadius: BorderRadius.circular(DribaBorderRadius.xl),
      borderColor: _isProMode ? DribaColors.tertiary : null,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: _isProMode ? DribaColors.premiumGradient : null,
              color: _isProMode ? null : DribaColors.glassFillActive,
              borderRadius: BorderRadius.circular(DribaBorderRadius.md),
            ),
            child: Icon(
              Icons.auto_awesome,
              color: _isProMode ? Colors.white : DribaColors.textTertiary,
              size: 20,
            ),
          ),
          const SizedBox(width: DribaSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Driba Pro',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: DribaColors.textPrimary,
                  ),
                ),
                Text(
                  'AI-powered cross-platform campaigns',
                  style: TextStyle(
                    fontSize: 12,
                    color: DribaColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isProMode,
            onChanged: (value) {
              HapticFeedback.selectionClick();
              setState(() => _isProMode = value);
            },
            activeColor: DribaColors.tertiary,
          ),
        ],
      ),
    );
  }

  Widget _buildProModeOptions() {
    final channels = [
      ('linkedin', 'LinkedIn', Icons.work_outline),
      ('twitter', 'X / Twitter', Icons.alternate_email),
      ('instagram', 'Instagram', Icons.camera_alt_outlined),
      ('tiktok', 'TikTok', Icons.music_note_outlined),
    ];

    final styles = [
      ('professional', 'Professional'),
      ('casual', 'Casual'),
      ('educational', 'Educational'),
      ('promotional', 'Promotional'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Channels
        const Text(
          'Cross-post to',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: DribaColors.textSecondary,
          ),
        ),
        const SizedBox(height: DribaSpacing.md),
        Wrap(
          spacing: DribaSpacing.sm,
          runSpacing: DribaSpacing.sm,
          children: channels.map((ch) {
            final isSelected = _selectedChannels.contains(ch.$1);
            return GlassPill(
              label: ch.$2,
              icon: ch.$3,
              isSelected: isSelected,
              selectedColor: DribaColors.tertiary,
              onTap: () => _toggleChannel(ch.$1),
            );
          }).toList(),
        ),
        
        const SizedBox(height: DribaSpacing.xl),
        
        // AI Style
        const Text(
          'AI Writing Style',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: DribaColors.textSecondary,
          ),
        ),
        const SizedBox(height: DribaSpacing.md),
        Wrap(
          spacing: DribaSpacing.sm,
          runSpacing: DribaSpacing.sm,
          children: styles.map((s) {
            final isSelected = _aiStyle == s.$1;
            return GlassPill(
              label: s.$2,
              isSelected: isSelected,
              selectedColor: DribaColors.tertiary,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _aiStyle = s.$1);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPostButton() {
    return SlideToActionButton(
      label: _isProMode ? 'Slide to launch campaign' : 'Slide to post',
      completedLabel: _isProMode ? 'Campaign launched!' : 'Posted!',
      sliderColor: _isProMode ? DribaColors.tertiary : DribaColors.primary,
      onComplete: _post,
    );
  }
}
