/*
  # New Features - Phase 3: Advanced Features
  
  This migration adds database support for:
  1. Survey & Feedback System
  2. Volunteer Management System
  3. Member Referral Program
  4. Payment Integration (Stripe)
  
  Tables:
  - surveys
  - survey_questions
  - survey_responses
  - volunteer_opportunities
  - volunteer_shifts
  - volunteer_assignments
  - referrals
  - payments
  - payment_methods
*/

-- ============================================================================
-- SURVEY & FEEDBACK SYSTEM
-- ============================================================================

-- Surveys table
CREATE TABLE IF NOT EXISTS surveys (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE,
    title text NOT NULL,
    description text,
    is_anonymous boolean DEFAULT false,
    status text DEFAULT 'draft' CHECK (status IN ('draft', 'active', 'closed')),
    created_by uuid REFERENCES profiles(id),
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    closes_at timestamptz
);

-- Survey questions table
CREATE TABLE IF NOT EXISTS survey_questions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    survey_id uuid REFERENCES surveys(id) ON DELETE CASCADE,
    question_text text NOT NULL,
    question_type text NOT NULL CHECK (question_type IN ('multiple_choice', 'text', 'rating', 'checkbox', 'dropdown', 'date')),
    options jsonb, -- for multiple choice, dropdown, checkbox
    is_required boolean DEFAULT false,
    order_index integer NOT NULL DEFAULT 0,
    created_at timestamptz DEFAULT now()
);

-- Survey responses table
CREATE TABLE IF NOT EXISTS survey_responses (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    survey_id uuid REFERENCES surveys(id) ON DELETE CASCADE,
    question_id uuid REFERENCES survey_questions(id) ON DELETE CASCADE,
    member_id uuid REFERENCES profiles(id) ON DELETE SET NULL, -- null if anonymous
    response_value text,
    response_data jsonb, -- for complex responses
    submitted_at timestamptz DEFAULT now()
);

-- Indexes for surveys
CREATE INDEX IF NOT EXISTS idx_surveys_organization ON surveys(organization_id);
CREATE INDEX IF NOT EXISTS idx_surveys_status ON surveys(status);
CREATE INDEX IF NOT EXISTS idx_survey_questions_survey ON survey_questions(survey_id);
CREATE INDEX IF NOT EXISTS idx_survey_questions_order ON survey_questions(order_index);
CREATE INDEX IF NOT EXISTS idx_survey_responses_survey ON survey_responses(survey_id);
CREATE INDEX IF NOT EXISTS idx_survey_responses_member ON survey_responses(member_id);

-- RLS policies for surveys
ALTER TABLE surveys ENABLE ROW LEVEL SECURITY;
ALTER TABLE survey_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE survey_responses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view active surveys in their organization"
    ON surveys FOR SELECT
    USING (
        organization_id IN (
            SELECT organization_id FROM profiles WHERE user_id = auth.uid()
        )
        AND (status = 'active' OR EXISTS (
            SELECT 1 FROM profiles
            WHERE user_id = auth.uid()
            AND organization_id = surveys.organization_id
            AND role IN ('admin', 'super_admin')
        ))
    );

CREATE POLICY "Admins can manage surveys"
    ON surveys FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE user_id = auth.uid()
            AND organization_id = surveys.organization_id
            AND role IN ('admin', 'super_admin')
        )
    );

CREATE POLICY "Users can view questions for accessible surveys"
    ON survey_questions FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM surveys s
            JOIN profiles p ON p.organization_id = s.organization_id
            WHERE s.id = survey_questions.survey_id
            AND p.user_id = auth.uid()
        )
    );

CREATE POLICY "Admins can manage survey questions"
    ON survey_questions FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM surveys s
            JOIN profiles p ON p.organization_id = s.organization_id
            WHERE s.id = survey_questions.survey_id
            AND p.user_id = auth.uid()
            AND p.role IN ('admin', 'super_admin')
        )
    );

CREATE POLICY "Users can submit survey responses"
    ON survey_responses FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM surveys s
            JOIN profiles p ON p.organization_id = s.organization_id
            WHERE s.id = survey_responses.survey_id
            AND p.user_id = auth.uid()
            AND s.status = 'active'
        )
    );

