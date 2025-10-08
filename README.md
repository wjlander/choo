# Choo Membership Management System

A comprehensive membership management system designed for single organizations with enhanced features, streamlined deployment, and extensive functionality.

---

## ✨ Features

### Core Membership Management
- ✅ Custom signup forms with dynamic fields
- ✅ Flexible membership types and pricing
- ✅ Linked profiles for family memberships
- ✅ Member approval workflow
- ✅ Membership history tracking
- ✅ Member notes and tags

### Communications
- ✅ Email templates library with variables
- ✅ Email campaigns via Resend
- ✅ Multiple mailing lists
- ✅ Committee-specific mailing lists (auto-managed)
- ✅ Position-based email sending permissions
- ✅ Automated workflows (welcome, renewal, expiry)
- ✅ In-app notifications
- ✅ Bulk email composer

### Events Management
- ✅ Event creation and management
- ✅ RSVP with capacity limits and waitlist
- ✅ QR code check-in system
- ✅ Attendance tracking and certificates
- ✅ Event calendar view with iCal export
- ✅ Event analytics
- ✅ Event ticketing (optional)

### Committees & Groups
- ✅ Committee management
- ✅ Position-based permissions
- ✅ Automatic mailing list synchronization
- ✅ Committee member auto-add to mailing lists
- ✅ Position-based email sending rights
- ✅ Meeting schedules

### Analytics & Reporting
- ✅ Advanced dashboard with charts
- ✅ Membership trends and insights
- ✅ Custom report builder
- ✅ CSV exports across all data
- ✅ Volunteer hour tracking
- ✅ Survey response analytics

### Documents
- ✅ Document library with folders
- ✅ Version control
- ✅ Approval workflow
- ✅ Categories and visibility control
- ✅ Download tracking
- ✅ Full-text search

### Member Features
- ✅ Member dashboard
- ✅ Profile management
- ✅ Event registration
- ✅ Mailing list subscriptions
- ✅ Member directory with search
- ✅ Onboarding checklist
- ✅ Referral program
- ✅ Volunteer opportunities
- ✅ Survey participation

### Security
- ✅ Two-factor authentication (2FA)
- ✅ Row Level Security (RLS)
- ✅ JWT authentication
- ✅ SSL automation
- ✅ Role-based access control
- ✅ Enhanced audit logging

### Administration
- ✅ Feature toggle system (enable/disable features)
- ✅ Custom branding (logo, colors, fonts)
- ✅ Member management
- ✅ Email campaign management
- ✅ Analytics and reports
- ✅ System configuration

---

## 🛠 Technology Stack

### Frontend
- **Framework**: Vite + React 18 + TypeScript
- **UI**: Tailwind CSS + Shadcn/ui components
- **State**: React Query + Zustand
- **Charts**: Recharts
- **i18n**: react-i18next (optional)

### Backend
- **Database**: Supabase (PostgreSQL)
- **Auth**: Supabase Auth with 2FA
- **Storage**: Supabase Storage
- **Email**: Resend API
- **Payments**: Stripe (optional)

### Infrastructure
- **Server**: Ubuntu/Debian
- **Web Server**: Nginx
- **Process Manager**: PM2
- **SSL**: Let's Encrypt (Certbot)

---

## 📦 Installation

### Prerequisites
- Ubuntu 20.04+ or Debian 11+
- Node.js 18+
- Supabase account
- Domain name (for production)

### Quick Start

1. **Clone Repository**
   ```bash
   git clone https://github.com/wjlander/choo.git
   cd choo
   ```

2. **Install Dependencies**
   ```bash
   npm install
   ```

3. **Configure Environment**
   ```bash
   cp .env.example .env
   # Edit .env with your Supabase credentials
   ```

4. **Run Database Migration**
   - Open Supabase Dashboard → SQL Editor
   - Run the migration file: `supabase/migrations/00000000000000_initial_schema.sql`
   - This creates all tables, indexes, RLS policies, and functions

5. **Start Development Server**
   ```bash
   npm run dev
   ```

6. **Access Application**
   - Visit: `http://localhost:5173`
   - Create your first admin account

---

## 🚀 Production Deployment

### Automated Deployment

```bash
# Make deployment script executable
chmod +x deploy.sh

# Run deployment (as root)
sudo ./deploy.sh
```

The deployment script will:
1. ✅ Update system packages
2. ✅ Install Node.js 18
3. ✅ Install PM2
4. ✅ Install Nginx
5. ✅ Install Certbot
6. ✅ Create application user
7. ✅ Copy application files
8. ✅ Install dependencies
9. ✅ Build application
10. ✅ Configure environment
11. ✅ Start with PM2
12. ✅ Configure Nginx
13. ✅ Obtain SSL certificate
14. ✅ Setup firewall

### Manual Deployment

See `docs/DEPLOYMENT_GUIDE.md` for detailed manual deployment instructions.

---

## 📚 Documentation

### User Guides
- **[Super Admin Guide](docs/SUPER_ADMIN_GUIDE.md)** - System administration
- **[Administrator Guide](docs/ADMINISTRATOR_GUIDE.md)** - Organization administration
- **[End User Guide](docs/END_USER_GUIDE.md)** - Member features and usage

