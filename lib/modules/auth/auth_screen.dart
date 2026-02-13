import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/driba_colors.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/animations/driba_animations.dart';
import 'auth_providers.dart';
import 'personalization_screen.dart';

/// Auth Screen — Login / Sign Up / Forgot Password
/// Immersive glass design with animated background
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgController;
  late AnimationController _formController;
  late Animation<double> _formFade;
  late Animation<Offset> _formSlide;

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _nameFocus = FocusNode();

  static const Color _accent = DribaColors.primary;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _formController = AnimationController(
      vsync: this,
      duration: DribaDurations.slow,
    )..forward();
    _formFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _formController, curve: Curves.easeOut),
    );
    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _formController, curve: DribaCurves.enter),
    );
  }

  @override
  void dispose() {
    _bgController.dispose();
    _formController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _switchMode(AuthMode mode) {
    HapticFeedback.selectionClick();
    ref.read(authFormProvider.notifier).setMode(mode);
    _formController.reset();
    _formController.forward();
  }

  Future<void> _submit() async {
    HapticFeedback.mediumImpact();
    final notifier = ref.read(authFormProvider.notifier);
    final form = ref.read(authFormProvider);

    switch (form.mode) {
      case AuthMode.login:
        final result = await notifier.login();
        if (result.isSuccess && mounted) {
          // Auth state listener handles navigation
        }
        break;
      case AuthMode.signUp:
        final result = await notifier.signUp();
        if (result.isSuccess && mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const PersonalizationScreen(),
            ),
          );
        }
        break;
      case AuthMode.forgotPassword:
        await notifier.sendPasswordReset();
        break;
    }
  }

  Future<void> _socialSignIn(Future<AuthResult> Function() method) async {
    HapticFeedback.mediumImpact();
    final result = await method();
    if (result.isSuccess && mounted) {
      if (result.isNewUser) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const PersonalizationScreen(),
          ),
        );
      }
      // Otherwise auth state listener handles navigation
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(authFormProvider);
    final screenSize = MediaQuery.of(context).size;
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: DribaColors.background,
      body: Stack(
        children: [
          // Animated background orbs
          _AnimatedBackground(controller: _bgController),

          // Content
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: screenSize.height),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    DribaSpacing.xl, topPad + DribaSpacing.huge, DribaSpacing.xl, DribaSpacing.xxxl),
                child: FadeTransition(
                  opacity: _formFade,
                  child: SlideTransition(
                    position: _formSlide,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Logo + title
                        _buildHeader(form.mode),

                        const SizedBox(height: DribaSpacing.xxxl),

                        // Form card
                        _buildFormCard(form),

                        const SizedBox(height: DribaSpacing.xl),

                        // Social sign-in
                        if (form.mode != AuthMode.forgotPassword)
                          _buildSocialButtons(form),

                        const SizedBox(height: DribaSpacing.xxl),

                        // Mode switch
                        _buildModeSwitch(form.mode),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────
  Widget _buildHeader(AuthMode mode) {
    final title = switch (mode) {
      AuthMode.login => 'Welcome\nBack',
      AuthMode.signUp => 'Create\nAccount',
      AuthMode.forgotPassword => 'Reset\nPassword',
    };
    final subtitle = switch (mode) {
      AuthMode.login => 'Sign in to your Driba world',
      AuthMode.signUp => 'Join the next generation of social',
      AuthMode.forgotPassword => 'We\'ll send you a reset link',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Driba logo mark
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: DribaColors.primaryGradient,
            borderRadius: BorderRadius.circular(DribaBorderRadius.md),
            boxShadow: DribaShadows.primaryGlow,
          ),
          child: const Center(
            child: Text(
              'D',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(height: DribaSpacing.xxl),
        Text(
          title,
          style: const TextStyle(
            color: DribaColors.textPrimary,
            fontSize: 40,
            fontWeight: FontWeight.w800,
            height: 1.1,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: DribaSpacing.md),
        Text(
          subtitle,
          style: TextStyle(
            color: DribaColors.textTertiary,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  // ── Form Card ───────────────────────────────
  Widget _buildFormCard(AuthFormState form) {
    return GlassContainer(
      padding: const EdgeInsets.all(DribaSpacing.xl),
      borderRadius: BorderRadius.circular(DribaBorderRadius.xxl),
      child: Column(
        children: [
          // Name field (sign up only)
          if (form.mode == AuthMode.signUp) ...[
            _GlassTextField(
              hint: 'Full name',
              icon: Icons.person_outline,
              value: form.displayName,
              focusNode: _nameFocus,
              textInputAction: TextInputAction.next,
              onChanged: ref.read(authFormProvider.notifier).setDisplayName,
              onSubmitted: (_) => _emailFocus.requestFocus(),
              accent: _accent,
            ),
            const SizedBox(height: DribaSpacing.lg),
          ],

          // Email field
          _GlassTextField(
            hint: 'Email',
            icon: Icons.email_outlined,
            value: form.email,
            focusNode: _emailFocus,
            keyboardType: TextInputType.emailAddress,
            textInputAction: form.mode == AuthMode.forgotPassword
                ? TextInputAction.done
                : TextInputAction.next,
            onChanged: ref.read(authFormProvider.notifier).setEmail,
            onSubmitted: (_) {
              if (form.mode == AuthMode.forgotPassword) {
                _submit();
              } else {
                _passwordFocus.requestFocus();
              }
            },
            accent: _accent,
            isValid: form.email.isEmpty ? null : form.isEmailValid,
          ),

          // Password field (not for forgot password)
          if (form.mode != AuthMode.forgotPassword) ...[
            const SizedBox(height: DribaSpacing.lg),
            _GlassTextField(
              hint: 'Password',
              icon: Icons.lock_outlined,
              value: form.password,
              focusNode: _passwordFocus,
              isPassword: true,
              isPasswordVisible: form.isPasswordVisible,
              onTogglePassword:
                  ref.read(authFormProvider.notifier).togglePasswordVisibility,
              textInputAction: TextInputAction.done,
              onChanged: ref.read(authFormProvider.notifier).setPassword,
              onSubmitted: (_) => _submit(),
              accent: _accent,
            ),
          ],

          // Password strength (sign up only)
          if (form.mode == AuthMode.signUp && form.password.isNotEmpty) ...[
            const SizedBox(height: DribaSpacing.md),
            _PasswordStrengthBar(
              strength: form.passwordStrength,
              label: form.passwordStrengthLabel,
              accent: _accent,
            ),
          ],

          // Forgot password link
          if (form.mode == AuthMode.login) ...[
            const SizedBox(height: DribaSpacing.md),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => _switchMode(AuthMode.forgotPassword),
                child: Text(
                  'Forgot password?',
                  style: TextStyle(
                    color: _accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],

          // Error / Success message
          if (form.errorMessage != null) ...[
            const SizedBox(height: DribaSpacing.lg),
            _MessageBanner(
              text: form.errorMessage!,
              isError: true,
            ),
          ],
          if (form.successMessage != null) ...[
            const SizedBox(height: DribaSpacing.lg),
            _MessageBanner(
              text: form.successMessage!,
              isError: false,
            ),
          ],

          const SizedBox(height: DribaSpacing.xl),

          // Submit button
          _buildSubmitButton(form),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(AuthFormState form) {
    final canSubmit = switch (form.mode) {
      AuthMode.login => form.canSubmitLogin,
      AuthMode.signUp => form.canSubmitSignUp,
      AuthMode.forgotPassword => form.canSubmitReset,
    };
    final label = switch (form.mode) {
      AuthMode.login => 'Sign In',
      AuthMode.signUp => 'Create Account',
      AuthMode.forgotPassword => 'Send Reset Link',
    };

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: GestureDetector(
        onTap: canSubmit ? _submit : null,
        child: AnimatedContainer(
          duration: DribaDurations.fast,
          decoration: BoxDecoration(
            gradient: canSubmit ? DribaColors.primaryGradient : null,
            color: canSubmit ? null : DribaColors.glassFillActive,
            borderRadius: BorderRadius.circular(DribaBorderRadius.pill),
            boxShadow: canSubmit ? DribaShadows.primaryGlow : null,
          ),
          child: Center(
            child: form.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    label,
                    style: TextStyle(
                      color: canSubmit
                          ? Colors.white
                          : DribaColors.textDisabled,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // ── Social Buttons ──────────────────────────
  Widget _buildSocialButtons(AuthFormState form) {
    final notifier = ref.read(authFormProvider.notifier);

    return Column(
      children: [
        // Divider
        Row(
          children: [
            Expanded(
              child: Container(height: 1, color: DribaColors.glassBorder),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: DribaSpacing.lg),
              child: Text(
                'or continue with',
                style: TextStyle(
                  color: DribaColors.textTertiary,
                  fontSize: 13,
                ),
              ),
            ),
            Expanded(
              child: Container(height: 1, color: DribaColors.glassBorder),
            ),
          ],
        ),
        const SizedBox(height: DribaSpacing.xl),

        // Social row
        Row(
          children: [
            Expanded(
              child: _SocialButton(
                label: 'Google',
                icon: Icons.g_mobiledata_rounded,
                iconSize: 28,
                onTap: form.isLoading
                    ? null
                    : () => _socialSignIn(notifier.googleSignIn),
              ),
            ),
            const SizedBox(width: DribaSpacing.md),
            Expanded(
              child: _SocialButton(
                label: 'Apple',
                icon: Icons.apple,
                onTap: form.isLoading
                    ? null
                    : () => _socialSignIn(notifier.appleSignIn),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Mode Switch ─────────────────────────────
  Widget _buildModeSwitch(AuthMode mode) {
    return Center(
      child: mode == AuthMode.forgotPassword
          ? GestureDetector(
              onTap: () => _switchMode(AuthMode.login),
              child: Text.rich(
                TextSpan(
                  text: 'Back to ',
                  style: TextStyle(color: DribaColors.textTertiary, fontSize: 14),
                  children: [
                    TextSpan(
                      text: 'Sign In',
                      style: TextStyle(
                        color: _accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : GestureDetector(
              onTap: () => _switchMode(
                mode == AuthMode.login ? AuthMode.signUp : AuthMode.login,
              ),
              child: Text.rich(
                TextSpan(
                  text: mode == AuthMode.login
                      ? 'Don\'t have an account? '
                      : 'Already have an account? ',
                  style: TextStyle(color: DribaColors.textTertiary, fontSize: 14),
                  children: [
                    TextSpan(
                      text: mode == AuthMode.login ? 'Sign Up' : 'Sign In',
                      style: TextStyle(
                        color: _accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// ============================================
// GLASS TEXT FIELD
// ============================================

class _GlassTextField extends StatelessWidget {
  final String hint;
  final IconData icon;
  final String value;
  final FocusNode? focusNode;
  final bool isPassword;
  final bool isPasswordVisible;
  final VoidCallback? onTogglePassword;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Color accent;
  final bool? isValid; // null = no indicator

  const _GlassTextField({
    required this.hint,
    required this.icon,
    required this.value,
    this.focusNode,
    this.isPassword = false,
    this.isPasswordVisible = false,
    this.onTogglePassword,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    required this.accent,
    this.isValid,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DribaColors.glassFill,
        borderRadius: BorderRadius.circular(DribaBorderRadius.lg),
        border: Border.all(
          color: isValid == true
              ? DribaColors.success.withOpacity(0.5)
              : isValid == false
                  ? DribaColors.error.withOpacity(0.5)
                  : DribaColors.glassBorder,
        ),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: DribaSpacing.lg),
            child: Icon(icon, color: DribaColors.textTertiary, size: 20),
          ),
          Expanded(
            child: TextField(
              focusNode: focusNode,
              obscureText: isPassword && !isPasswordVisible,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              style: const TextStyle(
                color: DribaColors.textPrimary,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: DribaColors.textDisabled),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: DribaSpacing.md,
                  vertical: DribaSpacing.lg,
                ),
              ),
              onChanged: onChanged,
              onSubmitted: onSubmitted,
            ),
          ),
          if (isPassword)
            GestureDetector(
              onTap: onTogglePassword,
              child: Padding(
                padding: const EdgeInsets.only(right: DribaSpacing.lg),
                child: Icon(
                  isPasswordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: DribaColors.textTertiary,
                  size: 20,
                ),
              ),
            ),
          if (isValid != null && !isPassword)
            Padding(
              padding: const EdgeInsets.only(right: DribaSpacing.lg),
              child: Icon(
                isValid! ? Icons.check_circle : Icons.cancel,
                color: isValid!
                    ? DribaColors.success
                    : DribaColors.error.withOpacity(0.5),
                size: 18,
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================
// PASSWORD STRENGTH BAR
// ============================================

class _PasswordStrengthBar extends StatelessWidget {
  final int strength;
  final String label;
  final Color accent;

  const _PasswordStrengthBar({
    required this.strength,
    required this.label,
    required this.accent,
  });

  Color get _color {
    if (strength <= 1) return DribaColors.error;
    if (strength <= 2) return DribaColors.warning;
    if (strength <= 3) return accent;
    return DribaColors.success;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: List.generate(5, (i) {
            return Expanded(
              child: Container(
                height: 3,
                margin: EdgeInsets.only(right: i < 4 ? 4 : 0),
                decoration: BoxDecoration(
                  color: i < strength ? _color : DribaColors.glassFillActive,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(height: DribaSpacing.xs),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              label,
              style: TextStyle(
                color: _color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ============================================
// MESSAGE BANNER
// ============================================

class _MessageBanner extends StatelessWidget {
  final String text;
  final bool isError;

  const _MessageBanner({required this.text, required this.isError});

  @override
  Widget build(BuildContext context) {
    final color = isError ? DribaColors.error : DribaColors.success;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DribaSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(DribaBorderRadius.md),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: color,
            size: 18,
          ),
          const SizedBox(width: DribaSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// SOCIAL BUTTON
// ============================================

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final double iconSize;
  final VoidCallback? onTap;

  const _SocialButton({
    required this.label,
    required this.icon,
    this.iconSize = 22,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        vertical: DribaSpacing.md,
      ),
      borderRadius: BorderRadius.circular(DribaBorderRadius.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: DribaColors.textPrimary, size: iconSize),
          const SizedBox(width: DribaSpacing.sm),
          Text(
            label,
            style: const TextStyle(
              color: DribaColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// ANIMATED BACKGROUND
// Floating gradient orbs
// ============================================

class _AnimatedBackground extends StatelessWidget {
  final AnimationController controller;

  const _AnimatedBackground({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Stack(
          children: [
            _orb(
              top: -80,
              right: -60,
              size: 250,
              color: DribaColors.primary.withOpacity(0.08),
              phase: 0,
            ),
            _orb(
              bottom: 200,
              left: -100,
              size: 300,
              color: DribaColors.secondary.withOpacity(0.06),
              phase: 0.33,
            ),
            _orb(
              bottom: -50,
              right: -40,
              size: 200,
              color: DribaColors.tertiary.withOpacity(0.06),
              phase: 0.66,
            ),
          ],
        );
      },
    );
  }

  Widget _orb({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
    required Color color,
    required double phase,
  }) {
    final t = (controller.value + phase) % 1.0;
    final dx = math.sin(t * 2 * math.pi) * 20;
    final dy = math.cos(t * 2 * math.pi) * 15;

    return Positioned(
      top: top != null ? top + dy : null,
      bottom: bottom != null ? bottom + dy : null,
      left: left != null ? left + dx : null,
      right: right != null ? right + dx : null,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withOpacity(0)],
          ),
        ),
      ),
    );
  }
}
