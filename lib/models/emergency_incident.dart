import '../services/health_evaluator.dart';
import 'vital_reading.dart';

enum EmergencyStatus {
  detected,
  sosPending,
  active,
  ambulanceAssigned,
  enRoute,
  arrived,
  responded,
  treated,
  discharged,
  resolved;

  String get displayName {
    switch (this) {
      case EmergencyStatus.detected:
        return 'ANOMALY DETECTED';
      case EmergencyStatus.sosPending:
        return 'SOS COUNTDOWN';
      case EmergencyStatus.active:
        return 'ACTIVE EMERGENCY';
      case EmergencyStatus.ambulanceAssigned:
        return 'AMBULANCE ASSIGNED';
      case EmergencyStatus.enRoute:
        return 'AMBULANCE EN ROUTE';
      case EmergencyStatus.arrived:
        return 'AMBULANCE ARRIVED';
      case EmergencyStatus.responded:
        return 'DOCTOR RESPONDED';
      case EmergencyStatus.treated:
        return 'PATIENT TREATED';
      case EmergencyStatus.discharged:
        return 'DISCHARGED FROM HOSPITAL';
      case EmergencyStatus.resolved:
        return 'RESOLVED / CLOSED';
    }
  }

  bool get isActiveOrPending =>
      this != EmergencyStatus.resolved &&
      this != EmergencyStatus.discharged &&
      this != EmergencyStatus.detected;

  bool get isResolvedOrDischarged =>
      this == EmergencyStatus.resolved || this == EmergencyStatus.discharged;
}

enum EmergencyTriggerType {
  manualSos,
  fallDetected,
  criticalVitals,
  cardiacAlert;

  String get displayName {
    switch (this) {
      case EmergencyTriggerType.manualSos:
        return 'Manual Emergency SOS Button';
      case EmergencyTriggerType.fallDetected:
        return 'Automated Fall Impact Alert';
      case EmergencyTriggerType.criticalVitals:
        return 'Critical Vital Anomaly Alert';
      case EmergencyTriggerType.cardiacAlert:
        return 'Cardiac / Arrhythmia Alert';
    }
  }
}

class EmergencyIncident {
  final String incidentId;
  final String patientUid;
  final String medicalId;
  final String patientName;
  final String bloodGroup;
  final String emergencyPhone;
  final List<String> criticalAllergies;
  final EmergencyTriggerType triggerType;
  final EmergencyStatus status;
  final VitalReading vitalsSnapshot;
  final double latitude;
  final double longitude;
  final String locationAddress;
  final bool isSimulatedLocation;
  final String? assignedHospitalName;
  final double? hospitalLatitude;
  final double? hospitalLongitude;
  final String? ambulanceId;
  final double? ambulanceLatitude;
  final double? ambulanceLongitude;
  final double? distanceKm;
  final int? etaMinutes;
  final double? initialDistanceKm;
  final int? initialDurationSeconds;
  final DateTime? dispatchedAt;
  final bool arrivalPopupShown;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final DateTime? lastUpdatedAt;
  final String? respondedDoctorName;
  final String? respondedDoctorId;
  final String? respondingHospitalId;
  final String? respondingHospitalName;

  const EmergencyIncident({
    required this.incidentId,
    required this.patientUid,
    required this.medicalId,
    required this.patientName,
    required this.bloodGroup,
    required this.emergencyPhone,
    required this.criticalAllergies,
    required this.triggerType,
    required this.status,
    required this.vitalsSnapshot,
    required this.latitude,
    required this.longitude,
    required this.locationAddress,
    this.isSimulatedLocation = true,
    this.assignedHospitalName,
    this.hospitalLatitude,
    this.hospitalLongitude,
    this.ambulanceId,
    this.ambulanceLatitude,
    this.ambulanceLongitude,
    this.distanceKm,
    this.etaMinutes,
    this.initialDistanceKm,
    this.initialDurationSeconds,
    this.dispatchedAt,
    this.arrivalPopupShown = false,
    required this.createdAt,
    this.resolvedAt,
    this.lastUpdatedAt,
    this.respondedDoctorName,
    this.respondedDoctorId,
    this.respondingHospitalId,
    this.respondingHospitalName,
  });

