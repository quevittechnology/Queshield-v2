# QueShield Manual Deployment Guide
# Use this if automated deployment isn't working

## Step 1: Setup SSH Key Authentication (One-time)

SSH into your VPS with password:
```
ssh root@145.223.19.208
```

Then run these commands on the VPS:
```bash
mkdir -p ~/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDZDnsWkgYMTJL6Y/fjffJHpnS9ki8ZsE6uO7T4QqdRfRWMMJtaUnvwWccbF8AIqlCVSivv3QZFJmYGwSo7KSFS84YmbWnqKhw0i/5chwjmUQ/miG7kKgRmZeRozIKVfP2QJZOkuxJ/iGZacKLyL3Ayow1pXDIKyY6R6JDA/Hrd12rpbIYOG5yQeIhYkBfhmWhxTgDpwUs32NYQBjyoMSb3UF8KpzvdxEcdhWPA1ii6vHuzfu9XQlpqMEn26vn9D575Lc/At0W/6yLv0US0Fk2v71cCRcFiNGMQ9U9DLPP3bER5mSv1WcNap3Y8OJhsC6Cq5ArLWLmexRpQ8FqhB6saqvXHwtwRGCY+aqOoD9WKdFeqnTYzR/B2Ubf6OpNNdck+8CR7JLXdRJ4ewYFw/zTpwCCU17Egdfbg0Z2RpV+LwtfQjqCvdlbeRzx+klVBnMiOqFCXkSXruxXjVo8lEd+3EQNrVaXLzGVvFp8DvgOxxAdhaoZB2U27ryp2fXNDnQGkStkqsDAx6QPKwFHyVD8ETjUIE9v5i4LLEU7REjIeu5fFkk1xA2++4VotEoZzEUELggASy+/RjYIafUcI1R8L+eMIZ9AE+Y8fdOZPqR82A4LqL055OOY58JJc+na5HFL3ERsLRbE/AYLBl6KcuFLvQLdPdgALmFUvuN1fznhzrw== user@vipechan" >> ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
exit
```

Test that SSH key works (should not ask for password):
```
ssh root@145.223.19.208
```

---

## Step 2: Upload Deployment Package

From your local machine (Windows PowerShell):
```powershell
cd f:\QUESHIELD
scp -r vps-deployment root@145.223.19.208:/root/queshield
```

This should now work without password!

---

## Step 3: Deploy on VPS

SSH into VPS:
```
ssh root@145.223.19.208
```

Run deployment script:
```bash
cd /root/queshield
chmod +x deploy.sh
./deploy.sh
```

The script will:
- Install Node.js, Nginx, PM2
- Deploy backend API
- Deploy web dashboard
- Configure everything automatically

---

## Step 4: Verify Deployment

Check if services are running:
```bash
pm2 status
systemctl status nginx
```

Test the website:
```bash
curl http://localhost
curl http://localhost/api/health
```

Get your public IP:
```bash
curl ifconfig.me
```

Open in browser: http://YOUR_VPS_IP

---

## Quick Commands

**View logs:**
```bash
pm2 logs queshield-api
tail -f /var/log/nginx/error.log
```

**Restart services:**
```bash
pm2 restart queshield-api
systemctl restart nginx
```

**Stop services:**
```bash
pm2 stop queshield-api
systemctl stop nginx
```

---

## Alternative: Use File Transfer Tool

If command-line upload doesn't work, use WinSCP or FileZilla:

1. Download WinSCP: https://winscp.net/
2. Connect to: 145.223.19.208
3. User: root
4. Upload `f:\QUESHIELD\vps-deployment\` to `/root/queshield`
5. Then follow Step 3 above

---

**You're ready to deploy! 🚀**
