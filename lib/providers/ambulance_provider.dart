import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/emergency_incident.dart';
import '../models/hospital.dart';
import '../services/routing_service.dart';

enum AmbulanceStatus {
  idle,
  assigned,
  enRoute,
  arrived;

  String get displayName {
    switch (this) {
      case AmbulanceStatus.idle:
        return 'Station Idle';
      case AmbulanceStatus.assigned:
        return 'Assigned to Emergency';
      case AmbulanceStatus.enRoute:
        return 'EN ROUTE TO PATIENT';
      case AmbulanceStatus.arrived:
        return 'ARRIVED AT SCENE';
    }
  }
}

class AmbulanceLocationProvider extends ChangeNotifier {
  final String ambulanceId;
  final String driverName;
  final String vehicleNumber;
  final bool isSimulation;

  AmbulanceStatus _status = AmbulanceStatus.idle;
  LatLng _currentPosition;
  double _totalRouteDistanceKm = 0.0;
  double _distanceKm = 0.0;
  int _etaMinutes = 0;
  int _totalDurationSeconds = 0;
  DateTime _dispatchedAt = DateTime.now();
  List<LatLng> _routePoints = [];
  int _currentWaypointIndex = 0;
  Timer? _movementTimer;
  EmergencyIncident? _activeIncident;
  DateTime _lastUpdatedAt = DateTime.now();

  // Callback when ambulance arrives or moves
  void Function(EmergencyIncident updated)? onIncidentUpdated;

  AmbulanceLocationProvider({
    this.ambulanceId = 'G1-AMB-01 (Pune Unit)',
    this.driverName = 'Officer K. Verma',
    this.vehicleNumber = 'MH-12-EM-1108',
    this.isSimulation = true,
    LatLng? initialPosition,
  }) : _currentPosition = initialPosition ?? const LatLng(18.5326, 73.8785); // Ruby Hall Station, Pune

  AmbulanceStatus get status => _status;
  LatLng get currentPosition => _currentPosition;
  double get latitude => _currentPosition.latitude;
  double get longitude => _currentPosition.longitude;
  double get distanceKm => _distanceKm;
  double get totalRouteDistanceKm => _totalRouteDistanceKm;
  int get etaMinutes => _etaMinutes;
  int get totalDurationSeconds => _totalDurationSeconds;
  DateTime get dispatchedAt => _dispatchedAt;
  List<LatLng> get routePoints => _routePoints;
  bool get isEnRoute => _status == AmbulanceStatus.enRoute;
  bool get hasArrived => _status == AmbulanceStatus.arrived;
  EmergencyIncident? get activeIncident => _activeIncident;
  DateTime get lastUpdatedAt => _lastUpdatedAt;

  /// Dispatch ambulance to emergency incident with wall-clock time anchor
  Future<void> dispatchToIncident(
    EmergencyIncident incident, {
    Hospital? baseHospital,
  }) async {
    _activeIncident = incident;
    _status = AmbulanceStatus.assigned;
    notifyListeners();

    final startPos = baseHospital != null
        ? LatLng(baseHospital.latitude, baseHospital.longitude)
        : _currentPosition;
    _currentPosition = startPos;

    final targetPos = LatLng(incident.latitude, incident.longitude);

    // Calculate routing
    final route = await RoutingService.getRoute(startPos, targetPos);
    if (_isDisposed) return;

    _routePoints = route.waypoints;
    _totalRouteDistanceKm = incident.initialDistanceKm ??
        (route.distanceKm > 0 ? route.distanceKm : (incident.distanceKm ?? 3.5));
    _distanceKm = _totalRouteDistanceKm;

    // Realistic Pune urban emergency driving speed (~35 km/h)
    final initialMinutes = incident.etaMinutes ?? max(1, (_totalRouteDistanceKm / 35.0 * 60).round());
    _totalDurationSeconds = incident.initialDurationSeconds ?? (initialMinutes * 60);
    _dispatchedAt = incident.dispatchedAt ?? incident.createdAt;
    _currentWaypointIndex = 0;
    _status = AmbulanceStatus.enRoute;
    _lastUpdatedAt = DateTime.now();

    // Perform initial wall-clock calculation
    _syncWallClockProgress();

    final updated = incident.copyWith(
      ambulanceLatitude: _currentPosition.latitude,
      ambulanceLongitude: _currentPosition.longitude,
      distanceKm: _distanceKm,
      etaMinutes: _etaMinutes,
      initialDistanceKm: _totalRouteDistanceKm,
      initialDurationSeconds: _totalDurationSeconds,
      dispatchedAt: _dispatchedAt,
      status: _status == AmbulanceStatus.arrived ? EmergencyStatus.arrived : EmergencyStatus.enRoute,
      lastUpdatedAt: _lastUpdatedAt,
    );
    _activeIncident = updated;
    onIncidentUpdated?.call(updated);

    if (!_isDisposed) notifyListeners();

    // Start wall-clock periodic tracking
    _startMovementSimulation();
  }

