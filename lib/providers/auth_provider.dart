import 'package:apoorva_app/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../model/user/app_user.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated }

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth;
  final UserService _userService;

  AppUser? _user;
  AuthStatus _status = AuthStatus.initial;

  AuthProvider({FirebaseAuth? auth, UserService? userService})
    : _auth = auth ?? FirebaseAuth.instance,
      _userService = userService ?? UserService() {
    // Automatically check for existing session on startup
    _initialize();
  }

  // Getters
  AppUser? get user => _user;
  AuthStatus get status => _status;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  /// Check if a user is already signed in when the app starts
  Future<void> _initialize() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      await _fetchAndSetUserProfile(firebaseUser.uid);
    } else {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  /// Helper to fetch profile and update state
  Future<void> _fetchAndSetUserProfile(String uid) async {
    try {
      final profile = await _userService.getUserById(uid);
      if (profile != null) {
        _user = profile;
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (_) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final profile = await _userService.getUserById(credential.user!.uid);

      if (profile == null) {
        await logout(); // Clean up if no profile exists
        throw 'User profile not found. Please contact support.';
      }

      _user = profile;
      _status = AuthStatus.authenticated;
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      throw _determineError(e.code);
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      throw 'An unexpected error occurred.';
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  String _determineError(String errorCode) {
    switch (errorCode) {
      case 'invalid-email':
        return 'The email address is badly formatted.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Try again later.';
      default:
        return 'An unknown authentication error occurred.';
    }
  }
}
