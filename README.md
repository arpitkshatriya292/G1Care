# 🩺 G1Care — AI-Powered Personal Health Companion

**G1Care** is a smart personal health companion designed to monitor users' health, identify potential emergencies, and connect users with hospitals through a digital health monitoring and emergency response system.

The project focuses on health monitoring, emergency SOS alerts, hospital coordination, and disaster preparedness. It aims to provide timely assistance through real-time data synchronization and a user-friendly mobile application.

---

## 📌 Table of Contents

* [Project Overview](#-project-overview)
* [Problem Statement](#-problem-statement)
* [Objectives](#-objectives)
* [Key Features](#-key-features)
* [System Workflow](#-system-workflow)
* [Technology Stack](#-technology-stack)
* [System Architecture](#-system-architecture)
* [User Roles](#-user-roles)
* [Project Structure](#-project-structure)
* [Installation and Setup](#-installation-and-setup)
* [Testing](#-testing)
* [Future Scope](#-future-scope)
* [Disclaimer](#-disclaimer)

---

## 🌍 Project Overview

G1Care is a Flutter-based mobile application prototype that aims to improve personal health monitoring and emergency response.

The application provides a digital health monitoring interface, emergency SOS functionality, hospital dashboards, and disaster-related information.

It uses Firebase services for backend functionality and data synchronization. The system is designed to help users access emergency assistance while allowing registered hospitals to view and respond to reported emergencies.

G1Care also includes a Disaster Mode interface to support awareness and preparedness during events such as heatwaves, floods, cyclones, earthquakes, and air pollution emergencies.

---

## ⚠️ Problem Statement

People may experience medical emergencies without being able to contact emergency services quickly. Delays in identifying health risks and coordinating assistance can increase the difficulty of providing timely support.

Traditional emergency systems may also face challenges during disasters, when communication and access to healthcare facilities can be disrupted.

G1Care aims to address these challenges by bringing health monitoring, emergency reporting, hospital coordination, and disaster preparedness into one application.

---

## 🎯 Objectives

* Provide a simple interface for personal health monitoring.
* Display health indicators such as heart rate and SpO₂.
* Allow users to trigger emergency SOS alerts.
* Make emergency information available to registered hospitals.
* Provide hospital-specific login and dashboard access.
* Support persistent data synchronization using Firebase.
* Provide a Disaster Mode interface for disaster-related information.
* Explore the use of on-device intelligence for early identification of potential health risks.

---

## ✨ Key Features

### 1. User Authentication

* User registration and login.
* Hospital registration and login.
* Separate access interfaces for users and hospitals.
* User-friendly authentication screens.

### 2. Digital Health Monitoring

* Digital wristband interface.
* Heart rate display.
* SpO₂ (blood oxygen saturation) display.
* Health status indicators for normal, warning, and critical conditions.

*Note: The current prototype's displayed readings should not be assumed to come from a physical medical sensor unless the appropriate hardware has been connected.*

### 3. Emergency SOS System

* Emergency SOS functionality for users.
* Emergency status visibility for registered hospitals.
* Hospital access to emergency information.
* Emergency response coordination.
* Persistent emergency status, subject to the implemented backend logic.

### 4. Hospital Dashboard

* Hospital registration and authentication.
* Hospital-specific dashboard access.
* Emergency incident monitoring.
* Hospital-side emergency management.

### 5. Disaster Mode

Provides a dedicated interface for disaster-related scenarios, including:

* Heatwaves
* Floods
* Cyclones
* Earthquakes
* Air pollution

The interface is intended to support disaster awareness and preparedness.

### 6. Firebase Integration

* Backend integration for application data.
* Cloud-based data storage where configured.
* Data synchronization between supported application sessions.
* Persistent storage for supported user, hospital, and emergency records.

### 7. Mobile Application Interface

* Flutter-based interface.
* Separate user and hospital experiences.
* Health monitoring screens.
* Emergency navigation and dashboard screens.

---

## 🔄 System Workflow

The following workflow describes the intended operation of G1Care.

```text
                  ┌─────────────────────┐
                  │    Launch G1Care    │
                  └──────────┬──────────┘
                             │
                  ┌──────────▼──────────┐
                  │      Login Page     │
                  └──────────┬──────────┘
                             │
                  ┌──────────▼──────────┐
                  │ Select Login Type   │
                  └──────────┬──────────┘
                             │
               ┌─────────────┴─────────────┐
               │                           │
      ┌────────▼────────┐         ┌────────▼────────┐
      │   User Login    │         │  Hospital Login │
      └────────┬────────┘         └────────┬────────┘
               │                           │
      ┌────────▼────────┐         ┌────────▼────────┐
      │ User Dashboard  │         │Hospital Dashboard│
      └────────┬────────┘         └────────┬────────┘
               │                           │
      ┌────────▼────────┐         ┌────────▼────────┐
      │ View Health Data│         │ View Emergencies│
      └────────┬────────┘         └────────┬────────┘
               │                           │
      ┌────────▼────────┐         ┌────────▼────────┐
      │ Assess Status   │         │ Open Incident   │
      └────────┬────────┘         └────────┬────────┘
               │                           │
         ┌─────▼─────┐             ┌───────▼────────┐
         │ SOS Alert?│             │ Respond to SOS │
         └─────┬─────┘             └───────┬────────┘
               │                           │
         Yes ──┘                           │
               │                           │
      ┌────────▼────────┐                   │
      │ Save/Publish SOS│                   │
      │ Through Backend │                   │
      └────────┬────────┘                   │
               │                           │
      ┌────────▼────────┐                   │
      │ Registered      │◄──────────────────┘
      │ Hospitals View  │
      │ Emergency Alert │
      └─────────────────┘

       Firebase supports configured
       authentication and data storage.
```

### Workflow Explanation

**Step 1: Launch the Application**

The user opens G1Care and reaches the login interface.

**Step 2: Select a Login Type**

The user selects either User Login or Hospital Login.

**Step 3: Authenticate**

The application authenticates the account using the configured authentication system.

**Step 4: Open the Dashboard**

* Users access their health monitoring and emergency features.
* Hospitals access their hospital dashboard and emergency management features.

**Step 5: Monitor Health Information**

The user can view the available health indicators, including heart rate and SpO₂.

**Step 6: Trigger an Emergency**

When an emergency occurs, the user can use the SOS functionality. Any automatic emergency detection depends on the features and data sources actually implemented.

**Step 7: Synchronize Emergency Information**

The application sends emergency information to the configured backend.

**Step 8: Hospital Response**

Registered hospitals can access available emergency information and respond through their dashboards, according to the implemented access controls and workflow.

**Step 9: Manage the Emergency**

The emergency status should remain consistent across supported sessions until the incident is resolved through the appropriate workflow.

---

## 🏗️ System Architecture

G1Care follows a mobile application and backend architecture.

```text
┌──────────────────────────────────────────┐
│           Flutter Mobile App             │
│                                          │
│  ┌────────────────┐  ┌────────────────┐  │
│  │ User Interface │  │Hospital Interface│ │
│  └────────────────┘  └────────────────┘  │
│                                          │
│  Authentication, Health Data and SOS     │
└────────────────────┬─────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────┐
│              Firebase Backend            │
│                                          │
│  ┌────────────────┐  ┌────────────────┐  │
│  │ Authentication │  │   Firestore    │  │
│  │                │  │  Data Storage  │  │
│  └────────────────┘  └────────────────┘  │
└────────────────────┬─────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────┐
│       Authorized Application Sessions    │
│                                          │
│   User Health Views and Hospital SOS     │
│             Management                   │
└──────────────────────────────────────────┘
```

Firebase Authentication and Cloud Firestore are used where configured in the project. Actual access permissions and synchronization behavior depend on the backend implementation and security rules.

---

## 🛠️ Technology Stack

| Technology              | Purpose                                       |
| ----------------------- | --------------------------------------------- |
| Flutter                 | Mobile application development                |
| Dart                    | Application programming language              |
| Firebase Authentication | User authentication, where configured         |
| Cloud Firestore         | Cloud data storage and synchronization        |
| Android Studio          | Development and debugging                     |
| Git                     | Version control                               |
| GitHub                  | Source code hosting and project collaboration |

---

## 👥 User Roles

### User

* Register and log in.
* Access the user dashboard.
* View available health information.
* Use emergency SOS functionality.
* Access supported emergency-related screens.

### Hospital

* Register and log in.
* Access its hospital dashboard.
* View available emergency incidents.
* Open and respond to emergency reports.
* Manage supported hospital-side emergency workflows.

Hospital-specific data isolation should be enforced through backend authorization and Firestore security rules, not just by hiding information in the user interface.

---

## 📁 Project Structure

The main project folders and files include:

```text
G1Care/
│
├── android/          # Android platform files
├── assets/           # Application assets and images
├── docs/             # Project documentation
├── ios/              # iOS platform files
├── lib/
│   ├── core/          # Shared constants and utilities
│   ├── models/        # Application data models
│   ├── providers/     # State management and providers
│   ├── screens/
│   │   ├── auth/      # Authentication screens
│   │   ├── disaster/  # Disaster Mode screens
│   │   ├── doctor/    # Doctor-related screens
│   │   ├── hospital/  # Hospital screens
│   │   ├── patient/   # User health screens
│   │   └── splash/    # Splash screen
│   ├── services/      # Backend and application services
│   ├── widgets/       # Reusable UI components
│   ├── app.dart       # Application configuration
│   └── main.dart      # Application entry point
│
├── test/              # Automated tests
├── web/               # Web platform files
├── windows/           # Windows platform files
├── pubspec.yaml       # Dependencies and project configuration
├── pubspec.lock       # Resolved dependency versions
├── analysis_options.yaml
├── .gitignore
└── README.md
```

*The structure above summarizes the main directories; individual files may change as development continues.*

---

## 🚀 Installation and Setup

### Prerequisites

Install the following tools:

* Flutter SDK
* Dart SDK (included with Flutter)
* Android Studio
* Git
* A GitHub account

### Step 1: Clone the Repository

```bash
git clone https://github.com/arpitkshatriya292/G1Care.git
```

### Step 2: Open the Project

```bash
cd G1Care
```

Open this folder in Android Studio or your preferred Flutter-compatible IDE.

### Step 3: Install Dependencies

Run:

```bash
flutter pub get
```

### Step 4: Configure Firebase

Ensure the required Firebase project configuration is available for the target platform.

Verify that:

* Firebase Authentication is configured if required by the application.
* Cloud Firestore is enabled if used by the application.
* Platform configuration files are available.
* Firestore security rules enforce appropriate access controls.

Do not commit service-account private keys, passwords, or other sensitive credentials to GitHub.

### Step 5: Check the Flutter Environment

```bash
flutter doctor
```

Resolve any required setup issues for your target platform.

### Step 6: Run the Application

Connect an Android device with USB debugging enabled or start an Android emulator.

Then run:

```bash
flutter run
```

---

## 🧪 Testing

The project includes automated Flutter tests.

Run static analysis:

```bash
flutter analyze
```

Run automated tests:

```bash
flutter test
```

These commands help identify code issues and verify automated test cases.

Passing tests do not, by themselves, guarantee that every feature works correctly on a physical device or in a production environment.

---

## 🔮 Future Scope

Potential future improvements include:

* Integration with physical health-monitoring wearables.
* Reliable sensor-based heart rate and SpO₂ collection.
* On-device AI for identifying potential health anomalies.
* Secure QR-based emergency identification.
* Improved emergency location sharing.
* Live ambulance tracking and navigation.
* Push notifications for emergency alerts.
* Stronger hospital verification and access controls.
* Improved operation during network disruptions.
* Enhanced disaster-related health alerts.
* Additional security, privacy, and reliability testing.

These are proposed improvements; their availability depends on future development and integration.

---

## 🔐 Security and Privacy

G1Care is designed around personal health information and emergency coordination.

Important security considerations include:

* Use authenticated access for protected features.
* Apply appropriate Firestore security rules.
* Restrict hospital access to authorized data.
* Avoid storing passwords directly in application databases.
* Keep private API credentials and service-account keys out of source control.
* Avoid publishing real patient information.
* Test authentication, authorization, and data isolation before deployment.

**Important:** This repository describes a prototype. Do not rely on it as a production medical monitoring or emergency dispatch system without appropriate validation, security review, and operational testing.

---

## ⚕️ Disclaimer

G1Care is a software prototype developed for educational and demonstration purposes.

It is not a substitute for professional medical advice, diagnosis, treatment, or emergency services. Displayed health readings and emergency alerts should not be treated as medically validated unless the underlying hardware and software have been appropriately tested.

In an actual emergency, contact the appropriate local emergency services.

---

## 👨‍💻 Developer

**Project:** G1Care — AI-Powered Personal Health Companion

**Repository:** [GitHub — G1Care](https://github.com/arpitkshatriya292/G1Care)

---

⭐ If you find this project interesting, consider starring the repository and sharing your feedback.

