import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../services/firestore_service.dart';
import '../hospital/hospital_edit_patient_medical_screen.dart';

class DoctorPatientProfileScreen extends StatefulWidget {
  final String? medicalId;

  const DoctorPatientProfileScreen({super.key, this.medicalId});

  @override
  State<DoctorPatientProfileScreen> createState() => _DoctorPatientProfileScreenState();
}

class _DoctorPatientProfileScreenState extends State<DoctorPatientProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;
  String? _errorMessage;
  ProfileRetrievalResult? _retrievalResult;
  StreamSubscription<ProfileRetrievalResult>? _streamSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final effectiveMedId = widget.medicalId ??
          (ModalRoute.of(context)?.settings.arguments as String?);
      if (effectiveMedId != null && effectiveMedId.isNotEmpty) {
        _loadPatientProfile(effectiveMedId);
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No Medical ID specified for patient lookup.';
        });
      }
    });
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    super.dispose();
  }

  Future<void> _loadPatientProfile(String medicalId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _firestoreService.fetchProfileWithSourceByMedicalId(medicalId);
      if (mounted) {
        if (result.profile != null) {
          // Verify that retrieved Medical ID matches requested Medical ID
          if (result.profile!.medicalId.isNotEmpty &&
              result.profile!.medicalId.trim().toUpperCase() != medicalId.trim().toUpperCase()) {
            setState(() {
              _isLoading = false;
              _errorMessage =
                  'Security Verification Mismatch: Scanned ID ($medicalId) does not match profile ID (${result.profile!.medicalId}).';
            });
            return;
          }

          setState(() {
            _retrievalResult = result;
            _isLoading = false;
          });

          // Subscribe to real-time updates for this patient record
          await _streamSub?.cancel();
          _streamSub = _firestoreService.streamProfileWithSourceByMedicalId(medicalId).listen((liveRes) {
            if (mounted && liveRes.profile != null) {
              setState(() {
                _retrievalResult = liveRes;
              });
            }
          });
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = result.errorMessage ?? 'Patient profile not found for ID: $medicalId';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to retrieve patient profile: $e';
        });
      }
    }
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

  void _navigateToHospitalEdit(String medicalId, String? patientUid) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HospitalEditPatientMedicalScreen(
          medicalId: medicalId,
          patientUid: patientUid,
        ),
      ),
    );
    if (updated == true && medicalId.isNotEmpty) {
      _loadPatientProfile(medicalId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveMedId = widget.medicalId ??
        (ModalRoute.of(context)?.settings.arguments as String?) ??
        '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Patient Medical Record'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          if (_retrievalResult?.profile != null)
            IconButton(
              icon: const Icon(Icons.edit_note_rounded),
              tooltip: 'Update Medical Data',
              onPressed: () => _navigateToHospitalEdit(
                _retrievalResult!.profile!.medicalId,
                _retrievalResult!.profile!.uid,
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Profile',
            onPressed: () {
              if (effectiveMedId.isNotEmpty) {
                _loadPatientProfile(effectiveMedId);
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text(
                    'Querying Medical Database...',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                ],
              ),
            )
          : _errorMessage != null
              ? _buildErrorView(effectiveMedId)
              : _buildProfileContent(_retrievalResult!),
    );
  }

  Widget _buildErrorView(String medicalId) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_off_outlined, size: 64, color: AppColors.emergencyRed),
            const SizedBox(height: 16),
            const Text(
              'Patient Record Lookup Failed',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.emergencyRedBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.emergencyRed.withValues(alpha: 0.3)),
              ),
              child: Text(
                _errorMessage ?? 'Unknown lookup error',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.emergencyRed, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to Triage'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _loadPatientProfile(medicalId),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry Lookup'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent(ProfileRetrievalResult result) {
    final profile = result.profile!;
    final isLive = result.isLive;
    final updatedFormatted = DateFormat('MMM dd, yyyy • hh:mm a').format(profile.updatedAt);
    final retrievedFormatted = DateFormat('hh:mm:ss a').format(result.retrievedAt);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LIVE VS OFFLINE STATUS BANNER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isLive ? AppColors.successGreenBg : AppColors.warningOrangeBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isLive ? AppColors.successGreen : AppColors.warningOrange,
                width: 1.5,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isLive ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                  color: isLive ? AppColors.successGreen : AppColors.warningOrange,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              isLive ? 'LIVE FIRESTORE RECORD' : 'OFFLINE / CACHED RECORD',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                color: isLive ? AppColors.successGreen : AppColors.warningOrange,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Synced: $retrievedFormatted',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isLive
                          ? 'Real-time verified medical history fetched directly from secure cloud database.'
                          : 'Network connection unavailable. Displaying locally verified emergency snapshot from device cache.',
                        style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // PATIENT HEADER & DEMOGRAPHICS CARD
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: const Icon(Icons.person, size: 36, color: AppColors.primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.fullName.isNotEmpty ? profile.fullName : 'Not specified',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    profile.medicalId,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.copy, size: 16, color: AppColors.primary),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  tooltip: 'Copy Medical ID',
                                  onPressed: () => _copyMedicalId(profile.medicalId),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Demographics Grid
                  _buildInfoRow(Icons.cake_outlined, 'Date of Birth', profile.dateOfBirth),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.wc_outlined, 'Gender', profile.gender),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.phone_outlined, 'Patient Phone', profile.phone),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.home_outlined, 'Residential Address', profile.address),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.medical_services_outlined, 'Primary Attending Doctor', profile.primaryDoctor),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.history_outlined, 'Record Last Updated', updatedFormatted),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // BLOOD GROUP & CRITICAL ALERTS
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.health_and_safety_outlined, color: AppColors.emergencyRed, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Vitals & Emergency Identifiers',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  // Blood Group Card
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Blood Group',
                        style: TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.emergencyRed,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          profile.bloodGroup.isNotEmpty ? profile.bloodGroup : 'Unknown',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Allergies
                  const Text(
                    'Allergies & Sensitivities',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  profile.allergies.isEmpty
                      ? const Text('None recorded', style: TextStyle(fontSize: 13, color: AppColors.textMuted))
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: profile.allergies.map((allergy) {
                            return Chip(
                              backgroundColor: AppColors.emergencyRedBg,
                              label: Text(
                                allergy,
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
                  const SizedBox(height: 16),

                  // Medical Conditions
                  const Text(
                    'Pre-existing & Chronic Conditions',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  profile.medicalConditions.isEmpty
                      ? const Text('None recorded', style: TextStyle(fontSize: 13, color: AppColors.textMuted))
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: profile.medicalConditions.map((cond) {
                            return Chip(
                              backgroundColor: AppColors.primaryLight,
                              label: Text(
                                cond,
                                style: const TextStyle(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                              side: const BorderSide(color: AppColors.primary),
                            );
                          }).toList(),
                        ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // STRUCTURED EMERGENCY CONTACTS (ICE)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.contact_phone_outlined, color: AppColors.secondary, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Emergency Contacts (ICE)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.emergencyContactInfo.name.isNotEmpty
                                  ? profile.emergencyContactInfo.name
                                  : 'Emergency Contact',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            Text(
                              'Relationship: ${profile.emergencyContactInfo.relationship.isNotEmpty ? profile.emergencyContactInfo.relationship : "Not specified"}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              profile.emergencyContactInfo.phone.isNotEmpty
                                  ? profile.emergencyContactInfo.phone
                                  : (profile.emergencyContact.isNotEmpty ? profile.emergencyContact : 'No phone specified'),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onPressed: () {
                          final phone = profile.emergencyContactInfo.phone.isNotEmpty
                              ? profile.emergencyContactInfo.phone
                              : profile.emergencyContact;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Dialing ICE: $phone')),
                          );
                        },
                        icon: const Icon(Icons.call, size: 16),
                        label: const Text('Call'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ACTIVE MEDICATIONS & PRESCRIPTIONS
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.medication_outlined, color: AppColors.primary, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Active Medications & Regimen',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  profile.medicines.isEmpty
                      ? const Text('No active medications declared.', style: TextStyle(fontSize: 13, color: AppColors.textMuted))
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: profile.medicines.length,
                          separatorBuilder: (_, __) => const Divider(height: 16),
                          itemBuilder: (ctx, index) {
                            final med = profile.medicines[index];
                            return Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.healing_outlined, color: AppColors.primary, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        med.name,
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                      ),
                                      Text(
                                        '${med.dosage} • ${med.frequency}',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // SURGERIES & PAST ILLNESSES
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.history_edu_outlined, color: AppColors.primaryDark, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Surgical & Clinical History',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  const Text('Past Surgeries:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  profile.previousSurgeries.isEmpty
                      ? const Text('None recorded', style: TextStyle(fontSize: 13, color: AppColors.textMuted))
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: profile.previousSurgeries.map((s) => Text('• $s', style: const TextStyle(fontSize: 13, color: AppColors.textPrimary))).toList(),
                        ),
                  const SizedBox(height: 12),
                  const Text('Previous Illnesses:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  profile.previousIllnesses.isEmpty
                      ? const Text('None recorded', style: TextStyle(fontSize: 13, color: AppColors.textMuted))
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: profile.previousIllnesses.map((i) => Text('• $i', style: const TextStyle(fontSize: 13, color: AppColors.textPrimary))).toList(),
                        ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // EMERGENCY NOTES
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.notes_outlined, color: AppColors.warningOrange, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Emergency Clinical Notes',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Text(
                    profile.emergencyNotes.isNotEmpty ? profile.emergencyNotes : 'No special emergency directives provided.',
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // HOSPITAL CLINICAL UPDATE ACTION
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => _navigateToHospitalEdit(profile.medicalId, profile.uid),
              icon: const Icon(Icons.edit_note_rounded, size: 22),
              label: const Text(
                'UPDATE HOSPITAL-MANAGED MEDICAL DATA',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Text(
            value.isNotEmpty ? value : 'Not specified',
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
