# Firebase Configuration Guide for G1Care

G1Care utilizes Firebase Authentication and Cloud Firestore for role storage, hospital doctor management, separated patient vs hospital medical profile permissions, and real-time multi-device emergency synchronization.

## Connecting Real Firebase Credentials
1. Go to [Firebase Console](https://console.firebase.google.com/) and create a project named `G1Care`.
2. Add an Android app with package name `com.g1care.g1care`.
3. Download `google-services.json` and place it at:
   `android/app/google-services.json`
4. Enable **Email/Password** authentication in Firebase Authentication console.
5. Create a Cloud Firestore database.

## Milestone 8 Firestore Security Rules
Copy and apply the following security rules in Firebase Console:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Check if request is made by account owner (Patient)
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    // Check if request is made by an authorized verified doctor or hospital staff
    function isApprovedDoctorOrHospital() {
      return isAuthenticated() && (
        (exists(/databases/$(database)/documents/doctors/$(request.auth.uid)) &&
         get(/databases/$(database)/documents/doctors/$(request.auth.uid)).data.verificationStatus == 'approved') ||
        (exists(/databases/$(database)/documents/hospitals/$(request.auth.uid)))
      );
    }

    // Users Collection (Patient Accounts) - Strict Self Access
    match /users/{userId} {
      allow read, write: if isOwner(userId);
    }

    // Hospitals Collection - Read by authenticated, Write by hospital admin
    match /hospitals/{hospitalId} {
      allow read: if isAuthenticated();
      allow write: if isOwner(hospitalId);
    }

    // Doctors Collection - Authenticated Read, Self/Hospital Write
    match /doctors/{doctorId} {
      allow read: if isAuthenticated();
      allow write: if isOwner(doctorId) || isApprovedDoctorOrHospital();
    }

    // Full Private Medical Profiles - Strict Field Ownership Separation:
    // 1. Patient Owner: Can read full profile, but can ONLY write personal details (fullName, dateOfBirth, gender, phone, address) and ICE contact.
    // 2. Verified Hospital / Doctor: Can read full profile, and can update clinical medical data (bloodGroup, allergies, conditions, medicines, surgeries, illnesses, directives).
    match /medicalProfiles/{userId} {
      allow read: if isOwner(userId) || isApprovedDoctorOrHospital();
      
      // Patient write rule: Prevent patient from overwriting clinical fields
      allow update: if isOwner(userId) &&
                       !request.resource.data.diff(resource.data).affectedKeys()
                        .hasAny(['bloodGroup', 'allergies', 'medicines', 'medicalConditions', 'previousSurgeries', 'previousIllnesses', 'emergencyNotes', 'primaryDoctor']);
      
      // Hospital / Doctor write rule: Can update clinical fields
      allow update: if isApprovedDoctorOrHospital();
      
      // Initial creation
      allow create: if isOwner(userId) || isApprovedDoctorOrHospital();
    }

    // Medical ID Index - Patient Owner Create, Verified Doctor Read/Query
    match /medicalIDs/{medicalId} {
      allow read: if isApprovedDoctorOrHospital();
      allow write: if isAuthenticated();
    }

    // Real-Time Active Emergency Incidents - Multi-Device Broadcast Sync
    match /emergencies/{incidentId} {
      // Patient owner and all hospital emergency teams can read live emergency streams
      allow read: if isAuthenticated();
      
      // Patients can trigger/cancel their own emergencies
      allow create: if isAuthenticated();
      
      // Hospital staff and responding doctors can update incident status (responded, treated, discharged, resolved)
      allow update: if isApprovedDoctorOrHospital() || isOwner(resource.data.patientUid);
      
      // Discharged records remain archived and are not deleted
      allow delete: if false;
    }
  }
}
```

