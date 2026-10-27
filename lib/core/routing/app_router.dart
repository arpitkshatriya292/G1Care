import 'package:flutter/material.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/auth/role_selection_screen.dart';
import '../../screens/patient/patient_home_screen.dart';
import '../../screens/patient/medical_profile_screen.dart';
import '../../screens/patient/edit_medical_profile_screen.dart';
import '../../screens/patient/medical_id_qr_screen.dart';
import '../../screens/patient/wristband_screen.dart';
import '../../screens/patient/patient_emergency_map_screen.dart';
import '../../screens/patient/disaster/disaster_mode_screen.dart';
import '../../screens/disaster/disaster_hub_screen.dart';
import '../../screens/patient/disaster/disaster_safe_location_screen.dart';
import '../../screens/patient/disaster/disaster_ask_ai_screen.dart';
import '../../screens/patient/disaster/disaster_wellness_screen.dart';
import '../../screens/doctor/doctor_home_screen.dart';
import '../../screens/doctor/doctor_verification_screen.dart';
import '../../screens/doctor/doctor_qr_scanner_screen.dart';
import '../../screens/doctor/emergency_triage_screen.dart';
import '../../screens/doctor/doctor_patient_profile_screen.dart';
import '../../screens/doctor/active_emergencies_screen.dart';
import '../../screens/doctor/doctor_emergency_map_screen.dart';

import '../../screens/hospital/hospital_registration_screen.dart';
import '../../screens/hospital/doctor_management_screen.dart';
import '../../screens/hospital/hospital_edit_patient_medical_screen.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Map<String, WidgetBuilder> get routes => {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/role-selection': (context) => const RoleSelectionScreen(),
        '/hospital/register': (context) => const HospitalRegistrationScreen(),
        '/hospital/doctors': (context) => const DoctorManagementScreen(),
        '/hospital/patient/edit-medical': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return HospitalEditPatientMedicalScreen(
            medicalId: args?['medicalId'] ?? '',
            patientUid: args?['patientUid'],
          );
        },
        '/patient/home': (context) => const PatientHomeScreen(),
        '/patient/medical-profile': (context) => const MedicalProfileScreen(),
        '/patient/medical-profile/edit': (context) => const EditMedicalProfileScreen(),
        '/patient/medical-id': (context) => const MedicalIdQrScreen(),
        '/patient/wristband': (context) => const WristbandScreen(),
        '/patient/emergency-map': (context) => const PatientEmergencyMapScreen(),
        '/disaster-hub': (context) => const DisasterHubScreen(),
        '/disaster-mode': (context) => const DisasterHubScreen(),
        '/patient/disaster-mode': (context) => const DisasterModeScreen(),
        '/patient/disaster-mode/safe-locations': (context) => const DisasterSafeLocationScreen(),
        '/patient/disaster-mode/ask-ai': (context) => const DisasterAskAiScreen(),
        '/patient/disaster-mode/wellness': (context) => const DisasterWellnessScreen(),
        '/doctor/home': (context) => const DoctorHomeScreen(),
        '/doctor/verification': (context) => const DoctorVerificationScreen(),
        '/doctor/scan': (context) => const DoctorQrScannerScreen(),
        '/doctor/triage': (context) => const EmergencyTriageScreen(),
        '/doctor/patient-profile': (context) => const DoctorPatientProfileScreen(),
        '/doctor/active-emergencies': (context) => const ActiveEmergenciesScreen(),
        '/doctor/emergency-map': (context) => const DoctorEmergencyMapScreen(),
      };
}
