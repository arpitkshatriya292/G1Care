import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import '../models/emergency_incident.dart';
import '../models/hospital.dart';
import '../models/vital_reading.dart';
import '../services/emergency_service.dart';
import '../services/notification_service.dart';
import 'ambulance_provider.dart';

class EmergencyProvider extends ChangeNotifier {
  final EmergencyService _emergencyService;
  final AmbulanceLocationProvider _defaultAmbulanceProvider;
  final Map<String, AmbulanceLocationProvider> _ambulanceByIncident = {};
  final Uuid _uuid = const Uuid();
  StreamSubscription<List<EmergencyIncident>>? _emergenciesSubscription;

  EmergencyIncident? _currentPatientIncident;
  List<EmergencyIncident> _activeEmergencies = [];
  bool _isLoading = false;
  String? _errorMessage;

  EmergencyProvider({
    EmergencyService? emergencyService,
    AmbulanceLocationProvider? ambulanceProvider,
  })  : _emergencyService = emergencyService ?? EmergencyService(),
        _defaultAmbulanceProvider = ambulanceProvider ?? AmbulanceLocationProvider() {
    _defaultAmbulanceProvider.onIncidentUpdated = (updated) {
      if (_currentPatientIncident?.incidentId == updated.incidentId) {
        _currentPatientIncident = updated.copyWith(
          arrivalPopupShown: _currentPatientIncident?.arrivalPopupShown ?? updated.arrivalPopupShown,
        );
        notifyListeners();
      }
      _updateIncidentInList(updated);
    };

    // Real-time synchronization across all devices via Firestore stream
    _emergenciesSubscription = _emergencyService.getActiveEmergenciesStream().listen((list) {
      _activeEmergencies = List.from(list);
      // Sync patient's current incident if updated remotely
      if (_currentPatientIncident != null) {
        final matching = _activeEmergencies
            .where((e) => e.incidentId == _currentPatientIncident!.incidentId)
            .toList();
        if (matching.isNotEmpty) {
          final matched = matching.first;
          _currentPatientIncident = matched.copyWith(
            arrivalPopupShown: _currentPatientIncident!.arrivalPopupShown || matched.arrivalPopupShown,
          );
          if (_currentPatientIncident!.status.isActiveOrPending) {
            NotificationService().showActiveEmergencyNotification(
              incidentId: _currentPatientIncident!.incidentId,
              title: 'G1Care • LIVE NAVIGATION ACTIVE',
              body: 'Emergency assistance is ${_currentPatientIncident!.status.displayName}. Tap for Live Navigation.',
            );
          } else {
            _currentPatientIncident = null;
            NotificationService().cancelActiveEmergencyNotification();
          }
        } else {
          // If remote hospital discharged/resolved it, update currentPatientIncident
          _currentPatientIncident = null;
          NotificationService().cancelActiveEmergencyNotification();
        }
      }
      notifyListeners();
    });

    refreshActiveEmergencies();
  }

  EmergencyIncident? get currentPatientIncident => _currentPatientIncident;
  bool get hasActiveEmergency =>
      _currentPatientIncident != null &&
      _currentPatientIncident!.status.isActiveOrPending;

  List<EmergencyIncident> get activeEmergencies => _activeEmergencies;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Returns the per-incident AmbulanceLocationProvider if one exists, or the default provider
  AmbulanceLocationProvider getAmbulanceForIncident(String incidentId) {
    if (_ambulanceByIncident.containsKey(incidentId)) {
      return _ambulanceByIncident[incidentId]!;
    }

    final matching = _activeEmergencies.where((e) => e.incidentId == incidentId).firstOrNull ??
        (_currentPatientIncident?.incidentId == incidentId ? _currentPatientIncident : null);

    if (matching != null) {
      final nearestHosp = Hospital.findNearest(matching.latitude, matching.longitude);
      final ambProv = AmbulanceLocationProvider(
        ambulanceId: matching.ambulanceId ?? 'G1-AMB-01 (Pune Unit)',
        initialPosition: LatLng(
          matching.ambulanceLatitude ?? nearestHosp.latitude,
          matching.ambulanceLongitude ?? nearestHosp.longitude,
        ),
      );
      ambProv.onIncidentUpdated = (updated) {
        if (_isDisposed) return;
        if (_currentPatientIncident?.incidentId == updated.incidentId) {
          _currentPatientIncident = updated;
          if (!_isDisposed) notifyListeners();
        }
        _updateIncidentInList(updated);
      };
      _ambulanceByIncident[incidentId] = ambProv;
      ambProv.syncWithIncident(matching);
      return ambProv;
    }

    return _defaultAmbulanceProvider;
  }

