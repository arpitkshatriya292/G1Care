import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_constants.dart';
import '../models/vital_reading.dart';

class SosCountdownDialog extends StatefulWidget {
  final VoidCallback onConfirmed;
  final VoidCallback onCancelled;

  const SosCountdownDialog({
    super.key,
    required this.onConfirmed,
    required this.onCancelled,
  });

  @override
  State<SosCountdownDialog> createState() => _SosCountdownDialogState();
}

class _SosCountdownDialogState extends State<SosCountdownDialog> {
  int _countdown = 5;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    HapticFeedback.heavyImpact();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() {
          _countdown--;
        });
        HapticFeedback.mediumImpact();
      } else {
        timer.cancel();
        Navigator.of(context).pop();
        widget.onConfirmed();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppColors.surface,
      contentPadding: const EdgeInsets.all(24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.emergencyRedBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emergency, color: AppColors.emergencyRed, size: 48),
          ),
          const SizedBox(height: 16),
          const Text(
            'EMERGENCY SOS TRIGGERED',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.emergencyRed,
              letterSpacing: 0.8,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Transmitting your location, medical ID, and live health vitals to the Doctor Emergency Network in:',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            width: 70,
            height: 70,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.emergencyRed, width: 3),
              color: AppColors.emergencyRedBg,
            ),
            child: Text(
              '$_countdown',
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: AppColors.emergencyRed,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: AppColors.textSecondary),
                  ),
                  onPressed: () {
                    _timer?.cancel();
                    Navigator.of(context).pop();
                    widget.onCancelled();
                  },
                  child: const Text(
                    "I'M OK / CANCEL",
                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emergencyRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    _timer?.cancel();
                    Navigator.of(context).pop();
                    widget.onConfirmed();
                  },
                  child: const Text(
                    'SEND NOW',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SosButton extends StatelessWidget {
  final VoidCallback onTriggered;
  final VoidCallback? onCancelled;
  final bool isEnabled;
  final String? disabledReason;
  final HealthRiskLevel riskLevel;

  const SosButton({
    super.key,
    required this.onTriggered,
    this.onCancelled,
    this.isEnabled = true,
    this.disabledReason,
    this.riskLevel = HealthRiskLevel.normal,
  });

  void _showCountdownDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SosCountdownDialog(
        onConfirmed: onTriggered,
        onCancelled: onCancelled ?? () {},
      ),
    );
  }

  void _handlePress(BuildContext context) {
    if (!isEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(disabledReason ?? 'Emergency SOS unavailable while condition is normal.'),
          backgroundColor: AppColors.textSecondary,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (riskLevel == HealthRiskLevel.warning) {
      _showWarningConfirmationDialog(context);
    } else {
      _showCountdownDialog(context);
    }
  }

  void _showWarningConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warningOrange, size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Request Ambulance Response?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: const Text(
          'Your health condition indicates a warning. Do you want to request an ambulance?',
          style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emergencyRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _showCountdownDialog(context);
            },
            child: const Text('CONFIRM EMERGENCY', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveDisabled = !isEnabled;

    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 64,
          margin: const EdgeInsets.only(top: 12, bottom: 6),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: effectiveDisabled
                  ? AppColors.cardBorder
                  : AppColors.emergencyRed,
              foregroundColor: effectiveDisabled
                  ? AppColors.textMuted
                  : Colors.white,
              elevation: effectiveDisabled ? 0 : 4,
              shadowColor: effectiveDisabled
                  ? Colors.transparent
                  : AppColors.emergencyRed.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: effectiveDisabled
                    ? const BorderSide(color: AppColors.cardBorder, width: 1.5)
                    : BorderSide.none,
              ),
            ),
            onPressed: () => _handlePress(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  effectiveDisabled ? Icons.lock_outline_rounded : Icons.emergency,
                  size: 28,
                  color: effectiveDisabled ? AppColors.textMuted : Colors.white,
                ),
                const SizedBox(width: 12),
                Text(
                  'EMERGENCY SOS',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: effectiveDisabled ? AppColors.textMuted : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (effectiveDisabled)
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Text(
              disabledReason ?? 'Emergency SOS unavailable while condition is normal.',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}
