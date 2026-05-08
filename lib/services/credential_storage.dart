import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CredentialStorage {
  static const _emailKey = 'qrkni_email';
  static const _passwordKey = 'qrkni_password';

  final _storage = const FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<void> save(String email, String password) async {
    await _storage.write(key: _emailKey, value: email);
    await _storage.write(key: _passwordKey, value: password);
  }

  Future<({String email, String password})?> read() async {
    final email = await _storage.read(key: _emailKey);
    final password = await _storage.read(key: _passwordKey);
    if (email == null || password == null) return null;
    return (email: email, password: password);
  }

  Future<void> clear() async {
    await _storage.delete(key: _emailKey);
    await _storage.delete(key: _passwordKey);
  }

  Future<bool> hasCredentials() async {
    final email = await _storage.read(key: _emailKey);
    return email != null;
  }
}
