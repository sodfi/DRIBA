import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/driba_colors.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/animations/driba_animations.dart';
import '../../core/providers/theme_provider.dart';

// ============================================
// SCREENS CUSTOMIZER
// Enable/disable + reorder Driba OS worlds
// Drag & drop interface with live preview
// ============================================

class _ScreenItem {
  final String id;
  final String name;
  final String emoji;
  final int color;
  final IconData icon;
  bool enabled;

  _ScreenItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
    required this.icon,
    this.enabled = true,
  });
}

class ScreensCustomizer extends ConsumerStatefulWidget {
  const ScreensCustomizer({super.key});

  @override
  ConsumerState<ScreensCustomizer> createState() => _ScreensCustomizerState();
}

class _ScreensCustomizerState extends ConsumerState<ScreensCustomizer> {
  late List<_ScreenItem> _screens;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _screens = [
      _ScreenItem(id: 'feed', name: 'Feed', emoji: '🏠', color: 0xFF00E1FF, icon: Icons.home),
      _ScreenItem(id: 'food', name: 'Food', emoji: '🍽️', color: 0xFFFF6B35, icon: Icons.restaurant),
      _ScreenItem(id: 'commerce', name: 'Commerce', emoji: '🛍️', color: 0xFFFFD700, icon: Icons.shopping_bag),
      _ScreenItem(id: 'travel', name: 'Travel', emoji: '✈️', color: 0xFF00B4D8, icon: Icons.flight),
      _ScreenItem(id: 'health', name: 'Health', emoji: '💚', color: 0xFF00D68F, icon: Icons.favorite),
      _ScreenItem(id: 'news', name: 'News', emoji: '📰', color: 0xFFFF3D71, icon: Icons.newspaper),
      _ScreenItem(id: 'learn', name: 'Learn', emoji: '📚', color: 0xFF8B5CF6, icon: Icons.school),
      _ScreenItem(id: 'art', name: 'Art', emoji: '🎨', color: 0xFFFFAA00, icon: Icons.brush, enabled: false),
      _ScreenItem(id: 'music', name: 'Music', emoji: '🎵', color: 0xFFEC4899, icon: Icons.music_note, enabled: false),
      _ScreenItem(id: 'fitness', name: 'Fitness', emoji: '💪', color: 0xFF2DD4BF, icon: Icons.fitness_center, enabled: false),
      _ScreenItem(id: 'gaming', name: 'Gaming', emoji: '🎮', color: 0xFF6366F1, icon: Icons.sports_esports, enabled: false),
      _ScreenItem(id: 'finance', name: 'Finance', emoji: '💰', color: 0xFF10B981, icon: Icons.account_balance_wallet, enabled: false),
    ];
  }

  List<_ScreenItem> get _enabledScreens => _screens.where((s) => s.enabled).toList();
  List<_ScreenItem> get _disabledScreens => _screens.where((s) => !s.enabled).toList();

  @override
  Widget build(BuildContext context) {
    final accent = ref.watch(themeProvider).accentColor;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        color: DribaColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(DribaBorderRadius.xxl)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(DribaSpacing.xl),
            child: Column(
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: DribaColors.glassBorder, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: DribaSpacing.xl),
                Row(
                  children: [
                    GlassCircleButton(size: 36, onTap: () => Navigator.pop(context), child: const Icon(Icons.close, color: DribaColors.textSecondary, size: 18)),
                    const SizedBox(width: DribaSpacing.md),
                    const Expanded(child: Text('My Screens', style: TextStyle(color: DribaColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800))),
                    if (_hasChanges)
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.heavyImpact();
                          // Would save to Firestore:
                          // final ids = _enabledScreens.map((s) => s.id).toList();
                          // await authService.updateProfile(enabledScreens: ids);
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: DribaSpacing.lg, vertical: DribaSpacing.sm),
                          decoration: BoxDecoration(gradient: LinearGradient(colors: [accent, accent.withOpacity(0.8)]), borderRadius: BorderRadius.circular(DribaBorderRadius.pill)),
                          child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Bottom bar preview
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DribaSpacing.xl),
            child: _buildNavPreview(accent),
          ),

          const SizedBox(height: DribaSpacing.md),

          // Content
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(DribaSpacing.xl, DribaSpacing.md, DribaSpacing.xl, bottomPad + DribaSpacing.xl),
              children: [
                // Active screens (reorderable)
                _buildSectionTitle('Active Screens', '${_enabledScreens.length}', accent),
                const SizedBox(height: DribaSpacing.sm),
                Text('Long press and drag to reorder', style: TextStyle(color: DribaColors.textDisabled, fontSize: 12)),
                const SizedBox(height: DribaSpacing.md),
                _buildActiveScreens(accent),

                const SizedBox(height: DribaSpacing.xxl),

                // Available screens
                if (_disabledScreens.isNotEmpty) ...[
                  _buildSectionTitle('Available Screens', '${_disabledScreens.length}', accent),
                  const SizedBox(height: DribaSpacing.sm),
                  Text('Tap to add to your navigation', style: TextStyle(color: DribaColors.textDisabled, fontSize: 12)),
                  const SizedBox(height: DribaSpacing.md),
                  _buildDisabledScreens(accent),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavPreview(Color accent) {
    final active = _enabledScreens.take(5).toList();
    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: DribaSpacing.md, horizontal: DribaSpacing.lg),
      borderRadius: BorderRadius.circular(DribaBorderRadius.pill),
      borderColor: accent.withOpacity(0.2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(active.length.clamp(0, 5), (i) {
          final screen = active[i];
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(screen.icon, color: i == 0 ? accent : DribaColors.textDisabled, size: 20),
              const SizedBox(height: 2),
              Text(screen.name, style: TextStyle(color: i == 0 ? accent : DribaColors.textDisabled, fontSize: 9, fontWeight: FontWeight.w600)),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildActiveScreens(Color accent) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (_, child) => Material(
            color: Colors.transparent,
            elevation: 0,
            child: Transform.scale(
              scale: 1.03,
              child: child,
            ),
          ),
          child: child,
        );
      },
      onReorder: (oldIndex, newIndex) {
        HapticFeedback.mediumImpact();
        setState(() {
          if (newIndex > oldIndex) newIndex--;
          final enabled = _enabledScreens;
          final item = enabled[oldIndex];

          // Find actual indices in _screens
          final List<_ScreenItem> reordered = [...enabled];
          reordered.removeAt(oldIndex);
          reordered.insert(newIndex, item);

          // Rebuild _screens with new order
          final disabled = _disabledScreens;
          _screens = [...reordered, ...disabled];
          _hasChanges = true;
        });
      },
      itemCount: _enabledScreens.length,
      itemBuilder: (context, index) {
        final screen = _enabledScreens[index];
        return _ScreenTile(
          key: ValueKey(screen.id),
          screen: screen,
          accent: accent,
          isActive: true,
          onToggle: () {
            HapticFeedback.mediumImpact();
            setState(() {
              screen.enabled = false;
              _hasChanges = true;
            });
          },
        );
      },
    );
  }

  Widget _buildDisabledScreens(Color accent) {
    return Column(
      children: _disabledScreens.map((screen) {
        return _ScreenTile(
          key: ValueKey(screen.id),
          screen: screen,
          accent: accent,
          isActive: false,
          onToggle: () {
            HapticFeedback.mediumImpact();
            setState(() {
              screen.enabled = true;
              _hasChanges = true;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildSectionTitle(String title, String count, Color accent) {
    return Row(
      children: [
        Text(title.toUpperCase(), style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
        const SizedBox(width: DribaSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(color: accent.withOpacity(0.12), borderRadius: BorderRadius.circular(DribaBorderRadius.pill)),
          child: Text(count, style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}

class _ScreenTile extends StatelessWidget {
  final _ScreenItem screen;
  final Color accent;
  final bool isActive;
  final VoidCallback onToggle;

  const _ScreenTile({
    super.key,
    required this.screen,
    required this.accent,
    required this.isActive,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(screen.color);

    return Padding(
      padding: const EdgeInsets.only(bottom: DribaSpacing.sm),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: DribaSpacing.lg, vertical: DribaSpacing.md),
        borderRadius: BorderRadius.circular(DribaBorderRadius.lg),
        borderColor: isActive ? color.withOpacity(0.15) : DribaColors.glassBorder,
        child: Row(
          children: [
            // Drag handle (only for active)
            if (isActive) ...[
              Icon(Icons.drag_indicator, color: DribaColors.textDisabled, size: 20),
              const SizedBox(width: DribaSpacing.sm),
            ],
            // Icon
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(isActive ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(DribaBorderRadius.md),
              ),
              child: Center(child: Text(screen.emoji, style: const TextStyle(fontSize: 20))),
            ),
            const SizedBox(width: DribaSpacing.md),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    screen.name,
                    style: TextStyle(
                      color: isActive ? DribaColors.textPrimary : DribaColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    screen.id,
                    style: TextStyle(color: DribaColors.textDisabled, fontSize: 11),
                  ),
                ],
              ),
            ),
            // Color indicator
            Container(
              width: 14, height: 14,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: isActive
                    ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 6)]
                    : null,
              ),
            ),
            const SizedBox(width: DribaSpacing.md),
            // Toggle
            GestureDetector(
              onTap: onToggle,
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: isActive
                      ? DribaColors.error.withOpacity(0.1)
                      : DribaColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isActive ? Icons.remove : Icons.add,
                  color: isActive ? DribaColors.error : DribaColors.success,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
