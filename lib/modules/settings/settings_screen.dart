import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/driba_colors.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/animations/driba_animations.dart';
import '../../core/providers/theme_provider.dart';
import 'appearance_sheet.dart';
import 'screens_customizer.dart';
import '../../core/widgets/glass_bottom_sheet.dart';

// ============================================
// SETTINGS SCREEN
// Full settings hub — uses global accent
// Account, Appearance, Screens, Notifications,
// Privacy, About, Sign Out, Delete Account
// ============================================

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Notification toggles (demo state)
  bool _pushEnabled = true;
  bool _emailEnabled = false;
  bool _orderUpdates = true;
  bool _newFollowers = true;
  bool _messages = true;
  bool _promotions = false;

  // Privacy toggles
  bool _profilePublic = true;
  bool _showActivity = true;
  bool _allowMessages = true;

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final accent = theme.accentColor;
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: theme.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(DribaSpacing.xl, topPad + DribaSpacing.lg, DribaSpacing.xl, DribaSpacing.xl),
              child: Row(
                children: [
                  GlassCircleButton(
                    size: 40,
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios_new, color: DribaColors.textSecondary, size: 18),
                  ),
                  const SizedBox(width: DribaSpacing.lg),
                  const Expanded(
                    child: Text('Settings', style: TextStyle(color: DribaColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
          ),

          // ── Account Section ─────────────────
          SliverToBoxAdapter(child: _sectionTitle('Account', accent)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: DribaSpacing.xl),
              child: _SettingsGroup(
                accent: accent,
                items: [
                  _SettingsItemData(icon: Icons.person_outline, title: 'Personal Info', subtitle: 'Name, email, phone', onTap: () => _showComingSoon('Personal Info')),
                  _SettingsItemData(icon: Icons.shield_outlined, title: 'Security', subtitle: 'Password, 2FA, sessions', onTap: () => _showComingSoon('Security')),
                  _SettingsItemData(icon: Icons.credit_card, title: 'Payment Methods', subtitle: '2 cards saved', onTap: () => _showComingSoon('Payments')),
                  _SettingsItemData(
                    icon: Icons.store_outlined, title: 'Business Tools', subtitle: 'Seller dashboard, analytics',
                    trailing: _proBadge(accent), onTap: () => _showComingSoon('Business Tools'),
                  ),
                ],
              ),
            ),
          ),

          // ── Appearance Section ──────────────
          SliverToBoxAdapter(child: _sectionTitle('Appearance', accent)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: DribaSpacing.xl),
              child: _SettingsGroup(
                accent: accent,
                items: [
                  _SettingsItemData(
                    icon: Icons.palette_outlined, title: 'Theme & Colors',
                    subtitle: '${theme.accent.name} · ${theme.themeMode == DribaThemeMode.amoled ? "AMOLED" : "Dark"}',
                    trailing: Container(width: 22, height: 22, decoration: BoxDecoration(color: accent, shape: BoxShape.circle, boxShadow: [BoxShadow(color: accent.withOpacity(0.4), blurRadius: 6)])),
                    onTap: () => _openAppearance(),
                  ),
                  _SettingsItemData(
                    icon: Icons.text_fields, title: 'Font Size',
                    subtitle: theme.fontScale.label,
                    onTap: () => _showFontPicker(accent),
                  ),
                  _SettingsItemData(
                    icon: Icons.blur_on, title: 'Glass Blur',
                    subtitle: '${(theme.blurIntensity * 100).toInt()}%',
                    onTap: () => _showBlurSlider(accent),
                  ),
                  _SettingsItemData(
                    icon: Icons.vibration, title: 'Haptic Feedback',
                    trailing: _toggle(theme.hapticsEnabled, accent, () {
                      ref.read(themeProvider.notifier).toggleHaptics();
                    }),
                  ),
                  _SettingsItemData(
                    icon: Icons.slow_motion_video, title: 'Reduced Motion',
                    trailing: _toggle(theme.reducedMotion, accent, () {
                      ref.read(themeProvider.notifier).toggleReducedMotion();
                    }),
                  ),
                ],
              ),
            ),
          ),

          // ── My Screens Section ──────────────
          SliverToBoxAdapter(child: _sectionTitle('My Screens', accent)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: DribaSpacing.xl),
              child: _SettingsGroup(
                accent: accent,
                items: [
                  _SettingsItemData(
                    icon: Icons.dashboard_customize_outlined, title: 'Customize Screens',
                    subtitle: 'Reorder, enable, disable worlds',
                    onTap: () => _openScreenCustomizer(),
                  ),
                ],
              ),
            ),
          ),

          // ── Notifications Section ───────────
          SliverToBoxAdapter(child: _sectionTitle('Notifications', accent)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: DribaSpacing.xl),
              child: _SettingsGroup(
                accent: accent,
                items: [
                  _SettingsItemData(
                    icon: Icons.notifications_outlined, title: 'Push Notifications',
                    trailing: _toggle(_pushEnabled, accent, () => setState(() => _pushEnabled = !_pushEnabled)),
                  ),
                  _SettingsItemData(
                    icon: Icons.email_outlined, title: 'Email Notifications',
                    trailing: _toggle(_emailEnabled, accent, () => setState(() => _emailEnabled = !_emailEnabled)),
                  ),
                  _SettingsItemData(
                    icon: Icons.local_shipping_outlined, title: 'Order Updates',
                    trailing: _toggle(_orderUpdates, accent, () => setState(() => _orderUpdates = !_orderUpdates)),
                  ),
                  _SettingsItemData(
                    icon: Icons.person_add_outlined, title: 'New Followers',
                    trailing: _toggle(_newFollowers, accent, () => setState(() => _newFollowers = !_newFollowers)),
                  ),
                  _SettingsItemData(
                    icon: Icons.chat_outlined, title: 'Messages',
                    trailing: _toggle(_messages, accent, () => setState(() => _messages = !_messages)),
                  ),
                  _SettingsItemData(
                    icon: Icons.campaign_outlined, title: 'Promotions & Deals',
                    trailing: _toggle(_promotions, accent, () => setState(() => _promotions = !_promotions)),
                  ),
                ],
              ),
            ),
          ),

          // ── Privacy Section ─────────────────
          SliverToBoxAdapter(child: _sectionTitle('Privacy', accent)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: DribaSpacing.xl),
              child: _SettingsGroup(
                accent: accent,
                items: [
                  _SettingsItemData(
                    icon: Icons.public, title: 'Public Profile',
                    trailing: _toggle(_profilePublic, accent, () => setState(() => _profilePublic = !_profilePublic)),
                  ),
                  _SettingsItemData(
                    icon: Icons.visibility_outlined, title: 'Show Activity Status',
                    trailing: _toggle(_showActivity, accent, () => setState(() => _showActivity = !_showActivity)),
                  ),
                  _SettingsItemData(
                    icon: Icons.message_outlined, title: 'Allow Messages from Anyone',
                    trailing: _toggle(_allowMessages, accent, () => setState(() => _allowMessages = !_allowMessages)),
                  ),
                  _SettingsItemData(
                    icon: Icons.block, title: 'Blocked Users',
                    subtitle: '0 blocked', onTap: () => _showComingSoon('Blocked Users'),
                  ),
                  _SettingsItemData(
                    icon: Icons.download_outlined, title: 'Download My Data',
                    onTap: () => _showComingSoon('Download Data'),
                  ),
                ],
              ),
            ),
          ),

          // ── About Section ───────────────────
          SliverToBoxAdapter(child: _sectionTitle('About', accent)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: DribaSpacing.xl),
              child: _SettingsGroup(
                accent: accent,
                items: [
                  _SettingsItemData(icon: Icons.info_outline, title: 'Version', trailingText: '1.0.0 (42)'),
                  _SettingsItemData(icon: Icons.description_outlined, title: 'Terms of Service', onTap: () => _showComingSoon('Terms')),
                  _SettingsItemData(icon: Icons.privacy_tip_outlined, title: 'Privacy Policy', onTap: () => _showComingSoon('Privacy Policy')),
                  _SettingsItemData(icon: Icons.help_outline, title: 'Help & Support', onTap: () => _showComingSoon('Help')),
                  _SettingsItemData(icon: Icons.favorite_outline, title: 'Rate Driba OS', onTap: () => HapticFeedback.mediumImpact()),
                ],
              ),
            ),
          ),

          // ── Sign Out ────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(DribaSpacing.xl, DribaSpacing.xxl, DribaSpacing.xl, DribaSpacing.md),
              child: GestureDetector(
                onTap: () => _showSignOutDialog(accent),
                child: GlassContainer(
                  padding: const EdgeInsets.symmetric(vertical: DribaSpacing.lg),
                  borderRadius: BorderRadius.circular(DribaBorderRadius.xl),
                  borderColor: DribaColors.error.withOpacity(0.2),
                  fillColor: DribaColors.error.withOpacity(0.03),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, color: DribaColors.error, size: 20),
                      SizedBox(width: DribaSpacing.sm),
                      Text('Sign Out', style: TextStyle(color: DribaColors.error, fontWeight: FontWeight.w700, fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Delete account
          SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomPad + 120),
                child: GestureDetector(
                  onTap: () => _showDeleteDialog(accent),
                  child: Text('Delete Account', style: TextStyle(color: DribaColors.textDisabled, fontSize: 13, decoration: TextDecoration.underline)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────

  Widget _sectionTitle(String title, Color accent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(DribaSpacing.xl, DribaSpacing.xxl, DribaSpacing.xl, DribaSpacing.md),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5),
      ),
    );
  }

  Widget _proBadge(Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xFFFFD700), const Color(0xFFFFAA00)]),
        borderRadius: BorderRadius.circular(DribaBorderRadius.pill),
      ),
      child: const Text('PRO', style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w900)),
    );
  }

  Widget _toggle(bool value, Color accent, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: DribaDurations.fast,
        width: 48, height: 28,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: value ? accent : DribaColors.glassFillActive,
          borderRadius: BorderRadius.circular(14),
        ),
        child: AnimatedAlign(
          duration: DribaDurations.fast,
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)],
            ),
          ),
        ),
      ),
    );
  }

  void _openAppearance() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AppearanceSheet(),
    );
  }

  void _openScreenCustomizer() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ScreensCustomizer(),
    );
  }

  void _showFontPicker(Color accent) {
    final current = ref.read(themeProvider).fontScale;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GlassBottomSheet(
        padding: const EdgeInsets.all(DribaSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: DribaSpacing.xl),
            const Text('Font Size', style: TextStyle(color: DribaColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: DribaSpacing.xl),
            ...FontScale.values.map((fs) {
              final isSelected = fs == current;
              return Padding(
                padding: const EdgeInsets.only(bottom: DribaSpacing.sm),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(themeProvider.notifier).setFontScale(fs);
                    Navigator.pop(ctx);
                  },
                  child: GlassContainer(
                    padding: const EdgeInsets.all(DribaSpacing.lg),
                    borderRadius: BorderRadius.circular(DribaBorderRadius.lg),
                    borderColor: isSelected ? accent : DribaColors.glassBorder,
                    fillColor: isSelected ? accent.withOpacity(0.05) : null,
                    child: Row(
                      children: [
                        Text('Aa', style: TextStyle(color: DribaColors.textPrimary, fontSize: 16 * fs.value, fontWeight: FontWeight.w700)),
                        const SizedBox(width: DribaSpacing.lg),
                        Expanded(child: Text(fs.label, style: TextStyle(color: DribaColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15))),
                        if (isSelected) Icon(Icons.check_circle, color: accent, size: 22),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom),
          ],
        ),
      ),
    );
  }

  void _showBlurSlider(Color accent) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final blur = ref.watch(themeProvider).blurIntensity;
          return GlassBottomSheet(
            padding: const EdgeInsets.all(DribaSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: DribaSpacing.xl),
                const Text('Glass Blur Intensity', style: TextStyle(color: DribaColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: DribaSpacing.sm),
                Text('${(blur * 100).toInt()}%', style: TextStyle(color: accent, fontSize: 28, fontWeight: FontWeight.w900)),
                const SizedBox(height: DribaSpacing.lg),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: accent,
                    inactiveTrackColor: DribaColors.glassFillActive,
                    thumbColor: accent,
                    overlayColor: accent.withOpacity(0.2),
                  ),
                  child: Slider(
                    value: blur,
                    onChanged: (v) {
                      ref.read(themeProvider.notifier).setBlurIntensity(v);
                      setSheetState(() {});
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Off', style: TextStyle(color: DribaColors.textTertiary, fontSize: 12)),
                    Text('Max', style: TextStyle(color: DribaColors.textTertiary, fontSize: 12)),
                  ],
                ),
                SizedBox(height: MediaQuery.of(ctx).padding.bottom + DribaSpacing.lg),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSignOutDialog(Color accent) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassContainer(
          padding: const EdgeInsets.all(DribaSpacing.xxl),
          borderRadius: BorderRadius.circular(DribaBorderRadius.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 56, height: 56, decoration: BoxDecoration(color: DribaColors.error.withOpacity(0.15), shape: BoxShape.circle),
                child: const Icon(Icons.logout, color: DribaColors.error, size: 28)),
              const SizedBox(height: DribaSpacing.xl),
              const Text('Sign Out?', style: TextStyle(color: DribaColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: DribaSpacing.sm),
              Text('You\'ll need to sign in again to access your account.', textAlign: TextAlign.center, style: TextStyle(color: DribaColors.textTertiary, fontSize: 14)),
              const SizedBox(height: DribaSpacing.xl),
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: GlassContainer(
                      padding: const EdgeInsets.symmetric(vertical: DribaSpacing.md),
                      borderRadius: BorderRadius.circular(DribaBorderRadius.pill),
                      child: const Center(child: Text('Cancel', style: TextStyle(color: DribaColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 15))),
                    ),
                  ),
                ),
                const SizedBox(width: DribaSpacing.md),
                Expanded(
                  child: GestureDetector(
                    onTap: () { Navigator.pop(ctx); /* authService.signOut() */ },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: DribaSpacing.md),
                      decoration: BoxDecoration(color: DribaColors.error, borderRadius: BorderRadius.circular(DribaBorderRadius.pill)),
                      child: const Center(child: Text('Sign Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15))),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(Color accent) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassContainer(
          padding: const EdgeInsets.all(DribaSpacing.xxl),
          borderRadius: BorderRadius.circular(DribaBorderRadius.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 56, height: 56, decoration: BoxDecoration(color: DribaColors.error.withOpacity(0.15), shape: BoxShape.circle),
                child: const Icon(Icons.warning_amber, color: DribaColors.error, size: 28)),
              const SizedBox(height: DribaSpacing.xl),
              const Text('Delete Account?', style: TextStyle(color: DribaColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: DribaSpacing.sm),
              Text('This action is permanent. All your data, posts, orders, and messages will be permanently deleted.', textAlign: TextAlign.center, style: TextStyle(color: DribaColors.textTertiary, fontSize: 14, height: 1.4)),
              const SizedBox(height: DribaSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: DribaSpacing.md),
                    decoration: BoxDecoration(color: DribaColors.error, borderRadius: BorderRadius.circular(DribaBorderRadius.pill)),
                    child: const Center(child: Text('Delete Permanently', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15))),
                  ),
                ),
              ),
              const SizedBox(height: DribaSpacing.md),
              GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Text('Cancel', style: TextStyle(color: DribaColors.textTertiary, fontWeight: FontWeight.w600, fontSize: 15)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(String feature) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature — coming soon'),
        backgroundColor: DribaColors.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DribaBorderRadius.lg)),
      ),
    );
  }
}

