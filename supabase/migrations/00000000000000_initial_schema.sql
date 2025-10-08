/*
  # Choo Membership Management System - Complete Database Schema
  
  This migration creates the complete database schema from scratch for a single organization.
  
  ## Features
  - Single organization mode (no multi-tenancy)
  - Feature toggle system for admins
  - Enhanced mailing list system with committee integration
  - All membership management features
  - Events, committees, documents, analytics
  - Payment processing, surveys, volunteers
  
  ## Tables Created
  1. Core: profiles, memberships, membership_types, membership_years
  2. Features: feature_settings
  3. Communications: email_campaigns, email_templates, email_workflows, notifications
  4. Mailing Lists: mailing_lists, mailing_list_subscribers, committee_mailing_permissions
  5. Events: events, event_registrations
  6. Committees: committees, committee_positions, committee_members
  7. Documents: documents, document_folders, document_versions, document_downloads
  8. Analytics: member_badges, badge_criteria, member_badge_awards, custom_reports
  9. Tags: member_tags, member_tag_assignments
  10. Communication: communication_log
  11. Onboarding: onboarding_tasks, member_onboarding_progress
  12. Surveys: surveys, survey_questions, survey_responses
  13. Volunteers: volunteer_opportunities, volunteer_shifts, volunteer_assignments
  14. Referrals: referrals
  15. Payments: payments, payment_methods
*/

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- CORE TABLES
-- ============================================================================

