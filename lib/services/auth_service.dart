import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import '../models/user.dart';
import '../models/doctor.dart';
import '../models/hospital_account.dart';
import 'firestore_service.dart';

class AuthService {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isFirebaseAvailable = false;

  AuthService() {
    _checkFirebaseStatus();
  }

  void _checkFirebaseStatus() {
    try {
      final app = fb_auth.FirebaseAuth.instance.app;
      _isFirebaseAvailable = true;
      debugPrint('Firebase Auth is ready on app: ${app.name}');
    } catch (e) {
      _isFirebaseAvailable = false;
      debugPrint('Firebase Auth not initialized. Running in Mock/Prototype Auth Mode.');
    }
  }

  bool get isFirebaseAvailable => _isFirebaseAvailable;

  /// Register Patient
  Future<AppUser> registerPatient({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    String uid = 'PATIENT-${DateTime.now().millisecondsSinceEpoch}';

    if (_isFirebaseAvailable) {
      try {
        final credential = await fb_auth.FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        if (credential.user != null) {
          uid = credential.user!.uid;
          await credential.user!.updateDisplayName(name);
        }
      } catch (e) {
        debugPrint('Firebase Auth Error (falling back to prototype ID): $e');
      }
    }

    final user = AppUser(
      uid: uid,
      name: name,
      email: email.trim(),
      phone: phone.trim(),
      role: UserRole.patient,
      createdAt: DateTime.now(),
    );

    // Save to Firestore / local repository
    await _firestoreService.createUserProfile(user);
    await _firestoreService.createDefaultMedicalProfile(uid, name, phone);

    return user;
  }

  /// Register Doctor
  Future<DoctorUser> registerDoctor({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String medicalRegistrationNumber,
    required String specialization,
    required String hospital,
  }) async {
    String uid = 'DOC-${DateTime.now().millisecondsSinceEpoch}';

    if (_isFirebaseAvailable) {
      try {
        final credential = await fb_auth.FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        if (credential.user != null) {
          uid = credential.user!.uid;
          await credential.user!.updateDisplayName('Dr. $name');
        }
      } catch (e) {
        debugPrint('Firebase Auth Error (falling back to prototype ID): $e');
      }
    }

    final doctor = DoctorUser(
      uid: uid,
      name: name,
      email: email.trim(),
      phone: phone.trim(),
      medicalRegistrationNumber: medicalRegistrationNumber.trim(),
      specialization: specialization.trim(),
      hospital: hospital.trim(),
      verificationStatus: DoctorVerificationStatus.pending,
      createdAt: DateTime.now(),
    );

    // Save to Firestore / local repository
    await _firestoreService.createDoctorProfile(doctor);

    return doctor;
  }

  /// Register Hospital with Firebase Auth & Firestore Profile
  Future<HospitalAccount> registerHospital({
    required HospitalAccount hospitalData,
    required String password,
  }) async {
    String uid = 'HOSP-${DateTime.now().millisecondsSinceEpoch}';

    if (_isFirebaseAvailable) {
      try {
        final credential = await fb_auth.FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: hospitalData.officialEmail.trim(),
          password: password,
        );
        if (credential.user != null) {
          uid = credential.user!.uid;
          await credential.user!.updateDisplayName(hospitalData.hospitalName);
        }
      } catch (e) {
        debugPrint('Firebase Auth Error registering hospital: $e');
      }
    }

    final hospital = HospitalAccount(
      id: uid,
      hospitalName: hospitalData.hospitalName,
      registrationNumber: hospitalData.registrationNumber,
      hospitalType: hospitalData.hospitalType,
      address: hospitalData.address,
      city: hospitalData.city,
      state: hospitalData.state,
      pinCode: hospitalData.pinCode,
      officialPhone: hospitalData.officialPhone,
      officialEmail: hospitalData.officialEmail.trim(),
      adminName: hospitalData.adminName,
      adminPhone: hospitalData.adminPhone,
      verificationStatus: hospitalData.verificationStatus,
      createdAt: DateTime.now(),
    );

    // Save profile to Firestore and local storage (without saving password to Firestore)
    await _firestoreService.saveHospitalProfile(hospital);
    return hospital;
  }

  /// Sign In for Hospital accounts
  Future<HospitalAccount?> signInHospital({
    required String email,
    required String password,
  }) async {
    String? uid;

    if (_isFirebaseAvailable) {
      try {
        final credential = await fb_auth.FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        uid = credential.user?.uid;
      } catch (e) {
        debugPrint('Firebase Hospital Login failed or offline: $e');
      }
    }

    // Lookup hospital by UID if Firebase signed in
    if (uid != null) {
      final hosp = await _firestoreService.getHospitalById(uid);
      if (hosp != null) return hosp;
    }

    // Lookup hospital by Email
    final hosp = await _firestoreService.getHospitalByEmail(email.trim());
    if (hosp != null) return hosp;

    // Fallback for default demo hospital credentials
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail == 'doctor.demo@g1care.com' ||
        cleanEmail == 'emergency.pune@rubyhall.demo' ||
        cleanEmail == HospitalAccount.demoHospital.officialEmail.toLowerCase()) {
      return HospitalAccount.demoHospital;
    }

    return null;
  }

  /// Sign In with Email & Password
  Future<dynamic> signIn({
    required String email,
    required String password,
  }) async {
    String? uid;

    if (_isFirebaseAvailable) {
      try {
        final credential = await fb_auth.FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        uid = credential.user?.uid;
      } catch (e) {
        debugPrint('Firebase Login failed or offline: $e');
      }
    }

    // First, check if this is a registered hospital account
    final hospital = await _firestoreService.getHospitalByEmail(email.trim());
    if (hospital != null) {
      return hospital;
    }

    // Lookup user in Firestore / local mock store
    final profile = await _firestoreService.getUserOrDoctorByEmail(email.trim());
    if (profile != null) {
      return profile;
    }

    // Default demo login fallback if profile isn't found
    if (email.contains('doctor') || email.contains('doc') || email.contains('rubyhall') || email.contains('hosp')) {
      final doc = DoctorUser(
        uid: uid ?? 'DOC-DEMO-001',
        name: 'Alex Sharma',
        email: email,
        phone: '+91 9876543210',
        medicalRegistrationNumber: 'MCI-2024-8849',
        specialization: 'Emergency Medicine',
        hospital: 'City Central Hospital',
        verificationStatus: DoctorVerificationStatus.approved,
        createdAt: DateTime.now(),
      );
      await _firestoreService.createDoctorProfile(doc);
      return doc;
    } else {
      final patient = AppUser(
        uid: uid ?? 'PATIENT-DEMO-001',
        name: 'Rahul Kumar',
        email: email,
        phone: '+91 9123456789',
        role: UserRole.patient,
        createdAt: DateTime.now(),
      );
      await _firestoreService.createUserProfile(patient);
      await _firestoreService.createDefaultMedicalProfile(patient.uid, patient.name, patient.phone);
      return patient;
    }
  }

  /// Sign Out
  Future<void> signOut() async {
    if (_isFirebaseAvailable) {
      try {
        await fb_auth.FirebaseAuth.instance.signOut();
      } catch (e) {
        debugPrint('Error signing out from Firebase: $e');
      }
    }
  }
}