### Technical Documentation
- **[Deployment Guide](docs/DEPLOYMENT_GUIDE.md)** - Production deployment
- **[Database Schema](docs/DATABASE_SCHEMA.md)** - Complete database structure
- **[Feature Toggle Guide](docs/FEATURE_TOGGLE_GUIDE.md)** - Managing features
- **[Mailing List Guide](docs/MAILING_LIST_GUIDE.md)** - Committee mailing lists

---

## 🔧 Configuration

### Environment Variables

```env
# Supabase Configuration
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key

# Email Configuration (Resend)
RESEND_API_KEY=your-resend-api-key

# Stripe Configuration (Optional)
STRIPE_PUBLIC_KEY=your-stripe-public-key
STRIPE_SECRET_KEY=your-stripe-secret-key

# Application Configuration
NODE_ENV=production
PORT=5173

# Organization Configuration
VITE_ORG_NAME=Choo
VITE_ORG_LOGO_URL=
VITE_PRIMARY_COLOR=#3B82F6
VITE_SECONDARY_COLOR=#1E40AF
```

### Feature Toggles

Administrators can enable/disable features through the admin panel:

- Events Management
- Committees & Groups
- Document Library
- Mailing Lists
- In-App Notifications
- Analytics & Reports
- Member Badges
- Member Tags
- Event Calendar
- QR Code Check-In
- Attendance Certificates
- Surveys & Feedback
- Volunteer Management
- Referral Program
- Payment Processing
- Event Ticketing
- Member Onboarding
- Two-Factor Authentication
- Custom Branding
- Multi-Language Support

---

## 📧 Enhanced Mailing List System

### Committee Mailing Lists

The system automatically manages committee mailing lists:

1. **Auto-Add Members**: When a member is added to a committee, they're automatically subscribed to the committee's mailing list
2. **Auto-Remove Members**: When a member is removed from a committee, they're automatically unsubscribed
3. **Access Control**: Only committee members can access committee mailing lists
4. **Position-Based Sending**: Specific committee positions can send emails to the list
5. **Personal Email**: Authorized positions can send using their personal email address
6. **Email Personalization**: Use database fields in emails ({{first_name}}, {{last_name}}, etc.)

### Setting Up Committee Mailing

1. Create a committee
2. Create positions within the committee
3. Configure mailing permissions for positions (Admin → Committees → Positions → Email Permissions)
4. Add members to positions
5. Members are automatically added to the committee mailing list
6. Authorized positions can send emails to the list

---

## 🔐 Security

### Authentication
- JWT-based authentication via Supabase
- Two-factor authentication (TOTP)
- Backup codes for account recovery
- Session management with timeout

### Authorization
- Role-based access control (RBAC)
- Row Level Security (RLS) policies
- Granular permissions per feature
- Position-based permissions for committees

### Data Protection
- Encryption at rest and in transit
- HTTPS enforcement
- Secure password hashing
- GDPR compliance features

---

## 📊 Performance

### Optimization
- Code splitting and lazy loading
- Image optimization
- Gzip compression
- CDN for static assets

### Caching
- Browser caching for static assets
- API response caching
- Database query caching

### Monitoring
- PM2 monitoring dashboard
- Application performance monitoring
- Error tracking and alerting
- Database performance monitoring

---

## 🔄 Updates & Maintenance

### Update Application
```bash
# Using update script
sudo update-choo-system

# Manual update
cd /var/www/choo-system
sudo -u choo git pull
sudo -u choo npm ci --production
sudo -u choo npm run build
sudo -u choo pm2 restart choo-system
```

### Backup & Restore
```bash
# Create backup
sudo -u choo /usr/local/bin/backup-choo-system

# Restore from backup
sudo -u choo /usr/local/bin/restore-choo-system backup_20251008_120000.tar.gz
```

### Monitoring
```bash
# View application logs
sudo -u choo pm2 logs choo-system

# Check application status
sudo -u choo pm2 status

# Monitor resources
sudo -u choo pm2 monit
```

---

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new features
5. Submit a pull request

---

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## 🆘 Support

### Documentation
- [Deployment Guide](docs/DEPLOYMENT_GUIDE.md)
- [Administrator Guide](docs/ADMINISTRATOR_GUIDE.md)
- [Feature Toggle Guide](docs/FEATURE_TOGGLE_GUIDE.md)

### Community
- GitHub Issues: [Report bugs or request features](https://github.com/wjlander/choo/issues)
- Discussions: [Ask questions and share ideas](https://github.com/wjlander/choo/discussions)

---

## 📈 Statistics

- **Total Features**: 60+
- **Database Tables**: 35+
- **API Endpoints**: 100+
- **Lines of Code**: 30,000+
- **Documentation Pages**: 20+

---

## 🙏 Acknowledgments

- Supabase for the excellent backend platform
- Vercel for Vite and React
- Tailwind CSS for the utility-first CSS framework
- Shadcn/ui for beautiful UI components

---

**Built for Choo with ❤️**

**Version**: 1.0.0  
**Last Updated**: October 2025  
**Status**: Production Ready ✅