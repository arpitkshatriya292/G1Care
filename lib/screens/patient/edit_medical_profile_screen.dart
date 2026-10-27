import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../models/emergency_contact.dart';
import '../../models/medical_profile.dart';
import '../../providers/medical_profile_provider.dart';

class EditMedicalProfileScreen extends StatefulWidget {
  const EditMedicalProfileScreen({super.key});

  @override
  State<EditMedicalProfileScreen> createState() => _EditMedicalProfileScreenState();
}

class _EditMedicalProfileScreenState extends State<EditMedicalProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _fullNameController;
  late TextEditingController _dobController;
  late TextEditingController _genderController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  // Emergency Contact (ICE)
  late TextEditingController _emNameController;
  late TextEditingController _emPhoneController;
  late TextEditingController _emRelController;

  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final profileProvider = Provider.of<MedicalProfileProvider>(context, listen: false);
      final profile = profileProvider.profile;

      _fullNameController = TextEditingController(text: profile?.fullName ?? '');
      _dobController = TextEditingController(text: profile?.dateOfBirth ?? '');
      _genderController = TextEditingController(text: profile?.gender ?? '');
      _phoneController = TextEditingController(text: profile?.phone ?? '');
      _addressController = TextEditingController(text: profile?.address ?? '');

      _emNameController = TextEditingController(text: profile?.emergencyContactInfo.name ?? '');
      _emPhoneController = TextEditingController(text: profile?.emergencyContactInfo.phone ?? '');
      _emRelController = TextEditingController(
          text: profile?.emergencyContactInfo.relationship.isNotEmpty == true
              ? profile!.emergencyContactInfo.relationship
              : 'Spouse');

      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _dobController.dispose();
    _genderController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emNameController.dispose();
    _emPhoneController.dispose();
    _emRelController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    if (_formKey.currentState!.validate()) {
      final profileProvider = Provider.of<MedicalProfileProvider>(context, listen: false);
      final currentProfile = profileProvider.profile;

      final updatedProfile = (currentProfile ?? MedicalProfile.empty('', '', '')).copyWithPatientDetails(
        fullName: _fullNameController.text.trim(),
        dateOfBirth: _dobController.text.trim(),
        gender: _genderController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        emergencyContactInfo: EmergencyContactInfo(
          name: _emNameController.text.trim(),
          phone: _emPhoneController.text.trim(),
          relationship: _emRelController.text.trim(),
          isPrimary: true,
        ),
      );

      final success = await profileProvider.savePatientDetails(updatedProfile);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Personal profile updated and synchronized!'),
            backgroundColor: AppColors.successGreen,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(profileProvider.errorMessage ?? 'Failed to save profile.'),
            backgroundColor: AppColors.emergencyRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<MedicalProfileProvider>(context);
    final profile = profileProvider.profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile & ICE Contacts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Save Changes',
            onPressed: profileProvider.isLoading ? null : _handleSave,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Personal & Emergency Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'You can update your personal contact and ICE details below. Clinical records are managed by authorized hospital doctors.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),

              // ==========================================
              // SECTION 1: PERSONAL DETAILS (EDITABLE)
              // ==========================================
              _buildSectionTitle('1. Personal Details', isEditable: true),
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Legal Name *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _dobController,
                      decoration: const InputDecoration(
                        labelText: 'Date of Birth (YYYY-MM-DD)',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _genderController,
                      decoration: const InputDecoration(
                        labelText: 'Gender (e.g. Male, Female)',
                        prefixIcon: Icon(Icons.wc_outlined),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Primary Phone Number',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Residential Address',
                  prefixIcon: Icon(Icons.home_outlined),
                ),
              ),
              const SizedBox(height: 24),

              // ==========================================
              // SECTION 2: IN CASE OF EMERGENCY (ICE) (EDITABLE)
              // ==========================================
              _buildSectionTitle('2. In Case of Emergency (ICE) Contact', isEditable: true),
              TextFormField(
                controller: _emNameController,
                decoration: const InputDecoration(
                  labelText: 'Emergency Contact Name *',
                  prefixIcon: Icon(Icons.contact_emergency_outlined),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Emergency contact name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emPhoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Emergency Contact Phone *',
                  prefixIcon: Icon(Icons.phone_in_talk_outlined),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Emergency phone is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emRelController,
                decoration: const InputDecoration(
                  labelText: 'Relationship (e.g. Spouse, Parent, Sibling)',
                  prefixIcon: Icon(Icons.people_outline),
                ),
              ),
              const SizedBox(height: 28),

              // ==========================================
              // HOSPITAL MANAGED INFORMATION BANNER
              // ==========================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.2),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 22),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'HOSPITAL-MANAGED MEDICAL DATA (READ-ONLY)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'The clinical sections below are managed and verified directly by authorized hospital medical staff to ensure accuracy and patient safety during triage.',
                            style: TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ==========================================
              // SECTION 3: CRITICAL EMERGENCY DATA (READ-ONLY)
              // ==========================================
              _buildSectionTitle('3. Critical Emergency Data', isEditable: false),
              Card(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppColors.cardBorder),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Blood Group Display
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Row(
                              children: [
                                Icon(Icons.bloodtype_outlined, color: AppColors.emergencyRed, size: 20),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Blood Group',
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.emergencyRed,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  profile?.bloodGroup.isNotEmpty == true
                                      ? profile!.bloodGroup
                                      : 'Unknown',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              _buildHospitalManagedBadge(),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      // Allergies
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'Known Allergies',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildHospitalManagedBadge(),
                        ],
                      ),
                      const SizedBox(height: 8),
                      profile == null || profile.allergies.isEmpty
                          ? const Text(
                              'No allergies recorded by hospital.',
                              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
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
                                  side: BorderSide(color: AppColors.emergencyRed.withValues(alpha: 0.3)),
                                );
                              }).toList(),
                            ),
                      const SizedBox(height: 16),

                      // Medical Conditions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'Pre-existing Medical Conditions',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildHospitalManagedBadge(),
                        ],
                      ),
                      const SizedBox(height: 8),
                      profile == null || profile.medicalConditions.isEmpty
                          ? const Text(
                              'No chronic conditions recorded by hospital.',
                              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                            )
                          : Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: profile.medicalConditions.map((cond) {
                                return Chip(
                                  backgroundColor: AppColors.primaryLight,
                                  label: Text(
                                    cond,
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                                );
                              }).toList(),
                            ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ==========================================
              // SECTION 4: CURRENT MEDICATIONS (READ-ONLY)
              // ==========================================
              _buildSectionTitle('4. Current Prescriptions', isEditable: false),
              Card(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppColors.cardBorder),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: profile == null || profile.medicines.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'No active medications listed by hospital.',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: profile.medicines.length,
                          separatorBuilder: (_, __) => const Divider(height: 16),
                          itemBuilder: (ctx, idx) {
                            final med = profile.medicines[idx];
                            return Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.medication, color: AppColors.secondary, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        med.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${med.dosage} • ${med.frequency}',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildHospitalManagedBadge(),
                              ],
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // ==========================================
              // SECTION 5: SURGICAL HISTORY & ILLNESSES (READ-ONLY)
              // ==========================================
              _buildSectionTitle('5. Surgical History & Past Illnesses', isEditable: false),
              Card(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppColors.cardBorder),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'Past Surgeries:',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildHospitalManagedBadge(),
                        ],
                      ),
                      const SizedBox(height: 6),
                      profile == null || profile.previousSurgeries.isEmpty
                          ? const Text('None recorded', style: TextStyle(fontSize: 13, color: AppColors.textMuted))
                          : Wrap(
                              spacing: 8,
                              children: profile.previousSurgeries.map((s) => Chip(label: Text(s, style: const TextStyle(fontSize: 12)))).toList(),
                            ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'Previous Illnesses:',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildHospitalManagedBadge(),
                        ],
                      ),
                      const SizedBox(height: 6),
                      profile == null || profile.previousIllnesses.isEmpty
                          ? const Text('None recorded', style: TextStyle(fontSize: 13, color: AppColors.textMuted))
                          : Wrap(
                              spacing: 8,
                              children: profile.previousIllnesses.map((i) => Chip(label: Text(i, style: const TextStyle(fontSize: 12)))).toList(),
                            ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ==========================================
              // SECTION 6: NOTES & PRIMARY DOCTOR (READ-ONLY)
              // ==========================================
              _buildSectionTitle('6. Special Directives & Primary Doctor', isEditable: false),
              Card(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppColors.cardBorder),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'Primary Attending Doctor:',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildHospitalManagedBadge(),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile?.primaryDoctor.isNotEmpty == true ? profile!.primaryDoctor : 'Not specified',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'Emergency Clinical Directives:',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildHospitalManagedBadge(),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile?.emergencyNotes.isNotEmpty == true ? profile!.emergencyNotes : 'No special emergency directives provided.',
                        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Save Button (Patient saves personal & ICE changes)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: profileProvider.isLoading ? null : _handleSave,
                  icon: profileProvider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(
                    profileProvider.isLoading ? 'Saving Changes...' : 'Save Personal & ICE Details',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {required bool isEditable}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          if (!isEditable)
            _buildHospitalManagedBadge()
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.successGreenBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_outlined, size: 11, color: AppColors.successGreen),
                  SizedBox(width: 3),
                  Text(
                    'EDITABLE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.successGreen,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHospitalManagedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, size: 11, color: AppColors.primary),
          SizedBox(width: 3),
          Text(
            'HOSPITAL MANAGED',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
