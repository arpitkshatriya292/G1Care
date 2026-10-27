import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/disaster_provider.dart';

class DisasterWellnessScreen extends StatelessWidget {
  const DisasterWellnessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final disasterProvider = Provider.of<DisasterProvider>(context);
    final health = disasterProvider.health;
    final baseline = disasterProvider.baseline;
    final indicators = disasterProvider.wellnessIndicators;

    final hrDelta = health.heartRate - baseline.restingHeartRate;
    final tempDelta = health.bodyTemperature - baseline.normalBodyTemp;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Wellness & Trends'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Non-diagnostic Medical Notice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Wellness indicators synthesize physiological and environmental data for situational awareness. They are not medical diagnoses.',
                      style: TextStyle(fontSize: 11, color: AppColors.primaryDark),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Daily Health Summary Card
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.cardBorder),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DAILY HEALTH SUMMARY',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryItem(
                          'Heart Rate',
                          '${health.heartRate} BPM',
                          hrDelta > 0 ? '+$hrDelta vs base' : 'Aligned',
                          hrDelta > 15 ? AppColors.warningOrange : AppColors.successGreen,
                        ),
                        _buildSummaryItem(
                          'SpO2',
                          '${health.spo2}%',
                          health.spo2 >= 95 ? 'Normal' : 'Desaturation',
                          health.spo2 >= 95 ? AppColors.successGreen : AppColors.emergencyRed,
                        ),
                        _buildSummaryItem(
                          'Body Temp',
                          '${health.bodyTemperature.toStringAsFixed(1)}°C',
                          tempDelta > 0.5 ? '+${tempDelta.toStringAsFixed(1)}°C' : 'Stable',
                          tempDelta > 1.0 ? AppColors.warningOrange : AppColors.successGreen,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Personal Baseline Comparison
            const Text(
              'Personal Baseline Comparison',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),

            _buildBaselineComparisonRow(
              title: 'Resting Heart Rate',
              currentVal: '${health.heartRate} BPM',
              baselineVal: '${baseline.restingHeartRate} BPM',
              deviation: hrDelta > 0 ? '+$hrDelta BPM' : '$hrDelta BPM',
              isElevated: hrDelta > 15,
            ),
            _buildBaselineComparisonRow(
              title: 'Oxygen Saturation (SpO2)',
              currentVal: '${health.spo2}%',
              baselineVal: '${baseline.normalSpo2}%',
              deviation: '${health.spo2 - baseline.normalSpo2}%',
              isElevated: health.spo2 < 95,
            ),
            _buildBaselineComparisonRow(
              title: 'Body Temperature',
              currentVal: '${health.bodyTemperature.toStringAsFixed(1)}°C',
              baselineVal: '${baseline.normalBodyTemp.toStringAsFixed(1)}°C',
              deviation: '${tempDelta > 0 ? "+" : ""}${tempDelta.toStringAsFixed(1)}°C',
              isElevated: tempDelta > 0.8,
            ),
            _buildBaselineComparisonRow(
              title: 'Sleep Duration',
              currentVal: '${health.sleepDurationHours.toStringAsFixed(1)} hrs',
              baselineVal: '${baseline.targetSleepHours.toStringAsFixed(1)} hrs',
              deviation: '${(health.sleepDurationHours - baseline.targetSleepHours).toStringAsFixed(1)} hrs',
              isElevated: health.sleepDurationHours < 6.0,
            ),

            const SizedBox(height: 20),

            // Wellness Risk Indicators Section
            const Text(
              'Situational Risk Indicators',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),

            ...indicators.map((ind) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ind.color.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(ind.icon, color: ind.color, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  ind.category,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: ind.color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    ind.status,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: ind.color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ind.details,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),

            const SizedBox(height: 16),

            // Health Trends (Activity & Sleep)
            const Text(
              'Activity & Sleep Telemetry',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: AppColors.cardBorder),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.directions_walk_rounded, color: AppColors.secondary, size: 18),
                              SizedBox(width: 6),
                              Text('Activity', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${health.activitySteps}',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const Text('Steps Today', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: AppColors.cardBorder),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.bedtime_rounded, color: Colors.indigo, size: 18),
                              SizedBox(width: 6),
                              Text('Sleep', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${health.sleepDurationHours.toStringAsFixed(1)} hrs',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          Text('Quality: ${health.sleepQuality}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, String sub, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(sub, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildBaselineComparisonRow({
    required String title,
    required String currentVal,
    required String baselineVal,
    required String deviation,
    required bool isElevated,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                Text('Baseline: $baselineVal', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(currentVal, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              Text(
                deviation,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isElevated ? AppColors.warningOrange : AppColors.successGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