-- User profiles (single organization)
CREATE TABLE IF NOT EXISTS profiles (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
    email text NOT NULL UNIQUE,
    first_name text NOT NULL,
    last_name text NOT NULL,
    phone text,
    address jsonb,
    role text DEFAULT 'member' CHECK (role IN ('member', 'admin', 'super_admin')),
    is_active boolean DEFAULT true,
    two_factor_enabled boolean DEFAULT false,
    two_factor_secret text,
    backup_codes text[],
    two_factor_enabled_at timestamptz,
    metadata jsonb DEFAULT '{}',
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Membership types
CREATE TABLE IF NOT EXISTS membership_types (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name text NOT NULL UNIQUE,
    description text,
    price decimal(10,2),
    duration_months integer DEFAULT 12,
    benefits jsonb DEFAULT '[]',
    is_active boolean DEFAULT true,
    display_order integer DEFAULT 0,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Membership years
CREATE TABLE IF NOT EXISTS membership_years (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    year integer NOT NULL UNIQUE,
    start_date date NOT NULL,
    end_date date NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now()
);

-- Memberships (annual membership tracking)
CREATE TABLE IF NOT EXISTS memberships (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    membership_type_id uuid REFERENCES membership_types(id),
    membership_year integer NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    status text DEFAULT 'active' CHECK (status IN ('active', 'expired', 'cancelled', 'pending')),
    amount_paid decimal(10,2),
    payment_date timestamptz,
    payment_reference text,
    notes text,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    UNIQUE(profile_id, membership_year)
);

-- Linked members (for family memberships)
CREATE TABLE IF NOT EXISTS linked_members (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    primary_member_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    linked_member_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    relationship text,
    created_at timestamptz DEFAULT now(),
    UNIQUE(primary_member_id, linked_member_id)
);

-- ============================================================================
-- FEATURE TOGGLE SYSTEM
-- ============================================================================

CREATE TABLE IF NOT EXISTS feature_settings (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    feature_key text NOT NULL UNIQUE,
    feature_name text NOT NULL,
    description text,
    is_enabled boolean DEFAULT true,
    category text DEFAULT 'general',
    display_order integer DEFAULT 0,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Insert default features
INSERT INTO feature_settings (feature_key, feature_name, description, category, display_order) VALUES
('events', 'Events Management', 'Enable event creation, registration, and management', 'core', 1),
('committees', 'Committees & Groups', 'Enable committee management and positions', 'core', 2),
('documents', 'Document Library', 'Enable document upload and management', 'core', 3),
('mailing_lists', 'Mailing Lists', 'Enable email campaigns and mailing lists', 'communications', 4),
('notifications', 'In-App Notifications', 'Enable notification center', 'communications', 5),
('analytics', 'Analytics & Reports', 'Enable advanced analytics dashboard', 'reporting', 6),
('badges', 'Member Badges', 'Enable achievement badges system', 'engagement', 7),
('tags', 'Member Tags', 'Enable member tagging system', 'management', 8),
('calendar', 'Event Calendar', 'Enable calendar view for events', 'events', 9),
('qr_checkin', 'QR Code Check-In', 'Enable QR code event check-in', 'events', 10),
('certificates', 'Attendance Certificates', 'Enable PDF certificate generation', 'events', 11),
('surveys', 'Surveys & Feedback', 'Enable survey creation and responses', 'engagement', 12),
('volunteers', 'Volunteer Management', 'Enable volunteer shift management', 'engagement', 13),
('referrals', 'Referral Program', 'Enable member referral system', 'engagement', 14),
('payments', 'Payment Processing', 'Enable Stripe payment integration', 'financial', 15),
('ticketing', 'Event Ticketing', 'Enable paid event tickets', 'events', 16),
('onboarding', 'Member Onboarding', 'Enable onboarding workflow', 'management', 17),
('2fa', 'Two-Factor Authentication', 'Enable 2FA for enhanced security', 'security', 18),
('custom_branding', 'Custom Branding', 'Enable logo and color customization', 'appearance', 19),
('multi_language', 'Multi-Language Support', 'Enable multiple language support', 'localization', 20)
ON CONFLICT (feature_key) DO NOTHING;

-- ============================================================================
-- MAILING LISTS (Enhanced)
-- ============================================================================

CREATE TABLE IF NOT EXISTS mailing_lists (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name text NOT NULL UNIQUE,
    description text,
    list_type text DEFAULT 'general' CHECK (list_type IN ('general', 'committee', 'event', 'custom')),
    committee_id uuid REFERENCES committees(id) ON DELETE CASCADE,
    is_public boolean DEFAULT true,
    auto_subscribe_new_members boolean DEFAULT false,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS mailing_list_subscribers (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    mailing_list_id uuid REFERENCES mailing_lists(id) ON DELETE CASCADE,
    profile_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    email text NOT NULL,
    status text DEFAULT 'subscribed' CHECK (status IN ('subscribed', 'unsubscribed', 'bounced')),
    subscribed_at timestamptz DEFAULT now(),
    unsubscribed_at timestamptz,
    UNIQUE(mailing_list_id, profile_id)
);

-- Committee mailing permissions (who can send to committee lists)
CREATE TABLE IF NOT EXISTS committee_mailing_permissions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    committee_id uuid REFERENCES committees(id) ON DELETE CASCADE,
    position_id uuid REFERENCES committee_positions(id) ON DELETE CASCADE,
    can_send_email boolean DEFAULT true,
    can_use_personal_email boolean DEFAULT false,
    created_at timestamptz DEFAULT now(),
    UNIQUE(committee_id, position_id)
);

-- ============================================================================
-- EMAIL SYSTEM
-- ============================================================================

CREATE TABLE IF NOT EXISTS email_templates (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name text NOT NULL UNIQUE,
    subject text NOT NULL,
    body_html text NOT NULL,
    body_text text,
    template_type text CHECK (template_type IN ('welcome', 'renewal', 'expiry', 'event', 'custom')),
    variables jsonb DEFAULT '[]',
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS email_campaigns (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name text NOT NULL,
    subject text NOT NULL,
    content text NOT NULL,
    template_id uuid REFERENCES email_templates(id),
    mailing_list_id uuid REFERENCES mailing_lists(id),
    status text DEFAULT 'draft' CHECK (status IN ('draft', 'scheduled', 'sending', 'sent', 'cancelled')),
    scheduled_at timestamptz,
    sent_at timestamptz,
    recipient_count integer DEFAULT 0,
    delivered_count integer DEFAULT 0,
    opened_count integer DEFAULT 0,
    clicked_count integer DEFAULT 0,
    bounced_count integer DEFAULT 0,
    created_by uuid REFERENCES profiles(id),
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS email_workflows (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name text NOT NULL,
    trigger_type text NOT NULL CHECK (trigger_type IN ('signup', 'approval', 'renewal', 'expiry', 'event_registration')),
    template_id uuid REFERENCES email_templates(id),
    delay_days integer DEFAULT 0,
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- ============================================================================
-- NOTIFICATIONS
-- ============================================================================

CREATE TABLE IF NOT EXISTS notifications (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    title text NOT NULL,
    message text NOT NULL,
    type text DEFAULT 'info' CHECK (type IN ('info', 'success', 'warning', 'error')),
    link text,
    is_read boolean DEFAULT false,
    created_at timestamptz DEFAULT now()
);

-- ============================================================================
-- EVENTS
-- ============================================================================

CREATE TABLE IF NOT EXISTS events (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    title text NOT NULL,
    description text,
    event_date date NOT NULL,
    start_time time,
    end_time time,
    location text,
    capacity integer,
    registration_deadline timestamptz,
    is_public boolean DEFAULT true,
    requires_approval boolean DEFAULT false,
    created_by uuid REFERENCES profiles(id),
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS event_registrations (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id uuid REFERENCES events(id) ON DELETE CASCADE,
    profile_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    status text DEFAULT 'registered' CHECK (status IN ('registered', 'waitlist', 'cancelled', 'attended')),
    registration_date timestamptz DEFAULT now(),
    qr_code text UNIQUE,
    checked_in_at timestamptz,
    checked_in_by uuid REFERENCES profiles(id),
    check_in_location text,
    check_in_notes text,
    notes text,
    UNIQUE(event_id, profile_id)
);

-- ============================================================================
-- COMMITTEES
-- ============================================================================

CREATE TABLE IF NOT EXISTS committees (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name text NOT NULL UNIQUE,
    description text,
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS committee_positions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    committee_id uuid REFERENCES committees(id) ON DELETE CASCADE,
    title text NOT NULL,
    description text,
    responsibilities text,
    display_order integer DEFAULT 0,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS committee_members (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    committee_id uuid REFERENCES committees(id) ON DELETE CASCADE,
    position_id uuid REFERENCES committee_positions(id) ON DELETE CASCADE,
    profile_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    start_date date DEFAULT CURRENT_DATE,
    end_date date,
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now(),
    UNIQUE(committee_id, position_id, profile_id)
);

-- ============================================================================
-- DOCUMENTS
-- ============================================================================

CREATE TABLE IF NOT EXISTS document_folders (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name text NOT NULL,
    parent_folder_id uuid REFERENCES document_folders(id) ON DELETE CASCADE,
    description text,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS documents (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    title text NOT NULL,
    description text,
    file_url text NOT NULL,
    folder_id uuid REFERENCES document_folders(id),
    category text DEFAULT 'general',
    is_public boolean DEFAULT false,
    approval_status text DEFAULT 'approved' CHECK (approval_status IN ('pending', 'approved', 'rejected')),
    expires_at timestamptz,
    access_roles text[] DEFAULT '{"member"}',
    file_size bigint,
    mime_type text,
    uploaded_by uuid REFERENCES profiles(id),
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS document_versions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id uuid REFERENCES documents(id) ON DELETE CASCADE,
    version_number integer NOT NULL,
    file_url text NOT NULL,
    file_size bigint,
    uploaded_by uuid REFERENCES profiles(id),
    uploaded_at timestamptz DEFAULT now(),
    change_notes text,
    UNIQUE(document_id, version_number)
);

CREATE TABLE IF NOT EXISTS document_downloads (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id uuid REFERENCES documents(id) ON DELETE CASCADE,
    profile_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    downloaded_at timestamptz DEFAULT now(),
    ip_address inet,
    user_agent text
);

-- ============================================================================
-- MEMBER TAGS
-- ============================================================================

CREATE TABLE IF NOT EXISTS member_tags (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name text NOT NULL UNIQUE,
    color text DEFAULT '#3B82F6',
    description text,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS member_tag_assignments (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    tag_id uuid REFERENCES member_tags(id) ON DELETE CASCADE,
    assigned_at timestamptz DEFAULT now(),
    assigned_by uuid REFERENCES profiles(id),
    UNIQUE(profile_id, tag_id)
);

-- ============================================================================
-- COMMUNICATION LOG
-- ============================================================================

CREATE TABLE IF NOT EXISTS communication_log (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    type text NOT NULL CHECK (type IN ('email', 'note', 'event', 'status_change', 'system')),
    subject text,
    content text,
    metadata jsonb DEFAULT '{}',
    created_by uuid REFERENCES profiles(id),
    created_at timestamptz DEFAULT now()
);

-- ============================================================================
-- ONBOARDING
-- ============================================================================

CREATE TABLE IF NOT EXISTS onboarding_tasks (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    title text NOT NULL,
    description text,
    order_index integer NOT NULL DEFAULT 0,
    is_required boolean DEFAULT false,
    task_type text DEFAULT 'manual' CHECK (task_type IN ('manual', 'automatic')),
    completion_criteria jsonb DEFAULT '{}',
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS member_onboarding_progress (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    task_id uuid REFERENCES onboarding_tasks(id) ON DELETE CASCADE,
    completed_at timestamptz,
    completion_notes text,
    UNIQUE(profile_id, task_id)
);

-- ============================================================================
-- SURVEYS
-- ============================================================================

CREATE TABLE IF NOT EXISTS surveys (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    title text NOT NULL,
    description text,
    is_anonymous boolean DEFAULT false,
    status text DEFAULT 'draft' CHECK (status IN ('draft', 'active', 'closed')),
    created_by uuid REFERENCES profiles(id),
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    closes_at timestamptz
);

CREATE TABLE IF NOT EXISTS survey_questions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    survey_id uuid REFERENCES surveys(id) ON DELETE CASCADE,
    question_text text NOT NULL,
    question_type text NOT NULL CHECK (question_type IN ('multiple_choice', 'text', 'rating', 'checkbox', 'dropdown', 'date')),
    options jsonb,
    is_required boolean DEFAULT false,
    order_index integer NOT NULL DEFAULT 0,
    created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS survey_responses (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    survey_id uuid REFERENCES surveys(id) ON DELETE CASCADE,
    question_id uuid REFERENCES survey_questions(id) ON DELETE CASCADE,
    profile_id uuid REFERENCES profiles(id) ON DELETE SET NULL,
    response_value text,
    response_data jsonb,
    submitted_at timestamptz DEFAULT now()
);

-- ============================================================================
-- VOLUNTEERS
-- ============================================================================

CREATE TABLE IF NOT EXISTS volunteer_opportunities (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    title text NOT NULL,
    description text,
    category text,
    location text,
    requirements text,
    benefits text,
    is_active boolean DEFAULT true,
    created_by uuid REFERENCES profiles(id),
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS volunteer_shifts (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    opportunity_id uuid REFERENCES volunteer_opportunities(id) ON DELETE CASCADE,
    shift_date date NOT NULL,
    start_time time NOT NULL,
    end_time time NOT NULL,
    capacity integer,
    location text,
    notes text,
    created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS volunteer_assignments (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    shift_id uuid REFERENCES volunteer_shifts(id) ON DELETE CASCADE,
    profile_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    status text DEFAULT 'confirmed' CHECK (status IN ('confirmed', 'completed', 'cancelled', 'no_show')),
    hours_worked decimal(5,2),
    notes text,
    assigned_at timestamptz DEFAULT now(),
    completed_at timestamptz,
    UNIQUE(shift_id, profile_id)
);

-- ============================================================================
-- REFERRALS
-- ============================================================================

CREATE TABLE IF NOT EXISTS referrals (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    referrer_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    referred_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    referral_code text UNIQUE NOT NULL,
    status text DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'rewarded', 'expired')),
    reward_type text,
    reward_value text,
    created_at timestamptz DEFAULT now(),
    completed_at timestamptz,
    rewarded_at timestamptz,
    UNIQUE(referrer_id, referred_id)
);

-- ============================================================================
-- PAYMENTS
-- ============================================================================

CREATE TABLE IF NOT EXISTS payments (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    stripe_payment_id text UNIQUE,
    stripe_payment_intent_id text,
    amount decimal(10,2) NOT NULL,
    currency text DEFAULT 'USD',
    status text DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'refunded', 'cancelled')),
    payment_type text CHECK (payment_type IN ('membership', 'event', 'donation', 'other')),
    reference_id uuid,
    reference_type text,
    invoice_url text,
    receipt_url text,
    metadata jsonb DEFAULT '{}',
    created_at timestamptz DEFAULT now(),
    completed_at timestamptz,
    refunded_at timestamptz
);

CREATE TABLE IF NOT EXISTS payment_methods (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    stripe_payment_method_id text UNIQUE,
    type text CHECK (type IN ('card', 'bank_account', 'other')),
    last4 text,
    brand text,
    exp_month integer,
    exp_year integer,
    is_default boolean DEFAULT false,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- ============================================================================
-- ANALYTICS
-- ============================================================================

CREATE TABLE IF NOT EXISTS member_badges (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name text NOT NULL UNIQUE,
    description text,
    icon text,
    color text DEFAULT '#3B82F6',
    criteria jsonb DEFAULT '{}',
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS member_badge_awards (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    badge_id uuid REFERENCES member_badges(id) ON DELETE CASCADE,
    awarded_at timestamptz DEFAULT now(),
    awarded_by uuid REFERENCES profiles(id),
    notes text,
    UNIQUE(profile_id, badge_id)
);

CREATE TABLE IF NOT EXISTS custom_reports (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name text NOT NULL,
    description text,
    report_type text,
    filters jsonb DEFAULT '{}',
    columns jsonb DEFAULT '[]',
    created_by uuid REFERENCES profiles(id),
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Profiles
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_is_active ON profiles(is_active);

-- Memberships
CREATE INDEX IF NOT EXISTS idx_memberships_profile ON memberships(profile_id);
CREATE INDEX IF NOT EXISTS idx_memberships_year ON memberships(membership_year);
CREATE INDEX IF NOT EXISTS idx_memberships_status ON memberships(status);
CREATE INDEX IF NOT EXISTS idx_memberships_type ON memberships(membership_type_id);

-- Events
CREATE INDEX IF NOT EXISTS idx_events_date ON events(event_date);
CREATE INDEX IF NOT EXISTS idx_event_registrations_event ON event_registrations(event_id);
CREATE INDEX IF NOT EXISTS idx_event_registrations_profile ON event_registrations(profile_id);
CREATE INDEX IF NOT EXISTS idx_event_registrations_qr ON event_registrations(qr_code);

-- Committees
CREATE INDEX IF NOT EXISTS idx_committee_members_committee ON committee_members(committee_id);
CREATE INDEX IF NOT EXISTS idx_committee_members_profile ON committee_members(profile_id);
CREATE INDEX IF NOT EXISTS idx_committee_members_position ON committee_members(position_id);

-- Mailing Lists
CREATE INDEX IF NOT EXISTS idx_mailing_list_subscribers_list ON mailing_list_subscribers(mailing_list_id);
CREATE INDEX IF NOT EXISTS idx_mailing_list_subscribers_profile ON mailing_list_subscribers(profile_id);
CREATE INDEX IF NOT EXISTS idx_mailing_lists_committee ON mailing_lists(committee_id);

-- Documents
CREATE INDEX IF NOT EXISTS idx_documents_folder ON documents(folder_id);
CREATE INDEX IF NOT EXISTS idx_documents_category ON documents(category);
CREATE INDEX IF NOT EXISTS idx_document_downloads_document ON document_downloads(document_id);
CREATE INDEX IF NOT EXISTS idx_document_downloads_profile ON document_downloads(profile_id);

-- Tags
CREATE INDEX IF NOT EXISTS idx_member_tag_assignments_profile ON member_tag_assignments(profile_id);
CREATE INDEX IF NOT EXISTS idx_member_tag_assignments_tag ON member_tag_assignments(tag_id);

-- Communication
CREATE INDEX IF NOT EXISTS idx_communication_log_profile ON communication_log(profile_id);
CREATE INDEX IF NOT EXISTS idx_communication_log_type ON communication_log(type);
CREATE INDEX IF NOT EXISTS idx_communication_log_created ON communication_log(created_at DESC);

-- Notifications
CREATE INDEX IF NOT EXISTS idx_notifications_profile ON notifications(profile_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);

-- Surveys
CREATE INDEX IF NOT EXISTS idx_survey_questions_survey ON survey_questions(survey_id);
CREATE INDEX IF NOT EXISTS idx_survey_responses_survey ON survey_responses(survey_id);
CREATE INDEX IF NOT EXISTS idx_survey_responses_profile ON survey_responses(profile_id);

-- Volunteers
CREATE INDEX IF NOT EXISTS idx_volunteer_shifts_opportunity ON volunteer_shifts(opportunity_id);
CREATE INDEX IF NOT EXISTS idx_volunteer_assignments_shift ON volunteer_assignments(shift_id);
CREATE INDEX IF NOT EXISTS idx_volunteer_assignments_profile ON volunteer_assignments(profile_id);

-- Payments
CREATE INDEX IF NOT EXISTS idx_payments_profile ON payments(profile_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(status);
CREATE INDEX IF NOT EXISTS idx_payment_methods_profile ON payment_methods(profile_id);

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE membership_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE membership_years ENABLE ROW LEVEL SECURITY;
ALTER TABLE linked_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE feature_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE mailing_lists ENABLE ROW LEVEL SECURITY;
ALTER TABLE mailing_list_subscribers ENABLE ROW LEVEL SECURITY;
ALTER TABLE committee_mailing_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_workflows ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_registrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE committees ENABLE ROW LEVEL SECURITY;
ALTER TABLE committee_positions ENABLE ROW LEVEL SECURITY;
ALTER TABLE committee_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE document_folders ENABLE ROW LEVEL SECURITY;
ALTER TABLE document_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE document_downloads ENABLE ROW LEVEL SECURITY;
ALTER TABLE member_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE member_tag_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE communication_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE onboarding_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE member_onboarding_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE surveys ENABLE ROW LEVEL SECURITY;
ALTER TABLE survey_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE survey_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE volunteer_opportunities ENABLE ROW LEVEL SECURITY;
ALTER TABLE volunteer_shifts ENABLE ROW LEVEL SECURITY;
ALTER TABLE volunteer_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE referrals ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_methods ENABLE ROW LEVEL SECURITY;
ALTER TABLE member_badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE member_badge_awards ENABLE ROW LEVEL SECURITY;
ALTER TABLE custom_reports ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Users can view all profiles" ON profiles FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "Admins can manage all profiles" ON profiles FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE user_id = auth.uid() AND role IN ('admin', 'super_admin'))
);

-- Memberships policies
CREATE POLICY "Users can view all memberships" ON memberships FOR SELECT USING (true);
CREATE POLICY "Admins can manage memberships" ON memberships FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE user_id = auth.uid() AND role IN ('admin', 'super_admin'))
);

-- Membership types policies
CREATE POLICY "Everyone can view membership types" ON membership_types FOR SELECT USING (true);
CREATE POLICY "Admins can manage membership types" ON membership_types FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE user_id = auth.uid() AND role IN ('admin', 'super_admin'))
);

-- Feature settings policies
CREATE POLICY "Everyone can view feature settings" ON feature_settings FOR SELECT USING (true);
CREATE POLICY "Admins can manage feature settings" ON feature_settings FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE user_id = auth.uid() AND role IN ('admin', 'super_admin'))
);

-- Mailing lists policies
CREATE POLICY "Users can view public mailing lists" ON mailing_lists FOR SELECT USING (
    is_public = true OR
    EXISTS (SELECT 1 FROM profiles WHERE user_id = auth.uid() AND role IN ('admin', 'super_admin'))
);
CREATE POLICY "Admins can manage mailing lists" ON mailing_lists FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE user_id = auth.uid() AND role IN ('admin', 'super_admin'))
);

-- Mailing list subscribers policies
CREATE POLICY "Users can view their subscriptions" ON mailing_list_subscribers FOR SELECT USING (
    profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid()) OR
    EXISTS (SELECT 1 FROM profiles WHERE user_id = auth.uid() AND role IN ('admin', 'super_admin'))
);
CREATE POLICY "Users can manage their subscriptions" ON mailing_list_subscribers FOR INSERT WITH CHECK (
    profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())
);
CREATE POLICY "Users can unsubscribe" ON mailing_list_subscribers FOR UPDATE USING (
    profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())
);
CREATE POLICY "Admins can manage all subscriptions" ON mailing_list_subscribers FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE user_id = auth.uid() AND role IN ('admin', 'super_admin'))
);

