import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/driba_colors.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/animations/driba_animations.dart';
import '../../shared/models/models.dart';

/// Profile Edit Sheet
/// Editable fields + AI bio generation
class ProfileEditSheet extends StatefulWidget {
  final DribaUser user;

  const ProfileEditSheet({super.key, required this.user});

  @override
  State<ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends State<ProfileEditSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _taglineController;
  late TextEditingController _bioController;
  late TextEditingController _websiteController;

  bool _isGeneratingBio = false;
  bool _isSaving = false;
  final List<String> _generatedBios = [];
  int _selectedBioIndex = -1;

  static const Color _accent = DribaColors.primary;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: DribaDurations.slow,
    )..forward();

    _nameController = TextEditingController(text: widget.user.displayName);
    _usernameController = TextEditingController(text: widget.user.username);
    _taglineController = TextEditingController(text: widget.user.tagline ?? '');
    _bioController = TextEditingController(text: widget.user.bio ?? '');
    _websiteController = TextEditingController(text: widget.user.websiteUrl ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    _taglineController.dispose();
    _bioController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _generateAiBio() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _isGeneratingBio = true;
      _generatedBios.clear();
      _selectedBioIndex = -1;
    });

    // Simulate AI bio generation (would call AI router in production)
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final name = _nameController.text;
    final tagline = _taglineController.text;

    setState(() {
      _isGeneratingBio = false;
      _generatedBios.addAll([
        '$name is a passionate ${tagline.isNotEmpty ? tagline.split('·').first.trim().toLowerCase() : 'creator'} based in San Francisco. With a focus on innovation and design, they bring a unique global perspective to every project. Always exploring the intersection of technology and culture.',
        'Creative mind. Strategic thinker. ${tagline.isNotEmpty ? tagline.split('·').first.trim() : 'Builder'} by day, storyteller by night. $name believes in the power of authentic connections and building products that matter.',
        'From the vibrant vibrant world of tech to the global stage — $name combines years of industry experience with a deep love for craft and community. Currently focused on redefining what social commerce can be.',
      ]);
    });
  }

  Future<void> _save() async {
    HapticFeedback.heavyImpact();
    setState(() => _isSaving = true);

    // Apply selected AI bio if chosen
    if (_selectedBioIndex >= 0) {
      _bioController.text = _generatedBios[_selectedBioIndex];
    }

    // TODO: Call auth service updateProfile()
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated!'),
          backgroundColor: DribaColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DribaBorderRadius.md)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: DribaColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(DribaBorderRadius.xxl),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: DribaSpacing.md),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: DribaColors.glassBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
                DribaSpacing.xl, DribaSpacing.lg, DribaSpacing.xl, DribaSpacing.md),
            child: Row(
              children: [
                GlassCircleButton(
                  size: 38,
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close,
                      color: DribaColors.textSecondary, size: 20),
                ),
                const SizedBox(width: DribaSpacing.md),
                const Expanded(
                  child: Text(
                    'Edit Profile',
                    style: TextStyle(
                      color: DribaColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _isSaving ? null : _save,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: DribaSpacing.xl, vertical: DribaSpacing.sm),
                    decoration: BoxDecoration(
                      gradient: DribaColors.primaryGradient,
                      borderRadius: BorderRadius.circular(DribaBorderRadius.pill),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Save',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),

          // Form
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                DribaSpacing.xl, 0, DribaSpacing.xl, bottomPad + DribaSpacing.xl,
              ),
              children: [
                // Avatar + cover
                _buildAvatarSection(),
                const SizedBox(height: DribaSpacing.xxl),

                // Name
                _EditField(
                  label: 'Display Name',
                  controller: _nameController,
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: DribaSpacing.lg),

                // Username
                _EditField(
                  label: 'Username',
                  controller: _usernameController,
                  icon: Icons.alternate_email,
                  prefix: '@',
                ),
                const SizedBox(height: DribaSpacing.lg),

                // Tagline
                _EditField(
                  label: 'Headline',
                  controller: _taglineController,
                  icon: Icons.title,
                  hint: 'Design Lead @Company · City 🌍',
                ),
                const SizedBox(height: DribaSpacing.lg),

                // Bio + AI button
                _buildBioSection(),
                const SizedBox(height: DribaSpacing.lg),

                // Website
                _EditField(
                  label: 'Website',
                  controller: _websiteController,
                  icon: Icons.language,
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: DribaSpacing.xxl),

                // Social links editor
                _buildSocialLinksEditor(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Avatar Section ──────────────────────────
  Widget _buildAvatarSection() {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _accent.withOpacity(0.3), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: _accent.withOpacity(0.2),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: CachedNetworkImageProvider(
                    widget.user.avatarUrl ?? 'https://i.pravatar.cc/300',
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => HapticFeedback.lightImpact(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: DribaColors.surface, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DribaSpacing.md),
          GestureDetector(
            onTap: () => HapticFeedback.lightImpact(),
            child: Text(
              'Change cover photo',
              style: TextStyle(
                color: _accent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bio Section + AI ────────────────────────
  Widget _buildBioSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Bio',
              style: TextStyle(
                color: DribaColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: _isGeneratingBio ? null : _generateAiBio,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: DribaSpacing.md, vertical: DribaSpacing.xs),
                decoration: BoxDecoration(
                  gradient: DribaColors.primaryGradient,
                  borderRadius: BorderRadius.circular(DribaBorderRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isGeneratingBio)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else
                      const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                    const SizedBox(width: DribaSpacing.xs),
                    Text(
                      _isGeneratingBio ? 'Generating...' : 'AI Generate',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: DribaSpacing.sm),

        // Text field
        GlassContainer(
          borderRadius: BorderRadius.circular(DribaBorderRadius.lg),
          padding: const EdgeInsets.symmetric(
            horizontal: DribaSpacing.lg,
            vertical: DribaSpacing.sm,
          ),
          child: TextField(
            controller: _bioController,
            maxLines: 4,
            maxLength: 280,
            style: const TextStyle(
              color: DribaColors.textPrimary,
              fontSize: 14,
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText: 'Tell the world about yourself...',
              hintStyle: TextStyle(color: DribaColors.textDisabled),
              border: InputBorder.none,
              counterStyle: TextStyle(color: DribaColors.textDisabled, fontSize: 11),
            ),
          ),
        ),

        // AI generated suggestions
        if (_generatedBios.isNotEmpty) ...[
          const SizedBox(height: DribaSpacing.lg),
          Text(
            'AI Suggestions',
            style: TextStyle(
              color: _accent,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: DribaSpacing.sm),
          ...List.generate(_generatedBios.length, (index) {
            final isSelected = _selectedBioIndex == index;
            return Padding(
              padding: const EdgeInsets.only(bottom: DribaSpacing.sm),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedBioIndex = isSelected ? -1 : index;
                    if (!isSelected) {
                      _bioController.text = _generatedBios[index];
                    }
                  });
                },
                child: GlassContainer(
                  padding: const EdgeInsets.all(DribaSpacing.md),
                  borderRadius: BorderRadius.circular(DribaBorderRadius.lg),
                  borderColor: isSelected ? _accent : null,
                  fillColor: isSelected ? _accent.withOpacity(0.06) : null,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: isSelected ? _accent : DribaColors.textDisabled,
                        size: 18,
                      ),
                      const SizedBox(width: DribaSpacing.sm),
                      Expanded(
                        child: Text(
                          _generatedBios[index],
                          style: TextStyle(
                            color: isSelected
                                ? DribaColors.textPrimary
                                : DribaColors.textTertiary,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  // ── Social Links ────────────────────────────
  Widget _buildSocialLinksEditor() {
    final platforms = [
      ('Twitter / X', Icons.alternate_email, 'twitter'),
      ('Instagram', Icons.camera_alt_outlined, 'instagram'),
      ('LinkedIn', Icons.work_outline, 'linkedin'),
      ('Dribbble', Icons.sports_basketball_outlined, 'dribbble'),
      ('GitHub', Icons.code, 'github'),
      ('YouTube', Icons.play_circle_outline, 'youtube'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Social Links',
          style: TextStyle(
            color: DribaColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: DribaSpacing.md),
        ...platforms.map((platform) {
          final existingLink = widget.user.socialLinks.firstWhere(
            (l) => l.platform == platform.$3,
            orElse: () => SocialLink(platform: platform.$3, url: '', username: ''),
          );
          final hasLink = existingLink.url.isNotEmpty;

          return Padding(
            padding: const EdgeInsets.only(bottom: DribaSpacing.sm),
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(
                horizontal: DribaSpacing.lg,
                vertical: DribaSpacing.md,
              ),
              borderRadius: BorderRadius.circular(DribaBorderRadius.lg),
              borderColor: hasLink ? _accent.withOpacity(0.2) : null,
              child: Row(
                children: [
                  Icon(
                    platform.$2,
                    color: hasLink ? _accent : DribaColors.textDisabled,
                    size: 20,
                  ),
                  const SizedBox(width: DribaSpacing.md),
                  Expanded(
                    child: Text(
                      hasLink ? existingLink.username ?? platform.$1 : platform.$1,
                      style: TextStyle(
                        color: hasLink
                            ? DribaColors.textPrimary
                            : DribaColors.textDisabled,
                        fontSize: 14,
                        fontWeight: hasLink ? FontWeight.w500 : FontWeight.w400,
                      ),
                    ),
                  ),
                  Icon(
                    hasLink ? Icons.check_circle : Icons.add_circle_outline,
                    color: hasLink ? _accent : DribaColors.textDisabled,
                    size: 20,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ── Edit Field ────────────────────────────────

class _EditField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String? hint;
  final String? prefix;
  final TextInputType? keyboardType;

  const _EditField({
    required this.label,
    required this.controller,
    required this.icon,
    this.hint,
    this.prefix,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: DribaColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: DribaSpacing.sm),
        GlassContainer(
          borderRadius: BorderRadius.circular(DribaBorderRadius.lg),
          padding: const EdgeInsets.symmetric(
            horizontal: DribaSpacing.lg,
            vertical: DribaSpacing.xs,
          ),
          child: Row(
            children: [
              Icon(icon, color: DribaColors.textTertiary, size: 18),
              const SizedBox(width: DribaSpacing.md),
              if (prefix != null)
                Text(
                  prefix!,
                  style: TextStyle(
                    color: DribaColors.textTertiary,
                    fontSize: 15,
                  ),
                ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: const TextStyle(
                    color: DribaColors.textPrimary,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(color: DribaColors.textDisabled),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: DribaSpacing.md),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
