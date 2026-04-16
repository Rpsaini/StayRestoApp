import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Stream<User?> get userStream => _auth.authStateChanges();

  static User? get currentUser => _auth.currentUser;

  static Future<AuthResult> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      await credential.user?.sendEmailVerification();
      return AuthResult(
        success: true,
        message: 'Account created! Please verify your email.',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, message: _errorMessage(e.code));
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Something went wrong. Try again.',
      );
    }
  }

  static Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user != null && !user.emailVerified) {
        await _auth.signOut();
        return AuthResult(
          success: false,
          message: 'Email not verified. Please check your inbox.',
          needsVerification: true,
        );
      }
      return AuthResult(success: true, message: 'Welcome back!');
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, message: _errorMessage(e.code));
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Something went wrong. Try again.',
      );
    }
  }

  static Future<AuthResult> resendVerificationEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await credential.user?.sendEmailVerification();
      await _auth.signOut();
      return AuthResult(success: true, message: 'Verification email sent!');
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, message: _errorMessage(e.code));
    }
  }

  static Future<AuthResult> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return AuthResult(success: true, message: 'Password reset email sent!');
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, message: _errorMessage(e.code));
    }
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  static String _errorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}

class AuthResult {
  final bool success;
  final String message;
  final bool needsVerification;

  AuthResult({
    required this.success,
    required this.message,
    this.needsVerification = false,
  });
}
