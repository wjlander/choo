# Super Admin Guide

## Table of Contents

1. [Introduction](#introduction)
2. [Accessing Super Admin Portal](#accessing-super-admin-portal)
3. [Organization Management](#organization-management)
4. [System Configuration](#system-configuration)
5. [User Management](#user-management)
6. [Security & Permissions](#security--permissions)
7. [Monitoring & Analytics](#monitoring--analytics)
8. [Backup & Recovery](#backup--recovery)
9. [Troubleshooting](#troubleshooting)

---

## Introduction

Welcome to the Super Admin Guide for the Membership Management System. As a Super Admin, you have system-wide access to manage multiple organizations, configure system settings, and oversee the entire platform.

### Super Admin Responsibilities

- **Organization Management**: Create, configure, and manage multiple organizations
- **System Configuration**: Configure global settings and features
- **User Management**: Manage super admin accounts and organization admins
- **Security**: Monitor security, manage permissions, and enforce policies
- **Monitoring**: Track system health, performance, and usage
- **Support**: Provide technical support to organization administrators

---

## Accessing Super Admin Portal

### Login Methods

**Method 1: URL Parameter**
```
https://yourdomain.com?org=admin
```

**Method 2: Subdomain**
```
https://admin.yourdomain.com
```

**Method 3: Custom Admin Domain**
```
https://admin.example.com
```

### First-Time Setup

1. **Initial Super Admin Creation**
   - Run the super admin creation script on your server
   - Or use the Supabase SQL editor to create your first super admin

2. **Login Credentials**
   - Use your designated super admin email
   - Set a strong password (minimum 12 characters)
   - Enable 2FA immediately after first login

3. **Security Best Practices**
   - Never share super admin credentials
   - Use a password manager
   - Enable two-factor authentication
   - Log out when not in use

---

## Organization Management

### Creating New Organizations

1. **Navigate to Organizations**
   - Click "Organizations" in the super admin menu
   - Click "Create New Organization"

2. **Organization Details**
   ```
   Required Fields:
   - Organization Name
   - Slug (URL identifier, e.g., "frps" for frps.org.uk)
   - Contact Email
   
   Optional Fields:
   - Domain (custom domain)
   - Logo URL
   - Primary Color
   - Secondary Color
   - Contact Phone
   - Address
   ```

3. **Configuration Options**
   - **Multi-tenancy**: Subdomain or custom domain
   - **Features**: Enable/disable specific features per organization
   - **Limits**: Set member limits, storage limits, etc.
   - **Billing**: Configure billing settings (if applicable)

4. **Initial Setup**
   - Create first organization admin
   - Configure default membership types
   - Set up email templates
   - Configure branding

### Managing Existing Organizations

#### View Organization List
- See all organizations in the system
- Filter by status (active, inactive, suspended)
- Search by name or slug
- Sort by creation date, member count, etc.

#### Organization Details
- View organization statistics
- See member count and activity
- Check storage usage
- Review recent activity logs

#### Edit Organization
- Update organization details
- Change branding and colors
- Modify contact information
- Update domain settings

#### Suspend/Activate Organization
- Temporarily suspend an organization
- Reactivate suspended organizations
- Set suspension reasons and notes

#### Delete Organization
- **Warning**: This action is irreversible
- All organization data will be permanently deleted
- Requires confirmation and reason
- Sends notification to organization admins

### Custom Domain Management

#### DNS Configuration
1. **Add Custom Domain**
   - Enter domain name (e.g., frps.org.uk)
   - System generates DNS verification records

2. **DNS Records Required**
   ```
   Type: TXT
   Name: _membership-verify
   Value: [generated verification code]
   
   Type: A
   Name: @ (or subdomain)
   Value: [server IP address]
   
   Type: CNAME (for wildcard)
   Name: *
   Value: yourdomain.com
   ```

3. **Verify Domain**
   - Click "Verify DNS" after adding records
   - System checks DNS propagation
   - May take up to 48 hours for DNS propagation

4. **SSL Certificate**
   - Automatically generated via Let's Encrypt
   - Wildcard SSL for subdomains
   - Auto-renewal configured

#### Domain Status
- **Pending**: Awaiting DNS verification
- **Verified**: DNS verified, SSL pending
- **Active**: Fully configured and operational
- **Failed**: Verification or SSL failed

---

## System Configuration

### Global Settings

#### Email Configuration
```
SMTP Settings:
- Email Provider: Resend (default)
- API Key: [configured in .env]
- From Email: noreply@yourdomain.com
- From Name: Membership System

Email Templates:
- Welcome Email
- Password Reset
- Membership Renewal
- Event Registration
- Custom Templates
```

#### Feature Flags
Enable/disable features system-wide or per organization:
- Digital Membership Cards
- Event Management
- Volunteer Management
- Survey System
- Payment Processing
- Referral Program
- Multi-language Support

#### Security Settings
```
Password Policy:
- Minimum Length: 8 characters
- Require Uppercase: Yes
- Require Numbers: Yes
- Require Special Characters: Yes
- Password Expiry: 90 days (optional)

Session Settings:
- Session Timeout: 30 minutes
- Remember Me Duration: 30 days
- Max Concurrent Sessions: 3

Two-Factor Authentication:
- Enforce for Admins: Yes/No
- Enforce for All Users: Yes/No
- Backup Codes: 10 per user
```

#### Rate Limiting
```
API Rate Limits:
- Login Attempts: 5 per 15 minutes
- API Requests: 100 per minute
- Email Sending: 50 per hour
- File Uploads: 10 per minute
```

### System Maintenance

#### Scheduled Maintenance
1. **Plan Maintenance Window**
   - Choose low-traffic time
   - Notify all organizations in advance
   - Set maintenance mode

2. **Maintenance Mode**
   - Display maintenance message
   - Block new logins
   - Allow super admins only
   - Show estimated completion time

3. **Post-Maintenance**
   - Verify all systems operational
   - Check database integrity
   - Test critical features
   - Notify organizations of completion

#### Database Maintenance
```bash
# Backup database
pg_dump -h localhost -U postgres membership_db > backup.sql

# Vacuum database
VACUUM ANALYZE;

# Reindex tables
REINDEX DATABASE membership_db;

# Check table sizes
SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename))
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

---

## User Management

### Super Admin Accounts

#### Create Super Admin
1. Navigate to "Super Admins"
2. Click "Add Super Admin"
3. Enter details:
   - Email
   - First Name
   - Last Name
   - Phone (optional)
4. Send invitation email
5. User sets password on first login

#### Manage Super Admins
- View all super admin accounts
- Edit super admin details
- Suspend/reactivate accounts
- Remove super admin access
- View activity logs

#### Super Admin Permissions
- Full system access
- Organization management
- User management
- System configuration
- Security settings
- Backup and recovery

### Organization Admins

#### View All Admins
- See admins across all organizations
- Filter by organization
- Search by name or email
- View admin activity

#### Promote/Demote Users
- Promote members to admin
- Demote admins to members
- Transfer admin rights
- Bulk role changes

#### Reset Admin Passwords
- Generate password reset link
- Send reset email
- Temporary password option
- Force password change on next login

---

## Security & Permissions

### Access Control

#### Role Hierarchy
```
Super Admin (System-wide)
  ├── Organization Admin (Organization-wide)
  │   ├── Committee Admin (Committee-specific)
  │   └── Member (Basic access)
  └── Member (Basic access)
```

#### Permission Matrix
| Feature | Super Admin | Org Admin | Member |
|---------|-------------|-----------|--------|
| View Organizations | ✓ | Own only | Own only |
| Create Organizations | ✓ | ✗ | ✗ |
| Manage Members | ✓ | ✓ | Own profile |
| Manage Events | ✓ | ✓ | Register only |
| View Analytics | ✓ | ✓ | Own data |
| System Settings | ✓ | ✗ | ✗ |
| Billing | ✓ | ✓ | ✗ |

### Security Monitoring

#### Activity Logs
- View all system activity
- Filter by user, organization, action
- Export logs for analysis
- Set up alerts for suspicious activity

#### Security Alerts
- Failed login attempts
- Unauthorized access attempts
- Data export activities
- Permission changes
- Bulk operations

#### Audit Trail
- Track all administrative actions
- Record data modifications
- Monitor permission changes
- Export audit reports

### Two-Factor Authentication

#### Enforce 2FA
1. Navigate to Security Settings
2. Enable "Require 2FA for Admins"
3. Set grace period (e.g., 7 days)
4. Notify affected users

#### 2FA Recovery
- Generate backup codes
- Reset 2FA for users
- Verify identity before reset
- Log all 2FA resets

---

## Monitoring & Analytics

### System Dashboard

#### Key Metrics
```
System Health:
- Uptime: 99.9%
- Response Time: < 200ms
- Error Rate: < 0.1%
- Active Users: 1,234

Resource Usage:
- CPU: 45%
- Memory: 2.1GB / 4GB
- Disk: 15GB / 100GB
- Database: 5GB
```

#### Organization Statistics
- Total Organizations: 25
- Active Organizations: 23
- Total Members: 5,432
- Active Members: 4,876
- New Members (30 days): 234

#### Usage Analytics
- Daily Active Users (DAU)
- Monthly Active Users (MAU)
- Feature Usage Statistics
- API Request Volume
- Email Delivery Rates

### Performance Monitoring

#### Response Times
- API Endpoints
- Database Queries
- Page Load Times
- Email Delivery

#### Error Tracking
- Application Errors
- Database Errors
- API Errors
- Email Failures

#### Alerts Configuration
```
Alert Thresholds:
- Response Time > 1s
- Error Rate > 1%
- CPU Usage > 80%
- Memory Usage > 90%
- Disk Usage > 85%

Notification Channels:
- Email
- SMS
- Slack
- PagerDuty
```

---

## Backup & Recovery

### Automated Backups

#### Backup Schedule
```
Daily Backups:
- Time: 2:00 AM UTC
- Retention: 7 days
- Location: /var/backups/membership-system/

Weekly Backups:
- Time: Sunday 2:00 AM UTC
- Retention: 4 weeks
- Location: /var/backups/membership-system/weekly/

Monthly Backups:
- Time: 1st of month 2:00 AM UTC
- Retention: 12 months
- Location: /var/backups/membership-system/monthly/
```

#### Backup Contents
- Database (PostgreSQL dump)
- Uploaded files (Supabase Storage)
- Configuration files
- Environment variables (encrypted)

### Manual Backup

```bash
# Create manual backup
sudo -u membership /usr/local/bin/backup-membership-system

# Backup with custom name
sudo -u membership /usr/local/bin/backup-membership-system "pre-upgrade-backup"

# Verify backup
sudo -u membership /usr/local/bin/verify-backup backup_20251008_120000.tar.gz
```

### Restore Procedures

#### Full System Restore
```bash
# 1. Stop application
sudo -u membership pm2 stop membership-system

# 2. Restore database
pg_restore -h localhost -U postgres -d membership_db backup.sql

# 3. Restore files
tar -xzf backup_20251008_120000.tar.gz -C /var/www/membership-system

# 4. Restart application
sudo -u membership pm2 restart membership-system

# 5. Verify restoration
curl https://yourdomain.com/health
```

#### Selective Restore
- Restore specific organization data
- Restore specific tables
- Restore specific files
- Point-in-time recovery

### Disaster Recovery

#### Recovery Time Objective (RTO)
- Target: < 4 hours
- Critical systems: < 1 hour

#### Recovery Point Objective (RPO)
- Target: < 24 hours
- Critical data: < 1 hour

#### DR Procedures
1. Assess damage and data loss
2. Notify stakeholders
3. Activate DR plan
4. Restore from backups
5. Verify data integrity
6. Resume operations
7. Post-incident review

---

## Troubleshooting

### Common Issues

#### Organizations Not Loading
```
Symptoms:
- Organization selector shows no organizations
- "No organizations found" error

Causes:
- Database connection issue
- RLS policy misconfiguration
- Cache issue

Solutions:
1. Check database connection
2. Verify RLS policies
3. Clear application cache
4. Check Supabase logs
```

#### SSL Certificate Issues
```
Symptoms:
- "Not Secure" warning in browser
- SSL certificate expired
- Certificate mismatch

Solutions:
1. Check certificate expiry: sudo certbot certificates
2. Renew certificate: sudo certbot renew
3. Verify domain configuration
4. Check Nginx configuration
5. Restart Nginx: sudo systemctl restart nginx
```

#### Email Delivery Failures
```
Symptoms:
- Emails not being sent
- Emails going to spam
- Bounce notifications

Solutions:
1. Check Resend API key
2. Verify sender domain
3. Check SPF/DKIM records
4. Review email logs
5. Check rate limits
```

#### Performance Issues
```
Symptoms:
- Slow page loads
- Timeouts
- High server load

Solutions:
1. Check server resources (CPU, memory, disk)
2. Review slow database queries
3. Check for N+1 queries
4. Optimize database indexes
5. Enable caching
6. Scale resources if needed
```

### Debug Mode

#### Enable Debug Logging
```bash
# Edit .env file
DEBUG=true
LOG_LEVEL=debug

# Restart application
sudo -u membership pm2 restart membership-system

# View logs
sudo -u membership pm2 logs membership-system
```

#### Database Query Logging
```sql
-- Enable query logging
ALTER SYSTEM SET log_statement = 'all';
ALTER SYSTEM SET log_duration = on;

-- Reload configuration
SELECT pg_reload_conf();

-- View slow queries
SELECT query, calls, total_time, mean_time
FROM pg_stat_statements
ORDER BY mean_time DESC
LIMIT 10;
```

### Support Resources

#### Documentation
- Technical Documentation: `/docs/TECHNICAL.md`
- API Documentation: `/docs/API.md`
- Deployment Guide: `/docs/DEPLOYMENT.md`

#### Community
- GitHub Issues: https://github.com/yourorg/membership-system/issues
- Community Forum: https://community.example.com
- Stack Overflow: Tag `membership-system`

#### Professional Support
- Email: support@example.com
- Phone: +1-555-0123
- Emergency Hotline: +1-555-0911 (24/7)

---

## Best Practices

### Security
1. **Regular Updates**: Keep system and dependencies updated
2. **Strong Passwords**: Enforce strong password policies
3. **2FA**: Require 2FA for all admins
4. **Access Control**: Follow principle of least privilege
5. **Audit Logs**: Regularly review audit logs
6. **Backups**: Verify backups regularly

### Performance
1. **Monitoring**: Set up comprehensive monitoring
2. **Optimization**: Regularly optimize database
3. **Caching**: Implement appropriate caching strategies
4. **CDN**: Use CDN for static assets
5. **Load Testing**: Perform regular load testing

### Maintenance
1. **Scheduled Maintenance**: Plan regular maintenance windows
2. **Communication**: Notify users in advance
3. **Testing**: Test in staging before production
4. **Rollback Plan**: Always have a rollback plan
5. **Documentation**: Keep documentation updated

---

## Appendix

### Keyboard Shortcuts
- `Ctrl + K`: Quick search
- `Ctrl + /`: Toggle sidebar
- `Ctrl + Shift + D`: Toggle debug mode
- `Esc`: Close modal/dialog

### API Endpoints
```
Super Admin API:
- GET /api/admin/organizations
- POST /api/admin/organizations
- PUT /api/admin/organizations/:id
- DELETE /api/admin/organizations/:id
- GET /api/admin/users
- GET /api/admin/analytics
- GET /api/admin/logs
```

### Database Schema
See `docs/DATABASE_SCHEMA.md` for complete database schema documentation.

### Changelog
See `CHANGELOG.md` for version history and updates.

---

**Last Updated**: October 2025  
**Version**: 2.0.0  
**Support**: support@example.com