-- Events policies
CREATE POLICY "Users can view public events" ON events FOR SELECT USING (is_public = true);
CREATE POLICY "Admins can manage events" ON events FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE user_id = auth.uid() AND role IN ('admin', 'super_admin'))
);

-- Event registrations policies
CREATE POLICY "Users can view their registrations" ON event_registrations FOR SELECT USING (
    profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid()) OR
    EXISTS (SELECT 1 FROM profiles WHERE user_id = auth.uid() AND role IN ('admin', 'super_admin'))
);
CREATE POLICY "Users can register for events" ON event_registrations FOR INSERT WITH CHECK (
    profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())
);
CREATE POLICY "Admins can manage registrations" ON event_registrations FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE user_id = auth.uid() AND role IN ('admin', 'super_admin'))
);

-- Committees policies
CREATE POLICY "Everyone can view committees" ON committees FOR SELECT USING (true);
CREATE POLICY "Admins can manage committees" ON committees FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE user_id = auth.uid() AND role IN ('admin', 'super_admin'))
);

-- Documents policies
CREATE POLICY "Users can view public documents" ON documents FOR SELECT USING (
    is_public = true OR
    EXISTS (SELECT 1 FROM profiles WHERE user_id = auth.uid() AND role IN ('admin', 'super_admin'))
);
CREATE POLICY "Admins can manage documents" ON documents FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE user_id = auth.uid() AND role IN ('admin', 'super_admin'))
);

