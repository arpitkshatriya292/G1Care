import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/user.dart';
import '../models/doctor.dart';
import '../models/medical_profile.dart';
import '../models/hospital_account.dart';
import 'medical_id_service.dart';

enum ProfileDataSource { liveFirestore, localCache, memoryCache, notFound }

class ProfileRetrievalResult {
  final MedicalProfile? profile;
  final ProfileDataSource source;
  final bool isLive;
  final String sourceLabel;
  final DateTime retrievedAt;
  final String? errorMessage;

  ProfileRetrievalResult({
    this.profile,
    required this.source,
    required this.isLive,
    required this.sourceLabel,
    required this.retrievedAt,
    this.errorMessage,
  });

  factory ProfileRetrievalResult.live(MedicalProfile profile) {
    return ProfileRetrievalResult(
      profile: profile,
      source: ProfileDataSource.liveFirestore,
      isLive: true,
      sourceLabel: 'Live Firestore Record',
      retrievedAt: DateTime.now(),
    );
  }

  factory ProfileRetrievalResult.cached(MedicalProfile profile, {String label = 'Cached Offline Record'}) {
    return ProfileRetrievalResult(
      profile: profile,
      source: ProfileDataSource.localCache,
      isLive: false,
      sourceLabel: label,
      retrievedAt: DateTime.now(),
    );
  }

  factory ProfileRetrievalResult.notFound(String message) {
    return ProfileRetrievalResult(
      profile: null,
      source: ProfileDataSource.notFound,
      isLive: false,
      sourceLabel: 'Not Found',
      retrievedAt: DateTime.now(),
      errorMessage: message,
    );
  }
}

class FirestoreService {
  // In-memory cache for fast synchronous access
  static final Map<String, AppUser> _mockUsers = {};
  static final Map<String, DoctorUser> _mockDoctors = {};
  static final Map<String, MedicalProfile> _mockProfiles = {};
  static final Map<String, HospitalAccount> _mockHospitals = {};
  static final Map<String, String> _mockMedicalIdToUid = {}; // Index: medicalId -> uid
  static final Map<String, StreamController<MedicalProfile?>> _profileControllers = {};

  static StreamController<MedicalProfile?> _getOrCreateProfileController(String uid) {
    return _profileControllers.putIfAbsent(
      uid,
      () => StreamController<MedicalProfile?>.broadcast(),
    );
  }

