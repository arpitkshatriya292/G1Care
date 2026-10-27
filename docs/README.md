# G1Care - Smart Emergency Medical Identification and Response System

G1Care is a Flutter application designed for emergency medical identification and response. It provides role-based features for **Patients** and **Verified Doctors**.

## Milestone 1 Overview
- **Clean Modular Architecture**: Clean separation into `core`, `models`, `services`, `providers`, `screens`, and `widgets`.
- **Material 3 Healthcare Theme**: Clean medical blue/teal aesthetic with Google Fonts (Outfit & Inter) and high contrast emergency styling.
- **Authentication & Roles**: Full authentication for Patient and Doctor roles.
- **Doctor Verification State Engine**: Doctor access is guarded by `verificationStatus` (PENDING, APPROVED, REJECTED, SUSPENDED).
- **Prototype Admin Simulator**: Allows manual toggling of doctor approval status for instant hackathon testing.
- **Offline / Mock Fallback**: Includes in-memory mock repositories so the app runs out-of-the-box in Android Studio without requiring immediate Firebase configuration.

## Folder Structure
```
g1care/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── constants/
│   │   ├── theme/
│   │   ├── routing/
│   │   ├── errors/
│   │   └── utils/
│   ├── models/
│   │   ├── user.dart
│   │   ├── doctor.dart
│   │   └── medical_profile.dart
│   ├── services/
│   │   ├── auth_service.dart
│   │   └── firestore_service.dart
│   ├── providers/
│   │   └── auth_provider.dart
│   ├── screens/
│   │   ├── splash/
│   │   ├── auth/
│   │   ├── patient/
│   │   └── doctor/
│   └── widgets/
│       ├── vital_card.dart
│       ├── sos_button.dart
│       ├── status_chip.dart
│       ├── doctor_verification_card.dart
│       └── loading_widget.dart
├── test/
│   ├── auth_test.dart
│   └── widget_test.dart
└── docs/
```