  /// Mark arrival notification popup as shown for an incident to prevent repeat popups
  Future<void> markArrivalPopupShown(String incidentId) async {
    if (_currentPatientIncident?.incidentId == incidentId) {
      _currentPatientIncident = _currentPatientIncident!.copyWith(arrivalPopupShown: true);
    }
    final idx = _activeEmergencies.indexWhere((e) => e.incidentId == incidentId);
    if (idx >= 0) {
      _activeEmergencies[idx] = _activeEmergencies[idx].copyWith(arrivalPopupShown: true);
    }
    if (_ambulanceByIncident.containsKey(incidentId)) {
      _ambulanceByIncident[incidentId]?.updateIncidentDetails(arrivalPopupShown: true);
    }

    final target = _currentPatientIncident?.incidentId == incidentId
        ? _currentPatientIncident
        : (idx >= 0 ? _activeEmergencies[idx] : null);

    if (target != null) {
      await _emergencyService.saveEmergencyIncident(target);
    }

    if (!_isDisposed) notifyListeners();
  }

  /// Critical active emergency cases count (Level 3 or Fall or Manual SOS)
  int get criticalCasesCount {
    return _activeEmergencies.where((e) {
      return e.status.isActiveOrPending && e.severity == HealthRiskLevel.critical;
    }).length;
  }

  /// Moderate active emergency cases count (Level 2 Warning)
  int get moderateCasesCount {
    return _activeEmergencies.where((e) {
      return e.status.isActiveOrPending && e.severity == HealthRiskLevel.warning;
    }).length;
  }

  void _updateIncidentInList(EmergencyIncident updated) {
    final idx = _activeEmergencies.indexWhere((e) => e.incidentId == updated.incidentId);
    if (idx >= 0) {
      if (updated.status.isResolvedOrDischarged) {
        _activeEmergencies.removeAt(idx);
      } else {
        _activeEmergencies[idx] = updated.copyWith(
          arrivalPopupShown: _activeEmergencies[idx].arrivalPopupShown || updated.arrivalPopupShown,
        );
      }
      if (!_isDisposed) notifyListeners();
    }
  }

  /// Authoritative check and restoration of patient's active emergency state from Firestore
  Future<EmergencyIncident?> syncPatientEmergencyState(String patientUid) async {
    final active = await _emergencyService.findActiveEmergencyForPatient(patientUid);
    if (active != null && active.status.isActiveOrPending) {
      _currentPatientIncident = active;
      if (!_activeEmergencies.any((e) => e.incidentId == active.incidentId)) {
        _activeEmergencies.insert(0, active);
      }

      // Restore ambulance tracking provider with wall-clock sync
      if (!_ambulanceByIncident.containsKey(active.incidentId)) {
        final nearestHosp = Hospital.findNearest(active.latitude, active.longitude);
        final ambProv = AmbulanceLocationProvider(
          ambulanceId: active.ambulanceId ?? 'G1-AMB-01 (Pune Unit)',
          initialPosition: LatLng(
            active.ambulanceLatitude ?? nearestHosp.latitude,
            active.ambulanceLongitude ?? nearestHosp.longitude,
          ),
        );
        ambProv.onIncidentUpdated = (updated) {
          if (_isDisposed) return;
          if (_currentPatientIncident?.incidentId == updated.incidentId) {
            _currentPatientIncident = updated;
            if (!_isDisposed) notifyListeners();
          }
          _updateIncidentInList(updated);
        };
        _ambulanceByIncident[active.incidentId] = ambProv;
        await ambProv.syncWithIncident(active);
      } else {
        await _ambulanceByIncident[active.incidentId]!.syncWithIncident(active);
      }

      // Show persistent ongoing notification
      NotificationService().showActiveEmergencyNotification(
        incidentId: active.incidentId,
        title: 'G1Care • LIVE NAVIGATION ACTIVE',
        body: 'Emergency response active (${active.status.displayName}). Tap to open Live Navigation.',
      );

      notifyListeners();
      return active;
    } else {
      if (_currentPatientIncident != null && _currentPatientIncident!.patientUid == patientUid) {
        _currentPatientIncident = null;
        NotificationService().cancelActiveEmergencyNotification();
        notifyListeners();
      }
      return null;
    }
  }

