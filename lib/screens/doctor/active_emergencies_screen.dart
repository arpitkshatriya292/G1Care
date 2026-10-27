import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../models/emergency_incident.dart';
import '../../providers/auth_provider.dart';
import '../../providers/emergency_provider.dart';
import '../../services/health_evaluator.dart';

class ActiveEmergenciesScreen extends StatefulWidget {
  const ActiveEmergenciesScreen({super.key});

  @override
  State<ActiveEmergenciesScreen> createState() => _ActiveEmergenciesScreenState();
}

class _ActiveEmergenciesScreenState extends State<ActiveEmergenciesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EmergencyProvider>(context, listen: false).refreshActiveEmergencies();
    });
  }

  @override
  Widget build(BuildContext context) {
    final emergencyProvider = Provider.of<EmergencyProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final emergencies = emergencyProvider.activeEmergencies;
    final doctor = authProvider.doctorUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Active Emergency Network'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Incidents',
            onPressed: () => emergencyProvider.refreshActiveEmergencies(),
          ),
        ],
      ),
      body: emergencyProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : emergencies.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: emergencies.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, idx) {
                    final inc = emergencies[idx];
                    return _buildEmergencyCard(context, inc, doctor?.name ?? 'Doctor');
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.health_and_safety_outlined, color: AppColors.successGreen, size: 72),
            const SizedBox(height: 16),
            const Text(
              'Emergency Network Clear',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'No active SOS emergency incidents in your coverage area at this moment.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyCard(BuildContext context, EmergencyIncident incident, String doctorName) {
    final eval = HealthStatusEvaluator.evaluate(incident.vitalsSnapshot);
    final timeStr = DateFormat('hh:mm a').format(incident.createdAt);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: eval.isCritical ? AppColors.emergencyRed : AppColors.warningOrange,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Severity Header & Time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: eval.isCritical ? AppColors.emergencyRedBg : AppColors.warningOrangeBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        eval.isCritical ? Icons.emergency : Icons.warning_rounded,
                        color: eval.isCritical ? AppColors.emergencyRed : AppColors.warningOrange,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        eval.isCritical ? 'CRITICAL EMERGENCY' : 'MODERATE ALERT',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: eval.isCritical ? AppColors.emergencyRed : AppColors.warningOrange,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  timeStr,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Patient Name & Medical ID
            Text(
              incident.patientName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Medical ID: ',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    Text(
                      incident.medicalId,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Blood Group: ${incident.bloodGroup}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Trigger & Vitals Snapshot
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trigger: ${incident.triggerType.displayName}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'HR: ${incident.vitalsSnapshot.heartRate} BPM • SpO2: ${incident.vitalsSnapshot.spo2}% • Resp: ${incident.vitalsSnapshot.respiratoryRate}/min',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Action Buttons (Open Map & Manage Case / Discharge)
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/doctor/emergency-map',
                        arguments: incident,
                      );
                    },
                    icon: const Icon(Icons.map_rounded, size: 18),
                    label: const Text('LIVE GPS MAP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.successGreen,
                      side: const BorderSide(color: AppColors.successGreen, width: 1.2),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _showDischargeConfirmationDialog(context, incident),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('DISCHARGE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDischargeConfirmationDialog(BuildContext context, EmergencyIncident incident) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.health_and_safety_rounded, color: AppColors.successGreen, size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Resolve & Discharge Case?',
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
              'Remove ${incident.patientName} (Medical ID: ${incident.medicalId}) from the Active Emergency Network?',
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            const Text(
              'Patient has been treated/discharged. This stops active ambulance tracking and updates hospital counters while preserving medical records.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.successGreen,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final emergencyProvider = Provider.of<EmergencyProvider>(context, listen: false);
              await emergencyProvider.dischargeEmergency(incident.incidentId);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${incident.patientName} discharged. Emergency case marked as discharged.'),
                    backgroundColor: AppColors.successGreen,
                  ),
                );
              }
            },
            child: const Text('CONFIRM DISCHARGE', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