-- Notifications policies
CREATE POLICY "Users can view their notifications" ON notifications FOR SELECT USING (
    profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())
);
CREATE POLICY "Users can update their notifications" ON notifications FOR UPDATE USING (
    profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())
);

-- Surveys policies
CREATE POLICY "Users can view active surveys" ON surveys FOR SELECT USING (
    status = 'active' OR
    EXISTS (SELECT 1 FROM profiles WHERE user_id = auth.uid() AND role IN ('admin', 'super_admin'))
);
CREATE POLICY "Admins can manage surveys" ON surveys FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE user_id = auth.uid() AND role IN ('admin', 'super_admin'))
);

-- Survey responses policies
CREATE POLICY "Users can submit responses" ON survey_responses FOR INSERT WITH CHECK (
    profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid()) OR profile_id IS NULL
);
CREATE POLICY "Users can view their responses" ON survey_responses FOR SELECT USING (
    profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid()) OR
    EXISTS (SELECT 1 FROM profiles WHERE user_id = auth.uid() AND role IN ('admin', 'super_admin'))
);

-- Payments policies
CREATE POLICY "Users can view their payments" ON payments FOR SELECT USING (
    profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid()) OR
    EXISTS (SELECT 1 FROM profiles WHERE user_id = auth.uid() AND role IN ('admin', 'super_admin'))
);
CREATE POLICY "System can create payments" ON payments FOR INSERT WITH CHECK (true);

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

-- Updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Add updated_at triggers
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_memberships_updated_at BEFORE UPDATE ON memberships FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_membership_types_updated_at BEFORE UPDATE ON membership_types FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_feature_settings_updated_at BEFORE UPDATE ON feature_settings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_mailing_lists_updated_at BEFORE UPDATE ON mailing_lists FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_email_templates_updated_at BEFORE UPDATE ON email_templates FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_email_campaigns_updated_at BEFORE UPDATE ON email_campaigns FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_email_workflows_updated_at BEFORE UPDATE ON email_workflows FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_events_updated_at BEFORE UPDATE ON events FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_committees_updated_at BEFORE UPDATE ON committees FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_committee_positions_updated_at BEFORE UPDATE ON committee_positions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_documents_updated_at BEFORE UPDATE ON documents FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_document_folders_updated_at BEFORE UPDATE ON document_folders FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_member_tags_updated_at BEFORE UPDATE ON member_tags FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_onboarding_tasks_updated_at BEFORE UPDATE ON onboarding_tasks FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_surveys_updated_at BEFORE UPDATE ON surveys FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_volunteer_opportunities_updated_at BEFORE UPDATE ON volunteer_opportunities FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_payment_methods_updated_at BEFORE UPDATE ON payment_methods FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Auto-generate QR code for event registrations
CREATE OR REPLACE FUNCTION generate_event_qr_code()
RETURNS text AS $$
DECLARE
    qr_code text;
    exists boolean;
