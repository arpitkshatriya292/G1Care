import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../models/medical_profile.dart';
import '../../models/medicine_item.dart';
import '../../providers/hospital_provider.dart';
import '../../providers/medical_profile_provider.dart';
import '../../services/firestore_service.dart';

class HospitalEditPatientMedicalScreen extends StatefulWidget {
  final String medicalId;
  final String? patientUid;

  const HospitalEditPatientMedicalScreen({
    super.key,
    required this.medicalId,
    this.patientUid,
  });

  @override
  State<HospitalEditPatientMedicalScreen> createState() =>
      _HospitalEditPatientMedicalScreenState();
}

class _HospitalEditPatientMedicalScreenState
    extends State<HospitalEditPatientMedicalScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  MedicalProfile? _currentProfile;

  // Hospital-Managed Form Fields
  String _selectedBloodGroup = 'O+';
  final List<String> _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
    'Unknown',
  ];
  final List<String> _allergies = [];
  final List<MedicineItem> _medicines = [];
  final List<String> _conditions = [];
  final List<String> _surgeries = [];
  final List<String> _illnesses = [];

  late TextEditingController _emergencyNotesController;
  late TextEditingController _primaryDoctorController;

  final TextEditingController _allergyInputController = TextEditingController();
  final TextEditingController _conditionInputController = TextEditingController();
  final TextEditingController _surgeryInputController = TextEditingController();
  final TextEditingController _illnessInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _emergencyNotesController = TextEditingController();
    _primaryDoctorController = TextEditingController();
    _loadPatientData();
  }

  @override
  void dispose() {
    _emergencyNotesController.dispose();
    _primaryDoctorController.dispose();
    _allergyInputController.dispose();
    _conditionInputController.dispose();
    _surgeryInputController.dispose();
    _illnessInputController.dispose();
    super.dispose();
  }

  Future<void> _loadPatientData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      MedicalProfile? profile;
      if (widget.patientUid != null && widget.patientUid!.isNotEmpty) {
        profile = await _firestoreService.getMedicalProfile(widget.patientUid!);
      } else {
        profile = await _firestoreService.getProfileByMedicalId(widget.medicalId);
      }

      if (profile != null) {
        _currentProfile = profile;
        _selectedBloodGroup = _bloodGroups.contains(profile.bloodGroup)
            ? profile.bloodGroup
            : 'O+';
        _allergies.clear();
        _allergies.addAll(profile.allergies);
        _medicines.clear();
        _medicines.addAll(profile.medicines);
        _conditions.clear();
        _conditions.addAll(profile.medicalConditions);
        _surgeries.clear();
        _surgeries.addAll(profile.previousSurgeries);
        _illnesses.clear();
        _illnesses.addAll(profile.previousIllnesses);
        _emergencyNotesController.text = profile.emergencyNotes;
        _primaryDoctorController.text = profile.primaryDoctor;

        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Patient profile not found for Medical ID: ${widget.medicalId}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading patient record: $e';
      });
    }
  }

  void _addAllergy() {
    final text = _allergyInputController.text.trim();
    if (text.isNotEmpty && !_allergies.contains(text)) {
      setState(() {
        _allergies.add(text);
        _allergyInputController.clear();
      });
    }
  }

  void _addCondition() {
    final text = _conditionInputController.text.trim();
    if (text.isNotEmpty && !_conditions.contains(text)) {
      setState(() {
        _conditions.add(text);
        _conditionInputController.clear();
      });
    }
  }

  void _addSurgery() {
    final text = _surgeryInputController.text.trim();
    if (text.isNotEmpty && !_surgeries.contains(text)) {
      setState(() {
        _surgeries.add(text);
        _surgeryInputController.clear();
      });
    }
  }

  void _addIllness() {
    final text = _illnessInputController.text.trim();
    if (text.isNotEmpty && !_illnesses.contains(text)) {
      setState(() {
        _illnesses.add(text);
        _illnessInputController.clear();
      });
    }
  }

  void _showAddMedicineDialog() {
    final nameCtrl = TextEditingController();
    final dosageCtrl = TextEditingController();
    final freqCtrl = TextEditingController(text: 'Daily');
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.medication_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Add Prescription', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Medication Name (e.g. Metformin)',
                  prefixIcon: Icon(Icons.medical_services_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dosageCtrl,
                decoration: const InputDecoration(
                  labelText: 'Dosage (e.g. 500mg, 1 tablet)',
                  prefixIcon: Icon(Icons.numbers_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: freqCtrl,
                decoration: const InputDecoration(
                  labelText: 'Frequency (e.g. Twice daily after meals)',
                  prefixIcon: Icon(Icons.schedule_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Special Instructions (optional)',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                setState(() {
                  _medicines.add(MedicineItem(
                    name: nameCtrl.text.trim(),
                    dosage: dosageCtrl.text.trim().isNotEmpty
                        ? dosageCtrl.text.trim()
                        : 'As directed',
                    frequency: freqCtrl.text.trim().isNotEmpty
                        ? freqCtrl.text.trim()
                        : 'Daily',
                    instructions: notesCtrl.text.trim().isNotEmpty
                        ? notesCtrl.text.trim()
                        : null,
                  ));
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('ADD DRUG'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSaveHospitalMedicalData() async {
    if (_formKey.currentState!.validate() && _currentProfile != null) {
      setState(() {
        _isSaving = true;
      });

      final hospitalProvider =
          Provider.of<HospitalProvider>(context, listen: false);
      final profileProvider =
          Provider.of<MedicalProfileProvider>(context, listen: false);

      final hospitalName = hospitalProvider.currentHospital.hospitalName;

      final updatedMedicalData = _currentProfile!.copyWithHospitalMedicalData(
        bloodGroup: _selectedBloodGroup,
        allergies: _allergies,
        medicines: _medicines,
        medicalConditions: _conditions,
        previousSurgeries: _surgeries,
        previousIllnesses: _illnesses,
        emergencyNotes: _emergencyNotesController.text.trim(),
        primaryDoctor: _primaryDoctorController.text.trim(),
        hospitalTag: hospitalName,
      );

      final success = await profileProvider.saveHospitalManagedMedicalData(
        _currentProfile!.uid,
        updatedMedicalData,
        hospitalName: hospitalName,
      );

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Patient medical records updated by $hospitalName & synchronized in real time!',
            ),
            backgroundColor: AppColors.successGreen,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(profileProvider.errorMessage ?? 'Failed to update record.'),
            backgroundColor: AppColors.emergencyRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hospitalProvider = Provider.of<HospitalProvider>(context);
    final hospital = hospitalProvider.currentHospital;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Patient Medical Record'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Save Hospital Medical Data',
            onPressed: (_isLoading || _isSaving) ? null : _handleSaveHospitalMedicalData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.emergencyRed),
                        const SizedBox(height: 12),
                        Text(_errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadPatientData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hospital Authority Banner
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.local_hospital_rounded, color: AppColors.primary, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'HOSPITAL CLINICAL DESK • ${hospital.hospitalName.toUpperCase()}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Patient: ${_currentProfile?.fullName ?? "Patient"} (ID: ${widget.medicalId})',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Section 3: Critical Emergency Data
                        _buildSectionTitle('Critical Emergency Data'),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedBloodGroup,
                          decoration: const InputDecoration(
                            labelText: 'Verified Blood Group *',
                            prefixIcon: Icon(Icons.bloodtype_outlined, color: AppColors.emergencyRed),
                          ),
                          items: _bloodGroups.map((bg) {
                            return DropdownMenuItem(
                              value: bg,
                              child: Text(bg, style: const TextStyle(fontWeight: FontWeight.bold)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedBloodGroup = val);
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // Allergies Tag List
                        const Text(
                          'Known Allergies (Food, Drug, Environmental)',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _allergyInputController,
                                decoration: const InputDecoration(
                                  hintText: 'e.g. Penicillin, Peanuts, Sulfa',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                                onSubmitted: (_) => _addAllergy(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _addAllergy,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              child: const Text('Add'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: _allergies.map((allergy) {
                            return Chip(
                              backgroundColor: AppColors.emergencyRedBg,
                              label: Text(
                                allergy,
                                style: const TextStyle(
                                  color: AppColors.emergencyRed,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              deleteIcon: const Icon(Icons.close, size: 16, color: AppColors.emergencyRed),
                              onDeleted: () {
                                setState(() => _allergies.remove(allergy));
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        // Pre-existing Conditions
                        const Text(
                          'Pre-existing Medical Conditions / Chronic Illnesses',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _conditionInputController,
                                decoration: const InputDecoration(
                                  hintText: 'e.g. Type 2 Diabetes, Hypertension, Asthma',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                                onSubmitted: (_) => _addCondition(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _addCondition,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              child: const Text('Add'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: _conditions.map((cond) {
                            return Chip(
                              backgroundColor: AppColors.primaryLight,
                              label: Text(
                                cond,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              deleteIcon: const Icon(Icons.close, size: 16, color: AppColors.primary),
                              onDeleted: () {
                                setState(() => _conditions.remove(cond));
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),

                        // Section 4: Current Prescriptions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: _buildSectionTitle('Current Prescriptions')),
                            TextButton.icon(
                              onPressed: _showAddMedicineDialog,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Drug'),
                            ),
                          ],
                        ),
                        if (_medicines.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'No medications recorded. Tap "+ Add Drug" to prescribe.',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _medicines.length,
                            itemBuilder: (ctx, idx) {
                              final med = _medicines[idx];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: const Icon(Icons.medication, color: AppColors.secondary),
                                  title: Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('${med.dosage} • ${med.frequency}'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AppColors.emergencyRed),
                                    onPressed: () {
                                      setState(() => _medicines.removeAt(idx));
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        const SizedBox(height: 24),

                        // Section 5: Surgical History & Past Illnesses
                        _buildSectionTitle('Surgical History & Past Illnesses'),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _surgeryInputController,
                                decoration: const InputDecoration(
                                  hintText: 'Add Surgery (e.g. CABG 2020)',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                                onSubmitted: (_) => _addSurgery(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _addSurgery,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              child: const Text('Add'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          children: _surgeries.map((s) {
                            return Chip(
                              label: Text(s),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () => setState(() => _surgeries.remove(s)),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _illnessInputController,
                                decoration: const InputDecoration(
                                  hintText: 'Add Past Illness (e.g. Pneumonia 2022)',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                                onSubmitted: (_) => _addIllness(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _addIllness,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              child: const Text('Add'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          children: _illnesses.map((i) {
                            return Chip(
                              label: Text(i),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () => setState(() => _illnesses.remove(i)),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),

                        // Section 6: Emergency Directives & Primary Doctor
                        _buildSectionTitle('Special Directives & Primary Doctor'),
                        TextFormField(
                          controller: _primaryDoctorController,
                          decoration: const InputDecoration(
                            labelText: 'Primary Doctor / Attending Physician Name',
                            prefixIcon: Icon(Icons.local_hospital_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _emergencyNotesController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Special Emergency Directives / Medical Notes',
                            hintText: 'e.g. Pacemaker implanted, severe latex allergy, DNR status, etc.',
                            prefixIcon: Icon(Icons.note_alt_outlined),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _isSaving ? null : _handleSaveHospitalMedicalData,
                            icon: _isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Icon(Icons.cloud_upload_rounded),
                            label: Text(
                              _isSaving ? 'Syncing with Firestore...' : 'SAVE & SYNC PATIENT MEDICAL DATA',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
