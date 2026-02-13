import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../shared/models/models.dart';

// ============================================
// AUTH SERVICE
//
// Firebase Authentication wrapper.
// Supports: email/password, Google, Apple.
// Auto-creates Firestore user profile on first sign-up.
//
// 0% platform fees — users keep everything.
// ============================================

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final GoogleSignIn _googleSignIn;

  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  // ── Getters ─────────────────────────────────

  User? get currentUser => _auth.currentUser;
  String? get uid => _auth.currentUser?.uid;
  bool get isLoggedIn => _auth.currentUser != null;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ============================================
  // EMAIL / PASSWORD
  // ============================================

  /// Sign up with email and password
  /// Creates user doc in Firestore after registration
  Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) return AuthResult.failure('Account creation failed');

      // Set display name
      await user.updateDisplayName(displayName);

      // Create Firestore profile
      await _createUserProfile(
        uid: user.uid,
        email: email,
        displayName: displayName,
        photoUrl: null,
        provider: 'email',
      );

      return AuthResult.success(user);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapAuthError(e.code));
    } catch (e) {
      return AuthResult.failure('Something went wrong. Please try again.');
    }
  }

  /// Sign in with email and password
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) return AuthResult.failure('Sign in failed');

      // Update last seen
      await _updateLastSeen(user.uid);

      return AuthResult.success(user);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapAuthError(e.code));
    } catch (e) {
      return AuthResult.failure('Something went wrong. Please try again.');
    }
  }

  /// Send password reset email
  Future<AuthResult> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return AuthResult.success(null, message: 'Reset link sent to $email');
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapAuthError(e.code));
    } catch (e) {
      return AuthResult.failure('Could not send reset email.');
    }
  }

  // ============================================
  // GOOGLE SIGN-IN
  // ============================================

  Future<AuthResult> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return AuthResult.failure('Google sign-in cancelled');
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) return AuthResult.failure('Google sign-in failed');

      // Check if user profile exists
      final exists = await _userExists(user.uid);
      if (!exists) {
        await _createUserProfile(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? googleUser.displayName ?? 'User',
          photoUrl: user.photoURL ?? googleUser.photoUrl,
          provider: 'google',
        );
        return AuthResult.success(user, isNewUser: true);
      }

      await _updateLastSeen(user.uid);
      return AuthResult.success(user);
    } catch (e) {
      return AuthResult.failure('Google sign-in failed. Please try again.');
    }
  }

  // ============================================
  // APPLE SIGN-IN
  // ============================================

  Future<AuthResult> signInWithApple() async {
    try {
      final appleProvider = AppleAuthProvider()
        ..addScope('email')
        ..addScope('name');

      final userCredential = await _auth.signInWithProvider(appleProvider);
      final user = userCredential.user;
      if (user == null) return AuthResult.failure('Apple sign-in failed');

      final exists = await _userExists(user.uid);
      if (!exists) {
        await _createUserProfile(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? 'User',
          photoUrl: user.photoURL,
          provider: 'apple',
        );
        return AuthResult.success(user, isNewUser: true);
      }

      await _updateLastSeen(user.uid);
      return AuthResult.success(user);
    } catch (e) {
      return AuthResult.failure('Apple sign-in failed. Please try again.');
    }
  }

  // ============================================
  // SIGN OUT
  // ============================================

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  // ============================================
  // PROFILE MANAGEMENT
  // ============================================

  /// Check if user document exists
  Future<bool> _userExists(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists;
  }

  /// Check if current user has completed onboarding
  Future<bool> hasCompletedOnboarding() async {
    if (uid == null) return false;
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return false;
    return doc.data()?['onboardingComplete'] == true;
  }

  /// Create initial Firestore user profile
  Future<void> _createUserProfile({
    required String uid,
    required String email,
    required String displayName,
    String? photoUrl,
    required String provider,
  }) async {
    await _db.collection('users').doc(uid).set({
      'displayName': displayName,
      'username': _generateUsername(displayName),
      'email': email,
      'avatarUrl': photoUrl,
      'bio': null,
      'isVerified': false,
      'isPro': false,
      'provider': provider,
      'enabledScreens': ['feed', 'food', 'commerce', 'learn'],
      'interests': [],
      'onboardingComplete': false,
      'stats': {
        'followersCount': 0,
        'followingCount': 0,
        'postsCount': 0,
      },
      'settings': {
        'theme': 'dark',
        'language': 'en',
        'notifications': true,
        'pushTokens': [],
      },
      'createdAt': FieldValue.serverTimestamp(),
      'lastSeenAt': FieldValue.serverTimestamp(),
    });
  }

  /// Generate a username from display name
  String _generateUsername(String displayName) {
    final base = displayName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '')
        .substring(0, displayName.length.clamp(0, 15));
    final suffix = DateTime.now().millisecondsSinceEpoch % 10000;
    return '${base}_$suffix';
  }

  /// Update last seen timestamp
  Future<void> _updateLastSeen(String uid) async {
    await _db.collection('users').doc(uid).update({
      'lastSeenAt': FieldValue.serverTimestamp(),
    });
  }

  /// Complete onboarding
  Future<void> completeOnboarding({
    required List<String> selectedScreens,
    required List<String> interests,
  }) async {
    if (uid == null) return;
    await _db.collection('users').doc(uid).update({
      'enabledScreens': selectedScreens,
      'interests': interests,
      'onboardingComplete': true,
    });
  }

  /// Update profile
  Future<void> updateProfile({
    String? displayName,
    String? bio,
    String? avatarUrl,
    String? username,
  }) async {
    if (uid == null) return;
    final updates = <String, dynamic>{};
    if (displayName != null) updates['displayName'] = displayName;
    if (bio != null) updates['bio'] = bio;
    if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;
    if (username != null) updates['username'] = username;
    if (updates.isNotEmpty) {
      await _db.collection('users').doc(uid).update(updates);
    }
  }

  // ============================================
  // ERROR MAPPING
  // ============================================

  String _mapAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Try again or reset it.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment.';
      case 'network-request-failed':
        return 'No internet connection. Check your network.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}

// ============================================
// AUTH RESULT
// ============================================

class AuthResult {
  final bool isSuccess;
  final User? user;
  final String? errorMessage;
  final String? message;
  final bool isNewUser;

  const AuthResult._({
    required this.isSuccess,
    this.user,
    this.errorMessage,
    this.message,
    this.isNewUser = false,
  });

  factory AuthResult.success(User? user, {bool isNewUser = false, String? message}) =>
      AuthResult._(isSuccess: true, user: user, isNewUser: isNewUser, message: message);

  factory AuthResult.failure(String error) =>
      AuthResult._(isSuccess: false, errorMessage: error);
}
