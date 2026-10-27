import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/doctor_verification_card.dart';

class DoctorVerificationScreen extends StatelessWidget {
  const DoctorVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final doctor = authProvider.doctorUser;
    final status = authProvider.doctorVerificationStatus;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Verification Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dr. ${doctor?.name ?? "Doctor"}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Reg. No: ${doctor?.medicalRegistrationNumber ?? "N/A"} | ${doctor?.specialization ?? "General"}',
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),

            // Verification Banner Card
            DoctorVerificationCard(
              status: status,
              onSimulateToggle: () async {
                await authProvider.simulateDoctorApprovalToggle();
                if (context.mounted && authProvider.isDoctorApproved) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('PROTOTYPE SIMULATION: Doctor License Approved! Redirecting to Doctor Dashboard...'),
                      backgroundColor: AppColors.successGreen,
                    ),
                  );
                }
              },
            ),

            const SizedBox(height: 32),
            const Text(
              'Backend Security Enforcement Rules:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            _buildRuleItem('1. Doctor registration creates doctors/{UID} with verificationStatus = PENDING.'),
            _buildRuleItem('2. Firestore Security Rules enforce doctor status == APPROVED before granting access.'),
            _buildRuleItem('3. PENDING, REJECTED, or SUSPENDED accounts are strictly blocked from QR scanning.'),
            _buildRuleItem('4. Hackathon Prototype: Use the "Simulate Admin" button above to toggle approval for demo testing.'),

            const SizedBox(height: 32),
            if (status == DoctorVerificationStatus.approved)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/doctor/home');
                  },
                  icon: const Icon(Icons.dashboard_rounded),
                  label: const Text('Enter Doctor Dashboard'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
