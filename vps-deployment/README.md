# QueShield VPS Deployment Package

## 📦 Contents

This package contains everything needed to deploy QueShield security platform to your VPS.

### Included Components:

1. **Backend API Server** (Node.js + Express)
   - URL security scanner
   - Phone spam detector
   - Threat database API
   
2. **Web Security Dashboard** (HTML/CSS/JS)
   - URL checker tool
   - Phone checker tool
   - Scam education center
   - Download page

3. **Deployment Scripts**
   - Automated setup script
   - Nginx configuration

---

## 🚀 Quick Deployment

### Method 1: Automated (Recommended)

1. **Upload this entire folder** to your VPS:
   ```bash
   scp -r vps-deployment root@145.223.19.208:/root/queshield
   ```

2. **SSH into your VPS**:
   ```bash
   ssh root@145.223.19.208
   ```

3. **Run deployment script**:
   ```bash
   cd /root/queshield
   chmod +x deploy.sh
   ./deploy.sh
   ```

4.  **Access your deployment**:
   - Web Dashboard: http://145.223.19.208
   - API: http://145.223.19.208/api

---

### Method 2: Manual Setup

If automated script fails, follow these manual steps:

#### Step 1: Install Dependencies
```bash
# Update system
apt-get update && apt-get upgrade -y

# Install Node.js 20.x
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# Install Nginx
apt-get install -y nginx

# Install PM2
npm install -g pm2
```

#### Step 2: Deploy Backend
```bash
mkdir -p /var/www/queshield
cp -r backend /var/www/queshield/
cd /var/www/queshield/backend
npm install --production

# Start with PM2
pm2 start server.js --name queshield-api
pm2 save
pm2 startup systemd
```

#### Step 3: Deploy Web Frontend
```bash
cp -r web /var/www/queshield/
chown -R www-data:www-data /var/www/queshield/web
```

#### Step 4: Configure Nginx
```bash
# Copy the nginx.conf content from deploy.sh into:
nano /etc/nginx/sites-available/queshield

# Enable site
ln -sf /etc/nginx/sites-available/queshield /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test and reload
nginx -t
systemctl reload nginx
```

#### Step 5: Configure Firewall
```bash
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw enable
```

---

## 📊 Verify Deployment

Check if services are running:
```bash
# Check backend
pm2 status
curl http://localhost:3000/health

# Check Nginx
systemctl status nginx

# Test API
curl http://localhost/api/health
```

---

## 🔧 Management Commands

```bash
# View backend logs
pm2 logs queshield-api

# Restart backend
pm2 restart queshield-api

# Stop backend
pm2 stop queshield-api

# Restart Nginx
systemctl restart nginx

# View Nginx logs
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log
```

---

## 🌐 API Endpoints

### Health Check
```bash
GET /api/health
```

### URL Scanner
```bash
POST /api/scan-url
Content-Type: application/json

{
  "url": "https://example.com"
}
```

### Phone Spam Checker
```bash
POST /api/check-phone
Content-Type: application/json

{
  "phone": "1401234567"
}
```

### Threat Statistics
```bash
GET /api/threats
```

---

## 🔒 Security Recommendations

1. **Set up SSL/TLS**:
   ```bash
   apt-get install certbot python3-certbot-nginx
   certbot --nginx -d yourdomain.com
   ```

2. **Configure domain** (optional):
   - Point your domain A record to: 145.223.19.208
   - Update nginx config with your domain name

3. **Enable automatic updates**:
   ```bash
   apt-get install unattended-upgrades
   dpkg-reconfigure --priority=low unattended-upgrades
   ```

4. **Set up monitoring**:
   ```bash
   pm2 install pm2-logrotate
   ```

---

## 📱 Adding APK Files (When Available)

When QueShield APK is built:

1. Upload APK to VPS:
   ```bash
   scp app-release.apk root@145.223.19.208:/var/www/queshield/web/download/
   ```

2. Update download page to include download link

3. Set permissions:
   ```bash
   chmod 644 /var/www/queshield/web/download/*.apk
   ```

---

## 🐛 Troubleshooting

### Backend not starting
```bash
cd /var/www/queshield/backend
npm install
pm2 restart queshield-api
pm2 logs queshield-api
```

### Nginx 502 Bad Gateway
```bash
# Check if  backend is running
pm2 status

# Check Nginx error logs
tail -f /var/log/nginx/error.log
```

### Cannot access website
```bash
# Check firewall
ufw status

# Check Nginx status
systemctl status nginx
```

---

## 📞 Support

For issues or questions:
- Check logs: `pm2 logs queshield-api`
- Review Nginx logs: `/var/log/nginx/error.log`
- Verify firewall: `ufw status`

---

## 📝 File Structure

```
/var/www/queshield/
├── backend/
│   ├── server.js
│   ├── package.json
│   ├── services/
│   │   ├── urlScanner.js
│   │   └── spamDetector.js
│   └── data/
│       └── threats.json
└── web/
    ├── index.html
    ├── url-checker.html
    ├── phone-checker.html
    ├── scam-education.html
    ├── download.html
    ├── css/
    │   └── style.css
    ├── js/
    │   └── app.js
    └── download/
        └── (APK files when available)
```

---

**QueShield VPS Deployment - Ready to Protect** 🛡️