CREATE POLICY "Users can view their own responses or admins can view all"
    ON survey_responses FOR SELECT
    USING (
        member_id IN (
            SELECT id FROM profiles WHERE user_id = auth.uid()
        )
        OR
        EXISTS (
            SELECT 1 FROM surveys s
            JOIN profiles p ON p.organization_id = s.organization_id
            WHERE s.id = survey_responses.survey_id
            AND p.user_id = auth.uid()
            AND p.role IN ('admin', 'super_admin')
        )
    );

-- ============================================================================
-- VOLUNTEER MANAGEMENT SYSTEM
-- ============================================================================

-- Volunteer opportunities table
CREATE TABLE IF NOT EXISTS volunteer_opportunities (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE,
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

-- Volunteer shifts table
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

-- Volunteer assignments table
CREATE TABLE IF NOT EXISTS volunteer_assignments (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    shift_id uuid REFERENCES volunteer_shifts(id) ON DELETE CASCADE,
    member_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    status text DEFAULT 'confirmed' CHECK (status IN ('confirmed', 'completed', 'cancelled', 'no_show')),
    hours_worked decimal(5,2),
    notes text,
    assigned_at timestamptz DEFAULT now(),
    completed_at timestamptz,
    UNIQUE(shift_id, member_id)
);

-- Indexes for volunteer management
CREATE INDEX IF NOT EXISTS idx_volunteer_opportunities_organization ON volunteer_opportunities(organization_id);
CREATE INDEX IF NOT EXISTS idx_volunteer_opportunities_active ON volunteer_opportunities(is_active);
CREATE INDEX IF NOT EXISTS idx_volunteer_shifts_opportunity ON volunteer_shifts(opportunity_id);
CREATE INDEX IF NOT EXISTS idx_volunteer_shifts_date ON volunteer_shifts(shift_date);
CREATE INDEX IF NOT EXISTS idx_volunteer_assignments_shift ON volunteer_assignments(shift_id);
CREATE INDEX IF NOT EXISTS idx_volunteer_assignments_member ON volunteer_assignments(member_id);
CREATE INDEX IF NOT EXISTS idx_volunteer_assignments_status ON volunteer_assignments(status);

-- RLS policies for volunteer opportunities
ALTER TABLE volunteer_opportunities ENABLE ROW LEVEL SECURITY;
ALTER TABLE volunteer_shifts ENABLE ROW LEVEL SECURITY;
ALTER TABLE volunteer_assignments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view active opportunities in their organization"
    ON volunteer_opportunities FOR SELECT
    USING (
        organization_id IN (
            SELECT organization_id FROM profiles WHERE user_id = auth.uid()
        )
        AND (is_active = true OR EXISTS (
            SELECT 1 FROM profiles
            WHERE user_id = auth.uid()
            AND organization_id = volunteer_opportunities.organization_id
            AND role IN ('admin', 'super_admin')
        ))
    );

CREATE POLICY "Admins can manage volunteer opportunities"
    ON volunteer_opportunities FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE user_id = auth.uid()
            AND organization_id = volunteer_opportunities.organization_id
            AND role IN ('admin', 'super_admin')
        )
    );

CREATE POLICY "Users can view shifts for accessible opportunities"
    ON volunteer_shifts FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM volunteer_opportunities vo
            JOIN profiles p ON p.organization_id = vo.organization_id
            WHERE vo.id = volunteer_shifts.opportunity_id
            AND p.user_id = auth.uid()
        )
    );

CREATE POLICY "Admins can manage volunteer shifts"
    ON volunteer_shifts FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM volunteer_opportunities vo
            JOIN profiles p ON p.organization_id = vo.organization_id
            WHERE vo.id = volunteer_shifts.opportunity_id
            AND p.user_id = auth.uid()
            AND p.role IN ('admin', 'super_admin')
        )
    );

