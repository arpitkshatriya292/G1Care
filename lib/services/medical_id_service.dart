import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import '../models/emergency_qr_payload.dart';
import '../models/medical_profile.dart';

/// Service responsible for Unique Medical ID generation, opaque security QR token
/// generation and resolution, and Emergency QR payload serialization with
/// prototype-level HMAC-SHA256 integrity checking.
class MedicalIdService {
  // Prototype HMAC secret key (used strictly for prototype tamper detection)
  static const String _prototypeHmacSecret = 'g1care_prototype_emergency_key_2026_sec';

  // In-memory QR token registry (prototype: session-scoped / shared local state)
  static final Map<String, String> _qrTokenRegistry = {}; // token -> medicalId

  /// Generates a standardized Unique Medical ID: G1-MED-YYYY-XXXXXX
  /// Example: G1-MED-2026-A8F9K2
  static String generateMedicalId({int? year}) {
    final currentYear = year ?? DateTime.now().year;
    final random = Random.secure();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Base32 without ambiguous 0/O, 1/I
    final codeBuffer = StringBuffer();
    for (int i = 0; i < 6; i++) {
      codeBuffer.write(chars[random.nextInt(chars.length)]);
    }
    return 'G1-MED-$currentYear-${codeBuffer.toString()}';
  }

  /// Generates an opaque, non-sensitive unique QR token: G1QR-XXXXXXXXXXXXXXXXXXXX
  /// Contains zero patient medical information.
  static String generateQrToken() {
    final random = Random.secure();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final buffer = StringBuffer();
    for (int i = 0; i < 20; i++) {
      buffer.write(chars[random.nextInt(chars.length)]);
    }
    return 'G1QR-${buffer.toString()}';
  }

  /// Registers an opaque token -> medicalId mapping
  static void registerQrToken(String token, String medicalId) {
    if (token.isNotEmpty && medicalId.isNotEmpty) {
      _qrTokenRegistry[token] = medicalId;
    }
  }

  /// Resolves an opaque token to its corresponding medicalId.
  /// Returns null if the token is unrecognized, expired, or invalid.
  static String? lookupMedicalIdByToken(String token) {
    return _qrTokenRegistry[token];
  }

  /// Checks if a string is formatted as a G1Care opaque QR token
  static bool isOpaqueQrToken(String value) {
    final trimmed = value.trim();
    return trimmed.startsWith('G1QR-') && !trimmed.contains('{') && !trimmed.contains(':');
  }

  /// Clear the token registry for clean test isolation
  @visibleForTesting
  static void clearQrTokenRegistryForTesting() {
    _qrTokenRegistry.clear();
  }

  /// Computes the prototype HMAC-SHA256 integrity tag for an EmergencyQrPayload
  static String computePrototypeIntegrityTag(EmergencyQrPayload payload) {
    final canonicalString = payload.toCanonicalString();
    final key = utf8.encode(_prototypeHmacSecret);
    final bytes = utf8.encode(canonicalString);
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(bytes);
    return digest.toString().substring(0, 16); // 16-character compact hex tag
  }

  /// Generates the minimal Emergency QR payload with embedded prototype integrity tag
  static EmergencyQrPayload createSignedEmergencyPayload(MedicalProfile profile) {
    final rawPayload = profile.toEmergencySnapshot();
    final tag = computePrototypeIntegrityTag(rawPayload);
    return rawPayload.copyWith(integrityTag: tag);
  }

  /// Generates the raw JSON string to be encoded into the QR Code image
  static String generateQrString(MedicalProfile profile) {
    final signedPayload = createSignedEmergencyPayload(profile);
    return signedPayload.toJson();
  }

  /// Verifies the prototype integrity tag of a raw QR JSON string
  /// Returns a record with validation status, parsed payload (if valid JSON), and error reason
  static ({bool isValid, EmergencyQrPayload? payload, String? error}) verifyQrPayload(
      String rawQrString) {
    try {
      final payload = EmergencyQrPayload.fromJson(rawQrString);
      
      if (payload.medId.isEmpty) {
        return (isValid: false, payload: null, error: 'Missing Medical ID in QR payload');
      }

      final expectedTag = computePrototypeIntegrityTag(payload);
      if (payload.integrityTag != expectedTag) {
        return (
          isValid: false,
          payload: payload,
          error: 'Integrity verification failed (Payload modified or untrusted tag)'
        );
      }

      return (isValid: true, payload: payload, error: null);
    } catch (e) {
      return (isValid: false, payload: null, error: 'Invalid QR payload format: $e');
    }
  }
}
