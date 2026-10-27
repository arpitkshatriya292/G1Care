import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/hospital_account.dart';
import '../models/hospital_doctor.dart';
import '../services/firestore_service.dart';

class HospitalProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  HospitalAccount _currentHospital = HospitalAccount.demoHospital;
  final List<HospitalDoctor> _doctors = List.from(HospitalDoctor.demoDoctors);
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;

  HospitalProvider() {
    _initStorage();
  }

  HospitalAccount get currentHospital => _currentHospital;
  List<HospitalDoctor> get doctors => List.unmodifiable(_doctors);
  List<HospitalDoctor> get verifiedDoctors => _doctors.where((d) => d.isVerified).toList();
  List<HospitalDoctor> get unverifiedDoctors => _doctors.where((d) => !d.isVerified).toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalDoctorsCount => _doctors.length;
  int get verifiedDoctorsCount => _doctors.where((d) => d.isVerified).length;
  int get unverifiedDoctorsCount => _doctors.where((d) => !d.isVerified).length;

  String _doctorStorageKey(String hospitalId) => 'g1care_hospital_doctors_$hospitalId';

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

  Future<void> _initStorage() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastHospId = prefs.getString('g1care_current_hospital_id');
      if (lastHospId != null && lastHospId.isNotEmpty) {
        final hosp = await _firestoreService.getHospitalById(lastHospId);
        if (hosp != null) {
          _currentHospital = hosp;
        }
      }
    } catch (_) {}
    await loadDoctorsForCurrentHospital();
    _isInitialized = true;
  }

  /// Switch or set current authenticated hospital session (Isolates Hospital A from Hospital B)
  Future<void> setCurrentHospital(HospitalAccount hospital) async {
    _currentHospital = hospital;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('g1care_current_hospital_id', hospital.id);
    } catch (_) {}
    await loadDoctorsForCurrentHospital();
    notifyListeners();
  }

  /// Load hospital profile by ID from Firestore / cache and set as active session
  Future<bool> loadHospitalById(String hospitalId) async {
    _isLoading = true;
    notifyListeners();

    final hosp = await _firestoreService.getHospitalById(hospitalId);
    if (hosp != null) {
      await setCurrentHospital(hosp);
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Backwards-compatible loader for doctor list
  Future<void> loadDoctorsFromStorage() => loadDoctorsForCurrentHospital();

  /// Load verified and registered doctors specifically for the active hospital
  Future<void> loadDoctorsForCurrentHospital() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storageKey = _doctorStorageKey(_currentHospital.id);
      String? storedJson = prefs.getString(storageKey);
      if (storedJson == null && _currentHospital.id == HospitalAccount.demoHospital.id) {
        storedJson = prefs.getString('g1care_hospital_doctors');
      }

      if (storedJson != null && storedJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(storedJson) as List<dynamic>;
        _doctors.clear();
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            _doctors.add(HospitalDoctor.fromMap(item));
          }
        }
      } else {
        _doctors.clear();
        _doctors.addAll(HospitalDoctor.demoDoctors);
        await _saveDoctorsToStorage();
      }
    } catch (e) {
      debugPrint('Error loading doctors from storage: $e');
      if (_doctors.isEmpty) {
        _doctors.addAll(HospitalDoctor.demoDoctors);
      }
    }
    notifyListeners();
  }

  Future<void> _saveDoctorsToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(_doctors.map((d) => d.toMap()).toList());
      // Save to global key (for backwards compatibility / single hospital tests)
      await prefs.setString('g1care_hospital_doctors', jsonString);
      // And save to hospital-specific key (for multi-hospital isolation)
      await prefs.setString(_doctorStorageKey(_currentHospital.id), jsonString);
    } catch (e) {
      debugPrint('Error persisting doctors to SharedPreferences: $e');
    }

    if (_isFirestoreAvailable) {
      try {
        final batch = _firestore!.batch();
        for (final doc in _doctors) {
          final docRef = _firestore!
              .collection(AppConstants.hospitalsCollection)
              .doc(_currentHospital.id)
              .collection('doctors')
              .doc(doc.id);
          batch.set(docRef, doc.toMap(), SetOptions(merge: true));
        }
        await batch.commit();
      } catch (e) {
        debugPrint('Error syncing doctors to Firestore: $e');
      }
    }
  }

  /// Register a new Hospital account and persist in Firestore & local store
  Future<void> registerHospital(HospitalAccount hospital) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await _firestoreService.saveHospitalProfile(hospital);
    await setCurrentHospital(hospital);

    _isLoading = false;
    notifyListeners();
  }

  /// Add a new doctor from Hospital Portal and persist immediately
  Future<void> addDoctor({
    required String name,
    required String medicalRegistrationNumber,
    required String specialty,
    required String department,
    required String role,
    required String phone,
    required String email,
    required int yearsOfExperience,
    required String joiningDate,
    bool isVerified = false,
  }) async {
    _isLoading = true;
    notifyListeners();

    final newDoc = HospitalDoctor(
      id: 'DOC-PUN-${DateTime.now().millisecondsSinceEpoch % 10000}',
      name: name,
      medicalRegistrationNumber: medicalRegistrationNumber,
      specialty: specialty,
      department: department,
      role: role,
      phone: phone,
      email: email,
      yearsOfExperience: yearsOfExperience,
      joiningDate: joiningDate,
      isVerified: isVerified,
    );

    _doctors.insert(0, newDoc);
    await _saveDoctorsToStorage();
    _isLoading = false;
    notifyListeners();
  }

  /// Verify a doctor (Hospital Administrator Action)
  Future<void> verifyDoctor(String doctorId) async {
    final index = _doctors.indexWhere((d) => d.id == doctorId);
    if (index != -1) {
      _doctors[index] = _doctors[index].copyWith(isVerified: true);
      await _saveDoctorsToStorage();
      notifyListeners();
    }
  }

  /// Toggle doctor verification status (for testing / admin revocation)
  Future<void> toggleDoctorVerification(String doctorId) async {
    final index = _doctors.indexWhere((d) => d.id == doctorId);
    if (index != -1) {
      final current = _doctors[index].isVerified;
      _doctors[index] = _doctors[index].copyWith(isVerified: !current);
      await _saveDoctorsToStorage();
      notifyListeners();
    }
  }
}