  /// Evaluates the overall health risk severity of this emergency incident
  HealthRiskLevel get severity {
    final eval = HealthStatusEvaluator.evaluate(vitalsSnapshot);
    if (eval.isCritical ||
        triggerType == EmergencyTriggerType.fallDetected ||
        triggerType == EmergencyTriggerType.manualSos ||
        triggerType == EmergencyTriggerType.cardiacAlert) {
      return HealthRiskLevel.critical;
    }
    if (eval.isWarning) {
      return HealthRiskLevel.warning;
    }
    return HealthRiskLevel.normal;
  }

  EmergencyIncident copyWith({
    String? incidentId,
    String? patientUid,
    String? medicalId,
    String? patientName,
    String? bloodGroup,
    String? emergencyPhone,
    List<String>? criticalAllergies,
    EmergencyTriggerType? triggerType,
    EmergencyStatus? status,
    VitalReading? vitalsSnapshot,
    double? latitude,
    double? longitude,
    String? locationAddress,
    bool? isSimulatedLocation,
    String? assignedHospitalName,
    double? hospitalLatitude,
    double? hospitalLongitude,
    String? ambulanceId,
    double? ambulanceLatitude,
    double? ambulanceLongitude,
    double? distanceKm,
    int? etaMinutes,
    double? initialDistanceKm,
    int? initialDurationSeconds,
    DateTime? dispatchedAt,
    bool? arrivalPopupShown,
    DateTime? createdAt,
    DateTime? resolvedAt,
    DateTime? lastUpdatedAt,
    String? respondedDoctorName,
    String? respondedDoctorId,
    String? respondingHospitalId,
    String? respondingHospitalName,
  }) {
    return EmergencyIncident(
      incidentId: incidentId ?? this.incidentId,
      patientUid: patientUid ?? this.patientUid,
      medicalId: medicalId ?? this.medicalId,
      patientName: patientName ?? this.patientName,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      criticalAllergies: criticalAllergies ?? this.criticalAllergies,
      triggerType: triggerType ?? this.triggerType,
      status: status ?? this.status,
      vitalsSnapshot: vitalsSnapshot ?? this.vitalsSnapshot,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationAddress: locationAddress ?? this.locationAddress,
      isSimulatedLocation: isSimulatedLocation ?? this.isSimulatedLocation,
      assignedHospitalName: assignedHospitalName ?? this.assignedHospitalName,
      hospitalLatitude: hospitalLatitude ?? this.hospitalLatitude,
      hospitalLongitude: hospitalLongitude ?? this.hospitalLongitude,
      ambulanceId: ambulanceId ?? this.ambulanceId,
      ambulanceLatitude: ambulanceLatitude ?? this.ambulanceLatitude,
      ambulanceLongitude: ambulanceLongitude ?? this.ambulanceLongitude,
      distanceKm: distanceKm ?? this.distanceKm,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      initialDistanceKm: initialDistanceKm ?? this.initialDistanceKm,
      initialDurationSeconds: initialDurationSeconds ?? this.initialDurationSeconds,
      dispatchedAt: dispatchedAt ?? this.dispatchedAt,
      arrivalPopupShown: arrivalPopupShown ?? this.arrivalPopupShown,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      respondedDoctorName: respondedDoctorName ?? this.respondedDoctorName,
      respondedDoctorId: respondedDoctorId ?? this.respondedDoctorId,
      respondingHospitalId: respondingHospitalId ?? this.respondingHospitalId,
      respondingHospitalName: respondingHospitalName ?? this.respondingHospitalName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'incidentId': incidentId,
      'patientUid': patientUid,
      'medicalId': medicalId,
      'patientName': patientName,
      'bloodGroup': bloodGroup,
      'emergencyPhone': emergencyPhone,
      'criticalAllergies': criticalAllergies,
      'triggerType': triggerType.name,
      'status': status.name,
      'vitalsSnapshot': vitalsSnapshot.toMap(),
      'latitude': latitude,
      'longitude': longitude,
      'locationAddress': locationAddress,
      'isSimulatedLocation': isSimulatedLocation,
      'assignedHospitalName': assignedHospitalName,
      'hospitalLatitude': hospitalLatitude,
      'hospitalLongitude': hospitalLongitude,
      'ambulanceId': ambulanceId,
      'ambulanceLatitude': ambulanceLatitude,
      'ambulanceLongitude': ambulanceLongitude,
      'distanceKm': distanceKm,
      'etaMinutes': etaMinutes,
      'initialDistanceKm': initialDistanceKm,
      'initialDurationSeconds': initialDurationSeconds,
      'dispatchedAt': dispatchedAt?.toIso8601String(),
      'arrivalPopupShown': arrivalPopupShown,
      'createdAt': createdAt.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'lastUpdatedAt': lastUpdatedAt?.toIso8601String(),
      'respondedDoctorName': respondedDoctorName,
      'respondedDoctorId': respondedDoctorId,
      'respondingHospitalId': respondingHospitalId,
      'respondingHospitalName': respondingHospitalName,
    };
  }

