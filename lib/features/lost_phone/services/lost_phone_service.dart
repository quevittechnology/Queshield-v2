import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../../core/services/database_service.dart';
import '../../core/services/notification_service.dart';

class LostPhoneService {
  static final LostPhoneService instance = LostPhoneService._internal();
  factory LostPhoneService() => instance;
  LostPhoneService._internal();

  static const MethodChannel _channel = MethodChannel('com.queshield/lostphone');

  bool _isTrackingEnabled = false;
  String? _trustedPhoneNumber;
  String? _lastKnownSim;

  /// Initialize lost phone protection
  Future<void> initialize() async {
    _isTrackingEnabled = DatabaseService.instance.getSetting<bool>(
      'lost_phone_enabled',
      defaultValue: false,
    ) ?? false;

    _trustedPhoneNumber = DatabaseService.instance.getSetting<String>(
      'trusted_phone_number',
    );

    _lastKnownSim = await _getSimCardId();
    
    if (_isTrackingEnabled) {
      await _startMonitoring();
    }
  }

  /// Enable lost phone protection
  /// 
  /// [trustedNumber] must be a valid phone number
  /// Throws [ArgumentError] if number is invalid
  Future<void> enable({required String trustedNumber}) async {
    // Validate input
    if (trustedNumber.isEmpty) {
      throw ArgumentError('Trusted phone number cannot be empty');
    }
    
    // Basic phone number validation
    final cleanNumber = trustedNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanNumber.length < 10) {
      throw ArgumentError('Invalid phone number format');
    }
    
    _isTrackingEnabled = true;
    _trustedPhoneNumber = cleanNumber;
    
    await DatabaseService.instance.setSetting('lost_phone_enabled', true);
    await DatabaseService.instance.setSetting('trusted_phone_number', cleanNumber);
    
    _lastKnownSim = await _getSimCardId();
    if (_lastKnownSim != null) {
      await DatabaseService.instance.setSetting('last_known_sim', _lastKnownSim);
    }
    
    await _startMonitoring();
    
