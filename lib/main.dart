import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';

import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notification service
  await NotificationService().initialize();

  // Safely initialize Firebase if options/google-services.json are present
  try {
    await Firebase.initializeApp();
    debugPrint('Firebase initialized successfully.');
  } catch (e) {
    debugPrint('Firebase initial setup notice: $e');
    debugPrint('G1Care running with safe local mock fallback for Android Studio testing.');
  }

  runApp(const G1CareApp());
}
