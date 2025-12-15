// URL Security Scanner Service
// Ported from QueShield Flutter app

const SUSPICIOUS_TLDS = ['.tk', '.ml', '.ga', '.cf', '.gq', '.pw', '.top', '.work', '.click', '.loan'];
const LEGITIMATE_DOMAINS = ['google.com', 'facebook.com', 'amazon.com', 'apple.com', 'microsoft.com', 'netflix.com'];
const TYPOSQUAT_DOMAINS = {
    'google.com': ['goog1e.com', 'gooogle.com', 'googlle.com'],
    'facebook.com': ['faceb00k.com', 'facebok.com', 'faecbook.com'],
    'amazon.com': ['amaz0n.com', 'amazonn.com', 'arnazom.com']
};

function scanURL(url) {
    return new Promise((resolve) => {
        const result = {
            url: url,
            isPhishing: false,
            riskLevel: 'safe',
            confidence: 0,
            threats: [],
            timestamp: new Date().toISOString()
        };

        try {
            // Parse URL
            const urlObj = new URL(url);
            const domain = urlObj.hostname.toLowerCase();
            const protocol = urlObj.protocol;

            // Check 1: HTTPS
            if (protocol !== 'https:') {
                result.threats.push('Not using HTTPS - insecure connection');
                result.confidence += 15;
            }

            // Check 2: Suspicious TLD
            const hasSuspiciousTLD = SUSPICIOUS_TLDS.some(tld => domain.endsWith(tld));
            if (hasSuspiciousTLD) {
                result.threats.push('Suspicious top-level domain');
                result.confidence += 25;
            }

            // Check 3: Typosquatting
            let isTyposquat = false;
            for (const [legit, fakes] of Object.entries(TYPOSQUAT_DOMAINS)) {
                if (fakes.includes(domain)) {
                    result.threats.push(`Typosquatting attempt - impersonating ${legit}`);
                    result.confidence += 40;
                    isTyposquat = true;
                    break;
                }
            }

            // Check 4: Excessive length or special characters
            if (domain.length > 50) {
                result.threats.push('Unusually long domain name');
                result.confidence += 10;
            }

            if ((domain.match(/@/g) || []).length > 0) {
                result.threats.push('Contains @ symbol (potential credential phishing)');
                result.confidence += 30;
            }

            if ((domain.match(/-/g) || []).length > 3) {
                result.threats.push('Excessive hyphens in domain');
                result.confidence += 15;
            }

            // Check 5: IP address instead of domain
            if (/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/.test(domain)) {
                result.threats.push('Using IP address instead of domain name');
                result.confidence += 20;
            }

            // Determine risk level
            if (result.confidence >= 50) {
                result.isPhishing = true;
                result.riskLevel = 'dangerous';
            } else if (result.confidence >= 25) {
                result.riskLevel = 'suspicious';
            } else {
                result.riskLevel = 'safe';
            }

            // Check if it's a legitimate domain
            if (LEGITIMATE_DOMAINS.includes(domain)) {
                result.riskLevel = 'safe';
                result.threats = ['Verified legitimate website'];
                result.confidence = 0;
            }

        } catch (error) {
            result.threats.push('Invalid URL format');
            result.riskLevel = 'unknown';
        }

        resolve(result);
    });
}

module.exports = { scanURL };
