const express = require('express');
const cors = require('cors');
const rateLimit = require('express-rate-limit');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Rate limiting
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100 // limit each IP to 100 requests per windowMs
});
app.use('/api/', limiter);

// Import services
const { scanURL } = require('./services/urlScanner');
const { checkPhone } = require('./services/spamDetector');
const threatsData = require('./data/threats.json');

// Health check
app.get('/health', (req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// URL Scanner API
app.post('/scan-url', async (req, res) => {
    try {
        const { url } = req.body;

        if (!url) {
            return res.status(400).json({ error: 'URL is required' });
        }

        const result = await scanURL(url);
        res.json(result);
    } catch (error) {
        res.status(500).json({ error: 'Scan failed', message: error.message });
    }
});

// Phone Number Spam Checker API
app.post('/check-phone', (req, res) => {
    try {
        const { phone } = req.body;

        if (!phone) {
            return res.status(400).json({ error: 'Phone number is required' });
        }

        const result = checkPhone(phone);
        res.json(result);
    } catch (error) {
        res.status(500).json({ error: 'Check failed', message: error.message });
    }
});

// Get threat statistics
app.get('/threats', (req, res) => {
    res.json({
        totalThreats: threatsData.phishingDomains.length + threatsData.spamPatterns.length,
        phishingDomains: threatsData.phishingDomains.length,
        spamPatterns: threatsData.spamPatterns.length,
        scamKeywords: threatsData.scamKeywords.length,
        lastUpdated: threatsData.lastUpdated
    });
});

// Start server
app.listen(PORT, () => {
    console.log(`🛡️  QueShield API Server running on port ${PORT}`);
    console.log(`📊 Health check: http://localhost:${PORT}/health`);
});
