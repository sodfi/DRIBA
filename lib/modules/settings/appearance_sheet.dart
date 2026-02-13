import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/driba_colors.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/animations/driba_animations.dart';
import '../../core/providers/theme_provider.dart';

// ============================================
// APPEARANCE SHEET
// Accent color picker, theme mode, live preview
// ============================================

class AppearanceSheet extends ConsumerStatefulWidget {
  const AppearanceSheet({super.key});

  @override
  ConsumerState<AppearanceSheet> createState() => _AppearanceSheetState();
}

class _AppearanceSheetState extends ConsumerState<AppearanceSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: DribaDurations.slow,
    )..forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final accent = theme.accentColor;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(DribaBorderRadius.xxl)),
      ),
      child: Column(
        children: [
          // Handle + header
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
                    const Expanded(child: Text('Appearance', style: TextStyle(color: DribaColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800))),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        ref.read(themeProvider.notifier).resetToDefaults();
                      },
                      child: Text('Reset', style: TextStyle(color: DribaColors.textTertiary, fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(DribaSpacing.xl, 0, DribaSpacing.xl, bottomPad + DribaSpacing.xl),
              children: [
                // ── Live Preview ────────────────
                _buildPreviewCard(theme, accent),
                const SizedBox(height: DribaSpacing.xxl),

                // ── Accent Color ────────────────
                _buildSectionTitle('Accent Color'),
                const SizedBox(height: DribaSpacing.md),
                _buildColorGrid(theme, accent),
                const SizedBox(height: DribaSpacing.xxl),

                // ── Theme Mode ──────────────────
                _buildSectionTitle('Theme Mode'),
                const SizedBox(height: DribaSpacing.md),
                _buildThemeModeSelector(theme, accent),
                const SizedBox(height: DribaSpacing.xxl),

                // ── Auto-play ───────────────────
                _buildSectionTitle('Media'),
                const SizedBox(height: DribaSpacing.md),
                _buildMediaToggle(theme, accent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Live Preview ────────────────────────────
  Widget _buildPreviewCard(ThemeState theme, Color accent) {
    final accentLight = theme.accentColorLight;

    return GlassContainer(
      padding: const EdgeInsets.all(DribaSpacing.xl),
      borderRadius: BorderRadius.circular(DribaBorderRadius.xxl),
      borderColor: accent.withOpacity(0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mini header
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [accent, accentLight]),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 18),
              ),
              const SizedBox(width: DribaSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Sara El Amrani', style: TextStyle(color: DribaColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                  Text('@saradesigns', style: TextStyle(color: accent, fontSize: 12)),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: DribaSpacing.lg, vertical: DribaSpacing.xs),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [accent, accentLight]),
                  borderRadius: BorderRadius.circular(DribaBorderRadius.pill),
                ),
                child: const Text('Follow', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: DribaSpacing.lg),
          // Mini content
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: DribaColors.glassFill,
              borderRadius: BorderRadius.circular(DribaBorderRadius.lg),
            ),
            child: Row(
              children: [
                Container(
                  width: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [accent.withOpacity(0.3), accent.withOpacity(0.1)]),
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(DribaBorderRadius.lg)),
                  ),
                  child: Icon(Icons.image, color: accent, size: 28),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(DribaSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(height: 10, width: 120, decoration: BoxDecoration(color: DribaColors.glassFillActive, borderRadius: BorderRadius.circular(5))),
                        const SizedBox(height: 6),
                        Container(height: 8, width: 80, decoration: BoxDecoration(color: DribaColors.glassFill, borderRadius: BorderRadius.circular(4))),
                        const SizedBox(height: 8),
                        Row(children: [
                          Icon(Icons.favorite, color: accent, size: 14),
                          const SizedBox(width: 4),
                          Container(height: 8, width: 30, decoration: BoxDecoration(color: accent.withOpacity(0.2), borderRadius: BorderRadius.circular(4))),
                        ]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DribaSpacing.md),
          // Mini nav bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: DribaSpacing.sm),
            decoration: BoxDecoration(
              color: DribaColors.glassFill,
              borderRadius: BorderRadius.circular(DribaBorderRadius.pill),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Icon(Icons.home, color: accent, size: 20),
                Icon(Icons.search, color: DribaColors.textDisabled, size: 20),
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(gradient: LinearGradient(colors: [accent, accentLight]), shape: BoxShape.circle),
                  child: const Icon(Icons.add, color: Colors.white, size: 18),
                ),
                Icon(Icons.chat_bubble_outline, color: DribaColors.textDisabled, size: 20),
                Icon(Icons.person_outline, color: DribaColors.textDisabled, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Color Grid ──────────────────────────────
  Widget _buildColorGrid(ThemeState theme, Color accent) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 0.85,
        crossAxisSpacing: DribaSpacing.md,
        mainAxisSpacing: DribaSpacing.md,
      ),
      itemCount: accentPresets.length,
      itemBuilder: (context, index) {
        final preset = accentPresets[index];
        final isSelected = preset.id == theme.accentId;

        return GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            ref.read(themeProvider.notifier).setAccent(preset.id);
          },
          child: AnimatedContainer(
            duration: DribaDurations.fast,
            decoration: BoxDecoration(
              color: isSelected ? preset.color.withOpacity(0.12) : DribaColors.glassFill,
              borderRadius: BorderRadius.circular(DribaBorderRadius.lg),
              border: Border.all(
                color: isSelected ? preset.color : DribaColors.glassBorder,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Color dot
                AnimatedContainer(
                  duration: DribaDurations.fast,
                  width: isSelected ? 32 : 28,
                  height: isSelected ? 32 : 28,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [preset.color, preset.colorLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: isSelected
                        ? [BoxShadow(color: preset.color.withOpacity(0.5), blurRadius: 10)]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
                const SizedBox(height: 4),
                Text(
                  preset.name,
                  style: TextStyle(
                    color: isSelected ? preset.color : DribaColors.textTertiary,
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Theme Mode ──────────────────────────────
  Widget _buildThemeModeSelector(ThemeState theme, Color accent) {
    return Row(
      children: [
        _ThemeModeCard(
          title: 'Dark',
          icon: Icons.dark_mode,
          isSelected: theme.themeMode == DribaThemeMode.dark,
          accent: accent,
          bgColor: DribaColors.background,
          onTap: () {
            HapticFeedback.selectionClick();
            ref.read(themeProvider.notifier).setThemeMode(DribaThemeMode.dark);
          },
        ),
        const SizedBox(width: DribaSpacing.md),
        _ThemeModeCard(
          title: 'AMOLED',
          icon: Icons.brightness_1,
          isSelected: theme.themeMode == DribaThemeMode.amoled,
          accent: accent,
          bgColor: Colors.black,
          onTap: () {
            HapticFeedback.selectionClick();
            ref.read(themeProvider.notifier).setThemeMode(DribaThemeMode.amoled);
          },
        ),
      ],
    );
  }

  Widget _buildMediaToggle(ThemeState theme, Color accent) {
    return GlassContainer(
      padding: const EdgeInsets.all(DribaSpacing.lg),
      borderRadius: BorderRadius.circular(DribaBorderRadius.xl),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: accent.withOpacity(0.08), borderRadius: BorderRadius.circular(DribaBorderRadius.md)),
            child: Icon(Icons.play_circle_outline, color: accent, size: 18),
          ),
          const SizedBox(width: DribaSpacing.md),
          const Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Auto-play Media', style: TextStyle(color: DribaColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
              Text('Play videos and animations in feed', style: TextStyle(color: DribaColors.textTertiary, fontSize: 12)),
            ],
          )),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(themeProvider.notifier).toggleAutoPlayMedia();
            },
            child: AnimatedContainer(
              duration: DribaDurations.fast,
              width: 48, height: 28,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: theme.autoPlayMedia ? accent : DribaColors.glassFillActive,
                borderRadius: BorderRadius.circular(14),
              ),
              child: AnimatedAlign(
                duration: DribaDurations.fast,
                alignment: theme.autoPlayMedia ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(width: 24, height: 24, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)])),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(color: DribaColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5),
    );
  }
}

class _ThemeModeCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final Color accent;
  final Color bgColor;
  final VoidCallback onTap;

  const _ThemeModeCard({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.accent,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: DribaDurations.fast,
          padding: const EdgeInsets.all(DribaSpacing.xl),
          decoration: BoxDecoration(
            color: isSelected ? accent.withOpacity(0.06) : DribaColors.glassFill,
            borderRadius: BorderRadius.circular(DribaBorderRadius.xl),
            border: Border.all(
              color: isSelected ? accent : DribaColors.glassBorder,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              // Preview
              Container(
                width: 64, height: 40,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(DribaBorderRadius.md),
                  border: Border.all(color: DribaColors.glassBorder),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(height: 4, width: 32, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 4),
                    Container(height: 3, width: 24, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(1.5))),
                  ],
                ),
              ),
              const SizedBox(height: DribaSpacing.md),
              Text(title, style: TextStyle(color: isSelected ? accent : DribaColors.textSecondary, fontWeight: FontWeight.w700, fontSize: 14)),
              if (isSelected)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Icon(Icons.check_circle, color: accent, size: 18),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