  /// Testing helper to simulate app restart memory clear
  @visibleForTesting
  static void clearInMemoryCacheForTesting() {
    _mockUsers.clear();
    _mockDoctors.clear();
    _mockProfiles.clear();
    _mockHospitals.clear();
    _mockMedicalIdToUid.clear();
    for (final controller in _profileControllers.values) {
      controller.close();
    }
    _profileControllers.clear();
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
      final fs = _firestore;
      return fs != null;
    } catch (_) {
      return false;
    }
  }

  /// Create or update User Profile
  Future<void> createUserProfile(AppUser user) async {
    _mockUsers[user.uid] = user;

    // Persist locally for offline/restart resilience
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('g1care_user_${user.uid}', jsonEncode(user.toMap()));
    } catch (e) {
      debugPrint('Local storage error saving user: $e');
    }

    if (_isFirestoreAvailable) {
      try {
        await _firestore!
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .set(user.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore Error saving user profile: $e');
      }
    }
  }

  /// Create or update Doctor Profile
  Future<void> createDoctorProfile(DoctorUser doctor) async {
    _mockDoctors[doctor.uid] = doctor;

    // Persist locally for offline/restart resilience
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('g1care_doctor_${doctor.uid}', jsonEncode(doctor.toMap()));
    } catch (e) {
      debugPrint('Local storage error saving doctor: $e');
    }

    if (_isFirestoreAvailable) {
      try {
        await _firestore!
            .collection(AppConstants.doctorsCollection)
            .doc(doctor.uid)
            .set(doctor.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore Error saving doctor profile: $e');
      }
    }
  }

  /// Create Default Medical Profile for Patient (Safe: does not overwrite existing profile)
  Future<MedicalProfile> createDefaultMedicalProfile(String uid, String name, String phone,
      {String? medicalId}) async {
    // Check if profile already exists locally or remotely before creating default
    final existing = await getMedicalProfile(uid);
    if (existing != null) {
      return existing;
    }

    final assignedMedId = medicalId ?? MedicalIdService.generateMedicalId();
    final profile = MedicalProfile.empty(uid, name, phone, medicalId: assignedMedId);
    
    await saveMedicalProfile(profile);
    return profile;
  }

  /// Save or Update Patient Medical Profile
  Future<void> saveMedicalProfile(MedicalProfile profile) async {
    _mockProfiles[profile.uid] = profile;
    if (profile.medicalId.isNotEmpty) {
      _mockMedicalIdToUid[profile.medicalId] = profile.uid;
    }

    // Persist locally for offline/restart resilience
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('g1care_profile_${profile.uid}', jsonEncode(profile.toMap()));
      if (profile.medicalId.isNotEmpty) {
        await prefs.setString('g1care_med_id_${profile.medicalId}', profile.uid);
      }
    } catch (e) {
      debugPrint('Local storage error saving medical profile: $e');
    }

    if (_isFirestoreAvailable) {
      try {
        // Save full private profile under medicalProfiles/{uid}
        await _firestore!
            .collection(AppConstants.medicalProfilesCollection)
            .doc(profile.uid)
            .set(profile.toMap(), SetOptions(merge: true));

        // Index Medical ID for fast emergency lookup if medicalId is present
        if (profile.medicalId.isNotEmpty) {
          await _firestore!
              .collection(AppConstants.medicalIdsCollection)
              .doc(profile.medicalId)
              .set({
            'medicalId': profile.medicalId,
            'uid': profile.uid,
            'fullName': profile.fullName,
            'bloodGroup': profile.bloodGroup,
            'updatedAt': profile.updatedAt.toIso8601String(),
          }, SetOptions(merge: true));
        }
      } catch (e) {
        debugPrint('Firestore Error saving medical profile: $e');
      }
    }

    // Broadcast update to real-time streams
    _getOrCreateProfileController(profile.uid).add(profile);
    if (profile.medicalId.isNotEmpty) {
      _getOrCreateProfileController('med_${profile.medicalId}').add(profile);
    }
  }

  /// Patient-Only Update: Modifies ONLY Personal Details and ICE Contacts, preserving all hospital medical data
  Future<MedicalProfile> updatePatientPersonalAndIceData(
    String uid,
    MedicalProfile patientChanges,
  ) async {
    final existing = await getMedicalProfile(uid) ?? MedicalProfile.empty(uid, patientChanges.fullName, patientChanges.phone);
    final updated = existing.copyWithPatientDetails(
      fullName: patientChanges.fullName,
      dateOfBirth: patientChanges.dateOfBirth,
      gender: patientChanges.gender,
      phone: patientChanges.phone,
      address: patientChanges.address,
      emergencyContactInfo: patientChanges.emergencyContactInfo,
    );
    await saveMedicalProfile(updated);
    return updated;
  }

  /// Hospital-Only Update: Modifies Hospital-Managed Medical Data, preserving patient personal details
  Future<MedicalProfile> updateHospitalManagedMedicalData(
    String uid,
    MedicalProfile hospitalChanges, {
    String? hospitalName,
  }) async {
    final existing = await getMedicalProfile(uid) ?? MedicalProfile.empty(uid, hospitalChanges.fullName, hospitalChanges.phone);
    final updated = existing.copyWithHospitalMedicalData(
      bloodGroup: hospitalChanges.bloodGroup,
      allergies: hospitalChanges.allergies,
      medicines: hospitalChanges.medicines,
      medicalConditions: hospitalChanges.medicalConditions,
      previousSurgeries: hospitalChanges.previousSurgeries,
      previousIllnesses: hospitalChanges.previousIllnesses,
      emergencyNotes: hospitalChanges.emergencyNotes,
      primaryDoctor: hospitalChanges.primaryDoctor,
      hospitalTag: hospitalName != null ? 'hospital ($hospitalName)' : 'hospital',
    );
    await saveMedicalProfile(updated);
    return updated;
  }

  /// Real-time stream of patient's medical profile
  Stream<MedicalProfile?> streamMedicalProfile(String uid) {
    if (_isFirestoreAvailable) {
      try {
        return _firestore!
            .collection(AppConstants.medicalProfilesCollection)
            .doc(uid)
            .snapshots()
            .map((snap) {
          if (snap.exists && snap.data() != null) {
            final profile = MedicalProfile.fromMap(snap.data()!);
            _mockProfiles[uid] = profile;
            if (profile.medicalId.isNotEmpty) {
              _mockMedicalIdToUid[profile.medicalId] = profile.uid;
            }
            return profile;
          }
          return _mockProfiles[uid];
        });
      } catch (e) {
        debugPrint('Error attaching Firestore profile stream: $e');
      }
    }

    // Offline / Mock / In-memory fallback stream
    final controller = _getOrCreateProfileController(uid);
    // Yield current value if present
    if (_mockProfiles.containsKey(uid)) {
      Future.microtask(() {
        if (!controller.isClosed) {
          controller.add(_mockProfiles[uid]);
        }
      });
    }
    return controller.stream;
  }

  /// Real-time stream of patient's medical profile by Medical ID
  Stream<ProfileRetrievalResult> streamProfileWithSourceByMedicalId(String medicalId) {
    final sanitizedMedId = medicalId.trim();
    if (sanitizedMedId.isEmpty) {
      return Stream.value(ProfileRetrievalResult.notFound('Medical ID cannot be empty'));
    }

    final controller = StreamController<ProfileRetrievalResult>.broadcast();

    // Initial fetch
    fetchProfileWithSourceByMedicalId(sanitizedMedId).then((initialResult) {
      if (!controller.isClosed) {
        controller.add(initialResult);
      }

      if (initialResult.profile != null) {
        final uid = initialResult.profile!.uid;
        streamMedicalProfile(uid).listen((updatedProfile) {
          if (!controller.isClosed && updatedProfile != null) {
            controller.add(ProfileRetrievalResult.live(updatedProfile));
          }
        }, onError: (err) {
          if (!controller.isClosed) {
            controller.add(ProfileRetrievalResult.cached(
              initialResult.profile!,
              label: 'Cached Record (Stream Error)',
            ));
          }
        });
      }
    });

    return controller.stream;
  }

  /// Get Patient Medical Profile by UID
  Future<MedicalProfile?> getMedicalProfile(String uid) async {
    if (_mockProfiles.containsKey(uid)) {
      return _mockProfiles[uid];
    }

    // Attempt to load from persistent local SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString('g1care_profile_$uid');
      if (profileJson != null && profileJson.isNotEmpty) {
        final Map<String, dynamic> data = jsonDecode(profileJson) as Map<String, dynamic>;
        final profile = MedicalProfile.fromMap(data);
        _mockProfiles[uid] = profile;
        if (profile.medicalId.isNotEmpty) {
          _mockMedicalIdToUid[profile.medicalId] = profile.uid;
        }
        return profile;
      }
    } catch (e) {
      debugPrint('Local storage error loading medical profile: $e');
    }

    if (_isFirestoreAvailable) {
      try {
        final snapshot = await _firestore!
            .collection(AppConstants.medicalProfilesCollection)
            .doc(uid)
            .get();
        if (snapshot.exists && snapshot.data() != null) {
          final profile = MedicalProfile.fromMap(snapshot.data()!);
          _mockProfiles[uid] = profile;
          if (profile.medicalId.isNotEmpty) {
            _mockMedicalIdToUid[profile.medicalId] = profile.uid;
          }
          // Also persist locally for offline access
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('g1care_profile_$uid', jsonEncode(profile.toMap()));
            if (profile.medicalId.isNotEmpty) {
              await prefs.setString('g1care_med_id_${profile.medicalId}', profile.uid);
            }
          } catch (_) {}
          return profile;
        }
      } catch (e) {
        debugPrint('Firestore Error getting medical profile: $e');
      }
    }
    return null;
  }

  /// Get Patient Medical Profile with Live/Cached Source Metadata
  Future<ProfileRetrievalResult> fetchProfileWithSourceByMedicalId(String medicalId) async {
    final sanitizedMedId = medicalId.trim();
    if (sanitizedMedId.isEmpty) {
      return ProfileRetrievalResult.notFound('Medical ID cannot be empty');
    }

    // 1. Try Live Firestore first if available
    if (_isFirestoreAvailable) {
      try {
        final doc = await _firestore!
            .collection(AppConstants.medicalIdsCollection)
            .doc(sanitizedMedId)
            .get();
        if (doc.exists && doc.data() != null) {
          final uid = doc.data()!['uid'] as String?;
          if (uid != null && uid.isNotEmpty) {
            _mockMedicalIdToUid[sanitizedMedId] = uid;
            final profileDoc = await _firestore!
                .collection(AppConstants.medicalProfilesCollection)
                .doc(uid)
                .get();
            if (profileDoc.exists && profileDoc.data() != null) {
              final profile = MedicalProfile.fromMap(profileDoc.data()!);
              _mockProfiles[uid] = profile;
              // Cache locally
              try {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('g1care_profile_$uid', jsonEncode(profile.toMap()));
                await prefs.setString('g1care_med_id_$sanitizedMedId', uid);
              } catch (_) {}
              return ProfileRetrievalResult.live(profile);
            }
          }
        }
      } catch (e) {
        debugPrint('Firestore query error (falling back to offline cache): $e');
      }
    }

    // 2. Fallback to Local Persistent Cache (SharedPreferences)
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedUid = prefs.getString('g1care_med_id_$sanitizedMedId');
      if (cachedUid != null && cachedUid.isNotEmpty) {
        final profileJson = prefs.getString('g1care_profile_$cachedUid');
        if (profileJson != null && profileJson.isNotEmpty) {
          final profile = MedicalProfile.fromMap(jsonDecode(profileJson) as Map<String, dynamic>);
          _mockProfiles[cachedUid] = profile;
          _mockMedicalIdToUid[sanitizedMedId] = cachedUid;
          return ProfileRetrievalResult.cached(profile, label: 'Cached Offline Record');
        }
      }
    } catch (e) {
      debugPrint('Local storage retrieval error: $e');
    }

    // 3. Fallback to In-Memory Session Cache
    if (_mockMedicalIdToUid.containsKey(sanitizedMedId)) {
      final uid = _mockMedicalIdToUid[sanitizedMedId]!;
      if (_mockProfiles.containsKey(uid)) {
        return ProfileRetrievalResult.cached(_mockProfiles[uid]!, label: 'Session Cached Record');
      }
    }

    return ProfileRetrievalResult.notFound('No medical profile found for ID "$sanitizedMedId"');
  }

  /// Get Patient Medical Profile by Medical ID (Convenience wrapper)
  Future<MedicalProfile?> getProfileByMedicalId(String medicalId) async {
    final result = await fetchProfileWithSourceByMedicalId(medicalId);
    return result.profile;
  }

  /// Get User or Doctor by UID
  Future<dynamic> getUserOrDoctor(String uid) async {
    if (_mockDoctors.containsKey(uid)) {
      return _mockDoctors[uid];
    }
    if (_mockUsers.containsKey(uid)) {
      return _mockUsers[uid];
    }

    // Check local storage
    try {
      final prefs = await SharedPreferences.getInstance();
      final doctorJson = prefs.getString('g1care_doctor_$uid');
      if (doctorJson != null && doctorJson.isNotEmpty) {
        final doctor = DoctorUser.fromMap(jsonDecode(doctorJson) as Map<String, dynamic>);
        _mockDoctors[uid] = doctor;
        return doctor;
      }
      final userJson = prefs.getString('g1care_user_$uid');
      if (userJson != null && userJson.isNotEmpty) {
        final user = AppUser.fromMap(jsonDecode(userJson) as Map<String, dynamic>);
        _mockUsers[uid] = user;
        return user;
      }
    } catch (e) {
      debugPrint('Local storage error fetching user/doctor: $e');
    }

    if (_isFirestoreAvailable) {
      try {
        final docSnapshot = await _firestore!
            .collection(AppConstants.doctorsCollection)
            .doc(uid)
            .get();
        if (docSnapshot.exists && docSnapshot.data() != null) {
          final doctor = DoctorUser.fromMap(docSnapshot.data()!);
          _mockDoctors[uid] = doctor;
          return doctor;
        }

        final userSnapshot = await _firestore!
            .collection(AppConstants.usersCollection)
            .doc(uid)
            .get();
        if (userSnapshot.exists && userSnapshot.data() != null) {
          final user = AppUser.fromMap(userSnapshot.data()!);
          _mockUsers[uid] = user;
          return user;
        }
      } catch (e) {
        debugPrint('Firestore Error fetching user/doctor: $e');
      }
    }
    return null;
  }

  /// Get User or Doctor by Email
  Future<dynamic> getUserOrDoctorByEmail(String email) async {
    final searchEmail = email.trim().toLowerCase();
    for (var doc in _mockDoctors.values) {
      if (doc.email.trim().toLowerCase() == searchEmail) return doc;
    }
    for (var u in _mockUsers.values) {
      if (u.email.trim().toLowerCase() == searchEmail) return u;
    }

    // Check local storage
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith('g1care_user_')) {
          final jsonStr = prefs.getString(key);
          if (jsonStr != null && jsonStr.isNotEmpty) {
            final user = AppUser.fromMap(jsonDecode(jsonStr) as Map<String, dynamic>);
            if (user.email.trim().toLowerCase() == searchEmail) {
              _mockUsers[user.uid] = user;
              return user;
            }
          }
        } else if (key.startsWith('g1care_doctor_')) {
          final jsonStr = prefs.getString(key);
          if (jsonStr != null && jsonStr.isNotEmpty) {
            final doctor = DoctorUser.fromMap(jsonDecode(jsonStr) as Map<String, dynamic>);
            if (doctor.email.trim().toLowerCase() == searchEmail) {
              _mockDoctors[doctor.uid] = doctor;
              return doctor;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Local storage error querying email: $e');
    }

    if (_isFirestoreAvailable) {
      try {
        final docQuery = await _firestore!
            .collection(AppConstants.doctorsCollection)
            .where('email', isEqualTo: email.trim())
            .get();
        if (docQuery.docs.isNotEmpty) {
          final doctor = DoctorUser.fromMap(docQuery.docs.first.data());
          _mockDoctors[doctor.uid] = doctor;
          return doctor;
        }

        final userQuery = await _firestore!
            .collection(AppConstants.usersCollection)
            .where('email', isEqualTo: email.trim())
            .get();
        if (userQuery.docs.isNotEmpty) {
          final user = AppUser.fromMap(userQuery.docs.first.data());
          _mockUsers[user.uid] = user;
          return user;
        }
      } catch (e) {
        debugPrint('Firestore Error querying email: $e');
      }
    }
    return null;
  }

  /// Update Doctor Verification Status (Admin/Prototype Simulation)
  Future<DoctorUser> updateDoctorVerificationStatus(
    String uid,
    DoctorVerificationStatus status,
  ) async {
    dynamic existing = await getUserOrDoctor(uid);
    DoctorUser? doctor = existing is DoctorUser ? existing : _mockDoctors[uid];

    if (doctor != null) {
      doctor = doctor.copyWith(verificationStatus: status);
      _mockDoctors[uid] = doctor;
    } else {
      doctor = DoctorUser(
        uid: uid,
        name: 'Doctor',
        email: '',
        phone: '',
        medicalRegistrationNumber: 'MCI-000',
        specialization: 'General',
        hospital: 'General Hospital',
        verificationStatus: status,
        createdAt: DateTime.now(),
      );
      _mockDoctors[uid] = doctor;
    }

    // Persist locally
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('g1care_doctor_$uid', jsonEncode(doctor.toMap()));
    } catch (e) {
      debugPrint('Local storage error updating doctor status: $e');
    }

    if (_isFirestoreAvailable) {
      try {
        await _firestore!
            .collection(AppConstants.doctorsCollection)
            .doc(uid)
            .update({
          'verificationStatus': status.name,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        debugPrint('Firestore Error updating verification status: $e');
      }
    }

    return doctor;
  }

  /// Create or update Hospital Profile (multi-hospital architecture)
  Future<void> saveHospitalProfile(HospitalAccount hospital) async {
    _mockHospitals[hospital.id] = hospital;

    // Persist locally for offline / app-restart resilience
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('g1care_hospital_${hospital.id}', jsonEncode(hospital.toMap()));

      // Save email -> hospitalId mapping for login lookup
      await prefs.setString(
        'g1care_hospital_email_${hospital.officialEmail.toLowerCase().trim()}',
        hospital.id,
      );

      // Track all registered hospital IDs
      final idList = prefs.getStringList('g1care_all_hospital_ids') ?? [];
      if (!idList.contains(hospital.id)) {
        idList.add(hospital.id);
        await prefs.setStringList('g1care_all_hospital_ids', idList);
      }
    } catch (e) {
      debugPrint('Local storage error saving hospital: $e');
    }

    // Persist in Firestore under hospitals/{uid}
    if (_isFirestoreAvailable) {
      try {
        await _firestore!
            .collection(AppConstants.hospitalsCollection)
            .doc(hospital.id)
            .set(hospital.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore Error saving hospital profile: $e');
      }
    }
  }

  /// Retrieve hospital profile by unique ID
  Future<HospitalAccount?> getHospitalById(String hospitalId) async {
    // 1. Check in-memory cache
    if (_mockHospitals.containsKey(hospitalId)) {
      return _mockHospitals[hospitalId];
    }

    // 2. Check Firestore if available
    if (_isFirestoreAvailable) {
      try {
        final doc = await _firestore!
            .collection(AppConstants.hospitalsCollection)
            .doc(hospitalId)
            .get();
        if (doc.exists && doc.data() != null) {
          final hosp = HospitalAccount.fromMap(doc.data()!);
          _mockHospitals[hosp.id] = hosp;
          return hosp;
        }
      } catch (e) {
        debugPrint('Firestore Error fetching hospital by id: $e');
      }
    }

    // 3. Check SharedPreferences local storage
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedJson = prefs.getString('g1care_hospital_$hospitalId');
      if (storedJson != null && storedJson.isNotEmpty) {
        final hosp = HospitalAccount.fromMap(jsonDecode(storedJson) as Map<String, dynamic>);
        _mockHospitals[hosp.id] = hosp;
        return hosp;
      }
    } catch (e) {
      debugPrint('Local storage error retrieving hospital: $e');
    }

    // 4. Default demo hospital fallback if ID matches demo
    if (hospitalId == HospitalAccount.demoHospital.id || hospitalId == 'HOSP-DEMO-001') {
      return HospitalAccount.demoHospital;
    }

    return null;
  }

  /// Retrieve hospital profile by email
  Future<HospitalAccount?> getHospitalByEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();

    // 1. Check in-memory cache
    for (final hosp in _mockHospitals.values) {
      if (hosp.officialEmail.toLowerCase().trim() == cleanEmail) {
        return hosp;
      }
    }

    // 2. Check demo hospital emails
    if (cleanEmail == HospitalAccount.demoHospital.officialEmail.toLowerCase().trim() ||
        cleanEmail == 'doctor.demo@g1care.com' ||
        cleanEmail == 'emergency.pune@rubyhall.demo') {
      return HospitalAccount.demoHospital;
    }

    // 3. Check Firestore
    if (_isFirestoreAvailable) {
      try {
        final query = await _firestore!
            .collection(AppConstants.hospitalsCollection)
            .where('officialEmail', isEqualTo: email.trim())
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) {
          final hosp = HospitalAccount.fromMap(query.docs.first.data());
          _mockHospitals[hosp.id] = hosp;
          return hosp;
        }
      } catch (e) {
        debugPrint('Firestore Error fetching hospital by email: $e');
      }
    }

    // 4. Check SharedPreferences mapping
    try {
      final prefs = await SharedPreferences.getInstance();
      final hospId = prefs.getString('g1care_hospital_email_$cleanEmail');
      if (hospId != null && hospId.isNotEmpty) {
        return await getHospitalById(hospId);
      }
    } catch (e) {
      debugPrint('Local storage error searching hospital by email: $e');
    }

    return null;
  }

  /// Get all registered hospitals
  Future<List<HospitalAccount>> getAllHospitals() async {
    final list = <HospitalAccount>[];
    final seenIds = <String>{};

    for (final hosp in _mockHospitals.values) {
      if (!seenIds.contains(hosp.id)) {
        list.add(hosp);
        seenIds.add(hosp.id);
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final idList = prefs.getStringList('g1care_all_hospital_ids') ?? [];
      for (final id in idList) {
        if (!seenIds.contains(id)) {
          final hosp = await getHospitalById(id);
          if (hosp != null && !seenIds.contains(hosp.id)) {
            list.add(hosp);
            seenIds.add(hosp.id);
          }
        }
      }
    } catch (_) {}

    if (!seenIds.contains(HospitalAccount.demoHospital.id)) {
      list.add(HospitalAccount.demoHospital);
    }

    return list;
  }
}
