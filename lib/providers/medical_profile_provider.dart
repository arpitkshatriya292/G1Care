import 'dart:async';
import 'package:flutter/material.dart';
import '../models/emergency_contact.dart';
import '../models/emergency_qr_payload.dart';
import '../models/medical_profile.dart';
import '../models/medicine_item.dart';
import '../services/firestore_service.dart';
import '../services/medical_id_service.dart';

class MedicalProfileProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  MedicalProfile? _profile;
  String? _qrToken;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  StreamSubscription<MedicalProfile?>? _profileSubscription;

  MedicalProfile? get profile => _profile;
  String get qrToken => _qrToken ?? '';
  bool get hasQrToken => _qrToken != null && _qrToken!.isNotEmpty;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  String get medicalId => _profile?.medicalId ?? '';
  String get bloodGroup => _profile?.bloodGroup ?? 'Unknown';
  List<String> get allergies => _profile?.allergies ?? [];
  List<MedicineItem> get medicines => _profile?.medicines ?? [];
  List<String> get medicalConditions => _profile?.medicalConditions ?? [];
  List<String> get previousSurgeries => _profile?.previousSurgeries ?? [];
  List<String> get previousIllnesses => _profile?.previousIllnesses ?? [];
  String get emergencyNotes => _profile?.emergencyNotes ?? '';
  String get primaryDoctor => _profile?.primaryDoctor ?? '';
  String get lastUpdatedBy => _profile?.lastUpdatedBy ?? 'system';
  EmergencyContactInfo get emergencyContactInfo =>
      _profile?.emergencyContactInfo ?? EmergencyContactInfo.empty();

  /// Returns the signed minimal offline Emergency QR payload DTO
  EmergencyQrPayload? get emergencySnapshot {
    if (_profile == null) return null;
    return MedicalIdService.createSignedEmergencyPayload(_profile!);
  }

  /// Returns the raw JSON encoded string for QR generation (legacy/internal)
  String get qrPayloadString {
    if (_profile == null) return '';
    return MedicalIdService.generateQrString(_profile!);
  }

  /// Helper for unit/widget testing
  void setProfileForTesting(MedicalProfile testProfile) {
    _profile = testProfile;
    notifyListeners();
  }

  /// Load profile for patient UID or initialize a new default profile with unique Medical ID
  Future<void> loadProfile(String uid, {String name = 'Patient', String phone = ''}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      var loadedProfile = await _firestoreService.getMedicalProfile(uid);

      if (loadedProfile == null) {
        // Initialize default profile with freshly generated Medical ID
        final generatedId = MedicalIdService.generateMedicalId();
        loadedProfile = await _firestoreService.createDefaultMedicalProfile(
          uid,
          name,
          phone,
          medicalId: generatedId,
        );
      } else if (loadedProfile.medicalId.isEmpty) {
        // If an existing legacy profile lacked a medical ID, generate and save one
        final generatedId = MedicalIdService.generateMedicalId();
        loadedProfile = loadedProfile.copyWith(medicalId: generatedId);
        await _firestoreService.saveMedicalProfile(loadedProfile);
      }

      _profile = loadedProfile;
      
      // Generate and register secure opaque QR token for this patient profile
      _qrToken = MedicalIdService.generateQrToken();
      MedicalIdService.registerQrToken(_qrToken!, loadedProfile.medicalId);

      // Subscribe to real-time updates from Firestore / server
      await _profileSubscription?.cancel();
      _profileSubscription = _firestoreService.streamMedicalProfile(uid).listen((updated) {
        if (updated != null) {
          _profile = updated;
          if (_qrToken == null || _qrToken!.isEmpty) {
            _qrToken = MedicalIdService.generateQrToken();
          }
          MedicalIdService.registerQrToken(_qrToken!, updated.medicalId);
          notifyListeners();
        }
      });

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load medical profile: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Patient action: Save ONLY personal details and ICE contacts, keeping hospital-managed data intact
  Future<bool> savePatientDetails(MedicalProfile patientChanges) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final updated = await _firestoreService.updatePatientPersonalAndIceData(
        patientChanges.uid.isNotEmpty ? patientChanges.uid : (_profile?.uid ?? ''),
        patientChanges,
      );
      _profile = updated;

      if (_qrToken == null || _qrToken!.isEmpty) {
        _qrToken = MedicalIdService.generateQrToken();
      }
      MedicalIdService.registerQrToken(_qrToken!, updated.medicalId);

      _successMessage = 'Personal details updated successfully.';
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update personal details: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Hospital action: Update hospital-managed medical fields for a patient
  Future<bool> saveHospitalManagedMedicalData(
    String uid,
    MedicalProfile hospitalChanges, {
    String? hospitalName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final updated = await _firestoreService.updateHospitalManagedMedicalData(
        uid,
        hospitalChanges,
        hospitalName: hospitalName,
      );
      _profile = updated;

      _successMessage = 'Patient medical record updated by hospital successfully.';
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update hospital medical record: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Save or update the entire medical profile (General/Full update)
  Future<bool> saveProfile(MedicalProfile updatedProfile) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      // Ensure updated timestamp and medical ID retention
      final profileToSave = updatedProfile.copyWith(
        medicalId: updatedProfile.medicalId.isNotEmpty
            ? updatedProfile.medicalId
            : (_profile?.medicalId ?? MedicalIdService.generateMedicalId()),
        updatedAt: DateTime.now(),
      );

      await _firestoreService.saveMedicalProfile(profileToSave);
      _profile = profileToSave;

      // Re-register or ensure token points to updated medical ID
      if (_qrToken == null || _qrToken!.isEmpty) {
        _qrToken = MedicalIdService.generateQrToken();
      }
      MedicalIdService.registerQrToken(_qrToken!, profileToSave.medicalId);

      _successMessage = 'Medical profile saved successfully.';
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to save medical profile: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Quick helper: Add an allergy tag
  Future<void> addAllergy(String allergy) async {
    if (_profile == null || allergy.trim().isEmpty) return;
    final trimmed = allergy.trim();
    if (_profile!.allergies.contains(trimmed)) return;

    final updated = _profile!.copyWith(
      allergies: [..._profile!.allergies, trimmed],
    );
    await saveProfile(updated);
  }

  /// Quick helper: Remove an allergy tag
  Future<void> removeAllergy(String allergy) async {
    if (_profile == null) return;
    final updated = _profile!.copyWith(
      allergies: _profile!.allergies.where((a) => a != allergy).toList(),
    );
    await saveProfile(updated);
  }

  /// Quick helper: Add a medicine item
  Future<void> addMedicine(MedicineItem medicine) async {
    if (_profile == null) return;
    final updated = _profile!.copyWith(
      medicines: [..._profile!.medicines, medicine],
    );
    await saveProfile(updated);
  }

  /// Quick helper: Remove a medicine item
  Future<void> removeMedicine(int index) async {
    if (_profile == null || index < 0 || index >= _profile!.medicines.length) return;
    final list = List<MedicineItem>.from(_profile!.medicines)..removeAt(index);
    final updated = _profile!.copyWith(medicines: list);
    await saveProfile(updated);
  }

  /// Reset message flags
  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    super.dispose();
  }
}
