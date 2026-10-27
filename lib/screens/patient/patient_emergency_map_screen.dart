import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../models/emergency_incident.dart';
import '../../providers/ambulance_provider.dart';
import '../../providers/emergency_provider.dart';
import '../../widgets/emergency_map_view.dart';

class PatientEmergencyMapScreen extends StatefulWidget {
  const PatientEmergencyMapScreen({super.key});

  @override
  State<PatientEmergencyMapScreen> createState() => _PatientEmergencyMapScreenState();
}

class _PatientEmergencyMapScreenState extends State<PatientEmergencyMapScreen> {
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
                const Text(
                  'The ambulance has reached the selected hospital.',
                  style: TextStyle(fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.successGreenBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_hospital_rounded, color: AppColors.successGreen, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          incident.assignedHospitalName != null
                              ? 'Destination: ${incident.assignedHospitalName}'
                              : 'Hospital Emergency Unit reached.',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
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
    final emergencyProvider = Provider.of<EmergencyProvider>(context);
    final incident = emergencyProvider.currentPatientIncident;
    final ambulanceProvider = incident != null
        ? emergencyProvider.getAmbulanceForIncident(incident.incidentId)
        : Provider.of<AmbulanceLocationProvider>(context);

    if (incident != null) {
      _checkAndShowArrivalDialog(incident, emergencyProvider, ambulanceProvider);
    }

    if (incident == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Emergency Response Map')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline, color: AppColors.successGreen, size: 72),
                const SizedBox(height: 16),
                const Text(
                  'No Active Emergency Incident',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'You have no pending SOS alerts. All emergency networks are idle.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Return to Dashboard'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Emergency Tracking & Response'),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // STATUS ALERT BANNER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: incident.status == EmergencyStatus.arrived
                    ? AppColors.successGreenBg
                    : AppColors.emergencyRedBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: incident.status == EmergencyStatus.arrived
                      ? AppColors.successGreen
                      : AppColors.emergencyRed,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    incident.status == EmergencyStatus.arrived
                        ? Icons.check_circle
                        : Icons.emergency_rounded,
                    color: incident.status == EmergencyStatus.arrived
                        ? AppColors.successGreen
                        : AppColors.emergencyRed,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          incident.status.displayName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: incident.status == EmergencyStatus.arrived
                                ? AppColors.successGreen
                                : AppColors.emergencyRed,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          incident.status == EmergencyStatus.arrived
                              ? 'Emergency Medical Team has arrived at your location.'
                              : 'Ambulance is navigating to your coordinates.',
                          style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // LIVE OPENSTREETMAP VIEW
            EmergencyMapView(
              incident: incident,
              routePoints: ambulanceProvider.routePoints,
              ambulancePosition: ambulanceProvider.currentPosition,
              height: 340,
            ),
            const SizedBox(height: 16),

            // TELEMETRY & ETA METRICS CARD
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricTile(
                            icon: Icons.directions_car_filled_rounded,
                            color: AppColors.primary,
                            title: 'Ambulance Unit',
                            value: incident.ambulanceId ?? ambulanceProvider.ambulanceId,
                            subtitle: ambulanceProvider.status.displayName,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricTile(
                            icon: Icons.timer_outlined,
                            color: AppColors.emergencyRed,
                            title: 'Estimated Arrival',
                            value: ambulanceProvider.hasArrived
                                ? 'ARRIVED'
                                : (ambulanceProvider.etaMinutes < 1
                                    ? '< 1 min'
                                    : '${ambulanceProvider.etaMinutes} min'),
                            subtitle: '${ambulanceProvider.distanceKm} km away',
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        const Icon(Icons.local_hospital, color: AppColors.secondary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Assigned Hospital Destination',
                                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                              Text(
                                incident.assignedHospitalName ?? 'Ruby Hall Clinic (Pune)',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
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
            const SizedBox(height: 20),

            // ACTION BUTTONS
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.emergencyRed, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: const Text('Cancel Emergency SOS?'),
                      content: const Text(
                        'Are you sure you are safe and want to cancel this active emergency incident? This will notify responders that you are OK.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('KEEP ACTIVE'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.successGreen,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text("I'M OK / CANCEL SOS"),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && context.mounted) {
                    await emergencyProvider.cancelSos();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Emergency incident resolved and cancelled.'),
                          backgroundColor: AppColors.successGreen,
                        ),
                      );
                      Navigator.pop(context);
                    }
                  }
                },
                icon: const Icon(Icons.check_circle_outline, color: AppColors.emergencyRed),
                label: const Text(
                  "I'M OK — CANCEL EMERGENCY ALERT",
                  style: TextStyle(
                    color: AppColors.emergencyRed,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
