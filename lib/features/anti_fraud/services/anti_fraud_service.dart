import '../../core/services/notification_service.dart';
import '../../core/services/database_service.dart';

class AntiFraudService {
  static final AntiFraudService instance = AntiFraudService._internal();
  factory AntiFraudService() => instance;
  AntiFraudService._internal();

  /// Analyze call for scam indicators
  Future<ScamAnalysisResult> analyzeCall({
    required String number,
    String? callerId,
  }) async {
    final List<String> indicators = [];
    int riskScore = 0;

    // 1. Check for government impersonation keywords
    if (callerId != null) {
      final govCheck = _checkGovernmentImpersonation(callerId);
      indicators.addAll(govCheck.indicators);
      riskScore += govCheck.score;
    }

    // 2. Check number patterns
    final numberCheck = _checkSuspiciousNumberPattern(number);
    indicators.addAll(numberCheck.indicators);
    riskScore += numberCheck.score;

    // 3. Check call time
    final timeCheck = _checkCallTime();
    indicators.addAll(timeCheck.indicators);
    riskScore += timeCheck.score;

    final isScam = riskScore >= 60;

    if (isScam) {
      await NotificationService.instance.showThreatNotification(
        title: '⚠️ Potential Scam Call',
        body: 'Call from $number shows scam indicators',
      );
    }

    return ScamAnalysisResult(
      number: number,
      isScam: isScam,
      riskScore: riskScore,
      indicators: indicators,
      scamType: _determineScamType(indicators),
    );
  }

  /// Analyze SMS for fraud
  Future<SmsScamResult> analyzeSms({
    required String sender,
    required String message,
  }) async {
    final List<String> redFlags = [];
    int riskScore = 0;

    final lowerMessage = message.toLowerCase();

    // 1. Check for digital arrest keywords
    final digitalArrestKeywords = [
      'digital arrest',
      'cyber crime',
      'fir registered',
      'warrant issued',
      'court summons',
      'immediate action',
    ];

    for (final keyword in digitalArrestKeywords) {
      if (lowerMessage.contains(keyword)) {
        redFlags.add('Digital arrest scam keyword: "$keyword"');
        riskScore += 25;
      }
    }

    // 2. Check for urgency tactics
    final urgencyKeywords = [
      'urgent',
      'immediately',
      'within 24 hours',
      'act now',
      'last chance',
      'time sensitive',
    ];

    int urgencyCount = 0;
    for (final keyword in urgencyKeywords) {
      if (lowerMessage.contains(keyword)) {
        urgencyCount++;
      }
    }

    if (urgencyCount >= 2) {
      redFlags.add('Creates false urgency');
      riskScore += 20;
    }

    // 3. Check for payment demands
    if (lowerMessage.contains('pay') || lowerMessage.contains('fine') ||
        lowerMessage.contains('penalty')) {
      redFlags.add('Demands payment');
      riskScore += 30;
    }

    // 4. Check for fear tactics
    final fearKeywords = [
      'arrest',
      'legal action',
      'police',
      'court',
      'jail',
      'seized',
      'blocked',
      'suspended',
    ];

    int fearCount = 0;
    for (final keyword in fearKeywords) {
      if (lowerMessage.contains(keyword)) {
        fearCount++;
      }
    }

    if (fearCount >= 2) {
      redFlags.add('Uses fear tactics');
      riskScore += 25;
    }

    // 5. Check for credential requests
    final credentialKeywords = [
      'verify otp',
      'share otp',
      'confirm otp',
      'send password',
      'account number',
      'cvv',
      'pin',
      'aadhar',
      'pan card',
    ];

    for (final keyword in credentialKeywords) {
      if (lowerMessage.contains(keyword)) {
        redFlags.add('Requests sensitive information');
        riskScore += 35;
        break;
      }
    }

    // 6. Check for suspicious links
    if (lowerMessage.contains('http') || lowerMessage.contains('www.')) {
      redFlags.add('Contains suspicious link');
      riskScore += 15;
    }

    final isScam = riskScore >= 50;

    if (isScam) {
      await NotificationService.instance.showThreatNotification(
        title: '🚨 Scam SMS Detected',
        body: 'Message from $sender appears fraudulent',
      );
    }

    return SmsScamResult(
      sender: sender,
      message: message,
      isScam: isScam,
      riskScore: riskScore,
      redFlags: redFlags,
      scamType: _determineSmsScamType(redFlags, lowerMessage),
    );
  }

  _ScamCheck _checkGovernmentImpersonation(String callerId) {
    final indicators = <String>[];
    int score = 0;

    final lowerCallerId = callerId.toLowerCase();

    final govKeywords = [
      'police',
      'cbi',
      'income tax',
      'customs',
      'cyber cell',
      'crime branch',
      'officer',
      'inspector',
    ];

    for (final keyword in govKeywords) {
      if (lowerCallerId.contains(keyword)) {
        indicators.add('Claims to be from: $keyword');
        score += 40;
        break;
      }
    }

    return _ScamCheck(indicators: indicators, score: score);
  }

  _ScamCheck _checkSuspiciousNumberPattern(String number) {
    final indicators = <String>[];
    int score = 0;

    // Remove country code
    String normalized = number.replaceAll(RegExp(r'^\+91'), '');

    // Check for VoIP numbers (often used by scammers)
    if (normalized.startsWith('080') || normalized.startsWith('020')) {
      indicators.add('Number appears to be VoIP/landline');
      score += 20;
    }

    // Check for international numbers
    if (number.startsWith('+') && !number.startsWith('+91')) {
      indicators.add('International number');
      score += 25;
    }

    // Check for hidden/private numbers
    if (number == 'Unknown' || number == 'Private' || number.isEmpty) {
      indicators.add('Caller ID hidden');
      score += 30;
    }

    return _ScamCheck(indicators: indicators, score: score);
  }

