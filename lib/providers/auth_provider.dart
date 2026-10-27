import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../models/user.dart';
import '../models/doctor.dart';
import '../models/hospital_account.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

enum AuthStatus { uninitialized, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  AuthStatus _status = AuthStatus.uninitialized;
  dynamic _currentUser; // AppUser, DoctorUser, or HospitalAccount
  UserRole? _selectedRole;
  String? _errorMessage;
  bool _isLoading = false;

  AuthStatus get status => _status;
  dynamic get currentUser => _currentUser;
  UserRole? get selectedRole => _selectedRole;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  bool get isPatient => _currentUser is AppUser;
  bool get isDoctor => _currentUser is DoctorUser || _currentUser is HospitalAccount;
  bool get isHospital => _currentUser is HospitalAccount;

  AppUser? get patientUser => isPatient ? _currentUser as AppUser : null;
  DoctorUser? get doctorUser => _currentUser is DoctorUser ? _currentUser as DoctorUser : null;
  HospitalAccount? get hospitalUser => isHospital ? _currentUser as HospitalAccount : null;

  DoctorVerificationStatus get doctorVerificationStatus {
    if (isDoctor && doctorUser != null) {
      return doctorUser!.verificationStatus;
    }
    return DoctorVerificationStatus.pending;
  }

  bool get isDoctorApproved =>
      isDoctor && doctorUser?.verificationStatus == DoctorVerificationStatus.approved;

  AuthProvider() {
    _initAuth();
  }

  Future<void> _initAuth() async {
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void setSelectedRole(UserRole role) {
    _selectedRole = role;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userProfile = await _authService.signIn(
        email: email,
        password: password,
      );

      if (userProfile != null) {
        _currentUser = userProfile;
        _selectedRole = isDoctor ? UserRole.doctor : UserRole.patient;
        _status = AuthStatus.authenticated;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Invalid credentials or user record not found.';
        _status = AuthStatus.unauthenticated;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.unauthenticated;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginHospital(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final hospital = await _authService.signInHospital(
        email: email,
        password: password,
      );

      if (hospital != null) {
        _currentUser = hospital;
        _selectedRole = UserRole.doctor;
        _status = AuthStatus.authenticated;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Invalid hospital credentials or record not found.';
        _status = AuthStatus.unauthenticated;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.unauthenticated;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerHospital({
    required HospitalAccount hospitalData,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final hospital = await _authService.registerHospital(
        hospitalData: hospitalData,
        password: password,
      );

      _currentUser = hospital;
      _selectedRole = UserRole.doctor;
      _status = AuthStatus.authenticated;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerPatient({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.registerPatient(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );

      _currentUser = user;
      _selectedRole = UserRole.patient;
      _status = AuthStatus.authenticated;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerDoctor({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String medicalRegistrationNumber,
    required String specialization,
    required String hospital,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final doctor = await _authService.registerDoctor(
        name: name,
        email: email,
        phone: phone,
        password: password,
        medicalRegistrationNumber: medicalRegistrationNumber,
        specialization: specialization,
        hospital: hospital,
      );

      _currentUser = doctor;
      _selectedRole = UserRole.doctor;
      _status = AuthStatus.authenticated;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Hackathon Prototype Admin Simulator: Toggle Doctor Approval Status
  Future<void> simulateDoctorApprovalToggle() async {
    if (!isDoctor || doctorUser == null) return;

    final newStatus = doctorUser!.isApproved
        ? DoctorVerificationStatus.pending
        : DoctorVerificationStatus.approved;

    _isLoading = true;
    notifyListeners();

    final updatedDoctor = await _firestoreService.updateDoctorVerificationStatus(
      doctorUser!.uid,
      newStatus,
    );

    _currentUser = updatedDoctor;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _authService.signOut();
    _currentUser = null;
    _selectedRole = null;
    _status = AuthStatus.unauthenticated;
    _isLoading = false;
    notifyListeners();
  }
}
