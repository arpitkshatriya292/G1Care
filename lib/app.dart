import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'providers/auth_provider.dart';
import 'providers/medical_profile_provider.dart';
import 'providers/location_provider.dart';
import 'providers/wristband_provider.dart';
import 'providers/ambulance_provider.dart';
import 'providers/emergency_provider.dart';
import 'providers/hospital_provider.dart';
import 'providers/disaster_provider.dart';

class G1CareApp extends StatelessWidget {
  const G1CareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider<HospitalProvider>(create: (_) => HospitalProvider()),
        ChangeNotifierProvider<MedicalProfileProvider>(create: (_) => MedicalProfileProvider()),
        ChangeNotifierProvider<LocationProvider>(create: (_) => LocationProvider()),
        ChangeNotifierProvider<WristbandProvider>(create: (_) => WristbandProvider()),
        ChangeNotifierProvider<AmbulanceLocationProvider>(create: (_) => AmbulanceLocationProvider()),
        ChangeNotifierProxyProvider<AmbulanceLocationProvider, EmergencyProvider>(
          create: (ctx) => EmergencyProvider(
            ambulanceProvider: Provider.of<AmbulanceLocationProvider>(ctx, listen: false),
          ),
          update: (ctx, ambulance, previous) =>
              previous ?? EmergencyProvider(ambulanceProvider: ambulance),
        ),
        ChangeNotifierProvider<DisasterProvider>(create: (_) => DisasterProvider()),
      ],
      child: MaterialApp(
        navigatorKey: AppRouter.navigatorKey,
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/',
        routes: AppRouter.routes,
      ),
    );
  }
}