  factory EmergencyIncident.fromMap(Map<String, dynamic> map) {
    return EmergencyIncident(
      incidentId: map['incidentId'] as String? ?? '',
      patientUid: map['patientUid'] as String? ?? '',
      medicalId: map['medicalId'] as String? ?? '',
      patientName: map['patientName'] as String? ?? 'Patient',
      bloodGroup: map['bloodGroup'] as String? ?? 'Unknown',
      emergencyPhone: map['emergencyPhone'] as String? ?? '',
      criticalAllergies: (map['criticalAllergies'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      triggerType: EmergencyTriggerType.values.firstWhere(
        (t) => t.name == map['triggerType'],
        orElse: () => EmergencyTriggerType.manualSos,
      ),
      status: EmergencyStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => EmergencyStatus.active,
      ),
      vitalsSnapshot: map['vitalsSnapshot'] != null
          ? VitalReading.fromMap(map['vitalsSnapshot'] as Map<String, dynamic>)
          : VitalReading.defaultNormal(),
      latitude: (map['latitude'] as num?)?.toDouble() ?? 18.5204,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 73.8567,
      locationAddress: map['locationAddress'] as String? ?? 'Pune, Maharashtra, India',
      isSimulatedLocation: map['isSimulatedLocation'] as bool? ?? true,
      assignedHospitalName: map['assignedHospitalName'] as String?,
      hospitalLatitude: (map['hospitalLatitude'] as num?)?.toDouble(),
      hospitalLongitude: (map['hospitalLongitude'] as num?)?.toDouble(),
      ambulanceId: map['ambulanceId'] as String?,
      ambulanceLatitude: (map['ambulanceLatitude'] as num?)?.toDouble(),
      ambulanceLongitude: (map['ambulanceLongitude'] as num?)?.toDouble(),
      distanceKm: (map['distanceKm'] as num?)?.toDouble(),
      etaMinutes: (map['etaMinutes'] as num?)?.toInt(),
      initialDistanceKm: (map['initialDistanceKm'] as num?)?.toDouble(),
      initialDurationSeconds: (map['initialDurationSeconds'] as num?)?.toInt(),
      dispatchedAt: map['dispatchedAt'] != null
          ? DateTime.tryParse(map['dispatchedAt'] as String)
          : null,
      arrivalPopupShown: map['arrivalPopupShown'] as bool? ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      resolvedAt: map['resolvedAt'] != null
          ? DateTime.tryParse(map['resolvedAt'] as String)
          : null,
      lastUpdatedAt: map['lastUpdatedAt'] != null
          ? DateTime.tryParse(map['lastUpdatedAt'] as String)
          : null,
      respondedDoctorName: map['respondedDoctorName'] as String?,
      respondedDoctorId: map['respondedDoctorId'] as String?,
      respondingHospitalId: map['respondingHospitalId'] as String?,
      respondingHospitalName: map['respondingHospitalName'] as String?,
    );
  }
}