  /// Reconstruct / synchronize ambulance state from stored incident using Wall-Clock Time
  Future<void> syncWithIncident(EmergencyIncident incident) async {
    _activeIncident = incident;
    _dispatchedAt = incident.dispatchedAt ?? incident.createdAt;
    _totalRouteDistanceKm = incident.initialDistanceKm ?? incident.distanceKm ?? 3.5;
    final initialMinutes = incident.etaMinutes ?? max(1, (_totalRouteDistanceKm / 35.0 * 60).round());
    _totalDurationSeconds = incident.initialDurationSeconds ?? (initialMinutes * 60);

    if (_routePoints.isEmpty) {
      final startPos = incident.hospitalLatitude != null && incident.hospitalLongitude != null
          ? LatLng(incident.hospitalLatitude!, incident.hospitalLongitude!)
          : const LatLng(18.5326, 73.8785);
      final targetPos = LatLng(incident.latitude, incident.longitude);
      final route = await RoutingService.getRoute(startPos, targetPos);
      if (_isDisposed) return;
      _routePoints = route.waypoints;
    }

    _syncWallClockProgress();
    if (!_isDisposed) notifyListeners();

    if (_status == AmbulanceStatus.enRoute) {
      _startMovementSimulation();
    }
  }

  /// Core Wall-Clock calculation: Computes progress ratio, remaining distance, ETA, and position
  void _syncWallClockProgress() {
    if (_routePoints.isEmpty) return;

    if (_activeIncident?.status == EmergencyStatus.arrived) {
      _status = AmbulanceStatus.arrived;
      _distanceKm = 0.0;
      _etaMinutes = 0;
      _currentWaypointIndex = _routePoints.length - 1;
      _currentPosition = _routePoints.last;
      _lastUpdatedAt = DateTime.now();
      return;
    }

    final totalDuration = _totalDurationSeconds > 0 ? _totalDurationSeconds : 360;
    final totalDistance = _totalRouteDistanceKm > 0 ? _totalRouteDistanceKm : 3.5;
    final elapsedSeconds = DateTime.now().difference(_dispatchedAt).inSeconds;

    if (elapsedSeconds >= totalDuration) {
      // Wall-clock time has reached or passed arrival time
      _status = AmbulanceStatus.arrived;
      _distanceKm = 0.0;
      _etaMinutes = 0;
      _currentWaypointIndex = _routePoints.length - 1;
      _currentPosition = _routePoints.last;
      _lastUpdatedAt = DateTime.now();

      if (_activeIncident != null && _activeIncident!.status != EmergencyStatus.arrived) {
        final updated = _activeIncident!.copyWith(
          ambulanceLatitude: _currentPosition.latitude,
          ambulanceLongitude: _currentPosition.longitude,
          distanceKm: 0.0,
          etaMinutes: 0,
          status: EmergencyStatus.arrived,
          lastUpdatedAt: _lastUpdatedAt,
        );
        _activeIncident = updated;
        onIncidentUpdated?.call(updated);
      }
    } else {
      // Ambulance is currently en route based on elapsed wall-clock seconds
      _status = AmbulanceStatus.enRoute;
      final progressRatio = (elapsedSeconds / totalDuration).clamp(0.0, 1.0);
      final remainingKm = totalDistance * (1.0 - progressRatio);
      _distanceKm = double.parse(remainingKm.clamp(0.0, 50.0).toStringAsFixed(1));

      final remainingSeconds = totalDuration - elapsedSeconds;
      _etaMinutes = max(1, (remainingSeconds / 60.0).ceil());

      if (_routePoints.length > 1) {
        _currentWaypointIndex = (progressRatio * (_routePoints.length - 1)).floor();
        _currentPosition = _routePoints[_currentWaypointIndex];
      }
      _lastUpdatedAt = DateTime.now();

      if (_activeIncident != null) {
        final updated = _activeIncident!.copyWith(
          ambulanceLatitude: _currentPosition.latitude,
          ambulanceLongitude: _currentPosition.longitude,
          distanceKm: _distanceKm,
          etaMinutes: _etaMinutes,
          status: EmergencyStatus.enRoute,
          lastUpdatedAt: _lastUpdatedAt,
        );
        _activeIncident = updated;
        onIncidentUpdated?.call(updated);
      }
    }
  }

  void _startMovementSimulation() {
    _movementTimer?.cancel();
    if (_routePoints.isEmpty || _isDisposed || _status == AmbulanceStatus.arrived) return;

    // Evaluate wall-clock time every 1.5 seconds
    _movementTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }

      _syncWallClockProgress();

      if (_status == AmbulanceStatus.arrived) {
        timer.cancel();
      }

      if (!_isDisposed) notifyListeners();
    });
  }

  /// Update stored incident details (such as arrivalPopupShown flag)
  void updateIncidentDetails({bool? arrivalPopupShown}) {
    if (_activeIncident != null) {
      _activeIncident = _activeIncident!.copyWith(
        arrivalPopupShown: arrivalPopupShown ?? _activeIncident!.arrivalPopupShown,
      );
    }
  }

  /// Reset / recall ambulance
  void reset() {
    _movementTimer?.cancel();
    _status = AmbulanceStatus.idle;
    _activeIncident = null;
    _routePoints = [];
    _totalRouteDistanceKm = 0.0;
    _distanceKm = 0.0;
    _etaMinutes = 0;
    _totalDurationSeconds = 0;
    _currentWaypointIndex = 0;
    _currentPosition = const LatLng(18.5326, 73.8785);
    _lastUpdatedAt = DateTime.now();
    if (!_isDisposed) notifyListeners();
  }

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    _movementTimer?.cancel();
    super.dispose();
  }
}