  /// Trigger a new Emergency SOS incident from patient with duplicate prevention
  Future<EmergencyIncident> triggerEmergencySos({
    required String patientUid,
    required String medicalId,
    required String patientName,
    required String bloodGroup,
    required String emergencyPhone,
    required List<String> criticalAllergies,
    required EmergencyTriggerType triggerType,
    required VitalReading vitalsSnapshot,
    required double latitude,
    required double longitude,
    required String locationAddress,
    bool isSimulatedLocation = true,
  }) async {
    // 1. Debounce / Duplicate Prevention: if already active in this session for this patient, reuse it
    if (_currentPatientIncident != null &&
        _currentPatientIncident!.status.isActiveOrPending &&
        _currentPatientIncident!.patientUid == patientUid) {
      NotificationService().showActiveEmergencyNotification(
        incidentId: _currentPatientIncident!.incidentId,
        title: 'G1Care • LIVE NAVIGATION ACTIVE',
        body: 'Emergency response active (${_currentPatientIncident!.status.displayName}). Tap for Live Navigation.',
      );
      return _currentPatientIncident!;
    }

    // 2. Check if an active emergency already exists in the backend network for this patient
    final existingActive = await _emergencyService.findActiveEmergencyForPatient(patientUid);
    if (existingActive != null) {
      _currentPatientIncident = existingActive;
      _updateIncidentInList(existingActive);
      NotificationService().showActiveEmergencyNotification(
        incidentId: existingActive.incidentId,
        title: 'G1Care • LIVE NAVIGATION ACTIVE',
        body: 'Emergency response active (${existingActive.status.displayName}). Tap for Live Navigation.',
      );
      notifyListeners();
      return existingActive;
    }

    _isLoading = true;
    notifyListeners();

    final suffix = _uuid.v4().substring(0, 6).toUpperCase();
    final incidentId = 'G1-INC-${DateTime.now().year}-$suffix';
    final nearestHosp = Hospital.findNearest(latitude, longitude);
    final distance = double.parse(
      (Hospital.calculateDistanceKm(
            latitude,
            longitude,
            nearestHosp.latitude,
            nearestHosp.longitude,
          ) *
          1.25)
          .clamp(1.0, 15.0)
          .toStringAsFixed(1),
    );
    final eta = max(2, (distance / 35.0 * 60).round());
    final ambUnitId = 'G1-AMB-${suffix.substring(0, 4)}';

    // Create per-incident ambulance provider
    final ambProv = AmbulanceLocationProvider(
      ambulanceId: '$ambUnitId (Pune Unit)',
      driverName: 'Officer K. Verma',
      vehicleNumber: 'MH-12-EM-${1000 + Random().nextInt(8999)}',
      initialPosition: LatLng(nearestHosp.latitude, nearestHosp.longitude),
    );

    ambProv.onIncidentUpdated = (updated) {
      if (_isDisposed) return;
      if (_currentPatientIncident?.incidentId == updated.incidentId) {
        _currentPatientIncident = updated.copyWith(
          arrivalPopupShown: _currentPatientIncident?.arrivalPopupShown ?? updated.arrivalPopupShown,
        );
        if (!_isDisposed) notifyListeners();
      }
      _updateIncidentInList(updated);
    };
    _ambulanceByIncident[incidentId] = ambProv;

    final incident = EmergencyIncident(
      incidentId: incidentId,
      patientUid: patientUid,
      medicalId: medicalId,
      patientName: patientName,
      bloodGroup: bloodGroup,
      emergencyPhone: emergencyPhone,
      criticalAllergies: criticalAllergies,
      triggerType: triggerType,
      status: EmergencyStatus.active,
      vitalsSnapshot: vitalsSnapshot,
      latitude: latitude,
      longitude: longitude,
      locationAddress: locationAddress,
      isSimulatedLocation: isSimulatedLocation,
      assignedHospitalName: nearestHosp.name,
      hospitalLatitude: nearestHosp.latitude,
      hospitalLongitude: nearestHosp.longitude,
      ambulanceId: ambProv.ambulanceId,
      ambulanceLatitude: nearestHosp.latitude,
      ambulanceLongitude: nearestHosp.longitude,
      distanceKm: distance,
      etaMinutes: eta,
      initialDistanceKm: distance,
      initialDurationSeconds: eta * 60,
      dispatchedAt: DateTime.now(),
      arrivalPopupShown: false,
      createdAt: DateTime.now(),
      lastUpdatedAt: DateTime.now(),
    );

    await _emergencyService.saveEmergencyIncident(incident);

    _currentPatientIncident = incident;
    // Remove if duplicate exists and insert at top
    _activeEmergencies.removeWhere((e) => e.incidentId == incident.incidentId);
    _activeEmergencies.insert(0, incident);
    _isLoading = false;

    // Show persistent background notification on device
    NotificationService().showActiveEmergencyNotification(
      incidentId: incident.incidentId,
      title: 'G1Care • LIVE NAVIGATION ACTIVE',
      body: 'Emergency response active (Ambulance Dispatched). Tap for Live Navigation.',
    );

    notifyListeners();

    // Automatically dispatch simulated digital ambulance for this incident
    await ambProv.dispatchToIncident(incident, baseHospital: nearestHosp);

    return incident;
  }

