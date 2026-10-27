import 'package:flutter/material.dart';

enum UserRole { patient, doctor }

enum DoctorVerificationStatus { pending, approved, rejected, suspended }

class AppConstants {
  static const String appName = 'G1Care';
  static const String appTagline = 'Smart Health & Disaster Response System';

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String doctorsCollection = 'doctors';
  static const String medicalProfilesCollection = 'medicalProfiles';
  static const String medicalIdsCollection = 'medicalIDs';
  static const String sensorReadingsCollection = 'sensorReadings';
  static const String emergenciesCollection = 'emergencies';
  static const String hospitalsCollection = 'hospitals';
  static const String auditLogsCollection = 'auditLogs';

  // Storage Keys
  static const String keyUserRole = 'g1care_user_role';
  static const String keyUserId = 'g1care_user_id';
  static const String keyIsLoggedIn = 'g1care_is_logged_in';
}

class AppColors {
  // Brand Healthcare Palette
  static const Color primary = Color(0xFF0F52BA);      // Medical Navy Blue
  static const Color primaryDark = Color(0xFF0A367C);  // Deep Medical Blue
  static const Color primaryLight = Color(0xFFE8F0FE); // Soft Blue Surface
  
  static const Color secondary = Color(0xFF00A896);    // Medical Teal Accent
  static const Color secondaryLight = Color(0xFFE6F7F5);

  // Status & Emergency Colors
  static const Color emergencyRed = Color(0xFFE63946);  // Emergency SOS Red
  static const Color emergencyRedBg = Color(0xFFFFEBEB);
  static const Color warningOrange = Color(0xFFF77F00); // Warning/Pending
  static const Color warningOrangeBg = Color(0xFFFFF4E5);
  static const Color successGreen = Color(0xFF2A9D8F);  // Verified/Normal
  static const Color successGreenBg = Color(0xFFE8F8F5);

  // Neutral Colors
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE2E8F0);
  
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
}
