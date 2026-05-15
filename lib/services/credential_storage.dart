import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum AuthMethod { email, google, apple }

class CredentialStorage {
  static const _emailKey = 'qrkni_email';
  static const _passwordKey = 'qrkni_password';
  static const _authMethodKey = 'qrkni_auth_method';
  static const _biometricEnabledKey = 'qrkni_biometric_enabled';

  final _storage = const FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<void> save(String email, String password) async {
    await _storage.write(key: _emailKey, value: email);
    await _storage.write(key: _passwordKey, value: password);
    await _storage.write(key: _authMethodKey, value: AuthMethod.email.name);
  }

  Future<void> markGoogleAuth() async {
    await _storage.write(key: _authMethodKey, value: AuthMethod.google.name);
    await _storage.delete(key: _emailKey);
    await _storage.delete(key: _passwordKey);
  }

  Future<void> markAppleAuth() async {
    await _storage.write(key: _authMethodKey, value: AuthMethod.apple.name);
    await _storage.delete(key: _emailKey);
    await _storage.delete(key: _passwordKey);
  }

  Future<AuthMethod?> getAuthMethod() async {
    final raw = await _storage.read(key: _authMethodKey);
    if (raw == null) return null;
    return AuthMethod.values.firstWhere(
      (m) => m.name == raw,
      orElse: () => AuthMethod.email,
    );
  }

  Future<({String email, String password})?> read() async {
    final email = await _storage.read(key: _emailKey);
    final password = await _storage.read(key: _passwordKey);
    if (email == null || password == null) return null;
    return (email: email, password: password);
  }

  Future<bool> isBiometricEnabled() async =>
      await _storage.read(key: _biometricEnabledKey) == 'true';

  Future<void> setBiometricEnabled(bool enabled) async {
    if (enabled) {
      await _storage.write(key: _biometricEnabledKey, value: 'true');
    } else {
      await _storage.delete(key: _biometricEnabledKey);
    }
  }

  Future<void> clear() async {
    await _storage.delete(key: _emailKey);
    await _storage.delete(key: _passwordKey);
    await _storage.delete(key: _authMethodKey);
    await _storage.delete(key: _biometricEnabledKey);
  }

  /// True pokud je uloženo cokoliv, čím lze biometricky obnovit přihlášení
  /// (email creds nebo google flag).
  Future<bool> hasCredentials() async {
    final method = await getAuthMethod();
    if (method == null) return false;
    if (method == AuthMethod.email) {
      final email = await _storage.read(key: _emailKey);
      return email != null;
    }
    return true; // Google — silent sign-in se pokusí obnovit session
  }

  // ── Worker device ────────────────────────────────────────────────────────

  static const _workerDeviceKey = 'qrkni_worker_device';
  static const _workerOwnerIdKey = 'qrkni_worker_owner_id';
  static const _workerNameKey = 'qrkni_worker_name';
  static const _workerPinHashKey = 'qrkni_worker_pin_hash';

  Future<bool> isWorkerDevice() async =>
      await _storage.read(key: _workerDeviceKey) == 'true';

  Future<String?> getWorkerOwnerId() =>
      _storage.read(key: _workerOwnerIdKey);

  Future<String?> getWorkerName() =>
      _storage.read(key: _workerNameKey);

  Future<String?> getWorkerPinHash() =>
      _storage.read(key: _workerPinHashKey);

  Future<void> pairAsWorkerDevice({
    required String ownerUserId,
    required String workerName,
    required String pinHash,
  }) async {
    await _storage.write(key: _workerDeviceKey, value: 'true');
    await _storage.write(key: _workerOwnerIdKey, value: ownerUserId);
    await _storage.write(key: _workerNameKey, value: workerName);
    await _storage.write(key: _workerPinHashKey, value: pinHash);
  }

  Future<void> unpairWorkerDevice() async {
    await _storage.delete(key: _workerDeviceKey);
    await _storage.delete(key: _workerOwnerIdKey);
    await _storage.delete(key: _workerNameKey);
    await _storage.delete(key: _workerPinHashKey);
  }
}
