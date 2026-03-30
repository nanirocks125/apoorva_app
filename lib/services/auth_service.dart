import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth;

  // Inject the instance via the constructor
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