CREATE POLICY "Members can view their own assignments"
    ON volunteer_assignments FOR SELECT
    USING (
        member_id IN (
            SELECT id FROM profiles WHERE user_id = auth.uid()
        )
        OR
        EXISTS (
            SELECT 1 FROM volunteer_shifts vs
            JOIN volunteer_opportunities vo ON vo.id = vs.opportunity_id
            JOIN profiles p ON p.organization_id = vo.organization_id
            WHERE vs.id = volunteer_assignments.shift_id
            AND p.user_id = auth.uid()
            AND p.role IN ('admin', 'super_admin')
        )
    );

CREATE POLICY "Members can sign up for shifts"
    ON volunteer_assignments FOR INSERT
    WITH CHECK (
        member_id IN (
            SELECT id FROM profiles WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Members can cancel their own assignments"
    ON volunteer_assignments FOR UPDATE
    USING (
        member_id IN (
            SELECT id FROM profiles WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Admins can manage all assignments"
    ON volunteer_assignments FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM volunteer_shifts vs
            JOIN volunteer_opportunities vo ON vo.id = vs.opportunity_id
            JOIN profiles p ON p.organization_id = vo.organization_id
            WHERE vs.id = volunteer_assignments.shift_id
            AND p.user_id = auth.uid()
            AND p.role IN ('admin', 'super_admin')
        )
    );

-- ============================================================================
-- MEMBER REFERRAL PROGRAM
-- ============================================================================

-- Referrals table
CREATE TABLE IF NOT EXISTS referrals (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE,
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

-- Indexes for referrals
CREATE INDEX IF NOT EXISTS idx_referrals_organization ON referrals(organization_id);
CREATE INDEX IF NOT EXISTS idx_referrals_referrer ON referrals(referrer_id);
CREATE INDEX IF NOT EXISTS idx_referrals_referred ON referrals(referred_id);
CREATE INDEX IF NOT EXISTS idx_referrals_code ON referrals(referral_code);
CREATE INDEX IF NOT EXISTS idx_referrals_status ON referrals(status);

-- RLS policies for referrals
ALTER TABLE referrals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members can view their own referrals"
    ON referrals FOR SELECT
    USING (
        referrer_id IN (
            SELECT id FROM profiles WHERE user_id = auth.uid()
        )
        OR
        referred_id IN (
            SELECT id FROM profiles WHERE user_id = auth.uid()
        )
        OR
        EXISTS (
            SELECT 1 FROM profiles
            WHERE user_id = auth.uid()
            AND organization_id = referrals.organization_id
            AND role IN ('admin', 'super_admin')
        )
    );

CREATE POLICY "System can create referrals"
    ON referrals FOR INSERT
    WITH CHECK (true);

CREATE POLICY "Admins can manage referrals"
    ON referrals FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE user_id = auth.uid()
            AND organization_id = referrals.organization_id
            AND role IN ('admin', 'super_admin')
        )
    );

-- Function to generate unique referral code
CREATE OR REPLACE FUNCTION generate_referral_code(p_member_id uuid)
RETURNS text AS $$
DECLARE
    v_code text;
    v_exists boolean;
BEGIN
    LOOP
        -- Generate 8-character alphanumeric code
        v_code := upper(substring(md5(random()::text || p_member_id::text) from 1 for 8));
        
        -- Check if code exists
        SELECT EXISTS(SELECT 1 FROM referrals WHERE referral_code = v_code) INTO v_exists;
        
        EXIT WHEN NOT v_exists;
    END LOOP;
    
    RETURN v_code;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- PAYMENT INTEGRATION (STRIPE)
-- ============================================================================

-- Payments table
CREATE TABLE IF NOT EXISTS payments (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE,
    member_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    stripe_payment_id text UNIQUE,
    stripe_payment_intent_id text,
    amount decimal(10,2) NOT NULL,
    currency text DEFAULT 'USD',
    status text DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'refunded', 'cancelled')),
    payment_type text CHECK (payment_type IN ('membership', 'event', 'donation', 'other')),
    reference_id uuid, -- membership_id, event_registration_id, etc.
    reference_type text, -- 'membership', 'event_registration', etc.
    invoice_url text,
    receipt_url text,
    metadata jsonb DEFAULT '{}',
    created_at timestamptz DEFAULT now(),
    completed_at timestamptz,
    refunded_at timestamptz
);

