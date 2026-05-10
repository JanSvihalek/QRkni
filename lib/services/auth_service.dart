import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
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

  // Přihlášení přes Google
  Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    return _signInWithGoogleAccount(googleUser);
  }

  /// Pokus o tiché obnovení Google session bez UI — vrátí null, pokud session
  /// vypršela a vyžaduje interaktivní login.
  Future<UserCredential?> signInWithGoogleSilent() async {
    final googleUser = await _googleSignIn.signInSilently();
    return _signInWithGoogleAccount(googleUser);
  }

  Future<UserCredential?> _signInWithGoogleAccount(
    GoogleSignInAccount? googleUser,
  ) async {
    if (googleUser == null) return null;
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user != null) {
      await _firestoreService.saveUser(
        uid: user.uid,
        email: user.email ?? '',
        isNewUser: userCredential.additionalUserInfo?.isNewUser ?? false,
      );
    }
    return userCredential;
  }

  // Odhlášení
  Future<void> signOut() async {
    await _googleSignIn.signOut();
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
