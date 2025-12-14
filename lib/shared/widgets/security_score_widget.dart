import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import '../providers/security_provider.dart';
import '../../theme/app_theme.dart';

class SecurityScoreWidget extends StatelessWidget {
  const SecurityScoreWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final securityProvider = context.watch<SecurityProvider>();
    final score = securityProvider.securityScore;
    
    // Determine color and status based on score
    final (color, gradient, status) = _getScoreDetails(score);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Circular Score Indicator
          SizedBox(
            width: 180,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background circle
                CustomPaint(
                  size: const Size(180, 180),
                  painter: _ScoreCirclePainter(
                    progress: score / 100,
                    color: Colors.white,
                  ),
                ),
                
                // Score text
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      score.toString(),
                      style: const TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'SECURITY SCORE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                
                // Pulsing effect if threats detected
                if (securityProvider.threatsDetected > 0)
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 2),
                    ),
                  )
                      .animate(onPlay: (controller) => controller.repeat())
                      .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.1, 1.1),
                        duration: 1500.ms,
                      )
                      .then()
                      .fade(begin: 0.5, end: 0),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Status text
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  (Color, Gradient, String) _getScoreDetails(int score) {
    if (score >= 71) {
      return (
        AppTheme.safeGreen,
        AppTheme.safeGradient,
        'Device is Protected',
      );
    } else if (score >= 41) {
      return (
        AppTheme.warningOrange,
        const LinearGradient(
          colors: [Color(0xFFFF9F0A), Color(0xFFFFB340)],
        ),
        'Needs Attention',
      );
    } else {
      return (
        AppTheme.dangerRed,
        AppTheme.dangerGradient,
        'Device at Risk',
      );
    }
  }
}

class _ScoreCirclePainter extends CustomPainter {
  final double progress;
  final Color color;

  _ScoreCirclePainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background circle
    final backgroundPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;

    canvas.drawCircle(center, radius - 6, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 6),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreCirclePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