-- Payment methods table
CREATE TABLE IF NOT EXISTS payment_methods (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    member_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
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

-- Indexes for payments
CREATE INDEX IF NOT EXISTS idx_payments_organization ON payments(organization_id);
CREATE INDEX IF NOT EXISTS idx_payments_member ON payments(member_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(status);
CREATE INDEX IF NOT EXISTS idx_payments_type ON payments(payment_type);
CREATE INDEX IF NOT EXISTS idx_payments_stripe_id ON payments(stripe_payment_id);
CREATE INDEX IF NOT EXISTS idx_payment_methods_member ON payment_methods(member_id);

-- RLS policies for payments
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_methods ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members can view their own payments"
    ON payments FOR SELECT
    USING (
        member_id IN (
            SELECT id FROM profiles WHERE user_id = auth.uid()
        )
        OR
        EXISTS (
            SELECT 1 FROM profiles
            WHERE user_id = auth.uid()
            AND organization_id = payments.organization_id
            AND role IN ('admin', 'super_admin')
        )
    );

CREATE POLICY "System can create payments"
    ON payments FOR INSERT
    WITH CHECK (true);

CREATE POLICY "Admins can manage payments"
    ON payments FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE user_id = auth.uid()
            AND organization_id = payments.organization_id
            AND role IN ('admin', 'super_admin')
        )
    );

CREATE POLICY "Members can view their own payment methods"
    ON payment_methods FOR SELECT
    USING (
        member_id IN (
            SELECT id FROM profiles WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Members can manage their own payment methods"
    ON payment_methods FOR ALL
    USING (
        member_id IN (
            SELECT id FROM profiles WHERE user_id = auth.uid()
        )
    );

-- ============================================================================
-- TRIGGERS
-- ============================================================================

CREATE TRIGGER update_surveys_updated_at
    BEFORE UPDATE ON surveys
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_volunteer_opportunities_updated_at
    BEFORE UPDATE ON volunteer_opportunities
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_payment_methods_updated_at
    BEFORE UPDATE ON payment_methods
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- ANALYTICS FUNCTIONS
-- ============================================================================

-- Function to get volunteer hours for a member
CREATE OR REPLACE FUNCTION get_member_volunteer_hours(p_member_id uuid)
RETURNS decimal AS $$
DECLARE
    v_total_hours decimal;
BEGIN
    SELECT COALESCE(SUM(hours_worked), 0) INTO v_total_hours
    FROM volunteer_assignments
    WHERE member_id = p_member_id
    AND status = 'completed';
    
    RETURN v_total_hours;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION get_member_volunteer_hours TO authenticated;

-- Function to get referral statistics
CREATE OR REPLACE FUNCTION get_member_referral_stats(p_member_id uuid)
RETURNS json AS $$
DECLARE
    v_total_referrals integer;
    v_completed_referrals integer;
    v_pending_referrals integer;
BEGIN
    SELECT COUNT(*) INTO v_total_referrals
    FROM referrals
    WHERE referrer_id = p_member_id;
    
    SELECT COUNT(*) INTO v_completed_referrals
    FROM referrals
    WHERE referrer_id = p_member_id
    AND status IN ('completed', 'rewarded');
    
    SELECT COUNT(*) INTO v_pending_referrals
    FROM referrals
    WHERE referrer_id = p_member_id
    AND status = 'pending';
    
    RETURN json_build_object(
        'total_referrals', v_total_referrals,
        'completed_referrals', v_completed_referrals,
        'pending_referrals', v_pending_referrals
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION get_member_referral_stats TO authenticated;

-- Function to get survey response statistics
CREATE OR REPLACE FUNCTION get_survey_stats(p_survey_id uuid)
RETURNS json AS $$
DECLARE
    v_total_responses integer;
    v_unique_respondents integer;
    v_completion_rate integer;
BEGIN
    SELECT COUNT(DISTINCT member_id) INTO v_unique_respondents
    FROM survey_responses
    WHERE survey_id = p_survey_id;
    
    SELECT COUNT(*) INTO v_total_responses
    FROM survey_responses
    WHERE survey_id = p_survey_id;
    
    RETURN json_build_object(
        'total_responses', v_total_responses,
        'unique_respondents', v_unique_respondents
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION get_survey_stats TO authenticated;