  /// Cancel active SOS (Patient confirmed "I'm OK")
  Future<void> cancelSos() async {
    if (_currentPatientIncident != null) {
      final incId = _currentPatientIncident!.incidentId;
      final resolved = _currentPatientIncident!.copyWith(
        status: EmergencyStatus.resolved,
        resolvedAt: DateTime.now(),
        lastUpdatedAt: DateTime.now(),
      );
      await _emergencyService.saveEmergencyIncident(resolved);

      _ambulanceByIncident[incId]?.reset();
      _ambulanceByIncident[incId]?.dispose();
      _ambulanceByIncident.remove(incId);
      _defaultAmbulanceProvider.reset();

      _activeEmergencies.removeWhere((e) => e.incidentId == resolved.incidentId);
      _currentPatientIncident = null;

      // Cancel persistent notification
      NotificationService().cancelActiveEmergencyNotification();

      notifyListeners();
    }
  }

  /// Doctor/Hospital acknowledges and responds to emergency incident
  Future<void> respondToEmergency({
    required String incidentId,
    required String doctorId,
    required String doctorName,
    String? respondingHospitalId,
    String? respondingHospitalName,
  }) async {
    final idx = _activeEmergencies.indexWhere((e) => e.incidentId == incidentId);
    if (idx >= 0) {
      final existing = _activeEmergencies[idx];
      final updated = existing.copyWith(
        status: EmergencyStatus.responded,
        respondedDoctorId: doctorId,
        respondedDoctorName: doctorName,
        respondingHospitalId: respondingHospitalId ?? existing.respondingHospitalId,
        respondingHospitalName: respondingHospitalName ?? existing.respondingHospitalName,
        lastUpdatedAt: DateTime.now(),
      );
      await _emergencyService.saveEmergencyIncident(updated);
      _activeEmergencies[idx] = updated;
      if (_currentPatientIncident?.incidentId == incidentId) {
        _currentPatientIncident = updated;
      }
      notifyListeners();
    }
  }

