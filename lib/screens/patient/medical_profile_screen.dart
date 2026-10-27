import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/medical_profile_provider.dart';
import '../../widgets/medical_badge_card.dart';

class MedicalProfileScreen extends StatefulWidget {
  const MedicalProfileScreen({super.key});

  @override
  State<MedicalProfileScreen> createState() => _MedicalProfileScreenState();
}

class _MedicalProfileScreenState extends State<MedicalProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final profileProvider = Provider.of<MedicalProfileProvider>(context, listen: false);
      if (auth.patientUser != null) {
        profileProvider.loadProfile(
          auth.patientUser!.uid,
          name: auth.patientUser!.name,
          phone: auth.patientUser!.phone,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<MedicalProfileProvider>(context);
    final profile = profileProvider.profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Medical Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_2_rounded),
            tooltip: 'Emergency QR',
            onPressed: () {
              Navigator.pushNamed(context, '/patient/medical-id');
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Profile',
            onPressed: () async {
              await Navigator.pushNamed(context, '/patient/medical-profile/edit');
            },
          ),
        ],
      ),
      body: profileProvider.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : profile == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      const Text('No Medical Profile Found'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          final auth = Provider.of<AuthProvider>(context, listen: false);
                          if (auth.patientUser != null) {
                            profileProvider.loadProfile(
                              auth.patientUser!.uid,
                              name: auth.patientUser!.name,
                              phone: auth.patientUser!.phone,
                            );
                          }
                        },
                        child: const Text('Retry Loading'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    final auth = Provider.of<AuthProvider>(context, listen: false);
                    if (auth.patientUser != null) {
                      await profileProvider.loadProfile(
                        auth.patientUser!.uid,
                        name: auth.patientUser!.name,
                        phone: auth.patientUser!.phone,
                      );
                    }
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Medical Badge Card
                        MedicalBadgeCard(
                          fullName: profile.fullName,
                          medicalId: profile.medicalId,
                          bloodGroup: profile.bloodGroup,
                          emergencyPhone: profile.emergencyContactInfo.phone,
                          onTap: () {
                            Navigator.pushNamed(context, '/patient/medical-id');
                          },
                        ),
                        const SizedBox(height: 20),

                        // Section 1: Personal Information
                        _buildSectionHeader(
                          title: 'Personal Information',
                          icon: Icons.person_outline,
                        ),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                _buildDataRow('Full Name', profile.fullName),
                                const Divider(height: 16),
                                _buildDataRow('Date of Birth', profile.dateOfBirth),
                                const Divider(height: 16),
                                _buildDataRow('Gender', profile.gender),
                                const Divider(height: 16),
                                _buildDataRow('Phone Number', profile.phone),
                                const Divider(height: 16),
                                _buildDataRow('Residential Address', profile.address),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Section 2: Emergency Contact (In Case of Emergency)
                        _buildSectionHeader(
                          title: 'In Case of Emergency (ICE)',
                          icon: Icons.contact_phone_outlined,
                          badge: 'Priority 1',
                        ),
                        Card(
                          color: AppColors.emergencyRedBg,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: AppColors.emergencyRed.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                _buildDataRow(
                                  'Primary Contact Name',
                                  profile.emergencyContactInfo.name.isNotEmpty
                                      ? profile.emergencyContactInfo.name
                                      : 'Not configured',
                                ),
                                const Divider(height: 16),
                                _buildDataRow(
                                  'Emergency Phone',
                                  profile.emergencyContactInfo.phone.isNotEmpty
                                      ? profile.emergencyContactInfo.phone
                                      : 'Not configured',
                                  highlight: true,
                                ),
                                const Divider(height: 16),
                                _buildDataRow(
                                  'Relationship',
                                  profile.emergencyContactInfo.relationship,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Section 3: Critical Medical Data
                        _buildSectionHeader(
                          title: 'Critical Medical Data',
                          icon: Icons.medical_services_outlined,
                          badge: 'Hospital Managed',
                          badgeColor: AppColors.primary,
                        ),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDataRow('Blood Group', profile.bloodGroup, isBloodGroup: true),
                                const SizedBox(height: 16),
                                const Text(
                                  'Known Allergies',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                profile.allergies.isEmpty
                                    ? const Text(
                                        'No known allergies recorded.',
                                        style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                                      )
                                    : Wrap(
                                        spacing: 8,
                                        runSpacing: 6,
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
                                            avatar: const Icon(
                                              Icons.warning_amber_rounded,
                                              size: 16,
                                              color: AppColors.emergencyRed,
                                            ),
                                            side: BorderSide(
                                              color: AppColors.emergencyRed.withValues(alpha: 0.3),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Pre-existing Medical Conditions',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                profile.medicalConditions.isEmpty
                                    ? const Text(
                                        'No chronic conditions recorded.',
                                        style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                                      )
                                    : Wrap(
                                        spacing: 8,
                                        runSpacing: 6,
                                        children: profile.medicalConditions.map((condition) {
                                          return Chip(
                                            backgroundColor: AppColors.primaryLight,
                                            label: Text(
                                              condition,
                                              style: const TextStyle(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                            side: BorderSide(
                                              color: AppColors.primary.withValues(alpha: 0.3),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Section 4: Current Medications
                        _buildSectionHeader(
                          title: 'Current Prescriptions & Medications',
                          icon: Icons.medication_outlined,
                          badge: 'Hospital Managed',
                          badgeColor: AppColors.primary,
                        ),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: profile.medicines.isEmpty
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(vertical: 12.0),
                                      child: Text(
                                        'No active medications listed.',
                                        style: TextStyle(color: AppColors.textMuted),
                                      ),
                                    ),
                                  )
                                : Column(
                                    children: profile.medicines.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final med = entry.value;
                                      return Column(
                                        children: [
                                          ListTile(
                                            contentPadding: EdgeInsets.zero,
                                            leading: CircleAvatar(
                                              backgroundColor:
                                                  AppColors.secondary.withValues(alpha: 0.15),
                                              child: const Icon(
                                                Icons.medication_rounded,
                                                color: AppColors.secondary,
                                                size: 20,
                                              ),
                                            ),
                                            title: Text(
                                              med.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                            subtitle: Text(
                                              '${med.dosage} • ${med.frequency}${med.instructions != null && med.instructions!.isNotEmpty ? " (${med.instructions})" : ""}',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ),
                                          if (index < profile.medicines.length - 1)
                                            const Divider(height: 1),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Section 5: Past Surgeries & Medical History
                        _buildSectionHeader(
                          title: 'Surgical & Clinical History',
                          icon: Icons.history_edu_outlined,
                          badge: 'Hospital Managed',
                          badgeColor: AppColors.primary,
                        ),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDataRow(
                                  'Previous Surgeries',
                                  profile.previousSurgeries.isEmpty
                                      ? 'None reported'
                                      : profile.previousSurgeries.join(', '),
                                ),
                                const Divider(height: 16),
                                _buildDataRow(
                                  'Previous Illnesses',
                                  profile.previousIllnesses.isEmpty
                                      ? 'None reported'
                                      : profile.previousIllnesses.join(', '),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Section 6: Emergency Notes & Primary Doctor
                        _buildSectionHeader(
                          title: 'Emergency Notes & Care Team',
                          icon: Icons.note_alt_outlined,
                          badge: 'Hospital Managed',
                          badgeColor: AppColors.primary,
                        ),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDataRow('Primary Physician', profile.primaryDoctor),
                                const Divider(height: 16),
                                const Text(
                                  'Special Emergency Instructions',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  profile.emergencyNotes.isNotEmpty
                                      ? profile.emergencyNotes
                                      : 'No special emergency notes provided.',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Action Buttons
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(context, '/patient/medical-profile/edit');
                            },
                            icon: const Icon(Icons.edit_note_rounded),
                            label: const Text('Edit Medical Profile'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(context, '/patient/medical-id');
                            },
                            icon: const Icon(Icons.qr_code_rounded),
                            label: const Text('View Emergency QR Code'),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    String? badge,
    Color? badgeColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badgeColor ?? AppColors.emergencyRed,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDataRow(
    String label,
    String value, {
    bool highlight = false,
    bool isBloodGroup = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 6,
          child: isBloodGroup
              ? Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.emergencyRed,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
              : Text(
                  value.isNotEmpty ? value : 'Not specified',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
                    color: highlight ? AppColors.emergencyRed : AppColors.textPrimary,
                  ),
                ),
        ),
      ],
    );
  }
}
