import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import 'status_chip.dart';

class DoctorVerificationCard extends StatelessWidget {
  final DoctorVerificationStatus status;
  final VoidCallback? onSimulateToggle;

  const DoctorVerificationCard({
    super.key,
    required this.status,
    this.onSimulateToggle,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    String title;
    String desc;

    switch (status) {
      case DoctorVerificationStatus.approved:
        bg = AppColors.successGreenBg;
        title = 'Medical Access Granted';
        desc = 'Your medical license registration is verified. You are authorized to scan patient QR codes.';
        break;
      case DoctorVerificationStatus.pending:
        bg = AppColors.warningOrangeBg;
        title = 'Verification Pending';
        desc = 'Your medical registration is under review. Scanning patient QR codes is currently disabled.';
        break;
      case DoctorVerificationStatus.rejected:
        bg = AppColors.emergencyRedBg;
        title = 'Verification Rejected';
        desc = 'Your medical registration document could not be verified. Please contact G1Care admin support.';
        break;
      case DoctorVerificationStatus.suspended:
        bg = AppColors.emergencyRedBg;
        title = 'Account Suspended';
        desc = 'Your medical access account is suspended. Contact compliance for assistance.';
        break;
    }

    return Card(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: status == DoctorVerificationStatus.approved
              ? AppColors.successGreen.withValues(alpha: 0.4)
              : status == DoctorVerificationStatus.pending
                  ? AppColors.warningOrange.withValues(alpha: 0.4)
                  : AppColors.emergencyRed.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StatusChip.doctorStatus(status),
                const Spacer(),
                if (onSimulateToggle != null)
                  TextButton.icon(
                    onPressed: onSimulateToggle,
                    icon: const Icon(Icons.admin_panel_settings, size: 16),
                    label: const Text('Simulate Admin', style: TextStyle(fontSize: 11)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              desc,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