BEGIN
    LOOP
        qr_code := upper(substring(md5(random()::text || clock_timestamp()::text) from 1 for 12));
        SELECT EXISTS(SELECT 1 FROM event_registrations WHERE qr_code = qr_code) INTO exists;
        EXIT WHEN NOT exists;
    END LOOP;
    RETURN qr_code;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION set_event_registration_qr_code()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.qr_code IS NULL THEN
        NEW.qr_code := generate_event_qr_code();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_set_event_registration_qr_code
    BEFORE INSERT ON event_registrations
    FOR EACH ROW
    EXECUTE FUNCTION set_event_registration_qr_code();

-- Auto-add committee members to committee mailing list
CREATE OR REPLACE FUNCTION auto_add_committee_member_to_mailing_list()
RETURNS TRIGGER AS $$
DECLARE
    v_mailing_list_id uuid;
    v_profile_email text;
BEGIN
    -- Get committee mailing list
    SELECT id INTO v_mailing_list_id
    FROM mailing_lists
    WHERE committee_id = NEW.committee_id
    AND list_type = 'committee';
    
    -- Get member email
    SELECT email INTO v_profile_email
    FROM profiles
    WHERE id = NEW.profile_id;
    
    -- Add to mailing list if exists
    IF v_mailing_list_id IS NOT NULL AND v_profile_email IS NOT NULL THEN
        INSERT INTO mailing_list_subscribers (mailing_list_id, profile_id, email, status)
        VALUES (v_mailing_list_id, NEW.profile_id, v_profile_email, 'subscribed')
        ON CONFLICT (mailing_list_id, profile_id) DO NOTHING;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_auto_add_committee_member_to_mailing_list
    AFTER INSERT ON committee_members
    FOR EACH ROW
    EXECUTE FUNCTION auto_add_committee_member_to_mailing_list();

