import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';

// ============================================
// AUTH PROVIDERS
//
// State management for the entire auth flow:
// service, auth state, form state, loading.
// ============================================

// ── Service ─────────────────────────────────

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// ── Auth State Stream ───────────────────────

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// ── Onboarding Check ────────────────────────

final hasCompletedOnboardingProvider = FutureProvider<bool>((ref) async {
  final auth = ref.watch(authStateProvider);
  return auth.when(
    data: (user) async {
      if (user == null) return false;
      final service = ref.read(authServiceProvider);
      return service.hasCompletedOnboarding();
    },
    loading: () => false,
    error: (_, __) => false,
  );
});

// ── Auth Flow State ─────────────────────────

enum AuthMode { login, signUp, forgotPassword }

class AuthFormState {
  final AuthMode mode;
  final String email;
  final String password;
  final String displayName;
  final bool isLoading;
  final bool isPasswordVisible;
  final String? errorMessage;
  final String? successMessage;

  const AuthFormState({
    this.mode = AuthMode.login,
    this.email = '',
    this.password = '',
    this.displayName = '',
    this.isLoading = false,
    this.isPasswordVisible = false,
    this.errorMessage,
    this.successMessage,
  });

  AuthFormState copyWith({
    AuthMode? mode,
    String? email,
    String? password,
    String? displayName,
    bool? isLoading,
    bool? isPasswordVisible,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return AuthFormState(
      mode: mode ?? this.mode,
      email: email ?? this.email,
      password: password ?? this.password,
      displayName: displayName ?? this.displayName,
      isLoading: isLoading ?? this.isLoading,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  // ── Validation ──────────────────────────────

  bool get isEmailValid =>
      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(email);

  bool get isPasswordValid => password.length >= 6;

  bool get isNameValid => displayName.trim().length >= 2;

  bool get canSubmitLogin => isEmailValid && isPasswordValid && !isLoading;

  bool get canSubmitSignUp =>
      isEmailValid && isPasswordValid && isNameValid && !isLoading;

  bool get canSubmitReset => isEmailValid && !isLoading;

  // ── Password Strength ───────────────────────

  int get passwordStrength {
    if (password.isEmpty) return 0;
    int score = 0;
    if (password.length >= 6) score++;
    if (password.length >= 10) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) score++;
    return score; // 0-5
  }

  String get passwordStrengthLabel {
    switch (passwordStrength) {
      case 0: return '';
      case 1: return 'Weak';
      case 2: return 'Fair';
      case 3: return 'Good';
      case 4: return 'Strong';
      case 5: return 'Excellent';
      default: return '';
    }
  }
}

class AuthFormNotifier extends StateNotifier<AuthFormState> {
  final AuthService _service;

  AuthFormNotifier(this._service) : super(const AuthFormState());

  void setMode(AuthMode mode) {
    state = state.copyWith(mode: mode, clearError: true, clearSuccess: true);
  }

  void setEmail(String email) {
    state = state.copyWith(email: email, clearError: true);
  }

  void setPassword(String password) {
    state = state.copyWith(password: password, clearError: true);
  }

  void setDisplayName(String name) {
    state = state.copyWith(displayName: name, clearError: true);
  }

  void togglePasswordVisibility() {
    state = state.copyWith(isPasswordVisible: !state.isPasswordVisible);
  }

  /// Email/password login
  Future<AuthResult> login() async {
    if (!state.canSubmitLogin) return AuthResult.failure('Invalid input');

    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _service.signInWithEmail(
      email: state.email.trim(),
      password: state.password,
    );

    if (result.isSuccess) {
      state = state.copyWith(isLoading: false);
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.errorMessage,
      );
    }
    return result;
  }

  /// Email/password sign up
  Future<AuthResult> signUp() async {
    if (!state.canSubmitSignUp) return AuthResult.failure('Invalid input');

    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _service.signUpWithEmail(
      email: state.email.trim(),
      password: state.password,
      displayName: state.displayName.trim(),
    );

    if (result.isSuccess) {
      state = state.copyWith(isLoading: false);
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.errorMessage,
      );
    }
    return result;
  }

  /// Google sign-in
  Future<AuthResult> googleSignIn() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _service.signInWithGoogle();

    state = state.copyWith(isLoading: false);
    if (!result.isSuccess) {
      state = state.copyWith(errorMessage: result.errorMessage);
    }
    return result;
  }

  /// Apple sign-in
  Future<AuthResult> appleSignIn() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _service.signInWithApple();

    state = state.copyWith(isLoading: false);
    if (!result.isSuccess) {
      state = state.copyWith(errorMessage: result.errorMessage);
    }
    return result;
  }

  /// Password reset
  Future<void> sendPasswordReset() async {
    if (!state.canSubmitReset) return;

    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);

    final result = await _service.sendPasswordReset(state.email.trim());

    state = state.copyWith(
      isLoading: false,
      successMessage: result.isSuccess ? result.message : null,
      errorMessage: result.isSuccess ? null : result.errorMessage,
    );
  }
}

final authFormProvider =
    StateNotifierProvider<AuthFormNotifier, AuthFormState>((ref) {
  final service = ref.watch(authServiceProvider);
  return AuthFormNotifier(service);
});

// ── Personalization State ───────────────────

class PersonalizationState {
  final int currentStep; // 0: screens, 1: interests, 2: profile
  final List<String> selectedScreens;
  final List<String> selectedInterests;
  final bool isLoading;

  const PersonalizationState({
    this.currentStep = 0,
    this.selectedScreens = const [],
    this.selectedInterests = const [],
    this.isLoading = false,
  });

  PersonalizationState copyWith({
    int? currentStep,
    List<String>? selectedScreens,
    List<String>? selectedInterests,
    bool? isLoading,
  }) {
    return PersonalizationState(
      currentStep: currentStep ?? this.currentStep,
      selectedScreens: selectedScreens ?? this.selectedScreens,
      selectedInterests: selectedInterests ?? this.selectedInterests,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class PersonalizationNotifier extends StateNotifier<PersonalizationState> {
  final AuthService _service;

  PersonalizationNotifier(this._service) : super(const PersonalizationState());

  void toggleScreen(String screenId) {
    final screens = List<String>.from(state.selectedScreens);
    if (screens.contains(screenId)) {
      screens.remove(screenId);
    } else {
      screens.add(screenId);
    }
    state = state.copyWith(selectedScreens: screens);
  }

  void toggleInterest(String interest) {
    final interests = List<String>.from(state.selectedInterests);
    if (interests.contains(interest)) {
      interests.remove(interest);
    } else {
      interests.add(interest);
    }
    state = state.copyWith(selectedInterests: interests);
  }

  void nextStep() {
    if (state.currentStep < 2) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void prevStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  Future<void> complete() async {
    state = state.copyWith(isLoading: true);
    await _service.completeOnboarding(
      selectedScreens:
          state.selectedScreens.isEmpty ? ['feed', 'food', 'commerce', 'learn'] : state.selectedScreens,
      interests: state.selectedInterests,
    );
    state = state.copyWith(isLoading: false);
  }
}

final personalizationProvider =
    StateNotifierProvider<PersonalizationNotifier, PersonalizationState>((ref) {
  final service = ref.watch(authServiceProvider);
  return PersonalizationNotifier(service);
});
