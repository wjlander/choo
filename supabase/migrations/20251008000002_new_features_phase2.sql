/*
  # New Features - Phase 2: Moderate Additions
  
  This migration adds database support for:
  1. QR Code Event Check-In System
  2. Two-Factor Authentication Support
  3. Member Onboarding Workflow
  4. Custom Organization Branding
  
  Tables:
  - onboarding_tasks
  - member_onboarding_progress
  
  Columns:
  - event_registrations: qr_code, checked_in_at, checked_in_by
  - organizations: branding fields
  - profiles: 2FA fields
*/

-- ============================================================================
-- QR CODE EVENT CHECK-IN SYSTEM
-- ============================================================================

-- Add QR code and check-in fields to event_registrations
ALTER TABLE event_registrations ADD COLUMN IF NOT EXISTS qr_code text UNIQUE;
ALTER TABLE event_registrations ADD COLUMN IF NOT EXISTS checked_in_at timestamptz;
ALTER TABLE event_registrations ADD COLUMN IF NOT EXISTS checked_in_by uuid REFERENCES profiles(id);
ALTER TABLE event_registrations ADD COLUMN IF NOT EXISTS check_in_location text;
ALTER TABLE event_registrations ADD COLUMN IF NOT EXISTS check_in_notes text;

-- Create index for QR code lookups
CREATE INDEX IF NOT EXISTS idx_event_registrations_qr_code ON event_registrations(qr_code);
CREATE INDEX IF NOT EXISTS idx_event_registrations_checked_in ON event_registrations(checked_in_at);

-- Function to generate unique QR code
CREATE OR REPLACE FUNCTION generate_event_qr_code()
RETURNS text AS $$
DECLARE
    qr_code text;
    exists boolean;
BEGIN
    LOOP
        -- Generate random alphanumeric code (12 characters)
        qr_code := upper(substring(md5(random()::text || clock_timestamp()::text) from 1 for 12));
        
        -- Check if code already exists
        SELECT EXISTS(SELECT 1 FROM event_registrations WHERE qr_code = qr_code) INTO exists;
        
        EXIT WHEN NOT exists;
    END LOOP;
    
    RETURN qr_code;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-generate QR code on registration
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

-- Function to check in attendee via QR code
CREATE OR REPLACE FUNCTION check_in_attendee(
    p_qr_code text,
    p_checked_in_by uuid,
    p_location text DEFAULT NULL,
    p_notes text DEFAULT NULL
)
RETURNS json AS $$
DECLARE
    v_registration event_registrations%ROWTYPE;
    v_event events%ROWTYPE;
    v_member profiles%ROWTYPE;
