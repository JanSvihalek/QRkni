import 'dart:convert';
import 'package:crypto/crypto.dart';

class WorkerService {
  /// QR kód formát: qrkni://w?oid={ownerUserId}&n={name}&h={pinHash}
  static const _scheme = 'qrkni://w';

  static String hashPin(String ownerUserId, String pin) {
    final bytes = utf8.encode('$ownerUserId:$pin');
    return sha256.convert(bytes).toString();
  }

  static bool verifyPin(String ownerUserId, String pin, String storedHash) {
    return hashPin(ownerUserId, pin) == storedHash;
  }

  static String buildQrData({
    required String ownerUserId,
    required String workerName,
    required String pinHash,
  }) {
    final encoded = Uri.encodeComponent(workerName);
    return '$_scheme?oid=$ownerUserId&n=$encoded&h=$pinHash';
  }

  static ({String ownerUserId, String workerName, String pinHash})? parseQrData(String raw) {
    try {
      if (!raw.startsWith(_scheme)) return null;
      final uri = Uri.parse(raw.replaceFirst('qrkni://', 'https://'));
      final oid = uri.queryParameters['oid'];
      final n = uri.queryParameters['n'];
      final h = uri.queryParameters['h'];
      if (oid == null || n == null || h == null) return null;
      return (ownerUserId: oid, workerName: n, pinHash: h);
    } catch (_) {
      return null;
    }
  }
}
