import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../models/emergency_qr_payload.dart';
import '../../services/medical_id_service.dart';

class EmergencyTriageScreen extends StatelessWidget {
  final EmergencyQrPayload? payload;

  const EmergencyTriageScreen({super.key, this.payload});

  void _copyMedicalId(BuildContext context, String medicalId) {
    Clipboard.setData(ClipboardData(text: medicalId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Medical ID "$medicalId" copied to clipboard!'),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectivePayload = payload ??
        (ModalRoute.of(context)?.settings.arguments as EmergencyQrPayload?);

    if (effectivePayload == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Emergency Triage Viewer')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 64, color: AppColors.warningOrange),
              const SizedBox(height: 16),
              const Text('No Emergency Data Available', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Return to Scanner'),
              ),
            ],
          ),
        ),
      );
    }

    final verification = MedicalIdService.verifyQrPayload(effectivePayload.toJson());
    final isTamperClean = verification.isValid;
    final issuedDate = effectivePayload.issuedAt > 0
        ? DateTime.fromMillisecondsSinceEpoch(effectivePayload.issuedAt)
        : null;
    final formattedDate = issuedDate != null
        ? DateFormat('MMM dd, yyyy • hh:mm a').format(issuedDate)
        : 'Timestamp unavailable';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Emergency Triage Viewer'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Copy Medical ID',
            onPressed: () => _copyMedicalId(context, effectivePayload.medId),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TOP STATUS BANNER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isTamperClean ? AppColors.successGreenBg : AppColors.warningOrangeBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isTamperClean ? AppColors.successGreen : AppColors.warningOrange,
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isTamperClean ? Icons.verified_user_rounded : Icons.shield_outlined,
                    color: isTamperClean ? AppColors.successGreen : AppColors.warningOrange,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isTamperClean
                              ? 'OFFLINE EMERGENCY TRIAGE SNAPSHOT'
                              : 'UNVERIFIED PAYLOAD WARNING',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: isTamperClean ? AppColors.successGreen : AppColors.warningOrange,
                          ),
                        ),
                        Text(
                          'Issued: $formattedDate',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  if (effectivePayload.integrityTag.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Text(
                        'TAG: ${effectivePayload.integrityTag}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // PATIENT IDENTIFIER CARD
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primaryLight,
                      child: const Icon(Icons.person, size: 32, color: AppColors.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            effectivePayload.name.isNotEmpty
                                ? effectivePayload.name
                                : 'Unknown Patient',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                effectivePayload.medId,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                  color: AppColors.primaryDark,
                                ),
                              ),
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: () => _copyMedicalId(context, effectivePayload.medId),
                                child: const Icon(Icons.copy_rounded, size: 16, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // CRITICAL EMERGENCY TRIAGE SECTION (VITAL RED CONTAINER)
            Card(
              color: AppColors.emergencyRedBg,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: AppColors.emergencyRed, width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Header
                    const Row(
                      children: [
                        Icon(Icons.emergency_rounded, color: AppColors.emergencyRed, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'PRIORITY TRIAGE METRICS',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.emergencyRed,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: Color(0xFFFCA5A5)),

                    // Blood Group Highlight Box
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BLOOD GROUP',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.emergencyRed,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              'Verified Emergency Type',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.emergencyRed,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.emergencyRed.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            effectivePayload.bg.isNotEmpty ? effectivePayload.bg : 'Unknown',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: Color(0xFFFCA5A5)),

                    // Severe Allergies Warning
                    const Text(
                      'CRITICAL ALLERGIES & CONTRAINDICATIONS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.emergencyRed,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    effectivePayload.alrg.isEmpty
                        ? const Text(
                            'No severe allergies declared on emergency record.',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          )
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: effectivePayload.alrg.map((allergy) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.emergencyRed, width: 1.2),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.emergencyRed),
                                    const SizedBox(width: 6),
                                    Text(
                                      allergy,
                                      style: const TextStyle(
                                        color: AppColors.emergencyRed,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                    const Divider(height: 24, color: Color(0xFFFCA5A5)),

                    // Critical Pre-existing Conditions
                    const Text(
                      'CRITICAL CONDITIONS / MEDICAL ALERTS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.emergencyRed,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    effectivePayload.cond.isEmpty
                        ? const Text(
                            'No pre-existing conditions on emergency record.',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          )
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: effectivePayload.cond.map((cond) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.primary, width: 1),
                                ),
                                child: Text(
                                  cond,
                                  style: const TextStyle(
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                    const Divider(height: 24, color: Color(0xFFFCA5A5)),

                    // In Case of Emergency Contact Phone Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'EMERGENCY CONTACT (ICE)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.emergencyRed,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                effectivePayload.emPhone.isNotEmpty
                                    ? effectivePayload.emPhone
                                    : 'Not specified',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.emergencyRed,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Dialing Emergency Contact: ${effectivePayload.emPhone}'),
                                backgroundColor: AppColors.emergencyRed,
                              ),
                            );
                          },
                          icon: const Icon(Icons.call, size: 18),
                          label: const Text('CALL ICE', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // PRIVACY & DATA MINIMIZATION NOTICE
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.privacy_tip_outlined, size: 20, color: AppColors.primary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Data Minimization Notice: This offline emergency snapshot contains only vital first-responder triage markers. Full clinical profile, home address, and complete prescription regimens are locked behind authenticated Medical ID retrieval.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ACTION: FETCH FULL MEDICAL PROFILE
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/doctor/patient-profile',
                    arguments: effectivePayload.medId,
                  );
                },
                icon: const Icon(Icons.assignment_ind_rounded, size: 24),
                label: const Text(
                  'RETRIEVE FULL MEDICAL PROFILE',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Scan another patient QR
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan Another Patient QR'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
