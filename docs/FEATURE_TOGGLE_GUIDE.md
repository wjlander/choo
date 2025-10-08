# Feature Toggle Guide - Choo Membership System

## Overview

The Choo membership system includes a powerful feature toggle system that allows administrators to enable or disable specific features without code changes. This provides flexibility to customize the system based on your organization's needs.

---

## Table of Contents

1. [Available Features](#available-features)
2. [Managing Features](#managing-features)
3. [Feature Categories](#feature-categories)
4. [Implementation Details](#implementation-details)
5. [Best Practices](#best-practices)

---

## Available Features

### Core Features

| Feature Key | Feature Name | Description | Default |
|------------|--------------|-------------|---------|
| `events` | Events Management | Enable event creation, registration, and management | ✅ Enabled |
| `committees` | Committees & Groups | Enable committee management and positions | ✅ Enabled |
| `documents` | Document Library | Enable document upload and management | ✅ Enabled |

### Communications

| Feature Key | Feature Name | Description | Default |
|------------|--------------|-------------|---------|
| `mailing_lists` | Mailing Lists | Enable email campaigns and mailing lists | ✅ Enabled |
| `notifications` | In-App Notifications | Enable notification center | ✅ Enabled |

### Reporting

| Feature Key | Feature Name | Description | Default |
|------------|--------------|-------------|---------|
| `analytics` | Analytics & Reports | Enable advanced analytics dashboard | ✅ Enabled |

### Engagement

| Feature Key | Feature Name | Description | Default |
|------------|--------------|-------------|---------|
| `badges` | Member Badges | Enable achievement badges system | ✅ Enabled |
| `surveys` | Surveys & Feedback | Enable survey creation and responses | ✅ Enabled |
| `volunteers` | Volunteer Management | Enable volunteer shift management | ✅ Enabled |
| `referrals` | Referral Program | Enable member referral system | ✅ Enabled |

### Management

| Feature Key | Feature Name | Description | Default |
|------------|--------------|-------------|---------|
| `tags` | Member Tags | Enable member tagging system | ✅ Enabled |
| `onboarding` | Member Onboarding | Enable onboarding workflow | ✅ Enabled |

### Events (Extended)

| Feature Key | Feature Name | Description | Default |
|------------|--------------|-------------|---------|
| `calendar` | Event Calendar | Enable calendar view for events | ✅ Enabled |
| `qr_checkin` | QR Code Check-In | Enable QR code event check-in | ✅ Enabled |
| `certificates` | Attendance Certificates | Enable PDF certificate generation | ✅ Enabled |
| `ticketing` | Event Ticketing | Enable paid event tickets | ❌ Disabled |

### Financial

| Feature Key | Feature Name | Description | Default |
|------------|--------------|-------------|---------|
| `payments` | Payment Processing | Enable Stripe payment integration | ❌ Disabled |

### Security

| Feature Key | Feature Name | Description | Default |
|------------|--------------|-------------|---------|
| `2fa` | Two-Factor Authentication | Enable 2FA for enhanced security | ✅ Enabled |

### Appearance

| Feature Key | Feature Name | Description | Default |
|------------|--------------|-------------|---------|
| `custom_branding` | Custom Branding | Enable logo and color customization | ✅ Enabled |

### Localization

| Feature Key | Feature Name | Description | Default |
|------------|--------------|-------------|---------|
| `multi_language` | Multi-Language Support | Enable multiple language support | ❌ Disabled |

---

## Managing Features

### Accessing Feature Settings

1. **Login as Administrator**
   - Navigate to the admin panel
   - Click on "Settings" or "System Configuration"

2. **Navigate to Features**
   - Click on "Feature Settings" or "Feature Toggles"
   - You'll see a list of all available features

3. **View Feature Details**
   - Each feature shows:
     - Feature name
     - Description
     - Current status (Enabled/Disabled)
     - Category
     - Last updated

### Enabling a Feature

1. **Select Feature**
   - Find the feature you want to enable
   - Click on the feature row or toggle switch

2. **Enable Feature**
   - Toggle the switch to "Enabled"
   - Or click "Enable" button

3. **Confirm Changes**
   - Review the confirmation message
   - Click "Save" or "Confirm"

4. **Verify Feature**
   - The feature should now be available in the application
   - Check the relevant menu items or sections

### Disabling a Feature

1. **Select Feature**
   - Find the feature you want to disable
   - Click on the feature row or toggle switch

2. **Disable Feature**
   - Toggle the switch to "Disabled"
   - Or click "Disable" button

3. **Confirm Changes**
   - Review the warning message
   - Understand that disabling may hide existing data
   - Click "Save" or "Confirm"

4. **Verify Feature**
   - The feature should now be hidden from the application
   - Related menu items should be removed

### Bulk Feature Management

1. **Select Multiple Features**
   - Use checkboxes to select multiple features
   - Or use "Select All" option

2. **Apply Action**
   - Click "Enable Selected" or "Disable Selected"
   - Confirm the bulk action

3. **Review Changes**
   - Check that all selected features were updated
   - Verify the application reflects the changes

---

## Feature Categories

Features are organized into categories for easier management:

### Core
Essential features for basic membership management:
- Events Management
- Committees & Groups
- Document Library

### Communications
Features related to member communication:
- Mailing Lists
- In-App Notifications

### Reporting
Analytics and reporting features:
- Analytics & Reports

### Engagement
Features to increase member engagement:
- Member Badges
- Surveys & Feedback
- Volunteer Management
- Referral Program

### Management
Administrative and management features:
- Member Tags
- Member Onboarding

### Events
Extended event management features:
- Event Calendar
- QR Code Check-In
- Attendance Certificates
- Event Ticketing

### Financial
Payment and financial features:
- Payment Processing

### Security
Security-related features:
- Two-Factor Authentication

### Appearance
Customization features:
- Custom Branding

### Localization
Language and localization features:
- Multi-Language Support

---

## Implementation Details

### Database Structure

Features are stored in the `feature_settings` table:

```sql
CREATE TABLE feature_settings (
    id uuid PRIMARY KEY,
    feature_key text UNIQUE NOT NULL,
    feature_name text NOT NULL,
    description text,
    is_enabled boolean DEFAULT true,
    category text DEFAULT 'general',
    display_order integer DEFAULT 0,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);
```

### Checking Feature Status

#### In SQL
```sql
SELECT is_feature_enabled('events');
```

#### In Application Code
```typescript
import { isFeatureEnabled } from '@/lib/config';

if (isFeatureEnabled('events')) {
  // Show events feature
}
```

#### In React Components
```typescript
import { useFeature } from '@/hooks/useFeature';

function EventsSection() {
  const { isEnabled, loading } = useFeature('events');
  
  if (loading) return <Loading />;
  if (!isEnabled) return null;
  
  return <EventsContent />;
}
```

### Feature Dependencies

Some features depend on others:

- **Event Ticketing** requires **Events Management** and **Payment Processing**
- **QR Code Check-In** requires **Events Management**
- **Attendance Certificates** requires **Events Management**
- **Committee Mailing Lists** requires **Mailing Lists** and **Committees**

The system automatically handles these dependencies:
- Enabling a feature enables its dependencies
- Disabling a feature warns about dependent features

---

## Best Practices

### 1. Start with Core Features

Enable core features first:
- Events Management
- Committees & Groups
- Document Library
- Mailing Lists

### 2. Enable Features Gradually

Don't enable all features at once:
- Start with essential features
- Train users on each feature
- Enable additional features as needed
- Monitor usage and feedback

### 3. Test Before Enabling

Before enabling a feature in production:
- Test in a development environment
- Train administrators
- Prepare user documentation
- Plan rollout communication

### 4. Monitor Feature Usage

Track which features are being used:
- Review analytics regularly
- Disable unused features
- Focus on high-value features
- Gather user feedback

### 5. Communicate Changes

When enabling/disabling features:
- Notify users in advance
- Provide training materials
- Offer support during transition
- Document the changes

### 6. Consider Performance

Some features impact performance:
- **Analytics**: Can be resource-intensive
- **Payments**: Requires external API calls
- **Multi-Language**: Increases page load time

Enable only features you need.

### 7. Security Considerations

Some features have security implications:
- **Two-Factor Authentication**: Highly recommended
- **Payment Processing**: Requires PCI compliance
- **Document Library**: Consider file size limits

Review security settings for each feature.

### 8. Backup Before Changes

Before making major feature changes:
- Create a database backup
- Document current settings
- Have a rollback plan
- Test in staging first

---

## Troubleshooting

### Feature Not Appearing After Enabling

1. **Clear Browser Cache**
   - Hard refresh (Ctrl+Shift+R)
   - Clear browser cache
   - Try incognito mode

2. **Check User Permissions**
   - Verify user has required role
   - Check feature-specific permissions
   - Review RLS policies

3. **Verify Database**
   - Check feature_settings table
   - Confirm is_enabled = true
   - Check for database errors

4. **Restart Application**
   - Restart PM2 process
   - Clear application cache
   - Reload configuration

### Feature Still Visible After Disabling

1. **Clear Application Cache**
   - Restart application
   - Clear Redis cache (if used)
   - Clear browser cache

2. **Check for Hardcoded References**
   - Review code for hardcoded feature checks
   - Ensure all components use feature flags
   - Update any cached configurations

3. **Verify Database Update**
   - Check feature_settings table
   - Confirm is_enabled = false
   - Check updated_at timestamp

### Feature Dependencies Not Working

1. **Check Dependency Configuration**
   - Review feature dependencies
   - Verify parent features are enabled
   - Check dependency chain

2. **Update Feature Settings**
   - Re-enable parent features
   - Disable and re-enable dependent features
   - Check for circular dependencies

---

## API Reference

### Get All Features

```typescript
GET /api/features

Response:
{
  "features": [
    {
      "id": "uuid",
      "feature_key": "events",
      "feature_name": "Events Management",
      "description": "Enable event creation...",
      "is_enabled": true,
      "category": "core",
      "display_order": 1
    }
  ]
}
```

### Get Single Feature

```typescript
GET /api/features/:feature_key

Response:
{
  "feature": {
    "id": "uuid",
    "feature_key": "events",
    "feature_name": "Events Management",
    "is_enabled": true
  }
}
```

### Update Feature

```typescript
PATCH /api/features/:feature_key

Request:
{
  "is_enabled": true
}

Response:
{
  "success": true,
  "feature": {
    "feature_key": "events",
    "is_enabled": true
  }
}
```

### Bulk Update Features

```typescript
PATCH /api/features/bulk

Request:
{
  "features": [
    { "feature_key": "events", "is_enabled": true },
    { "feature_key": "surveys", "is_enabled": false }
  ]
}

Response:
{
  "success": true,
  "updated": 2
}
```

---

## Examples

### Example 1: Enabling Payment Processing

```typescript
// 1. Enable payment processing feature
await updateFeature('payments', { is_enabled: true });

// 2. Configure Stripe keys in environment
STRIPE_PUBLIC_KEY=pk_live_...
STRIPE_SECRET_KEY=sk_live_...

// 3. Restart application
pm2 restart choo-system

// 4. Verify feature is available
const paymentsEnabled = await isFeatureEnabled('payments');
console.log('Payments enabled:', paymentsEnabled);
```

### Example 2: Disabling Unused Features

```typescript
// Disable features not being used
const unusedFeatures = ['referrals', 'volunteers', 'surveys'];

for (const feature of unusedFeatures) {
  await updateFeature(feature, { is_enabled: false });
}

// Verify changes
const enabledFeatures = await getEnabledFeatures();
console.log('Enabled features:', enabledFeatures);
```

### Example 3: Feature-Gated Component

```typescript
import { useFeature } from '@/hooks/useFeature';

function VolunteerSection() {
  const { isEnabled, loading } = useFeature('volunteers');
  
  if (loading) {
    return <Skeleton />;
  }
  
  if (!isEnabled) {
    return (
      <Alert>
        <AlertTitle>Feature Not Available</AlertTitle>
        <AlertDescription>
          The volunteer management feature is currently disabled.
          Contact your administrator to enable it.
        </AlertDescription>
      </Alert>
    );
  }
  
  return <VolunteerManagement />;
}
```

---

## Support

For questions about feature toggles:
- Check this guide first
- Review the [Administrator Guide](ADMINISTRATOR_GUIDE.md)
- Contact support: support@choo.org
- GitHub Issues: https://github.com/wjlander/choo/issues

---

**Last Updated**: October 2025  
**Version**: 1.0.0