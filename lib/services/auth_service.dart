import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _firestoreService = FirestoreService();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _firestoreService.saveUser(
      uid: credential.user!.uid,
      email: email,
      isNewUser: true,
    );
    return credential;
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _firestoreService.saveUser(
      uid: credential.user!.uid,
      email: email,
    );
    return credential;
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
