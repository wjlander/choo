# Mailing List Guide - Choo Membership System

## Overview

The Choo membership system includes an enhanced mailing list system with special features for committee management. This guide covers how to set up and use mailing lists, especially committee mailing lists with automatic member management and position-based sending permissions.

---

## Table of Contents

1. [Mailing List Types](#mailing-list-types)
2. [Committee Mailing Lists](#committee-mailing-lists)
3. [Position-Based Email Permissions](#position-based-email-permissions)
4. [Email Personalization](#email-personalization)
5. [Setting Up Committee Mailing](#setting-up-committee-mailing)
6. [Managing Subscriptions](#managing-subscriptions)
7. [Sending Emails](#sending-emails)
8. [Best Practices](#best-practices)

---

## Mailing List Types

The system supports four types of mailing lists:

### 1. General Lists
- **Purpose**: Organization-wide communications
- **Examples**: Newsletter, Announcements, Updates
- **Access**: Public or restricted
- **Management**: Manual subscription

### 2. Committee Lists
- **Purpose**: Committee-specific communications
- **Examples**: Board Members, Events Committee, Finance Committee
- **Access**: Restricted to committee members only
- **Management**: Automatic subscription based on committee membership

### 3. Event Lists
- **Purpose**: Event-specific communications
- **Examples**: Annual Gala Attendees, Workshop Participants
- **Access**: Restricted to event registrants
- **Management**: Automatic subscription based on event registration

### 4. Custom Lists
- **Purpose**: Special interest groups
- **Examples**: Volunteers, Donors, Regional Groups
- **Access**: Configurable
- **Management**: Manual or automatic based on criteria

---

## Committee Mailing Lists

Committee mailing lists are automatically managed by the system.

### Automatic Member Management

#### When a Member is Added to a Committee:
1. System detects the new committee member
2. Finds the committee's mailing list
3. Automatically subscribes the member to the list
4. Member receives confirmation email (optional)
5. Member can now receive committee emails

#### When a Member is Removed from a Committee:
1. System detects the member removal
2. Finds the committee's mailing list
3. Automatically unsubscribes the member from the list
4. Member stops receiving committee emails

### Access Control

Committee mailing lists have restricted access:
- **View List**: Only committee members can see the list
- **View Subscribers**: Only committee members can see who's subscribed
- **Send Emails**: Only authorized positions can send emails
- **Manage List**: Only admins can manage list settings

### Creating a Committee Mailing List

1. **Navigate to Committees**
   - Admin Panel → Committees
   - Select the committee

2. **Create Mailing List**
   - Click "Create Mailing List"
   - Or go to Mailing Lists → Create New

3. **Configure List**
   ```
   Name: [Committee Name] Mailing List
   Type: Committee
   Committee: [Select Committee]
   Is Public: No (restricted to committee members)
   Auto-subscribe: Yes (automatically add committee members)
   ```

4. **Save List**
   - Click "Create List"
   - System automatically adds current committee members

---

## Position-Based Email Permissions

Specific committee positions can be granted permission to send emails to the committee mailing list.

### Permission Types

#### 1. Can Send Email
- **Description**: Position can send emails to the committee list
- **Use Case**: Chair, Secretary, Communications Officer
- **Default**: No

#### 2. Can Use Personal Email
- **Description**: Position can send using their personal email address
- **Use Case**: Chair sending personal messages
- **Default**: No
- **Benefit**: Emails appear from the person's email, not a generic address

### Setting Up Email Permissions

1. **Navigate to Committee Positions**
   - Admin Panel → Committees → [Committee] → Positions

2. **Select Position**
   - Click on the position (e.g., "Chair")
   - Click "Email Permissions"

3. **Configure Permissions**
   ```
   Position: Chair
   Can Send Email: ✓ Yes
   Can Use Personal Email: ✓ Yes
   ```

4. **Save Permissions**
   - Click "Save"
   - Position holders can now send emails

### Example Configuration

**Board of Directors Committee:**

| Position | Can Send Email | Can Use Personal Email |
|----------|---------------|----------------------|
| Chair | ✓ Yes | ✓ Yes |
| Vice Chair | ✓ Yes | ✗ No |
| Secretary | ✓ Yes | ✗ No |
| Treasurer | ✗ No | ✗ No |
| Member | ✗ No | ✗ No |

**Events Committee:**

| Position | Can Send Email | Can Use Personal Email |
|----------|---------------|----------------------|
| Events Coordinator | ✓ Yes | ✓ Yes |
| Assistant Coordinator | ✓ Yes | ✗ No |
| Volunteer | ✗ No | ✗ No |

---

## Email Personalization

Emails sent to mailing lists can include personalized fields from the database.

### Available Fields

#### Member Information
- `{{first_name}}` - Member's first name
- `{{last_name}}` - Member's last name
- `{{email}}` - Member's email address
- `{{phone}}` - Member's phone number
- `{{full_name}}` - Member's full name (first + last)

#### Membership Information
- `{{membership_type}}` - Current membership type
- `{{membership_status}}` - Current membership status
- `{{membership_expiry}}` - Membership expiry date
- `{{membership_year}}` - Current membership year

#### Committee Information (for committee lists)
- `{{committee_name}}` - Committee name
- `{{position_title}}` - Member's position in committee
- `{{committee_role}}` - Member's role description

#### Organization Information
- `{{org_name}}` - Organization name
- `{{org_email}}` - Organization contact email
- `{{org_phone}}` - Organization phone number
- `{{org_website}}` - Organization website

### Using Personalization

#### Example 1: Welcome Email
```
Subject: Welcome to {{committee_name}}, {{first_name}}!

Dear {{first_name}} {{last_name}},

Welcome to the {{committee_name}}! We're excited to have you join us as {{position_title}}.

Your first meeting is scheduled for [date]. We look forward to working with you.

Best regards,
{{org_name}}
```

#### Example 2: Meeting Reminder
```
Subject: {{committee_name}} Meeting Reminder

Hi {{first_name}},

This is a reminder about our upcoming {{committee_name}} meeting:

Date: [date]
Time: [time]
Location: [location]

As {{position_title}}, please review the attached agenda before the meeting.

See you there!
```

#### Example 3: Membership Renewal
```
Subject: Membership Renewal - {{first_name}}

Dear {{first_name}},

Your {{membership_type}} membership expires on {{membership_expiry}}.

Please renew your membership to continue enjoying member benefits.

Renew now: [link]

Thank you,
{{org_name}}
```

---

## Setting Up Committee Mailing

### Complete Setup Guide

#### Step 1: Create Committee
1. Navigate to Admin Panel → Committees
2. Click "Create Committee"
3. Enter committee details:
   ```
   Name: Board of Directors
   Description: Governing body of the organization
   Is Active: Yes
   ```
4. Click "Create"

#### Step 2: Create Positions
1. Select the committee
2. Click "Add Position"
3. Create positions:
   ```
   Position 1:
   Title: Chair
   Description: Leads the board
   Responsibilities: [list]
   
   Position 2:
   Title: Secretary
   Description: Records minutes
   Responsibilities: [list]
   
   Position 3:
   Title: Treasurer
   Description: Manages finances
   Responsibilities: [list]
   ```

#### Step 3: Configure Email Permissions
1. For each position, click "Email Permissions"
2. Configure as needed:
   ```
   Chair:
   - Can Send Email: Yes
   - Can Use Personal Email: Yes
   
   Secretary:
   - Can Send Email: Yes
   - Can Use Personal Email: No
   
   Treasurer:
   - Can Send Email: No
   - Can Use Personal Email: No
   ```

#### Step 4: Create Mailing List
1. Navigate to Mailing Lists
2. Click "Create List"
3. Configure:
   ```
   Name: Board of Directors Mailing List
   Description: Communications for board members
   Type: Committee
   Committee: Board of Directors
   Is Public: No
   Auto-subscribe New Members: Yes
   ```
4. Click "Create"

#### Step 5: Add Committee Members
1. Navigate to Committee → Members
2. Click "Add Member"
3. Select member and position:
   ```
   Member: John Doe
   Position: Chair
   Start Date: [date]
   ```
4. Click "Add"
5. Member is automatically added to mailing list

#### Step 6: Test Email Sending
1. Login as a member with email permissions (e.g., Chair)
2. Navigate to Mailing Lists → Board of Directors
3. Click "Compose Email"
4. Write email with personalization:
   ```
   Subject: Board Meeting Agenda
   
   Dear {{first_name}},
   
   Please find attached the agenda for our next board meeting.
   
   Best regards,
   [Your Name]
   Chair, Board of Directors
   ```
5. Click "Send"
6. All committee members receive the email

---

## Managing Subscriptions

### Viewing Subscriptions

#### As Administrator:
1. Navigate to Mailing Lists
2. Select a list
3. Click "Subscribers"
4. View all subscribers with:
   - Name
   - Email
   - Status (Subscribed/Unsubscribed)
   - Subscription date

#### As Committee Member:
1. Navigate to My Committees
2. Select committee
3. Click "Mailing List"
4. View committee members (if permitted)

### Manual Subscription Management

#### Subscribe a Member:
1. Navigate to Mailing Lists → [List] → Subscribers
2. Click "Add Subscriber"
3. Select member or enter email
4. Click "Subscribe"

#### Unsubscribe a Member:
1. Navigate to Mailing Lists → [List] → Subscribers
2. Find member
3. Click "Unsubscribe"
4. Confirm action

#### Bulk Operations:
1. Navigate to Mailing Lists → [List] → Subscribers
2. Select multiple members (checkboxes)
3. Choose action:
   - Subscribe Selected
   - Unsubscribe Selected
   - Export to CSV
4. Confirm action

### Member Self-Management

Members can manage their own subscriptions:

1. **View Subscriptions**
   - Navigate to My Profile → Mailing Lists
   - See all subscribed lists

2. **Subscribe to Public Lists**
   - Browse available lists
   - Click "Subscribe"
   - Receive confirmation

3. **Unsubscribe from Lists**
   - View subscriptions
   - Click "Unsubscribe"
   - Confirm action
   - Note: Cannot unsubscribe from committee lists while in committee

4. **Update Email Preferences**
   - Set email frequency
   - Choose digest mode
   - Set notification preferences

---

## Sending Emails

### Composing an Email

#### Step 1: Access Email Composer
1. Navigate to Mailing Lists
2. Select the list
3. Click "Compose Email"

#### Step 2: Write Email
```
From: [Your email or organization email]
To: [Mailing list name]
Subject: [Email subject]

Body:
[Email content with personalization fields]
```

#### Step 3: Add Personalization
- Click "Insert Field" to add personalization
- Select field from dropdown
- Field is inserted at cursor position

#### Step 4: Preview Email
- Click "Preview"
- See how email looks with sample data
- Check personalization fields

#### Step 5: Send Email
- Click "Send Now" for immediate sending
- Or "Schedule" to send later
- Confirm sending

### Email Templates

Create reusable templates:

1. **Create Template**
   - Navigate to Email Templates
   - Click "Create Template"
   - Enter template details:
     ```
     Name: Committee Meeting Reminder
     Subject: {{committee_name}} Meeting - {{date}}
     Body: [Template with placeholders]
     ```

2. **Use Template**
   - When composing email
   - Click "Use Template"
   - Select template
   - Customize as needed

3. **Manage Templates**
   - Edit existing templates
   - Delete unused templates
   - Share templates with other admins

---

## Best Practices

### 1. Committee Mailing Lists

**Do:**
- Create a mailing list for each committee
- Set list type to "Committee"
- Enable auto-subscribe for committee members
- Configure email permissions for appropriate positions
- Use descriptive list names

**Don't:**
- Create multiple lists for the same committee
- Make committee lists public
- Give all positions email sending permissions
- Manually manage committee list subscriptions

### 2. Email Permissions

**Do:**
- Grant permissions to leadership positions (Chair, Coordinator)
- Allow personal email for chairs/leaders
- Document who has email permissions
- Review permissions regularly
- Train authorized senders

**Don't:**
- Give everyone email permissions
- Allow personal email for all positions
- Forget to revoke permissions when positions change
- Grant permissions without training

### 3. Email Personalization

**Do:**
- Use personalization to make emails more engaging
- Test personalization with sample data
- Provide fallback values for missing fields
- Use appropriate fields for context
- Keep personalization simple

**Don't:**
- Overuse personalization (looks spammy)
- Use sensitive fields inappropriately
- Forget to test personalization
- Use fields that might be empty

### 4. Subscription Management

**Do:**
- Let members manage their own subscriptions (for public lists)
- Respect unsubscribe requests
- Keep subscription lists clean
- Remove bounced emails
- Monitor subscription trends

**Don't:**
- Force subscriptions (except committee lists)
- Ignore unsubscribe requests
- Keep inactive subscribers
- Share subscription lists
- Spam members

### 5. Email Content

**Do:**
- Write clear, concise emails
- Use descriptive subject lines
- Include call-to-action
- Proofread before sending
- Test emails before sending to full list

**Don't:**
- Send too frequently
- Use all caps or excessive punctuation
- Include large attachments
- Send without proofreading
- Forget to include unsubscribe link (for non-committee lists)

---

## Troubleshooting

### Member Not Receiving Committee Emails

**Possible Causes:**
1. Member not added to committee
2. Mailing list not created for committee
3. Email bouncing
4. Email in spam folder
5. Wrong email address

**Solutions:**
1. Verify member is in committee
2. Check mailing list exists and is linked to committee
3. Check email delivery logs
4. Ask member to check spam folder
5. Verify email address in profile

### Cannot Send Email to Committee List

**Possible Causes:**
1. Position doesn't have email permissions
2. Not a member of the committee
3. Mailing list is disabled
4. Email service issue

**Solutions:**
1. Check email permissions for your position
2. Verify you're a committee member
3. Check mailing list is active
4. Contact administrator

### Personalization Fields Not Working

**Possible Causes:**
1. Incorrect field syntax
2. Field doesn't exist in database
3. Field is empty for some members
4. Template not saved properly

**Solutions:**
1. Check field syntax: `{{field_name}}`
2. Use only available fields
3. Provide fallback values
4. Save and test template

### Auto-Subscribe Not Working

**Possible Causes:**
1. Mailing list not linked to committee
2. Auto-subscribe disabled
3. Database trigger not working
4. Member already subscribed

**Solutions:**
1. Check mailing list committee link
2. Enable auto-subscribe in list settings
3. Check database logs
4. Verify subscription status

---

## API Reference

### Get Mailing Lists

```typescript
GET /api/mailing-lists

Response:
{
  "lists": [
    {
      "id": "uuid",
      "name": "Board of Directors",
      "list_type": "committee",
      "committee_id": "uuid",
      "subscriber_count": 12
    }
  ]
}
```

### Get Committee Email Permissions

```typescript
GET /api/committees/:id/email-permissions

Response:
{
  "permissions": [
    {
      "position_id": "uuid",
      "position_title": "Chair",
      "can_send_email": true,
      "can_use_personal_email": true
    }
  ]
}
```

### Send Email to List

```typescript
POST /api/mailing-lists/:id/send

Request:
{
  "subject": "Meeting Reminder",
  "body": "Dear {{first_name}}, ...",
  "from_email": "chair@example.com",
  "use_personal_email": true
}

Response:
{
  "success": true,
  "sent_count": 12,
  "failed_count": 0
}
```

---

## Examples

### Example 1: Setting Up Board Mailing List

```typescript
// 1. Create committee
const committee = await createCommittee({
  name: "Board of Directors",
  description: "Governing body"
});

// 2. Create positions
const chairPosition = await createPosition({
  committee_id: committee.id,
  title: "Chair"
});

// 3. Set email permissions
await setEmailPermissions({
  position_id: chairPosition.id,
  can_send_email: true,
  can_use_personal_email: true
});

// 4. Create mailing list
const mailingList = await createMailingList({
  name: "Board of Directors Mailing List",
  list_type: "committee",
  committee_id: committee.id,
  is_public: false,
  auto_subscribe: true
});

// 5. Add members (automatically subscribed)
await addCommitteeMember({
  committee_id: committee.id,
  position_id: chairPosition.id,
  profile_id: member.id
});
```

### Example 2: Sending Personalized Email

```typescript
// Compose email with personalization
const email = {
  subject: "Welcome to {{committee_name}}, {{first_name}}!",
  body: `
    Dear {{first_name}} {{last_name}},
    
    Welcome to the {{committee_name}}! We're excited to have you 
    join us as {{position_title}}.
    
    Your first meeting is on {{meeting_date}}.
    
    Best regards,
    {{org_name}}
  `,
  from_email: "chair@example.com",
  use_personal_email: true
};

// Send to committee list
await sendToMailingList(mailingList.id, email);
```

---

## Support

For questions about mailing lists:
- Check this guide first
- Review the [Administrator Guide](ADMINISTRATOR_GUIDE.md)
- Contact support: support@choo.org
- GitHub Issues: https://github.com/wjlander/choo/issues

---

**Last Updated**: October 2025  
**Version**: 1.0.0