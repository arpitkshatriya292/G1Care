import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';

class StatusChip extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const StatusChip({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });

  factory StatusChip.doctorStatus(DoctorVerificationStatus status) {
    switch (status) {
      case DoctorVerificationStatus.approved:
        return const StatusChip(
          label: 'VERIFIED DOCTOR',
          backgroundColor: AppColors.successGreenBg,
          textColor: AppColors.successGreen,
          icon: Icons.verified_user,
        );
      case DoctorVerificationStatus.pending:
        return const StatusChip(
          label: 'VERIFICATION PENDING',
          backgroundColor: AppColors.warningOrangeBg,
          textColor: AppColors.warningOrange,
          icon: Icons.pending_actions,
        );
      case DoctorVerificationStatus.rejected:
        return const StatusChip(
          label: 'VERIFICATION REJECTED',
          backgroundColor: AppColors.emergencyRedBg,
          textColor: AppColors.emergencyRed,
          icon: Icons.cancel,
        );
      case DoctorVerificationStatus.suspended:
        return const StatusChip(
          label: 'ACCOUNT SUSPENDED',
          backgroundColor: AppColors.emergencyRedBg,
          textColor: AppColors.emergencyRed,
          icon: Icons.block,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: textColor),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
