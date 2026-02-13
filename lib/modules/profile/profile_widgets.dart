import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/driba_colors.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/glass_bottom_sheet.dart';
import '../../shared/models/models.dart';

// ============================================
// PROFILE WIDGETS
// Reusable components for profile screens
// ============================================

/// Settings Sheet — accessed from profile gear icon
class SettingsSheet extends StatelessWidget {
  const SettingsSheet({super.key});

  static const Color _accent = DribaColors.primary;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return GlassBottomSheet(
      heightFraction: 0.75,
      child: Column(
        children: [
          // Title
          const Padding(
            padding: EdgeInsets.all(DribaSpacing.xl),
            child: Row(
              children: [
                Icon(Icons.settings_outlined,
                    color: DribaColors.textPrimary, size: 22),
                SizedBox(width: DribaSpacing.md),
                Text(
                  'Settings',
                  style: TextStyle(
                    color: DribaColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          // Settings list
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                DribaSpacing.xl, 0, DribaSpacing.xl, bottomPad + DribaSpacing.xl,
              ),
              children: [
                _SettingsSection(title: 'Account', items: [
                  _SettingsItem(
                    icon: Icons.person_outline,
                    title: 'Personal Info',
                    subtitle: 'Name, email, phone',
                  ),
                  _SettingsItem(
                    icon: Icons.lock_outline,
                    title: 'Security',
                    subtitle: 'Password, 2FA',
                  ),
                  _SettingsItem(
                    icon: Icons.payment_outlined,
                    title: 'Payment Methods',
                    subtitle: 'Cards, wallets',
                  ),
                  _SettingsItem(
                    icon: Icons.store_outlined,
                    title: 'Business Tools',
                    subtitle: 'POS, invoicing, analytics',
                    badge: 'PRO',
                    badgeColor: Color(0xFFFFD700),
                  ),
                ]),
                const SizedBox(height: DribaSpacing.lg),
                _SettingsSection(title: 'Preferences', items: [
                  _SettingsItem(
                    icon: Icons.palette_outlined,
                    title: 'Appearance',
                    subtitle: 'Dark mode (always on)',
                    trailing: 'Dark',
                  ),
                  _SettingsItem(
                    icon: Icons.language,
                    title: 'Language',
                    subtitle: 'App language',
                    trailing: 'English',
                  ),
                  _SettingsItem(
                    icon: Icons.grid_view_rounded,
                    title: 'My Screens',
                    subtitle: 'Add or remove worlds',
                  ),
                  _SettingsItem(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    subtitle: 'Push, email, sounds',
                    hasToggle: true,
                    toggleValue: true,
                  ),
                ]),
                const SizedBox(height: DribaSpacing.lg),
                _SettingsSection(title: 'About', items: [
                  _SettingsItem(
                    icon: Icons.info_outline,
                    title: 'About Driba',
                    subtitle: 'Version 1.0.0',
                  ),
                  _SettingsItem(
                    icon: Icons.description_outlined,
                    title: 'Terms of Service',
                  ),
                  _SettingsItem(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                  ),
                  _SettingsItem(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                  ),
                ]),
                const SizedBox(height: DribaSpacing.xxl),
                // Sign out
                GestureDetector(
                  onTap: () {
                    HapticFeedback.heavyImpact();
                    Navigator.pop(context);
                  },
                  child: GlassContainer(
                    padding: const EdgeInsets.all(DribaSpacing.lg),
                    borderRadius:
                        BorderRadius.circular(DribaBorderRadius.lg),
                    borderColor: DribaColors.error.withOpacity(0.3),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout,
                            color: DribaColors.error, size: 20),
                        SizedBox(width: DribaSpacing.sm),
                        Text(
                          'Sign Out',
                          style: TextStyle(
                            color: DribaColors.error,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: DribaSpacing.md),
                // Delete account
                Center(
                  child: GestureDetector(
                    onTap: () => HapticFeedback.lightImpact(),
                    child: Text(
                      'Delete Account',
                      style: TextStyle(
                        color: DribaColors.textDisabled,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<_SettingsItem> items;

  const _SettingsSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: DribaColors.textTertiary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: DribaSpacing.sm),
        GlassContainer(
          borderRadius: BorderRadius.circular(DribaBorderRadius.xl),
          padding: EdgeInsets.zero,
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DribaSpacing.lg,
                      vertical: DribaSpacing.md,
                    ),
                    child: Row(
                      children: [
                        Icon(item.icon,
                            color: DribaColors.textSecondary, size: 20),
                        const SizedBox(width: DribaSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    item.title,
                                    style: const TextStyle(
                                      color: DribaColors.textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (item.badge != null) ...[
                                    const SizedBox(width: DribaSpacing.sm),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: (item.badgeColor ??
                                                DribaColors.primary)
                                            .withOpacity(0.15),
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        item.badge!,
                                        style: TextStyle(
                                          color: item.badgeColor ??
                                              DribaColors.primary,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (item.subtitle != null)
                                Text(
                                  item.subtitle!,
                                  style: TextStyle(
                                    color: DribaColors.textTertiary,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (item.trailing != null)
                          Text(
                            item.trailing!,
                            style: TextStyle(
                              color: DribaColors.textTertiary,
                              fontSize: 13,
                            ),
                          ),
                        if (item.hasToggle)
                          Switch(
                            value: item.toggleValue,
                            onChanged: (_) {},
                            activeColor: DribaColors.primary,
                          )
                        else
                          Icon(Icons.chevron_right,
                              color: DribaColors.textDisabled, size: 20),
                      ],
                    ),
                  ),
                  if (index < items.length - 1)
                    Divider(
                      height: 1,
                      indent: DribaSpacing.xxxl + DribaSpacing.md,
                      color: DribaColors.glassBorder,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailing;
  final String? badge;
  final Color? badgeColor;
  final bool hasToggle;
  final bool toggleValue;

  const _SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.badge,
    this.badgeColor,
    this.hasToggle = false,
    this.toggleValue = false,
  });
}

// ============================================
// PROFILE LINK CARD
// Used when sharing a profile externally
// ============================================

class ProfileLinkCard extends StatelessWidget {
  final DribaUser user;
  final Color accent;

  const ProfileLinkCard({
    super.key,
    required this.user,
    this.accent = DribaColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(DribaSpacing.xl),
      borderRadius: BorderRadius.circular(DribaBorderRadius.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: accent.withOpacity(0.3), width: 2),
            ),
            child: CircleAvatar(
              radius: 36,
              backgroundImage: user.avatarUrl != null
                  ? NetworkImage(user.avatarUrl!)
                  : null,
              child: user.avatarUrl == null
                  ? Text(
                      user.displayName[0],
                      style: TextStyle(
                        color: accent,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: DribaSpacing.md),
          // Name + verification
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                user.displayName,
                style: const TextStyle(
                  color: DribaColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (user.verificationStatus == VerificationStatus.verified) ...[
                const SizedBox(width: 4),
                Icon(Icons.verified, color: accent, size: 18),
              ],
            ],
          ),
          Text(
            '@${user.username}',
            style: TextStyle(color: accent, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          if (user.tagline != null) ...[
            const SizedBox(height: DribaSpacing.sm),
            Text(
              user.tagline!,
              style: TextStyle(
                color: DribaColors.textTertiary,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: DribaSpacing.lg),
          // Mini stats
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _MiniStat(value: '${user.followersCount}', label: 'followers'),
              Container(
                width: 1,
                height: 20,
                margin: const EdgeInsets.symmetric(horizontal: DribaSpacing.lg),
                color: DribaColors.glassBorder,
              ),
              _MiniStat(value: '${user.postsCount}', label: 'posts'),
            ],
          ),
          const SizedBox(height: DribaSpacing.lg),
          // View profile button
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DribaSpacing.xxl,
              vertical: DribaSpacing.md,
            ),
            decoration: BoxDecoration(
              gradient: DribaColors.primaryGradient,
              borderRadius: BorderRadius.circular(DribaBorderRadius.pill),
            ),
            child: const Text(
              'View Profile',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;

  const _MiniStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: DribaColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: DribaColors.textTertiary, fontSize: 11),
        ),
      ],
    );
  }
}