BEGIN
    -- Get registration
    SELECT * INTO v_registration
    FROM event_registrations
    WHERE qr_code = p_qr_code;
    
    IF NOT FOUND THEN
        RETURN json_build_object('success', false, 'message', 'Invalid QR code');
    END IF;
    
    -- Check if already checked in
    IF v_registration.checked_in_at IS NOT NULL THEN
        RETURN json_build_object(
            'success', false,
            'message', 'Already checked in',
            'checked_in_at', v_registration.checked_in_at
        );
    END IF;
    
    -- Get event details
    SELECT * INTO v_event FROM events WHERE id = v_registration.event_id;
    
    -- Get member details
    SELECT * INTO v_member FROM profiles WHERE id = v_registration.member_id;
    
    -- Update registration
    UPDATE event_registrations
    SET
        checked_in_at = now(),
        checked_in_by = p_checked_in_by,
        check_in_location = p_location,
        check_in_notes = p_notes
    WHERE id = v_registration.id;
    
    -- Log to communication history
    INSERT INTO communication_log (
        organization_id,
        member_id,
        type,
        subject,
        content,
        created_by,
        metadata
    ) VALUES (
        v_event.organization_id,
        v_registration.member_id,
        'event',
        'Event Check-In',
        'Checked in to event: ' || v_event.title,
        p_checked_in_by,
        json_build_object(
            'event_id', v_event.id,
            'event_title', v_event.title,
            'check_in_location', p_location
        )
    );
    
    RETURN json_build_object(
        'success', true,
        'message', 'Check-in successful',
        'member_name', v_member.first_name || ' ' || v_member.last_name,
        'event_title', v_event.title,
        'checked_in_at', now()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION check_in_attendee TO authenticated;

-- ============================================================================
-- TWO-FACTOR AUTHENTICATION SUPPORT
-- ============================================================================

-- Add 2FA fields to profiles
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS two_factor_enabled boolean DEFAULT false;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS two_factor_secret text;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS backup_codes text[];
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS two_factor_enabled_at timestamptz;

-- Create index for 2FA lookups
CREATE INDEX IF NOT EXISTS idx_profiles_two_factor_enabled ON profiles(two_factor_enabled);

-- ============================================================================
-- MEMBER ONBOARDING WORKFLOW
-- ============================================================================

-- Onboarding tasks table
CREATE TABLE IF NOT EXISTS onboarding_tasks (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE,
    title text NOT NULL,
    description text,
    order_index integer NOT NULL DEFAULT 0,
    is_required boolean DEFAULT false,
    task_type text DEFAULT 'manual' CHECK (task_type IN ('manual', 'automatic')),
    completion_criteria jsonb DEFAULT '{}',
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Member onboarding progress table
CREATE TABLE IF NOT EXISTS member_onboarding_progress (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    member_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    task_id uuid REFERENCES onboarding_tasks(id) ON DELETE CASCADE,
    completed_at timestamptz,
    completion_notes text,
    UNIQUE(member_id, task_id)
);

-- Indexes for onboarding
CREATE INDEX IF NOT EXISTS idx_onboarding_tasks_organization ON onboarding_tasks(organization_id);
CREATE INDEX IF NOT EXISTS idx_onboarding_tasks_order ON onboarding_tasks(order_index);
CREATE INDEX IF NOT EXISTS idx_member_onboarding_progress_member ON member_onboarding_progress(member_id);
CREATE INDEX IF NOT EXISTS idx_member_onboarding_progress_task ON member_onboarding_progress(task_id);

-- RLS policies for onboarding tasks
ALTER TABLE onboarding_tasks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view onboarding tasks in their organization"
    ON onboarding_tasks FOR SELECT
    USING (
        organization_id IN (
            SELECT organization_id FROM profiles WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Admins can manage onboarding tasks"
    ON onboarding_tasks FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE user_id = auth.uid()
            AND organization_id = onboarding_tasks.organization_id
            AND role IN ('admin', 'super_admin')
        )
    );

-- RLS policies for onboarding progress
ALTER TABLE member_onboarding_progress ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members can view their own onboarding progress"
    ON member_onboarding_progress FOR SELECT
    USING (
        member_id IN (
            SELECT id FROM profiles WHERE user_id = auth.uid()
        )
        OR
        EXISTS (
            SELECT 1 FROM profiles p1
            JOIN profiles p2 ON p2.id = member_onboarding_progress.member_id
            WHERE p1.user_id = auth.uid()
            AND p1.organization_id = p2.organization_id
            AND p1.role IN ('admin', 'super_admin')
        )
    );

CREATE POLICY "Members can update their own onboarding progress"
    ON member_onboarding_progress FOR UPDATE
    USING (
        member_id IN (
            SELECT id FROM profiles WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "System can create onboarding progress"
    ON member_onboarding_progress FOR INSERT
    WITH CHECK (true);

-- Function to get member onboarding status
CREATE OR REPLACE FUNCTION get_member_onboarding_status(p_member_id uuid)
RETURNS json AS $$
DECLARE
    v_total_tasks integer;
    v_completed_tasks integer;
    v_required_tasks integer;
    v_completed_required integer;
    v_organization_id uuid;
BEGIN
    -- Get member's organization
    SELECT organization_id INTO v_organization_id
    FROM profiles
    WHERE id = p_member_id;
    
    -- Count total tasks
    SELECT COUNT(*) INTO v_total_tasks
    FROM onboarding_tasks
    WHERE organization_id = v_organization_id;
    
    -- Count completed tasks
    SELECT COUNT(*) INTO v_completed_tasks
    FROM member_onboarding_progress
    WHERE member_id = p_member_id
    AND completed_at IS NOT NULL;
    
    -- Count required tasks
    SELECT COUNT(*) INTO v_required_tasks
    FROM onboarding_tasks
    WHERE organization_id = v_organization_id
    AND is_required = true;
    
    -- Count completed required tasks
    SELECT COUNT(*) INTO v_completed_required
    FROM member_onboarding_progress mop
    JOIN onboarding_tasks ot ON ot.id = mop.task_id
    WHERE mop.member_id = p_member_id
    AND mop.completed_at IS NOT NULL
    AND ot.is_required = true;
    
    RETURN json_build_object(
        'total_tasks', v_total_tasks,
        'completed_tasks', v_completed_tasks,
        'required_tasks', v_required_tasks,
        'completed_required', v_completed_required,
        'completion_percentage', CASE WHEN v_total_tasks > 0 THEN (v_completed_tasks::float / v_total_tasks * 100)::integer ELSE 0 END,
        'is_complete', v_completed_required >= v_required_tasks
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION get_member_onboarding_status TO authenticated;

-- Trigger to create onboarding progress for new members
CREATE OR REPLACE FUNCTION initialize_member_onboarding()
RETURNS TRIGGER AS $$
BEGIN
    -- Create progress entries for all onboarding tasks
    INSERT INTO member_onboarding_progress (member_id, task_id)
    SELECT NEW.id, ot.id
    FROM onboarding_tasks ot
    WHERE ot.organization_id = NEW.organization_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_initialize_member_onboarding
    AFTER INSERT ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION initialize_member_onboarding();

-- ============================================================================
-- CUSTOM ORGANIZATION BRANDING
-- ============================================================================

-- Add branding fields to organizations table
ALTER TABLE organizations ADD COLUMN IF NOT EXISTS logo_url text;
ALTER TABLE organizations ADD COLUMN IF NOT EXISTS favicon_url text;
ALTER TABLE organizations ADD COLUMN IF NOT EXISTS font_family text DEFAULT 'Inter';
ALTER TABLE organizations ADD COLUMN IF NOT EXISTS email_header_html text;
ALTER TABLE organizations ADD COLUMN IF NOT EXISTS email_footer_html text;
ALTER TABLE organizations ADD COLUMN IF NOT EXISTS custom_css text;
ALTER TABLE organizations ADD COLUMN IF NOT EXISTS theme_config jsonb DEFAULT '{}';

-- Note: primary_color and secondary_color already exist in organizations table

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Trigger for updated_at on onboarding_tasks
CREATE TRIGGER update_onboarding_tasks_updated_at
    BEFORE UPDATE ON onboarding_tasks
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- ANALYTICS FUNCTIONS
-- ============================================================================

-- Function to get event check-in statistics
CREATE OR REPLACE FUNCTION get_event_checkin_stats(p_event_id uuid)
RETURNS json AS $$
DECLARE
    v_total_registrations integer;
    v_checked_in integer;
    v_not_checked_in integer;
BEGIN
    SELECT COUNT(*) INTO v_total_registrations
    FROM event_registrations
    WHERE event_id = p_event_id;
    
    SELECT COUNT(*) INTO v_checked_in
    FROM event_registrations
    WHERE event_id = p_event_id
    AND checked_in_at IS NOT NULL;
    
    v_not_checked_in := v_total_registrations - v_checked_in;
    
    RETURN json_build_object(
        'total_registrations', v_total_registrations,
        'checked_in', v_checked_in,
        'not_checked_in', v_not_checked_in,
        'check_in_rate', CASE WHEN v_total_registrations > 0 THEN (v_checked_in::float / v_total_registrations * 100)::integer ELSE 0 END
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION get_event_checkin_stats TO authenticated;

-- Function to get organization onboarding statistics
CREATE OR REPLACE FUNCTION get_organization_onboarding_stats(p_organization_id uuid)
RETURNS json AS $$
DECLARE
    v_total_members integer;
    v_completed_onboarding integer;
    v_in_progress integer;
BEGIN
    SELECT COUNT(*) INTO v_total_members
    FROM profiles
    WHERE organization_id = p_organization_id
    AND role = 'member';
    
    SELECT COUNT(DISTINCT mop.member_id) INTO v_completed_onboarding
    FROM member_onboarding_progress mop
    JOIN profiles p ON p.id = mop.member_id
    JOIN onboarding_tasks ot ON ot.id = mop.task_id
    WHERE p.organization_id = p_organization_id
    AND ot.is_required = true
    AND mop.completed_at IS NOT NULL
    GROUP BY mop.member_id
    HAVING COUNT(*) = (
        SELECT COUNT(*) FROM onboarding_tasks
        WHERE organization_id = p_organization_id
        AND is_required = true
    );
    
    v_in_progress := v_total_members - v_completed_onboarding;
    
    RETURN json_build_object(
        'total_members', v_total_members,
        'completed_onboarding', v_completed_onboarding,
        'in_progress', v_in_progress,
        'completion_rate', CASE WHEN v_total_members > 0 THEN (v_completed_onboarding::float / v_total_members * 100)::integer ELSE 0 END
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION get_organization_onboarding_stats TO authenticated;