  /// Hospital medical staff marks emergency as treated
  Future<void> treatEmergency(String incidentId) async {
    final idx = _activeEmergencies.indexWhere((e) => e.incidentId == incidentId);
    final existing = idx >= 0
        ? _activeEmergencies[idx]
        : await _emergencyService.getEmergencyIncident(incidentId);

    if (existing != null) {
      final updated = existing.copyWith(
        status: EmergencyStatus.treated,
        lastUpdatedAt: DateTime.now(),
      );
      await _emergencyService.saveEmergencyIncident(updated);
      if (idx >= 0) {
        _activeEmergencies[idx] = updated;
      }
      if (_currentPatientIncident?.incidentId == incidentId) {
        _currentPatientIncident = updated;
      }
      if (!_isDisposed) notifyListeners();
    }
  }

  /// Hospital staff discharges patient from active emergency network
  Future<void> dischargeEmergency(String incidentId) async {
    final idx = _activeEmergencies.indexWhere((e) => e.incidentId == incidentId);
    final existing = idx >= 0
        ? _activeEmergencies[idx]
        : await _emergencyService.getEmergencyIncident(incidentId);

    if (existing != null) {
      final updated = existing.copyWith(
        status: EmergencyStatus.discharged,
        resolvedAt: DateTime.now(),
        lastUpdatedAt: DateTime.now(),
      );
      await _emergencyService.saveEmergencyIncident(updated);
      if (idx >= 0) {
        _activeEmergencies.removeAt(idx);
      } else {
        _activeEmergencies.removeWhere((e) => e.incidentId == incidentId);
      }

      _ambulanceByIncident[incidentId]?.onIncidentUpdated = null;
      _ambulanceByIncident[incidentId]?.reset();
      _ambulanceByIncident[incidentId]?.dispose();
      _ambulanceByIncident.remove(incidentId);

      if (_currentPatientIncident?.incidentId == incidentId) {
        _currentPatientIncident = null;
        _defaultAmbulanceProvider.reset();
        NotificationService().cancelActiveEmergencyNotification();
      }
      if (!_isDisposed) notifyListeners();
    }
  }

  /// Resolve emergency incident (Doctor or Medical team marks safe)
  Future<void> resolveEmergency(String incidentId) async {
    final idx = _activeEmergencies.indexWhere((e) => e.incidentId == incidentId);
    final existing = idx >= 0
        ? _activeEmergencies[idx]
        : await _emergencyService.getEmergencyIncident(incidentId);

    if (existing != null) {
      final updated = existing.copyWith(
        status: EmergencyStatus.resolved,
        resolvedAt: DateTime.now(),
        lastUpdatedAt: DateTime.now(),
      );
      await _emergencyService.saveEmergencyIncident(updated);
      if (idx >= 0) {
        _activeEmergencies.removeAt(idx);
      } else {
        _activeEmergencies.removeWhere((e) => e.incidentId == incidentId);
      }

      _ambulanceByIncident[incidentId]?.onIncidentUpdated = null;
      _ambulanceByIncident[incidentId]?.reset();
      _ambulanceByIncident[incidentId]?.dispose();
      _ambulanceByIncident.remove(incidentId);

      if (_currentPatientIncident?.incidentId == incidentId) {
        _currentPatientIncident = null;
        _defaultAmbulanceProvider.reset();
        NotificationService().cancelActiveEmergencyNotification();
      }
      if (!_isDisposed) notifyListeners();
    }
  }

  /// Refresh list of active emergencies
  Future<void> refreshActiveEmergencies() async {
    _isLoading = true;
    if (!_isDisposed) notifyListeners();

    try {
      _activeEmergencies = await _emergencyService.getActiveEmergencies();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    _emergenciesSubscription?.cancel();
    for (final amb in _ambulanceByIncident.values) {
      amb.onIncidentUpdated = null;
      amb.reset();
      amb.dispose();
    }
    _ambulanceByIncident.clear();
    _defaultAmbulanceProvider.onIncidentUpdated = null;
    _defaultAmbulanceProvider.reset();
    super.dispose();
  }
}