-- Remove committee member from mailing list when removed from committee
CREATE OR REPLACE FUNCTION auto_remove_committee_member_from_mailing_list()
RETURNS TRIGGER AS $$
DECLARE
    v_mailing_list_id uuid;
BEGIN
    -- Get committee mailing list
    SELECT id INTO v_mailing_list_id
    FROM mailing_lists
    WHERE committee_id = OLD.committee_id
    AND list_type = 'committee';
    
    -- Remove from mailing list if exists
    IF v_mailing_list_id IS NOT NULL THEN
        DELETE FROM mailing_list_subscribers
        WHERE mailing_list_id = v_mailing_list_id
        AND profile_id = OLD.profile_id;
    END IF;
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_auto_remove_committee_member_from_mailing_list
    AFTER DELETE ON committee_members
    FOR EACH ROW
    EXECUTE FUNCTION auto_remove_committee_member_from_mailing_list();

-- Initialize onboarding for new members
CREATE OR REPLACE FUNCTION initialize_member_onboarding()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO member_onboarding_progress (profile_id, task_id)
    SELECT NEW.id, ot.id
    FROM onboarding_tasks ot;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_initialize_member_onboarding
    AFTER INSERT ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION initialize_member_onboarding();

-- Check if feature is enabled
CREATE OR REPLACE FUNCTION is_feature_enabled(p_feature_key text)
RETURNS boolean AS $$
DECLARE
    v_enabled boolean;
