import 'dart:math';
import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';

/// The official G1Care Logo featuring:
/// - Turquoise-to-Royal-Blue gradient 'G'-shaped medical emblem
/// - Center heart and emergency medical cross symbol
/// - Premium typographic branding
class G1CareLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool showTagline;
  final Color? textColor;
  final bool isDark;

  const G1CareLogo({
    super.key,
    this.size = 72,
    this.showText = false,
    this.showTagline = false,
    this.textColor,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final logoMark = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _G1CareLogoPainter(),
      ),
    );

    if (!showText) {
      return logoMark;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        logoMark,
        const SizedBox(height: 12),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'G1',
                style: TextStyle(
                  fontSize: size * 0.42,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: isDark ? Colors.white : const Color(0xFF0F3959),
                ),
              ),
              TextSpan(
                text: 'Care',
                style: TextStyle(
                  fontSize: size * 0.42,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: const Color(0xFF00A896),
                ),
              ),
            ],
          ),
        ),
        if (showTagline) ...[
          const SizedBox(height: 6),
          Text(
            'Smart Health & Disaster Response System',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: max(11, size * 0.16),
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : AppColors.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ],
    );
  }
}

class _G1CareLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    // 1. Soft Shadow
    final shadowPaint = Paint()
      ..color = const Color(0xFF00A896).withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center + const Offset(0, 4), radius * 0.88, shadowPaint);

    // 2. Base Container: Smooth Squircle with Turquoise to Deep Blue Gradient
    final rect = Rect.fromCenter(center: center, width: w, height: h);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(w * 0.28));

    final gradientPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF00C9FF), // Vibrant Turquoise
          Color(0xFF00A896), // Medical Cyan-Teal
          Color(0xFF028090), // Ocean Teal
          Color(0xFF05668D), // Deep Medical Navy
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);

    canvas.drawRRect(rrect, gradientPaint);

    // 3. Subtle Inner Glow Ring
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.03
      ..color = Colors.white.withValues(alpha: 0.35);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: w * 0.88, height: h * 0.88),
        Radius.circular(w * 0.24),
      ),
      ringPaint,
    );

    // 4. Center Medical Heart & Cross Symbol
    // Medical Cross
    final crossPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final crossWidth = w * 0.16;
    final crossLength = w * 0.44;
    final cornerRadius = Radius.circular(w * 0.04);

    // Vertical Cross Bar
    final vBar = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: crossWidth, height: crossLength),
      cornerRadius,
    );
    canvas.drawRRect(vBar, crossPaint);

    // Horizontal Cross Bar
    final hBar = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: crossLength, height: crossWidth),
      cornerRadius,
    );
    canvas.drawRRect(hBar, crossPaint);

    // Center Pulse / Heartbeat Line (Turquoise Accent)
    final pulsePaint = Paint()
      ..color = const Color(0xFF05668D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.045
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final pulsePath = Path();
    pulsePath.moveTo(w * 0.30, h * 0.50);
    pulsePath.lineTo(w * 0.42, h * 0.50);
    pulsePath.lineTo(w * 0.47, h * 0.38);
    pulsePath.lineTo(w * 0.53, h * 0.62);
    pulsePath.lineTo(w * 0.58, h * 0.50);
    pulsePath.lineTo(w * 0.70, h * 0.50);

    canvas.drawPath(pulsePath, pulsePaint);

    // 5. 'G' Notch Accent (Top Right subtle dot)
    final dotPaint = Paint()
      ..color = const Color(0xFF00FFC5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.78, h * 0.22), w * 0.045, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
