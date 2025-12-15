// Phone Number Spam Detector Service
// Ported from QueShield Flutter app

const SPAM_PATTERNS = [
    { pattern: /^140\d{7}$/, name: 'Telemarketing (140xxxxxx)' },
    { pattern: /^1800\d{6,7}$/, name: 'Toll-free number' },
    { pattern: /^(\d)\1{9}$/, name: 'Repeated digits' },
    { pattern: /^(0123456789|1234567890)$/, name: 'Sequential digits' }
];

const KNOWN_SPAM_PREFIXES = ['140', '1800', '0000', '1111', '9999'];

function checkPhone(phone) {
    const result = {
        phone: phone,
        isSpam: false,
        confidence: 0,
        reasons: [],
        recommendation: 'safe',
        timestamp: new Date().toISOString()
    };

    // Clean phone number
    const cleanPhone = phone.replace(/[\s\-\(\)]/g, '');

    // Check 1: Pattern matching
    for (const { pattern, name } of SPAM_PATTERNS) {
        if (pattern.test(cleanPhone)) {
            result.reasons.push(`Matches ${name} pattern`);
            result.confidence += 30;
        }
    }

    // Check 2: Known spam prefixes
    for (const prefix of KNOWN_SPAM_PREFIXES) {
        if (cleanPhone.startsWith(prefix)) {
            result.reasons.push(`Starts with known spam prefix: ${prefix}`);
            result.confidence += 25;
            break;
        }
    }

    // Check 3: Repeated digit detection
    const digitCounts = {};
    for (const digit of cleanPhone) {
        digitCounts[digit] = (digitCounts[digit] || 0) + 1;
    }
    const maxRepeated = Math.max(...Object.values(digitCounts));
    if (maxRepeated >= 7) {
        result.reasons.push(`Excessive repeated digits (${maxRepeated} times)`);
        result.confidence += 20;
    }

    // Check 4: Sequential digits
    let sequentialCount = 1;
    for (let i = 1; i < cleanPhone.length; i++) {
        if (parseInt(cleanPhone[i]) === parseInt(cleanPhone[i - 1]) + 1) {
            sequentialCount++;
        }
    }
    if (sequentialCount >= 5) {
        result.reasons.push('Contains long sequential digit pattern');
        result.confidence += 15;
    }

    // Check 5: Length check
    if (cleanPhone.length < 10 || cleanPhone.length > 12) {
        result.reasons.push('Unusual phone number length');
        result.confidence += 10;
    }

    // Determine recommendation
    if (result.confidence >= 50) {
        result.isSpam = true;
        result.recommendation = 'block';
    } else if (result.confidence >= 30) {
        result.isSpam = true;
        result.recommendation = 'caution';
    } else {
        result.recommendation = 'safe';
    }

    if (result.reasons.length === 0) {
        result.reasons.push('No spam indicators detected');
    }

    return result;
}

module.exports = { checkPhone };
