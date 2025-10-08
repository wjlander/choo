# Deployment Guide - Membership Management System v2.0

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Automated Deployment](#automated-deployment)
4. [Manual Deployment](#manual-deployment)
5. [Post-Deployment Configuration](#post-deployment-configuration)
6. [SSL Configuration](#ssl-configuration)
7. [Database Setup](#database-setup)
8. [Troubleshooting](#troubleshooting)
9. [Maintenance](#maintenance)

---

## Overview

This guide covers deploying the Membership Management System v2.0 to Ubuntu/Debian servers without Docker. The system uses:

- **Node.js** for the application runtime
- **PM2** for process management
- **Nginx** as reverse proxy
- **Certbot** for SSL certificates
- **Supabase** for database and authentication

### Deployment Architecture

```
Internet
    ↓
Nginx (Port 80/443)
    ↓
Node.js Application (Port 5173)
    ↓
Supabase (PostgreSQL + Auth + Storage)
```

---

## Prerequisites

### Server Requirements

**Minimum Specifications:**
- Ubuntu 20.04+ or Debian 11+
- 2 CPU cores
- 2GB RAM
- 20GB disk space
- Root or sudo access

**Recommended Specifications:**
- Ubuntu 22.04 LTS
- 4 CPU cores
- 4GB RAM
- 50GB SSD
- Dedicated server or VPS

### Domain Requirements

- Domain name (e.g., member.example.com)
- DNS access to configure A and TXT records
- Email address for SSL certificates

### External Services

1. **Supabase Account**
   - Create project at https://supabase.com
   - Note your project URL and anon key
   - Configure authentication settings

2. **Resend Account** (for emails)
   - Sign up at https://resend.com
   - Get API key
   - Verify sender domain

3. **Stripe Account** (optional, for payments)
   - Sign up at https://stripe.com
   - Get API keys (test and live)

---

## Automated Deployment

### Step 1: Prepare Server

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install git
sudo apt install -y git

# Clone repository
git clone https://github.com/wjlander/newmembership.git
cd newmembership/membership-rebuild
```

### Step 2: Run Deployment Script

```bash
# Make script executable
chmod +x deploy.sh

# Run deployment
sudo ./deploy.sh
```

### Step 3: Follow Prompts

The script will ask for:
1. **Domain name**: e.g., member.example.com
2. **Email address**: For SSL certificates
3. **Application port**: Default 5173 (press Enter)

### Step 4: Configure Environment

```bash
# Edit environment file
sudo nano /var/www/membership-system/.env
```

Add your credentials:
```env
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
RESEND_API_KEY=your-resend-key
```

### Step 5: Restart Application

```bash
sudo -u membership pm2 restart membership-system
```

### Step 6: Verify Deployment

```bash
# Check application status
sudo -u membership pm2 status

# Check logs
sudo -u membership pm2 logs membership-system --lines 50

# Test health endpoint
curl https://your-domain.com/health
```

---

## Manual Deployment

### Step 1: System Preparation

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y curl wget git build-essential
```

### Step 2: Install Node.js

```bash
# Add NodeSource repository
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -

# Install Node.js
sudo apt install -y nodejs

# Verify installation
node -v  # Should show v18.x.x
npm -v   # Should show 9.x.x or higher
```

### Step 3: Install PM2

```bash
# Install PM2 globally
sudo npm install -g pm2

# Verify installation
pm2 -v
```

### Step 4: Install Nginx

```bash
# Install Nginx
sudo apt install -y nginx

# Enable and start Nginx
sudo systemctl enable nginx
sudo systemctl start nginx

# Verify installation
sudo systemctl status nginx
```

### Step 5: Install Certbot

```bash
# Install Certbot
sudo apt install -y certbot python3-certbot-nginx

# Verify installation
certbot --version
```

### Step 6: Create Application User

```bash
# Create user
sudo useradd -r -s /bin/bash -d /home/membership -m membership

# Verify user
id membership
```

### Step 7: Create Directories

```bash
# Create application directory
sudo mkdir -p /var/www/membership-system

# Create backup directory
sudo mkdir -p /var/backups/membership-system

# Create logs directory
sudo mkdir -p /var/log/membership-system

# Set ownership
sudo chown -R membership:membership /var/www/membership-system
sudo chown -R membership:membership /var/backups/membership-system
sudo chown -R membership:membership /var/log/membership-system
```

### Step 8: Deploy Application Files

```bash
# Clone repository
cd /tmp
git clone https://github.com/wjlander/newmembership.git

# Copy files
sudo cp -r /tmp/newmembership/membership-rebuild/* /var/www/membership-system/

# Set ownership
sudo chown -R membership:membership /var/www/membership-system

# Clean up
rm -rf /tmp/newmembership
```

### Step 9: Configure Environment

```bash
# Copy environment template
sudo cp /var/www/membership-system/.env.example /var/www/membership-system/.env

# Edit environment file
sudo nano /var/www/membership-system/.env
```

Add your configuration:
```env
# Supabase
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key

# Resend
RESEND_API_KEY=your-resend-key

# Stripe (optional)
STRIPE_PUBLIC_KEY=your-stripe-public-key
STRIPE_SECRET_KEY=your-stripe-secret-key

# Application
NODE_ENV=production
PORT=5173
```

Set permissions:
```bash
sudo chown membership:membership /var/www/membership-system/.env
sudo chmod 600 /var/www/membership-system/.env
```

### Step 10: Install Dependencies

```bash
cd /var/www/membership-system
sudo -u membership npm ci --production
```

### Step 11: Build Application

```bash
cd /var/www/membership-system
sudo -u membership npm run build
```

### Step 12: Create Production Server

```bash
sudo nano /var/www/membership-system/server.js
```

Add:
```javascript
import express from 'express';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const app = express();
const PORT = process.env.PORT || 5173;

app.use(express.static(join(__dirname, 'dist')));

app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

app.get('*', (req, res) => {
  res.sendFile(join(__dirname, 'dist', 'index.html'));
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
```

### Step 13: Create PM2 Configuration

```bash
sudo nano /var/www/membership-system/ecosystem.config.cjs
```

Add:
```javascript
module.exports = {
  apps: [{
    name: 'membership-system',
    script: './server.js',
    instances: 'max',
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: 5173
    },
    error_file: '/var/log/membership-system/error.log',
    out_file: '/var/log/membership-system/out.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    merge_logs: true,
    autorestart: true,
    max_restarts: 10,
    min_uptime: '10s',
    max_memory_restart: '500M'
  }]
};
```

### Step 14: Start Application

```bash
cd /var/www/membership-system

# Start with PM2
sudo -u membership pm2 start ecosystem.config.cjs

# Save PM2 configuration
sudo -u membership pm2 save

# Setup PM2 startup script
sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u membership --hp /home/membership
```

### Step 15: Configure Nginx

```bash
sudo nano /etc/nginx/sites-available/membership-system
```

Add:
```nginx
# HTTP - Redirect to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name your-domain.com *.your-domain.com;
    
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    location / {
        return 301 https://$host$request_uri;
    }
}

# HTTPS
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name your-domain.com *.your-domain.com;
    
    # SSL Configuration (will be updated by Certbot)
    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/json application/javascript;
    
    # Proxy to Node.js
    location / {
        proxy_pass http://localhost:5173;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
    
    # Health check
    location /health {
        proxy_pass http://localhost:5173/health;
        access_log off;
    }
}
```

Enable site:
```bash
# Create symlink
sudo ln -s /etc/nginx/sites-available/membership-system /etc/nginx/sites-enabled/

# Remove default site
sudo rm /etc/nginx/sites-enabled/default

# Test configuration
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx
```

### Step 16: Obtain SSL Certificate

```bash
# Create directory for ACME challenge
sudo mkdir -p /var/www/certbot

# Obtain certificate
sudo certbot --nginx -d your-domain.com -d "*.your-domain.com" \
    --non-interactive \
    --agree-tos \
    --email your-email@example.com \
    --redirect

# Setup auto-renewal
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer
```

### Step 17: Configure Firewall

```bash
# Allow SSH
sudo ufw allow 22/tcp

# Allow HTTP
sudo ufw allow 80/tcp

# Allow HTTPS
sudo ufw allow 443/tcp

# Enable firewall
sudo ufw --force enable

# Check status
sudo ufw status
```

---

## Post-Deployment Configuration

### 1. Database Setup

Run migrations in Supabase SQL Editor:

```sql
-- Run in order:
-- 1. Core schema
-- 2. Email & subscribers
-- 3. Custom domains
-- 4. Events table
-- 5. Mailing lists
-- 6. Events & committees
-- 7. Phase 3 advanced features
-- 8. Phase 1 quick wins
-- 9. New features phase 1
-- 10. New features phase 2
-- 11. New features phase 3
```

### 2. Create Super Admin

```sql
-- In Supabase SQL Editor
INSERT INTO profiles (user_id, organization_id, email, first_name, last_name, role)
VALUES (
    'your-user-id',  -- Get from Supabase Auth
    'admin-org-id',  -- Create admin organization first
    'admin@example.com',
    'Super',
    'Admin',
    'super_admin'
);
```

### 3. Create First Organization

Access: `https://your-domain.com?org=admin`

1. Login as super admin
2. Navigate to Organizations
3. Click "Create Organization"
4. Fill in details
5. Save

### 4. Configure Email Settings

In Resend dashboard:
1. Verify sender domain
2. Add DNS records (SPF, DKIM)
3. Test email delivery

### 5. Test All Features

- [ ] User registration
- [ ] Email delivery
- [ ] Event creation
- [ ] Document upload
- [ ] Payment processing (if enabled)
- [ ] QR code generation
- [ ] 2FA setup

---

## SSL Configuration

### Wildcard SSL Certificate

For subdomain support:

```bash
# Install DNS plugin (example for Cloudflare)
sudo apt install python3-certbot-dns-cloudflare

# Create credentials file
sudo nano /root/.secrets/cloudflare.ini
```

Add:
```ini
dns_cloudflare_api_token = your-api-token
```

Obtain certificate:
```bash
sudo certbot certonly \
    --dns-cloudflare \
    --dns-cloudflare-credentials /root/.secrets/cloudflare.ini \
    -d your-domain.com \
    -d "*.your-domain.com"
```

### SSL Renewal

Automatic renewal is configured via systemd timer:

```bash
# Check renewal timer
sudo systemctl status certbot.timer

# Test renewal
sudo certbot renew --dry-run

# Force renewal
sudo certbot renew --force-renewal
```

---

## Database Setup

### Supabase Configuration

1. **Create Project**
   - Go to https://supabase.com
   - Create new project
   - Note project URL and keys

2. **Configure Authentication**
   ```
   Settings → Authentication:
   - Enable Email provider
   - Configure email templates
   - Set site URL
   - Add redirect URLs
   ```

3. **Run Migrations**
   - Go to SQL Editor
   - Run each migration file in order
   - Verify tables created

4. **Configure Storage**
   ```
   Storage → Create buckets:
   - documents (public)
   - logos (public)
   - avatars (public)
   ```

5. **Set Up RLS Policies**
   - Verify RLS enabled on all tables
   - Test policies with different roles

---

## Troubleshooting

### Application Won't Start

```bash
# Check PM2 status
sudo -u membership pm2 status

# View logs
sudo -u membership pm2 logs membership-system

# Check for errors
sudo -u membership pm2 logs membership-system --err

# Restart application
sudo -u membership pm2 restart membership-system
```

### SSL Certificate Issues

```bash
# Check certificate
sudo certbot certificates

# Test renewal
sudo certbot renew --dry-run

# Check Nginx configuration
sudo nginx -t

# View Nginx error log
sudo tail -f /var/log/nginx/error.log
```

### Database Connection Issues

```bash
# Test connection
curl https://your-project.supabase.co/rest/v1/

# Check environment variables
sudo -u membership cat /var/www/membership-system/.env | grep SUPABASE

# Verify Supabase project status
# Check Supabase dashboard
```

### Port Already in Use

```bash
# Find process using port 5173
sudo lsof -i :5173

# Kill process
sudo kill -9 <PID>

# Or change port in .env
sudo nano /var/www/membership-system/.env
# Change PORT=5173 to PORT=5174
```

---

## Maintenance

### Regular Updates

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Update Node.js packages
cd /var/www/membership-system
sudo -u membership npm update

# Rebuild application
sudo -u membership npm run build

# Restart application
sudo -u membership pm2 restart membership-system
```

### Backup Procedures

```bash
# Create backup
sudo tar -czf /var/backups/membership-system/backup_$(date +%Y%m%d_%H%M%S).tar.gz \
    --exclude=node_modules \
    --exclude=dist \
    -C /var/www membership-system

# Backup database (from Supabase dashboard)
# Settings → Database → Backups

# List backups
ls -lh /var/backups/membership-system/
```

### Monitoring

```bash
# View application logs
sudo -u membership pm2 logs membership-system

# Monitor resources
sudo -u membership pm2 monit

# Check disk space
df -h

# Check memory usage
free -h

# Check CPU usage
top
```

### Log Rotation

```bash
# Configure PM2 log rotation
sudo -u membership pm2 install pm2-logrotate

# Configure rotation settings
sudo -u membership pm2 set pm2-logrotate:max_size 10M
sudo -u membership pm2 set pm2-logrotate:retain 7
```

---

## Performance Optimization

### Enable Caching

```nginx
# Add to Nginx configuration
location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

### Enable Compression

```nginx
# Already included in configuration
gzip on;
gzip_vary on;
gzip_min_length 1024;
gzip_types text/plain text/css text/xml text/javascript application/javascript;
```

### Database Optimization

```sql
-- Run in Supabase SQL Editor
VACUUM ANALYZE;
REINDEX DATABASE postgres;
```

---

## Security Checklist

- [ ] SSL certificate installed and auto-renewal configured
- [ ] Firewall configured (UFW)
- [ ] Strong passwords for all accounts
- [ ] 2FA enabled for admin accounts
- [ ] Environment variables secured (chmod 600)
- [ ] Regular backups configured
- [ ] Security headers configured in Nginx
- [ ] Rate limiting enabled
- [ ] Fail2ban installed (optional)
- [ ] Regular security updates applied

---

## Support

For deployment issues:
- Check logs: `sudo -u membership pm2 logs membership-system`
- Review documentation: `/docs/`
- GitHub Issues: https://github.com/wjlander/newmembership/issues
- Email: support@example.com

---

**Last Updated**: October 2025  
**Version**: 2.0.0