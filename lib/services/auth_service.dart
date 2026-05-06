import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream pro sledování stavu přihlášení
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Aktuální uživatel
  User? get currentUser => _auth.currentUser;

  // Registrace
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Přihlášení
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Odhlášení
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Reset hesla
  Future<void> resetPassword({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Smazání účtu
  Future<void> deleteAccount() async {
    await _auth.currentUser?.delete();
  }
}
