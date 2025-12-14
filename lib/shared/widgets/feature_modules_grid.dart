import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../features/anti_fraud/anti_fraud_screen.dart';
import '../../features/lost_phone/lost_phone_screen.dart';

class FeatureModulesGrid extends StatelessWidget {
  const FeatureModulesGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final modules = [
      _FeatureModule(
        icon: Icons.shield_outlined,
        title: 'Antivirus',
        subtitle: 'Scan & Protect',
        gradient: AppTheme.primaryGradient,
        onTap: () => _showComingSoon(context, 'Antivirus'),
      ),
      _FeatureModule(
        icon: Icons.phone,
        title: 'Caller ID',
        subtitle: 'Block Spam',
        gradient: const LinearGradient(
          colors: [Color(0xFF32D74B), Color(0xFF30DB5B)],
        ),
        onTap: () => _showComingSoon(context, 'Caller ID'),
      ),
      _FeatureModule(
        icon: Icons.credit_card,
        title: 'Payment',
        subtitle: 'Secure Transactions',
        gradient: const LinearGradient(
          colors: [Color(0xFF5E5CE6), Color(0xFF8E8CD8)],
        ),
        onTap: () => _showComingSoon(context, 'Payment Security'),
      ),
      _FeatureModule(
        icon: Icons.language,
        title: 'Web Security',
        subtitle: 'Safe Browsing',
        gradient: const LinearGradient(
          colors: [Color(0xFFFF9F0A), Color(0xFFFFB340)],
        ),
        onTap: () => _showComingSoon(context, 'Web Security'),
      ),
      _FeatureModule(
        icon: Icons.warning_amber,
        title: 'Anti-Fraud',
        subtitle: 'Scam Protection',
        gradient: const LinearGradient(
          colors: [Color(0xFFFF453A), Color(0xFFFF6961)],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AntiFraudScreen()),
        ),
      ),
      _FeatureModule(
        icon: Icons.wifi,
        title: 'Network',
        subtitle: 'Wi-Fi Security',
        gradient: const LinearGradient(
          colors: [Color(0xFF64D2FF), Color(0xFF8ADDFF)],
        ),
        onTap: () => _showComingSoon(context, 'Network Security'),
      ),
      _FeatureModule(
        icon: Icons.phone_android,
        title: 'Lost Phone',
        subtitle: 'Find & Protect',
        gradient: const LinearGradient(
          colors: [Color(0xFFBF5AF2), Color(0xFFDA6FDA)],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LostPhoneScreen()),
        ),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: modules.length,
      itemBuilder: (context, index) {
        return modules[index]
            .animate()
            .fadeIn(delay: (100 * index).ms, duration: 600.ms)
            .scale(begin: const Offset(0.8, 0.8));
      },
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature - Coming soon!')),
    );
  }
}

class _FeatureModule extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final VoidCallback onTap;

  const _FeatureModule({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 32),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