BEGIN
    SELECT is_enabled INTO v_enabled
    FROM feature_settings
    WHERE feature_key = p_feature_key;
    
    RETURN COALESCE(v_enabled, false);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION is_feature_enabled TO authenticated;

-- Check if user can send to committee mailing list
CREATE OR REPLACE FUNCTION can_send_to_committee_list(
    p_profile_id uuid,
    p_committee_id uuid
)
RETURNS boolean AS $$
DECLARE
    v_can_send boolean;
BEGIN
    SELECT EXISTS (
        SELECT 1
        FROM committee_members cm
        JOIN committee_mailing_permissions cmp ON cmp.position_id = cm.position_id
        WHERE cm.profile_id = p_profile_id
        AND cm.committee_id = p_committee_id
        AND cm.is_active = true
        AND cmp.can_send_email = true
    ) INTO v_can_send;
    
    RETURN v_can_send;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION can_send_to_committee_list TO authenticated;

-- Get member's committee positions with email permissions
CREATE OR REPLACE FUNCTION get_member_email_permissions(p_profile_id uuid)
RETURNS TABLE (
    committee_id uuid,
    committee_name text,
    position_title text,
    can_send_email boolean,
    can_use_personal_email boolean
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.id as committee_id,
        c.name as committee_name,
        cp.title as position_title,
        cmp.can_send_email,
        cmp.can_use_personal_email
    FROM committee_members cm
    JOIN committees c ON c.id = cm.committee_id
    JOIN committee_positions cp ON cp.id = cm.position_id
    LEFT JOIN committee_mailing_permissions cmp ON cmp.position_id = cm.position_id
    WHERE cm.profile_id = p_profile_id
    AND cm.is_active = true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION get_member_email_permissions TO authenticated;