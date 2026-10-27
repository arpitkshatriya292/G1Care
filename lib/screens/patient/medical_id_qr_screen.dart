import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/medical_profile_provider.dart';

class MedicalIdQrScreen extends StatefulWidget {
  const MedicalIdQrScreen({super.key});

  @override
  State<MedicalIdQrScreen> createState() => _MedicalIdQrScreenState();
}

class _MedicalIdQrScreenState extends State<MedicalIdQrScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final profileProvider = Provider.of<MedicalProfileProvider>(context, listen: false);
      if (auth.patientUser != null && profileProvider.profile == null) {
        profileProvider.loadProfile(
          auth.patientUser!.uid,
          name: auth.patientUser!.name,
          phone: auth.patientUser!.phone,
        );
      }
    });
  }

  void _copyMedicalId(String medicalId) {
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
    final profileProvider = Provider.of<MedicalProfileProvider>(context);
    final profile = profileProvider.profile;
    final snapshot = profileProvider.emergencySnapshot;
    final qrData = profileProvider.qrToken.isNotEmpty
        ? profileProvider.qrToken
        : profileProvider.medicalId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Medical ID & Emergency QR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Medical Info',
            onPressed: () {
              Navigator.pushNamed(context, '/patient/medical-profile/edit');
            },
          ),
        ],
      ),
      body: profileProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : profile == null
              ? const Center(child: Text('Please create your medical profile first.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      // Header Card with Medical ID & Copy Button
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'OFFICIAL EMERGENCY IDENTIFIER',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  profile.medicalId.isNotEmpty
                                      ? profile.medicalId
                                      : 'G1-MED-PENDING',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                    color: AppColors.primaryDark,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.copy_rounded, size: 20, color: AppColors.primary),
                                  tooltip: 'Copy ID',
                                  onPressed: () => _copyMedicalId(profile.medicalId),
                                ),
                              ],
                            ),
                            Text(
                              profile.fullName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // QR Code Box Container
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(color: AppColors.cardBorder, width: 1.5),
                        ),
                        child: Column(
                          children: [
                            // QR Image using qr_flutter (Encodes Opaque Token Only)
                            QrImageView(
                              data: qrData,
                              version: QrVersions.auto,
                              size: 240.0,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: AppColors.primaryDark,
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: AppColors.textPrimary,
                              ),
                              errorCorrectionLevel: QrErrorCorrectLevel.M,
                            ),
                            const SizedBox(height: 16),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.lock_outline_rounded,
                                  size: 16,
                                  color: AppColors.successGreen,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Secure Opaque Token (Zero Medical Data in QR)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.successGreen,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Privacy Notice Alert Card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.privacy_tip_outlined, size: 20, color: AppColors.primary),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Security & Privacy: Scanning this QR with a generic phone/camera reveals only a secure opaque token. No medical history, name, or contacts are stored inside the QR code. Medical profiles are only resolvable by verified G1Care medical responders.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Offline Emergency Snapshot Card for First Responders
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'First-Responder Emergency Quick View',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      Card(
                        color: AppColors.emergencyRedBg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: AppColors.emergencyRed.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Blood Group Banner
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'PATIENT BLOOD TYPE',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.emergencyRed,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      Text(
                                        'Verified Medical Group',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.emergencyRed,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      snapshot?.bg.isNotEmpty == true ? snapshot!.bg : 'N/A',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),

                              // Critical Allergies
                              const Text(
                                'CRITICAL ALLERGIES',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.emergencyRed,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              snapshot == null || snapshot.alrg.isEmpty
                                  ? const Text(
                                      'No severe allergies on emergency record',
                                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                    )
                                  : Wrap(
                                      spacing: 6,
                                      children: snapshot.alrg.map((a) {
                                        return Chip(
                                          backgroundColor: Colors.white,
                                          label: Text(
                                            a,
                                            style: const TextStyle(
                                              color: AppColors.emergencyRed,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                          side: const BorderSide(color: AppColors.emergencyRed),
                                        );
                                      }).toList(),
                                    ),
                              const Divider(height: 24),

                              // Emergency Contact Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
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
                                        snapshot?.emPhone.isNotEmpty == true
                                            ? snapshot!.emPhone
                                            : 'Not configured',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.emergencyRed,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Calling Emergency Contact: ${snapshot?.emPhone}'),
                                          backgroundColor: AppColors.emergencyRed,
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.phone, size: 16),
                                    label: const Text('CALL ICE'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Full Profile Link
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, '/patient/medical-profile');
                        },
                        icon: const Icon(Icons.assignment_ind_outlined),
                        label: const Text('View Full Protected Medical Profile'),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }
}