// ── Settings Group Widget ─────────────────────
class _SettingsItemData {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailingText;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsItemData({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailingText,
    this.trailing,
    this.onTap,
  });
}

class _SettingsGroup extends StatelessWidget {
  final List<_SettingsItemData> items;
  final Color accent;

  const _SettingsGroup({required this.items, required this.accent});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(DribaBorderRadius.xl),
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          final isLast = i == items.length - 1;
          return GestureDetector(
            onTap: item.onTap != null
                ? () { HapticFeedback.lightImpact(); item.onTap!(); }
                : null,
            behavior: HitTestBehavior.opaque,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: DribaSpacing.lg, vertical: DribaSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(DribaBorderRadius.md),
                        ),
                        child: Icon(item.icon, color: accent, size: 18),
                      ),
                      const SizedBox(width: DribaSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title, style: const TextStyle(color: DribaColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
                            if (item.subtitle != null)
                              Text(item.subtitle!, style: TextStyle(color: DribaColors.textTertiary, fontSize: 12)),
                          ],
                        ),
                      ),
                      if (item.trailing != null) item.trailing!
                      else if (item.trailingText != null) Text(item.trailingText!, style: TextStyle(color: DribaColors.textTertiary, fontSize: 13))
                      else if (item.onTap != null) Icon(Icons.chevron_right, color: DribaColors.textDisabled, size: 20),
                    ],
                  ),
                ),
                if (!isLast)
                  Padding(
                    padding: const EdgeInsets.only(left: 64),
                    child: Divider(height: 1, color: DribaColors.glassBorder),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
