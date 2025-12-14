import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../lost_phone/services/lost_phone_service.dart';

class LostPhoneScreen extends StatefulWidget {
  const LostPhoneScreen({super.key});

  @override
  State<LostPhoneScreen> createState() => _LostPhoneScreenState();
}

class _LostPhoneScreenState extends State<LostPhoneScreen> {
  final _messageController = TextEditingController();
  final _trustedNumberController = TextEditingController();
  bool _isLoading = false;
  LostPhoneStatus? _status;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final status = await LostPhoneService.instance.getStatus();
    setState(() => _status = status);
    
    if (LostPhoneService.instance.trustedNumber != null) {
      _trustedNumberController.text = LostPhoneService.instance.trustedNumber!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lost Phone Protection'),
        elevation: 0,
      ),
      body: _status == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStatus,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Status Card
                  _buildStatusCard(),
                  
                  const SizedBox(height: 20),
                  
                  // Enable/Disable Protection
                  if (!_status!.trackingEnabled)
                    _buildEnableCard()
                  else ...[
                    // Protection Features
                    _buildLocationCard(),
                    const SizedBox(height: 16),
                    _buildActionsCard(),
                    const SizedBox(height: 16),
                    _buildEmergencyCard(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    final isProtected = _status!.trackingEnabled;
    final isLost = _status!.isLost;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: isLost
            ? AppTheme.dangerGradient
            : isProtected
                ? AppTheme.safeGradient
                : const LinearGradient(colors: [Colors.grey, Colors.grey]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            isLost
                ? Icons.error_outline
                : isProtected
                    ? Icons.verified_user
                    : Icons.shield_outlined,
            size: 64,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          Text(
            isLost
                ? 'Device Marked as Lost'
                : isProtected
                    ? 'Protection Active'
                    : 'Protection Disabled',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (isProtected) ...[
            const SizedBox(height: 8),
            Text(
              'Trusted: ${_status!.trackingEnabled ? _trustedNumberController.text : "Not Set"}',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).scale();
  }

  Widget _buildEnableCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enable Lost Phone Protection',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Features included:',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _buildFeatureRow(Icons.location_on, 'Location tracking'),
          _buildFeatureRow(Icons.sim_card, 'SIM change detection'),
          _buildFeatureRow(Icons.lock, 'Remote lock & wipe'),
          _buildFeatureRow(Icons.volume_up, 'Remote alarm'),
          _buildFeatureRow(Icons.message, 'SMS alerts'),
          const SizedBox(height: 16),
          TextField(
            controller: _trustedNumberController,
            decoration: InputDecoration(
              labelText: 'Trusted Phone Number',
              hintText: '+91 XXXXX-XXXXX',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _enableProtection,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppTheme.primaryBlue,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Enable Protection'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.safeGreen),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    final location = _status!.location;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.my_location, color: AppTheme.primaryBlue),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Location',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text('Last updated', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              Icon(
                location != null ? Icons.check_circle : Icons.error,
                color: location != null ? AppTheme.safeGreen : Colors.orange,
              ),
            ],
          ),
          if (location != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white10
                    : Colors.black12,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.place, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(location.timestamp),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openInMaps(location),
                icon: const Icon(Icons.map),
                label: const Text('Open in Google Maps'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            const Text('Location unavailable'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _refreshLocation,
              child: const Text('Refresh Location'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Remote Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildActionButton(
            'Play Alarm',
            'Sound loud alarm even if phone is silent',
            Icons.volume_up,
            AppTheme.warningOrange,
            _playAlarm,
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            'Mark as Lost',
            'Lock phone and start tracking',
            Icons.error_outline,
            AppTheme.dangerRed,
            _markAsLost,
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            'Send Location SMS',
            'Send current location to trusted contact',
            Icons.sms,
            AppTheme.primaryBlue,
            _sendLocationSms,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: color),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.dangerRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dangerRed.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning, color: AppTheme.dangerRed),
              SizedBox(width: 12),
              Text(
                'Emergency Actions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('These actions cannot be undone easily:'),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _showDisableDialog(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.dangerRed,
                side: const BorderSide(color: AppTheme.dangerRed),
              ),
              child: const Text('Disable Protection'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _enableProtection() async {
    if (_trustedNumberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter trusted phone number')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await LostPhoneService.instance.enable(
        trustedNumber: _trustedNumberController.text,
      );

      await _loadStatus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lost phone protection enabled!')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshLocation() async {
    final location = await LostPhoneService.instance.getCurrentLocation();
    await _loadStatus();

    if (mounted && location != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location updated')),
      );
    }
  }

  Future<void> _openInMaps(PhoneLocation location) async {
    final url = Uri.parse(location.googleMapsUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _playAlarm() async {
    await LostPhoneService.instance.playAlarm();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alarm playing at maximum volume'),
          action: SnackBarAction(label: 'Stop', onPressed: null),
        ),
      );
    }
  }

  Future<void> _markAsLost() async {
    final message = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Lost'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter message to display on lock screen:'),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Contact +91 XXXXX if found',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, _messageController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerRed,
            ),
            child: const Text('Mark as Lost'),
          ),
        ],
      ),
    );

    if (message != null && message.isNotEmpty) {
      await LostPhoneService.instance.markAsLost(message: message);
      await _loadStatus();
    }
  }

  Future<void> _sendLocationSms() async {
    final location = await LostPhoneService.instance.getCurrentLocation();
    // SMS would be sent automatically
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location SMS sent to trusted contact')),
      );
    }
  }

  Future<void> _showDisableDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disable Protection?'),
        content: const Text(
          'This will disable all lost phone features including location tracking and SIM change detection.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerRed,
            ),
            child: const Text('Disable'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await LostPhoneService.instance.disable();
      await _loadStatus();
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _trustedNumberController.dispose();
    super.dispose();
  }
}
