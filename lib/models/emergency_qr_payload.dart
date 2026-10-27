import 'dart:convert';

/// Minimal Emergency QR Payload DTO
/// Designed strictly for offline first-responder triage snapshots.
/// Excludes private medical details such as full home address, full prescription regimens,
/// past surgeries, private physician notes, and internal database UIDs.
class EmergencyQrPayload {
  final String schema;
  final String medId;
  final String name;
  final String bg; // Blood Group
  final List<String> alrg; // Severe/Critical Allergies
  final List<String> cond; // Critical Pre-existing Conditions
  final String emPhone; // Primary Emergency Phone
  final int issuedAt; // Milliseconds since epoch
  final String integrityTag; // Prototype HMAC-SHA256 integrity check

  EmergencyQrPayload({
    this.schema = 'g1/v1',
    required this.medId,
    required this.name,
    required this.bg,
    required this.alrg,
    required this.cond,
    required this.emPhone,
    required this.issuedAt,
    this.integrityTag = '',
  });

  /// Canonical string used for computing prototype HMAC-SHA256 integrity tag
  String toCanonicalString() {
    final sortedAllergies = List<String>.from(alrg)..sort();
    final sortedConditions = List<String>.from(cond)..sort();
    return '$schema|$medId|${name.trim()}|${bg.trim()}|${sortedAllergies.join(",")}|${sortedConditions.join(",")}|${emPhone.trim()}|$issuedAt';
  }

  Map<String, dynamic> toMap() {
    return {
      'schema': schema,
      'medId': medId,
      'name': name,
      'bg': bg,
      'alrg': alrg,
      'cond': cond,
      'emPhone': emPhone,
      'issuedAt': issuedAt,
      'integrityTag': integrityTag,
    };
  }

  String toJson() => jsonEncode(toMap());

  factory EmergencyQrPayload.fromMap(Map<String, dynamic> map) {
    return EmergencyQrPayload(
      schema: map['schema'] ?? 'g1/v1',
      medId: map['medId'] ?? '',
      name: map['name'] ?? '',
      bg: map['bg'] ?? 'Unknown',
      alrg: List<String>.from(map['alrg'] ?? []),
      cond: List<String>.from(map['cond'] ?? []),
      emPhone: map['emPhone'] ?? '',
      issuedAt: map['issuedAt'] is int
          ? map['issuedAt']
          : int.tryParse(map['issuedAt']?.toString() ?? '0') ?? 0,
      integrityTag: map['integrityTag'] ?? '',
    );
  }

  factory EmergencyQrPayload.fromJson(String source) {
    return EmergencyQrPayload.fromMap(jsonDecode(source) as Map<String, dynamic>);
  }

  EmergencyQrPayload copyWith({
    String? schema,
    String? medId,
    String? name,
    String? bg,
    List<String>? alrg,
    List<String>? cond,
    String? emPhone,
    int? issuedAt,
    String? integrityTag,
  }) {
    return EmergencyQrPayload(
      schema: schema ?? this.schema,
      medId: medId ?? this.medId,
      name: name ?? this.name,
      bg: bg ?? this.bg,
      alrg: alrg ?? this.alrg,
      cond: cond ?? this.cond,
      emPhone: emPhone ?? this.emPhone,
      issuedAt: issuedAt ?? this.issuedAt,
      integrityTag: integrityTag ?? this.integrityTag,
    );
  }
}
