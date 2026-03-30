import 'package:flutter/material.dart';
import '../model/user/app_user.dart';

class AuthProvider with ChangeNotifier {
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
}
