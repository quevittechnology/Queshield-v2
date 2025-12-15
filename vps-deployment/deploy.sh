#!/bin/bash

# QueShield VPS Deployment Script
# Run this script on your VPS as root

set -e

echo "🛡️  QueShield VPS Deployment Starting..."
echo ""

# Update system
echo "📦 Updating system packages..."
apt-get update -qq
apt-get upgrade -y -qq

# Install Node.js 20.x
echo "📦 Installing Node.js 20.x..."
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt-get install -y nodejs
fi
node -v
npm -v

# Install Nginx
echo "📦 Installing Nginx..."
if ! command -v nginx &> /dev/null; then
    apt-get install -y nginx
fi
nginx -v

# Install PM2 globally
echo "📦 Installing PM2 process manager..."
npm install -g pm2

# Configure firewall
echo "🔒 Configuring firewall..."
if command -v ufw &> /dev/null; then
    ufw allow 22/tcp
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw --force enable
fi

# Create application directory
echo "📁 Creating application directory..."
mkdir -p /var/www/queshield
cd /var/www/queshield

# Copy files (assumes script is run from deployment directory)
echo "📋 Copying application files..."
cp -r ./backend /var/www/queshield/
cp -r ./web /var/www/queshield/

# Install backend dependencies
echo "📦 Installing backend dependencies..."
cd /var/www/queshield/backend
npm install --production

# Configure Nginx
echo "⚙️  Configuring Nginx..."
cat > /etc/nginx/sites-available/queshield << 'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    
    server_name _;
    
    # Web Dashboard (root)
    location / {
        root /var/www/queshield/web;
        index index.html;
        try_files $uri $uri/ /index.html;
    }
    
    # Backend API
    location /api/ {
        proxy_pass http://localhost:3000/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_cache_bypass $http_upgrade;
    }
    
    # APK Downloads 
    location /download/ {
        alias /var/www/queshield/web/download/;
        autoindex on;
        add_header Content-Disposition 'attachment';
    }
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
}
EOF

# Enable site
ln -sf /etc/nginx/sites-available/queshield /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
nginx -t

# Reload Nginx
systemctl reload nginx
systemctl enable nginx

# Start backend with PM2
echo "🚀 Starting backend server..."
cd /var/www/queshield/backend
pm2 delete queshield-api 2>/dev/null || true
pm2 start server.js --name queshield-api
pm2 save
pm2 startup systemd -u root --hp /root

# Set permissions
echo "🔐 Setting permissions..."
chown -R www-data:www-data /var/www/queshield/web
chmod -R 755 /var/www/queshield/web

echo ""
echo "✅ QueShield deployment complete!"
echo ""
echo "📊 Service Status:"
pm2 status
echo ""
systemctl status nginx --no-pager
echo ""
echo "🌐 Access your deployment:"
echo "   Web Dashboard: http://$(curl -s ifconfig.me)"
echo "   API Endpoint:  http://$(curl -s ifconfig.me)/api"
echo ""
echo "📝 Management Commands:"
echo "   View logs:     pm2 logs queshield-api"
echo "   Restart API:   pm2 restart queshield-api"
echo "   Stop API:      pm2 stop queshield-api"
echo ""
