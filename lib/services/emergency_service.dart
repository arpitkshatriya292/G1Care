import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/emergency_incident.dart';

class EmergencyService {
  static final Map<String, EmergencyIncident> _mockEmergencies = {};
  static final StreamController<List<EmergencyIncident>> _emergenciesStreamController =
      StreamController<List<EmergencyIncident>>.broadcast();

  @visibleForTesting
  static void clearInMemoryEmergenciesForTesting() {
    _mockEmergencies.clear();
  }

  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  bool get _isFirestoreAvailable {
    try {
      return _firestore != null;
    } catch (_) {
      return false;
    }
  }

  /// Create or update an emergency incident
  Future<void> saveEmergencyIncident(EmergencyIncident incident) async {
    _mockEmergencies[incident.incidentId] = incident;

    // Persist locally for offline / cold restart resilience
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'g1care_emergency_${incident.incidentId}',
        jsonEncode(incident.toMap()),
      );

      // Maintain list of all emergency IDs
      final idList = prefs.getStringList('g1care_all_emergency_ids') ?? [];
      if (!idList.contains(incident.incidentId)) {
        idList.add(incident.incidentId);
        await prefs.setStringList('g1care_all_emergency_ids', idList);
      }
    } catch (e) {
      debugPrint('Local storage error saving emergency: $e');
    }

    if (_isFirestoreAvailable) {
      try {
        await _firestore!
            .collection(AppConstants.emergenciesCollection)
            .doc(incident.incidentId)
            .set(incident.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore Error saving emergency incident: $e');
      }
    }

    // Broadcast updated active emergencies list to subscribers
    _broadcastActiveEmergencies();
  }

  void _broadcastActiveEmergencies() {
    getActiveEmergencies().then((list) {
      if (!_emergenciesStreamController.isClosed) {
        _emergenciesStreamController.add(list);
      }
    });
  }

  /// Check if an active emergency already exists for this patient (Duplicate prevention)
  Future<EmergencyIncident?> findActiveEmergencyForPatient(String patientUid) async {
    final activeList = await getActiveEmergencies();
    for (final inc in activeList) {
      if (inc.patientUid == patientUid && inc.status.isActiveOrPending) {
        return inc;
      }
    }
    return null;
  }

  /// Real-time stream of all active emergencies in the network
  Stream<List<EmergencyIncident>> getActiveEmergenciesStream() {
    if (_isFirestoreAvailable) {
      try {
        return _firestore!
            .collection(AppConstants.emergenciesCollection)
            .snapshots()
            .map((snapshot) {
          final list = <EmergencyIncident>[];
          final seenIds = <String>{};
          for (final doc in snapshot.docs) {
            final inc = EmergencyIncident.fromMap(doc.data());
            _mockEmergencies[inc.incidentId] = inc;
            if (inc.status.isActiveOrPending && !seenIds.contains(inc.incidentId)) {
              list.add(inc);
              seenIds.add(inc.incidentId);
            }
          }
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
      } catch (e) {
        debugPrint('Error attaching Firestore emergencies stream: $e');
      }
    }

    // Offline / In-memory fallback stream
    Future.microtask(() => _broadcastActiveEmergencies());
    return _emergenciesStreamController.stream;
  }

  /// Get specific emergency by ID
  Future<EmergencyIncident?> getEmergencyIncident(String incidentId) async {
    if (_mockEmergencies.containsKey(incidentId)) {
      return _mockEmergencies[incidentId];
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('g1care_emergency_$incidentId');
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final incident = EmergencyIncident.fromMap(
          jsonDecode(jsonStr) as Map<String, dynamic>,
        );
        _mockEmergencies[incidentId] = incident;
        return incident;
      }
    } catch (e) {
      debugPrint('Local storage error loading emergency: $e');
    }

    if (_isFirestoreAvailable) {
      try {
        final doc = await _firestore!
            .collection(AppConstants.emergenciesCollection)
            .doc(incidentId)
            .get();
        if (doc.exists && doc.data() != null) {
          final incident = EmergencyIncident.fromMap(doc.data()!);
          _mockEmergencies[incidentId] = incident;
          return incident;
        }
      } catch (e) {
        debugPrint('Firestore Error fetching emergency: $e');
      }
    }

    return null;
  }

  /// Get all active emergencies (for Doctor Network)
  Future<List<EmergencyIncident>> getActiveEmergencies() async {
    final list = <EmergencyIncident>[];
    final seenIds = <String>{};

    // 1. From in-memory
    for (final inc in _mockEmergencies.values) {
      if (inc.status.isActiveOrPending && !seenIds.contains(inc.incidentId)) {
        list.add(inc);
        seenIds.add(inc.incidentId);
      }
    }

    // 2. From local storage
    try {
      final prefs = await SharedPreferences.getInstance();
      final idList = prefs.getStringList('g1care_all_emergency_ids') ?? [];
      for (final id in idList) {
        if (!seenIds.contains(id)) {
          final jsonStr = prefs.getString('g1care_emergency_$id');
          if (jsonStr != null && jsonStr.isNotEmpty) {
            final inc = EmergencyIncident.fromMap(
              jsonDecode(jsonStr) as Map<String, dynamic>,
            );
            _mockEmergencies[id] = inc;
            if (inc.status.isActiveOrPending) {
              list.add(inc);
              seenIds.add(id);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Local storage error querying active emergencies: $e');
    }

    // 3. From Firestore
    if (_isFirestoreAvailable) {
      try {
        final query = await _firestore!
            .collection(AppConstants.emergenciesCollection)
            .get();
        for (final doc in query.docs) {
          final inc = EmergencyIncident.fromMap(doc.data());
          _mockEmergencies[inc.incidentId] = inc;
          if (!seenIds.contains(inc.incidentId) && inc.status.isActiveOrPending) {
            list.add(inc);
            seenIds.add(inc.incidentId);
          }
        }
      } catch (e) {
        debugPrint('Firestore Error querying active emergencies: $e');
      }
    }

    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }
}