  _ScamCheck _checkCallTime() {
    final indicators = <String>[];
    int score = 0;

    final now = DateTime.now();
    final hour = now.hour;

    // Scammers often call during off-hours
    if (hour < 8 || hour > 21) {
      indicators.add('Calling during unusual hours');
      score += 15;
    }

    return _ScamCheck(indicators: indicators, score: score);
  }

  String _determineScamType(List<String> indicators) {
    final allIndicators = indicators.join(' ').toLowerCase();

    if (allIndicators.contains('cbi') || allIndicators.contains('police')) {
      return 'Government Impersonation';
    }
    if (allIndicators.contains('voip')) {
      return 'VoIP Scam Call';
    }
    if (allIndicators.contains('international')) {
      return 'International Scam';
    }
    return 'Unknown Scam';
  }

  String _determineSmsScamType(List<String> redFlags, String message) {
    final allFlags = redFlags.join(' ').toLowerCase();

    if (allFlags.contains('digital arrest')) {
      return 'Digital Arrest Scam';
    }
    if (allFlags.contains('verify otp') || allFlags.contains('sensitive')) {
      return 'OTP/Credential Theft';
    }
    if (allFlags.contains('payment')) {
      return 'Payment Fraud';
    }
    if (message.contains('prize') || message.contains('won')) {
      return 'Lottery/Prize Scam';
    }
    if (message.contains('kyc') || message.contains('update')) {
      return 'KYC Update Scam';
    }
    return 'Generic Phishing';
  }

  /// Get fraud awareness tips
  List<FraudTip> getFraudAwarenessTips() {
    return [
      FraudTip(
        title: 'Digital Arrest Scam',
        description: 'Scammers impersonate police/CBI and threaten "digital arrest" to extort money.',
        redFlags: [
          'Claims to be from CBI, Police, Customs',
          'Threatens arrest or legal action',
          'Demands immediate payment',
          'Uses video calls to intimidate',
        ],
        whatToDo: [
          'Hang up immediately',
          'Government agencies don\'t call for arrests',
          'Report to cybercrime.gov.in',
          'Never share OTP or bank details',
        ],
      ),
      FraudTip(
        title: 'Fake IT/Tax Notice Scam',
        description: 'Scammers send fake income tax notices demanding payment.',
        redFlags: [
          'SMS/email about tax refund or penalty',
          'Asks to click suspicious links',
          'Requests bank account details',
          'Creates urgency (24-hour deadline)',
        ],
        whatToDo: [
          'Verify from official IT website',
          'Don\'t click unknown links',
          'IT dept uses registered email/post',
          'Call official helpline if worried',
        ],
      ),
      FraudTip(
        title: 'OTP Scam',
        description: 'Scammers trick you into sharing OTP to steal money.',
        redFlags: [
          'Calls claiming "wrong OTP sent"',
          'Asks you to share OTP received',
          'Pretends to be bank/delivery agent',
          'Says "just read the OTP"',
        ],
        whatToDo: [
          'NEVER share OTP with anyone',
          'Banks never ask for OTP',
          'OTP is for YOUR use only',
          'Report suspicious calls',
        ],
      ),
      FraudTip(
        title: 'Fake Parcel/Courier Scam',
        description: 'Scammers claim illegal parcel in your name and demand payment.',
        redFlags: [
          '"Parcel held at customs"',
          'Contains drugs/illegal items',
          'Threatens police action',
          'Demands payment to release',
        ],
        whatToDo: [
          'Courier companies use email/SMS',
          'Don\'t pay unknown callers',
          'Verify with courier company directly',
          'Report to police if threatened',
        ],
      ),
      FraudTip(
        title: 'Lottery/Prize Scam',
        description: 'Fake lottery wins asking for fee to claim prize.',
        redFlags: [
          '"You won a lottery you never entered"',
          'Asks for processing fee',
          'Requests bank details',
          'Too good to be true',
        ],
        whatToDo: [
          'You can\'t win what you didn\'t enter',
          'Real lotteries don\'t ask for fees',
          'Block and report number',
          'Never share bank details',
        ],
      ),
    ];
  }
}

class _ScamCheck {
  final List<String> indicators;
  final int score;

  _ScamCheck({required this.indicators, required this.score});
}

class ScamAnalysisResult {
  final String number;
  final bool isScam;
  final int riskScore;
  final List<String> indicators;
  final String scamType;

  ScamAnalysisResult({
    required this.number,
    required this.isScam,
    required this.riskScore,
    required this.indicators,
    required this.scamType,
  });
}

class SmsScamResult {
  final String sender;
  final String message;
  final bool isScam;
  final int riskScore;
  final List<String> redFlags;
  final String scamType;

  SmsScamResult({
    required this.sender,
    required this.message,
    required this.isScam,
    required this.riskScore,
    required this.redFlags,
    required this.scamType,
  });
}

class FraudTip {
  final String title;
  final String description;
  final List<String> redFlags;
  final List<String> whatToDo;

  FraudTip({
    required this.title,
    required this.description,
    required this.redFlags,
    required this.whatToDo,
  });
}
