import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'firestore_service.dart';

/// Vyhazována, když e-mail již existuje pod jiným poskytovatelem.
/// Obsahuje čekající credential pro následné propojení účtů.
class AccountExistsException implements Exception {
  final String email;
  final AuthCredential pendingCredential;

  const AccountExistsException({
    required this.email,
    required this.pendingCredential,
  });
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final _firestoreService = FirestoreService();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signUp({
    required String email,
    required String password,
    DateTime? termsAcceptedAt,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _firestoreService.saveUser(
      uid: credential.user!.uid,
      email: email,
      isNewUser: true,
      termsAcceptedAt: termsAcceptedAt,
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
    try {
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user != null) {
        final isNew = userCredential.additionalUserInfo?.isNewUser ?? false;
        await _firestoreService.saveUser(
          uid: user.uid,
          email: user.email ?? '',
          isNewUser: isNew,
          termsAcceptedAt: isNew ? DateTime.now() : null,
        );
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        throw AccountExistsException(
          email: e.email ?? googleUser.email,
          pendingCredential: credential,
        );
      }
      rethrow;
    }
  }

  Future<UserCredential?> signInWithApple() async {
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );
    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );
    try {
      final userCredential = await _auth.signInWithCredential(oauthCredential);
      final user = userCredential.user;
      if (user != null) {
        final isNew = userCredential.additionalUserInfo?.isNewUser ?? false;
        await _firestoreService.saveUser(
          uid: user.uid,
          email: user.email ?? appleCredential.email ?? '',
          isNewUser: isNew,
          termsAcceptedAt: isNew ? DateTime.now() : null,
        );
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        throw AccountExistsException(
          email: e.email ?? appleCredential.email ?? '',
          pendingCredential: oauthCredential,
        );
      }
      rethrow;
    }
  }

  /// Přihlásí e-mailem a heslem a okamžitě propojí čekající OAuth credential.
  /// Používá se po zachycení [AccountExistsException].
  Future<void> signInAndLink({
    required String email,
    required String password,
    required AuthCredential pendingCredential,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await cred.user!.linkWithCredential(pendingCredential);
    await _firestoreService.saveUser(uid: cred.user!.uid, email: email);
  }

  // Odhlášení — Firebase session zruší, ale Google session ponechá zacachovanou,
  // aby `signInWithGoogleSilent()` po Face ID dokázal session obnovit. Pro plné
  // odpojení Google účtu volej `disconnectGoogle()`.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Plně odpojí Google účet od aplikace (revokuje OAuth grant). Používej
  /// pouze, když chce uživatel skutečně přepnout / zapomenout Google účet.
  Future<void> disconnectGoogle() async {
    try {
      await _googleSignIn.disconnect();
    } catch (_) {
      await _googleSignIn.signOut();
    }
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
