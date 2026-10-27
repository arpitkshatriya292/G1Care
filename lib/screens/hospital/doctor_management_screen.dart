import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/validators.dart';
import '../../models/hospital_doctor.dart';
import '../../providers/hospital_provider.dart';

class DoctorManagementScreen extends StatefulWidget {
  const DoctorManagementScreen({super.key});

  @override
  State<DoctorManagementScreen> createState() => _DoctorManagementScreenState();
}

class _DoctorManagementScreenState extends State<DoctorManagementScreen> {
  String _filter = 'all'; // all, verified, unverified

  void _showAddDoctorDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final regNoCtrl = TextEditingController();
    final specCtrl = TextEditingController(text: 'Emergency Medicine');
    final deptCtrl = TextEditingController(text: 'Emergency Department');
    final roleCtrl = TextEditingController(text: 'Emergency Physician');
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final expCtrl = TextEditingController(text: '5');
    final joinDateCtrl = TextEditingController(text: 'Today');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.person_add_rounded, color: AppColors.primary, size: 26),
            SizedBox(width: 10),
            Text('Register New Doctor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Doctor Full Name *', prefixIcon: Icon(Icons.person_outline)),
                    validator: (v) => Validators.validateRequired(v, 'Doctor Name'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: regNoCtrl,
                    decoration: const InputDecoration(labelText: 'Medical Registration / License No *', prefixIcon: Icon(Icons.badge_outlined)),
                    validator: (v) => Validators.validateRequired(v, 'Registration Number'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: specCtrl,
                    decoration: const InputDecoration(labelText: 'Specialization *', prefixIcon: Icon(Icons.medical_information_outlined)),
                    validator: (v) => Validators.validateRequired(v, 'Specialization'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: deptCtrl,
                    decoration: const InputDecoration(labelText: 'Department *', prefixIcon: Icon(Icons.apartment_outlined)),
                    validator: (v) => Validators.validateRequired(v, 'Department'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: roleCtrl,
                    decoration: const InputDecoration(labelText: 'Designation / Role *', prefixIcon: Icon(Icons.work_outline)),
                    validator: (v) => Validators.validateRequired(v, 'Role'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Phone Number *', prefixIcon: Icon(Icons.phone_outlined)),
                    validator: Validators.validatePhone,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email Address *', prefixIcon: Icon(Icons.email_outlined)),
                    validator: Validators.validateEmail,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: expCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Years of Experience *', prefixIcon: Icon(Icons.timeline)),
                    validator: (v) => Validators.validateRequired(v, 'Experience'),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final hospitalProvider = Provider.of<HospitalProvider>(context, listen: false);
                await hospitalProvider.addDoctor(
                  name: nameCtrl.text.trim(),
                  medicalRegistrationNumber: regNoCtrl.text.trim(),
                  specialty: specCtrl.text.trim(),
                  department: deptCtrl.text.trim(),
                  role: roleCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  yearsOfExperience: int.tryParse(expCtrl.text.trim()) ?? 0,
                  joiningDate: joinDateCtrl.text.trim(),
                  isVerified: false, // Starts as unverified/pending
                );

                if (ctx.mounted) Navigator.pop(ctx);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${nameCtrl.text.trim()} added. Status: PENDING VERIFICATION.'),
                      backgroundColor: AppColors.warningOrange,
                    ),
                  );
                }
              }
            },
            child: const Text('ADD DOCTOR'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hospitalProvider = Provider.of<HospitalProvider>(context);
    final allDoctors = hospitalProvider.doctors;

    final filteredDoctors = allDoctors.where((d) {
      if (_filter == 'verified') return d.isVerified;
      if (_filter == 'unverified') return !d.isVerified;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded),
            tooltip: 'Add Doctor',
            onPressed: () => _showAddDoctorDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header stats banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 360;
                  return Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Hospital Doctor Registry',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${hospitalProvider.totalDoctorsCount} Reg • ${hospitalProvider.verifiedDoctorsCount} Verified • ${hospitalProvider.unverifiedDoctorsCount} Pending',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _showAddDoctorDialog(context),
                        icon: const Icon(Icons.add, size: 16),
                        label: Text(
                          isCompact ? 'ADD' : 'ADD DOCTOR',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Filter Tabs (Horizontally scrollable for responsiveness)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All (${hospitalProvider.totalDoctorsCount})', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Verified (${hospitalProvider.verifiedDoctorsCount})', 'verified'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Unverified (${hospitalProvider.unverifiedDoctorsCount})', 'unverified'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Doctors List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredDoctors.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, idx) {
                final doc = filteredDoctors[idx];
                return _buildDoctorCard(context, doc, hospitalProvider);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      selectedColor: AppColors.primaryLight,
      onSelected: (_) {
        setState(() => _filter = value);
      },
    );
  }

  Widget _buildDoctorCard(BuildContext context, HospitalDoctor doc, HospitalProvider provider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: doc.isVerified ? AppColors.cardBorder : AppColors.warningOrange,
          width: doc.isVerified ? 1 : 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Name, Specialty & Status Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: doc.isVerified ? AppColors.primaryLight : AppColors.warningOrangeBg,
                  child: Icon(
                    Icons.person,
                    color: doc.isVerified ? AppColors.primary : AppColors.warningOrange,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${doc.specialty} • ${doc.department}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                      Text(
                        'Role: ${doc.role} • ${doc.yearsOfExperience} yrs exp',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: doc.isVerified ? AppColors.successGreenBg : AppColors.warningOrangeBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: doc.isVerified ? AppColors.successGreen : AppColors.warningOrange,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    doc.isVerified ? 'VERIFIED' : 'UNVERIFIED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: doc.isVerified ? AppColors.successGreen : AppColors.warningOrange,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.cardBorder),
            const SizedBox(height: 10),

            // Reg number & Contact (Wrap for responsiveness)
            Wrap(
              spacing: 16,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.badge_outlined, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Reg: ${doc.medicalRegistrationNumber}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontFamily: 'monospace'),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.phone_outlined, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(doc.phone, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Action Button: Verify / Revoke Access
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: doc.isVerified ? AppColors.textSecondary : AppColors.successGreen,
                  side: BorderSide(
                    color: doc.isVerified ? AppColors.cardBorder : AppColors.successGreen,
                    width: 1.2,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  await provider.toggleDoctorVerification(doc.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          !doc.isVerified
                              ? '${doc.name} verified successfully! Doctor-level access granted.'
                              : '${doc.name} verification revoked.',
                        ),
                        backgroundColor: !doc.isVerified ? AppColors.successGreen : AppColors.warningOrange,
                      ),
                    );
                  }
                },
                icon: Icon(
                  doc.isVerified ? Icons.remove_circle_outline : Icons.verified_user_rounded,
                  size: 16,
                ),
                label: Text(
                  doc.isVerified ? 'REVOKE ACCESS' : 'VERIFY DOCTOR (GRANT ACCESS)',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
