import 'package:apoorva_app/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../model/user/app_user.dart';

class AuthProvider with ChangeNotifier {
  // Add these fields
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  AppUser? _user;

  AppUser? get user => _user;
  bool get isAuthenticated => _user != null;

  void setUser(AppUser user) {
    _user = user;
    notifyListeners(); // This notifies all screens to update
  }

  void logout() {
    _user = null;
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final AppUser? user = await _userService.getUserById(
        credential.user!.uid,
      );

      if (user == null) {
        // If profile doesn't exist, sign them out immediately
        await _auth.signOut();
        throw 'User profile not found. Please contact support.';
      }

      _user = user;
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      throw _determineError(e.code);
    } catch (e) {
      // Catch-all for database errors or null pointers
      throw e.toString();
    }
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
