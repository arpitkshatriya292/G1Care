import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:g1care/core/constants/app_constants.dart';
import 'package:g1care/models/user.dart';
import 'package:g1care/models/doctor.dart';
import 'package:g1care/providers/auth_provider.dart';
import 'package:g1care/services/firestore_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FirestoreService.clearInMemoryCacheForTesting();
  });

  group('Milestone 1 Auth & Models Unit Tests', () {
    test('AppUser patient model serialization', () {
      final user = AppUser(
        uid: 'USR101',
        name: 'Rahul Kumar',
        email: 'rahul@example.com',
        phone: '+919876543210',
        role: UserRole.patient,
        createdAt: DateTime.now(),
      );

      expect(user.uid, 'USR101');
      expect(user.role, UserRole.patient);

      final map = user.toMap();
      final fromMapUser = AppUser.fromMap(map);

      expect(fromMapUser.name, 'Rahul Kumar');
      expect(fromMapUser.role, UserRole.patient);
    });

    test('DoctorUser verification status checks', () {
      final doctorPending = DoctorUser(
        uid: 'DOC101',
        name: 'Alex Sharma',
        email: 'doctor@example.com',
        phone: '+919876543210',
        medicalRegistrationNumber: 'MCI-8899',
        specialization: 'Cardiology',
        hospital: 'City Hospital',
        verificationStatus: DoctorVerificationStatus.pending,
        createdAt: DateTime.now(),
      );

      expect(doctorPending.isPending, isTrue);
      expect(doctorPending.isApproved, isFalse);

      final doctorApproved = doctorPending.copyWith(
        verificationStatus: DoctorVerificationStatus.approved,
      );

      expect(doctorApproved.isApproved, isTrue);
      expect(doctorApproved.isPending, isFalse);
    });

    test('AuthProvider state transitions and prototype doctor approval toggle', () async {
      final provider = AuthProvider();
      expect(provider.status, AuthStatus.unauthenticated);

      final regSuccess = await provider.registerDoctor(
        name: 'Test Doc',
        email: 'testdoc@g1care.com',
        phone: '+919876543210',
        password: 'password123',
        medicalRegistrationNumber: 'MCI-0011',
        specialization: 'Emergency',
        hospital: 'Metro Hospital',
      );

      expect(regSuccess, isTrue);
      expect(provider.isDoctor, isTrue);
      expect(provider.doctorVerificationStatus, DoctorVerificationStatus.pending);
      expect(provider.isDoctorApproved, isFalse);

      // Simulate Admin Approval Toggle
      await provider.simulateDoctorApprovalToggle();

      expect(provider.doctorVerificationStatus, DoctorVerificationStatus.approved);
      expect(provider.isDoctorApproved, isTrue);
    });
  });
}
