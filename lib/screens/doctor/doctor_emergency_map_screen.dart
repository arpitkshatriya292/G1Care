import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../models/emergency_incident.dart';
import '../../models/emergency_qr_payload.dart';
import '../../providers/ambulance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/emergency_provider.dart';
import '../../services/health_evaluator.dart';
import '../../widgets/emergency_map_view.dart';

class DoctorEmergencyMapScreen extends StatefulWidget {
  final EmergencyIncident? incident;

  const DoctorEmergencyMapScreen({super.key, this.incident});

  @override
  State<DoctorEmergencyMapScreen> createState() => _DoctorEmergencyMapScreenState();
}

class _DoctorEmergencyMapScreenState extends State<DoctorEmergencyMapScreen> {
  bool _dialogShowing = false;

  void _checkAndShowArrivalDialog(
    EmergencyIncident incident,
    EmergencyProvider emergencyProvider,
    AmbulanceLocationProvider ambulanceProvider,
  ) {
    if ((ambulanceProvider.hasArrived || incident.status == EmergencyStatus.arrived) &&
        !incident.arrivalPopupShown &&
        !_dialogShowing) {
      _dialogShowing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await emergencyProvider.markArrivalPopupShown(incident.incidentId);
        if (!mounted) return;
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.successGreen, size: 28),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Ambulance Reached Hospital',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'The ambulance carrying ${incident.patientName} has reached the selected hospital facility.',
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.successGreenBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.medical_services_rounded, color: AppColors.successGreen, size: 22),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Prepare emergency bay and immediate triage assessment.',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.successGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('ACKNOWLEDGE'),
              ),
            ],
          ),
        );
        _dialogShowing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final emergencyProvider = Provider.of<EmergencyProvider>(context);

    // Get incident from widget arg or route settings
    final effectiveIncident = widget.incident ??
        (ModalRoute.of(context)?.settings.arguments as EmergencyIncident?) ??
        emergencyProvider.activeEmergencies.firstOrNull;

    if (effectiveIncident != null) {
      final ambProv = emergencyProvider.getAmbulanceForIncident(effectiveIncident.incidentId);
      _checkAndShowArrivalDialog(effectiveIncident, emergencyProvider, ambProv);
    }

    if (effectiveIncident == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Doctor Emergency Map')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off_outlined, size: 64, color: AppColors.textMuted),
              const SizedBox(height: 16),
              const Text('No Emergency Case Selected', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Active Emergencies'),
              ),
            ],
          ),
        ),
      );
    }

    final ambulanceProvider = emergencyProvider.getAmbulanceForIncident(effectiveIncident.incidentId);
    final eval = HealthStatusEvaluator.evaluate(effectiveIncident.vitalsSnapshot);
    final doctor = authProvider.doctorUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Emergency: ${effectiveIncident.patientName}'),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TOP STATUS & SEVERITY BAR
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: eval.isCritical ? AppColors.emergencyRedBg : AppColors.warningOrangeBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: eval.isCritical ? AppColors.emergencyRed : AppColors.warningOrange,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    eval.isCritical ? Icons.emergency : Icons.warning_rounded,
                    color: eval.isCritical ? AppColors.emergencyRed : AppColors.warningOrange,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          eval.overallLevel.displayName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: eval.isCritical ? AppColors.emergencyRed : AppColors.warningOrange,
                          ),
                        ),
                        Text(
                          eval.summaryText,
                          style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // LIVE OPENSTREETMAP VIEW
            EmergencyMapView(
              incident: effectiveIncident,
              routePoints: ambulanceProvider.routePoints,
              ambulancePosition: ambulanceProvider.currentPosition,
              height: 320,
            ),
            const SizedBox(height: 14),

            // PATIENT & AMBULANCE METRICS CARD
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              effectiveIncident.patientName,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Medical ID: ${effectiveIncident.medicalId}',
                              style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Blood: ${effectiveIncident.bloodGroup}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Ambulance Status', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              const SizedBox(height: 2),
                              Text(
                                ambulanceProvider.status.displayName,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Distance & ETA', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              const SizedBox(height: 2),
                              Text(
                                ambulanceProvider.hasArrived
                                    ? 'ARRIVED AT SCENE'
                                    : '${ambulanceProvider.distanceKm} km • ~${ambulanceProvider.etaMinutes < 1 ? "< 1 min" : "${ambulanceProvider.etaMinutes} min"}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.emergencyRed),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // NAVIGATION BUTTONS: VIEW TRIAGE & VIEW FULL PROFILE
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      // Construct EmergencyQrPayload for standard Triage Screen
                      final payload = EmergencyQrPayload(
                        schema: 'g1/v1',
                        medId: effectiveIncident.medicalId,
                        name: effectiveIncident.patientName,
                        bg: effectiveIncident.bloodGroup,
                        alrg: effectiveIncident.criticalAllergies,
                        cond: [],
                        emPhone: effectiveIncident.emergencyPhone,
                        issuedAt: DateTime.now().millisecondsSinceEpoch,
                        integrityTag: 'EMERGENCY_DISPATCH_VERIFIED',
                      );
                      Navigator.pushNamed(
                        context,
                        '/doctor/triage',
                        arguments: payload,
                      );
                    },
                    icon: const Icon(Icons.assignment_outlined, size: 18),
                    label: const Text('VIEW TRIAGE'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppColors.primary),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/doctor/patient-profile',
                        arguments: effectiveIncident.medicalId,
                      );
                    },
                    icon: const Icon(Icons.person_search_outlined, size: 18),
                    label: const Text('FULL PROFILE'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // DOCTOR INCIDENT RESPONSE BUTTON
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.successGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  await emergencyProvider.respondToEmergency(
                    incidentId: effectiveIncident.incidentId,
                    doctorId: doctor?.uid ?? 'DOC-01',
                    doctorName: doctor?.name ?? 'Doctor',
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Doctor response acknowledged and logged to incident.'),
                        backgroundColor: AppColors.successGreen,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.check_circle),
                label: const Text('ACKNOWLEDGE & RESPOND TO CASE'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