    await NotificationService.instance.showNotification(
      title: 'Lost Phone Protection Enabled',
      body: 'Your device is now protected with anti-theft features',
    );
  }

  /// Disable lost phone protection
  Future<void> disable() async {
    _isTrackingEnabled = false;
    await DatabaseService.instance.setSetting('lost_phone_enabled', false);
    await _stopMonitoring();
  }

  /// Get current location
  Future<PhoneLocation?> getCurrentLocation() async {
    try {
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        return null;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      final location = PhoneLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: DateTime.now(),
      );

      // Save last known location
      await _saveLastLocation(location);

      return location;
    } catch (e) {
      // Return last known location if available
      return _getLastKnownLocation();
    }
  }

  /// Mark phone as lost
  Future<void> markAsLost({
    required String message,
    bool enableAlarm = false,
  }) async {
    await DatabaseService.instance.setSetting('phone_is_lost', true);
    await DatabaseService.instance.setSetting('lost_phone_message', message);
    await DatabaseService.instance.setSetting('lost_phone_alarm', enableAlarm);

    if (enableAlarm) {
      await playAlarm();
    }

    // Show message on lock screen
    await _showLockScreenMessage(message);

    // Start location tracking
    await _startLocationTracking();

    // Send SMS to trusted contact
    if (_trustedPhoneNumber != null) {
      final location = await getCurrentLocation();
      await _sendLocationSms(_trustedPhoneNumber!, location);
    }
  }

  /// Mark phone as found
  Future<void> markAsFound() async {
    await DatabaseService.instance.setSetting('phone_is_lost', false);
    await stopAlarm();
    await _stopLocationTracking();
    await _clearLockScreenMessage();
  }

  /// Play loud alarm
  Future<void> playAlarm() async {
    try {
      await _channel.invokeMethod('playAlarm');
    } catch (e) {
      // Platform not implemented
    }
  }

  /// Stop alarm
  Future<void> stopAlarm() async {
    try {
      await _channel.invokeMethod('stopAlarm');
    } catch (e) {
      // Platform not implemented
    }
  }

  /// Remote lock device
  Future<void> remoteLock({String? message}) async {
    try {
      await _channel.invokeMethod('lockDevice', {
        'message': message ?? 'This device has been lost. Please contact owner.',
      });
    } catch (e) {
      // Platform not implemented
    }

    await DatabaseService.instance.setSetting('device_locked', true);
  }

  /// Set wipe confirmation code (hashed for security)
  Future<void> setWipeCode(String code) async {
    if (code.length < 6) {
      throw ArgumentError('Wipe code must be at least 6 characters');
    }
    
    // Hash the code with salt before storing
    final bytes = utf8.encode(code + 'QUESHIELD_WIPE_SALT_V1');
    final hashed = sha256.convert(bytes).toString();
    
    await DatabaseService.instance.setSetting('wipe_code_hash', hashed);
  }
  
  /// Verify wipe code
  bool _verifyWipeCode(String code) {
    final bytes = utf8.encode(code + 'QUESHIELD_WIPE_SALT_V1');
    final hashed = sha256.convert(bytes).toString();
    
    final savedHash = DatabaseService.instance.getSetting<String>('wipe_code_hash');
    return savedHash != null && hashed == savedHash;
  }

  /// Remote wipe device (requires user confirmation)
  /// 
  /// [confirmationCode] must match the previously set wipe code
  /// Returns true if wipe was initiated, false otherwise
  Future<bool> remoteWipe({required String confirmationCode}) async {
    // Security check - verify hashed code
    if (!_verifyWipeCode(confirmationCode)) {
      return false;
    }

    try {
      await _channel.invokeMethod('wipeDevice');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Capture photo of potential thief
  Future<void> captureThiefPhoto() async {
    try {
      // This would use front camera to capture photo
      await _channel.invokeMethod('captureThiefPhoto');
    } catch (e) {
      // Platform not implemented
    }
  }

  /// Check for SIM card change
  Future<bool> checkSimChange() async {
    final currentSim = await _getSimCardId();
    final savedSim = DatabaseService.instance.getSetting<String>('last_known_sim');

    if (savedSim != null && currentSim != savedSim && currentSim != null) {
      // SIM changed!
      await _handleSimChange(currentSim);
      return true;
    }

    return false;
  }

  /// Get device status
  Future<LostPhoneStatus> getStatus() async {
    final isLost = DatabaseService.instance.getSetting<bool>('phone_is_lost') ?? false;
    final isLocked = DatabaseService.instance.getSetting<bool>('device_locked') ?? false;
    final message = DatabaseService.instance.getSetting<String>('lost_phone_message');
    final location = await getCurrentLocation();
    final batteryLevel = await _getBatteryLevel();

    return LostPhoneStatus(
      isLost: isLost,
      isLocked: isLocked,
      message: message,
      location: location,
      batteryLevel: batteryLevel,
      lastUpdated: DateTime.now(),
      trackingEnabled: _isTrackingEnabled,
    );
  }

  Future<void> _startMonitoring() async {
    // Monitor SIM card changes
    // This would be implemented with native code
  }

  Future<void> _stopMonitoring() async {
    // Stop monitoring
  }

  Future<String?> _getSimCardId() async {
    try {
      return await _channel.invokeMethod('getSimCardId');
    } catch (e) {
      return null;
    }
  }

  Future<void> _handleSimChange(String newSim) async {
    await DatabaseService.instance.setSetting('last_known_sim', newSim);

    // Send alert to trusted contact
    if (_trustedPhoneNumber != null && _isTrackingEnabled) {
      await NotificationService.instance.showThreatNotification(
        title: '⚠️ SIM Card Changed!',
        body: 'Someone changed the SIM card in your device',
      );

      // Try to send SMS from new SIM to trusted number
      final location = await getCurrentLocation();
      await _sendSimChangeAlert(_trustedPhoneNumber!, newSim, location);
    }

    // Automatically mark as lost if SIM changed
    if (_isTrackingEnabled) {
      await markAsLost(
        message: 'This device was reported lost. SIM card changed detected.',
        enableAlarm: false,
      );
    }
  }

  Future<void> _saveLastLocation(PhoneLocation location) async {
    await DatabaseService.instance.setSetting('last_latitude', location.latitude);
    await DatabaseService.instance.setSetting('last_longitude', location.longitude);
    await DatabaseService.instance.setSetting('last_location_time', 
      location.timestamp.millisecondsSinceEpoch);
  }

  PhoneLocation? _getLastKnownLocation() {
    final lat = DatabaseService.instance.getSetting<double>('last_latitude');
    final lng = DatabaseService.instance.getSetting<double>('last_longitude');
    final time = DatabaseService.instance.getSetting<int>('last_location_time');

    if (lat != null && lng != null && time != null) {
      return PhoneLocation(
        latitude: lat,
        longitude: lng,
        accuracy: 0,
        timestamp: DateTime.fromMillisecondsSinceEpoch(time),
      );
    }

    return null;
  }

  Future<void> _sendLocationSms(String? phoneNumber, PhoneLocation? location) async {
    // Null safety checks
    if (phoneNumber == null || phoneNumber.isEmpty) {
      throw StateError('No trusted phone number configured');
    }
    
    if (location == null) {
      throw StateError('Location unavailable');
    }

    final message = '''
QueShield Alert: Your device location
Lat: ${location.latitude.toStringAsFixed(6)}
Lng: ${location.longitude.toStringAsFixed(6)}
Google Maps: https://maps.google.com/?q=${location.latitude},${location.longitude}
Time: ${location.timestamp.toLocal()}
''';

    try {
      await _channel.invokeMethod('sendSms', {
        'number': phoneNumber,
        'message': message,
      });
    } on PlatformException catch (e) {
      throw StateError('Failed to send SMS: ${e.message}');
    } catch (e) {
      throw StateError('Failed to send SMS: $e');
    }
  }

  Future<void> _sendSimChangeAlert(String phoneNumber, String newSim, PhoneLocation? location) async {
    final message = '''
⚠️ QueShield SIM Change Alert!
New SIM detected in your device.
New SIM ID: $newSim
${location != null ? 'Location: https://maps.google.com/?q=${location.latitude},${location.longitude}' : 'Location unavailable'}
''';

    try {
      await _channel.invokeMethod('sendSms', {
        'number': phoneNumber,
        'message': message,
      });
    } catch (e) {
      // SMS failed
    }
  }

  Future<void> _showLockScreenMessage(String message) async {
    try {
      await _channel.invokeMethod('showLockScreenMessage', {'message': message});
    } catch (e) {
      // Platform not implemented
    }
  }

  Future<void> _clearLockScreenMessage() async {
    try {
      await _channel.invokeMethod('clearLockScreenMessage');
    } catch (e) {
      // Platform not implemented
    }
  }

  Future<void> _startLocationTracking() async {
    // Start periodic location updates
    // Send to trusted contact every 30 minutes
  }

  Future<void> _stopLocationTracking() async {
    // Stop location updates
  }

  Future<int> _getBatteryLevel() async {
    try {
      final level = await _channel.invokeMethod('getBatteryLevel');
      return level ?? 100;
    } catch (e) {
      return 100;
    }
  }

  bool get isEnabled => _isTrackingEnabled;
  String? get trustedNumber => _trustedPhoneNumber;
}

class PhoneLocation {
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;

  PhoneLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
  });

  String get googleMapsUrl =>
      'https://maps.google.com/?q=$latitude,$longitude';
}

class LostPhoneStatus {
  final bool isLost;
  final bool isLocked;
  final String? message;
  final PhoneLocation? location;
  final int batteryLevel;
  final DateTime lastUpdated;
  final bool trackingEnabled;

  LostPhoneStatus({
    required this.isLost,
    required this.isLocked,
    this.message,
    this.location,
    required this.batteryLevel,
    required this.lastUpdated,
    required this.trackingEnabled,
  });
}
