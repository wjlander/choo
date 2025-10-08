/*
  # Complete Single Organization Schema
  
  1. Tables Created
    - organization_membership_types: Membership type definitions
    - organization_form_schemas: Custom signup form schemas
    - memberships: Member subscription records
    - documents: Document management
    - events: Event management
    - event_registrations: Event attendance tracking
    - committees: Committee definitions
    - committee_positions: Committee roles
    - committee_members: Committee membership
    - mailing_list_subscriptions: Email subscription management
    - notifications: System notifications
  
  2. Security
    - Enable RLS on all tables
    - Add policies for authenticated users
    - Admin-only policies for management functions
    - Member self-service policies where appropriate
    
  3. Indexes
    - Performance indexes on frequently queried columns
    - Foreign key indexes for joins
*/

-- ============================================================================
-- MEMBERSHIP TYPES
-- ============================================================================

CREATE TABLE IF NOT EXISTS organization_membership_types (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id text DEFAULT 'single-org',
    name text NOT NULL,
    description text,
    price decimal(10,2),
    duration_months integer,
    is_active boolean DEFAULT true,
    display_order integer DEFAULT 0,
    benefits jsonb DEFAULT '[]',
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

ALTER TABLE organization_membership_types ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view active membership types"
    ON organization_membership_types FOR SELECT
    USING (is_active = true);

CREATE POLICY "Admins can manage membership types"
    ON organization_membership_types FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE user_id = auth.uid()
            AND role IN ('admin', 'super_admin')
        )
    );

CREATE INDEX IF NOT EXISTS idx_org_membership_types_org ON organization_membership_types(organization_id);
CREATE INDEX IF NOT EXISTS idx_org_membership_types_active ON organization_membership_types(is_active);

-- ============================================================================
-- FORM SCHEMAS
-- ============================================================================

CREATE TABLE IF NOT EXISTS organization_form_schemas (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id text DEFAULT 'single-org',
    form_type text DEFAULT 'signup',
    schema_version integer DEFAULT 1,
    schema_data jsonb NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

ALTER TABLE organization_form_schemas ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view active form schemas"
    ON organization_form_schemas FOR SELECT
    USING (is_active = true);

CREATE POLICY "Admins can manage form schemas"
    ON organization_form_schemas FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE user_id = auth.uid()
            AND role IN ('admin', 'super_admin')
        )
    );

CREATE INDEX IF NOT EXISTS idx_org_form_schemas_org ON organization_form_schemas(organization_id);
CREATE INDEX IF NOT EXISTS idx_org_form_schemas_active ON organization_form_schemas(is_active);

-- ============================================================================
-- MEMBERSHIPS
-- ============================================================================

CREATE TABLE IF NOT EXISTS memberships (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    member_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    membership_type_id uuid REFERENCES organization_membership_types(id),
    start_date date NOT NULL,
    end_date date,
    status text DEFAULT 'active' CHECK (status IN ('active', 'expired', 'cancelled')),
    auto_renew boolean DEFAULT false,
    payment_status text DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'failed')),
    amount_paid decimal(10,2),
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

ALTER TABLE memberships ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members can view their own memberships"
    ON memberships FOR SELECT
    USING (
        member_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())
        OR EXISTS (
            SELECT 1 FROM profiles
            WHERE user_id = auth.uid()
            AND role IN ('admin', 'super_admin')
        )
    );

CREATE POLICY "Admins can manage all memberships"
    ON memberships FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE user_id = auth.uid()
            AND role IN ('admin', 'super_admin')
        )
    );

CREATE INDEX IF NOT EXISTS idx_memberships_member ON memberships(member_id);
CREATE INDEX IF NOT EXISTS idx_memberships_status ON memberships(status);
CREATE INDEX IF NOT EXISTS idx_memberships_end_date ON memberships(end_date);

-- ============================================================================
-- DOCUMENTS
-- ============================================================================

CREATE TABLE IF NOT EXISTS documents (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id text DEFAULT 'single-org',
    title text NOT NULL,
    description text,
    file_url text NOT NULL,
    file_type text,
    category text,
    is_public boolean DEFAULT false,
    uploaded_by uuid REFERENCES profiles(id),
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view documents"
    ON documents FOR SELECT
    USING (
        is_public = true
        OR EXISTS (
            SELECT 1 FROM profiles WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Admins can manage documents"
    ON documents FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE user_id = auth.uid()
            AND role IN ('admin', 'super_admin')
        )
    );

CREATE INDEX IF NOT EXISTS idx_documents_org ON documents(organization_id);
CREATE INDEX IF NOT EXISTS idx_documents_public ON documents(is_public);

-- ============================================================================
-- EVENTS
-- ============================================================================

CREATE TABLE IF NOT EXISTS events (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id text DEFAULT 'single-org',
    title text NOT NULL,
    description text,
    start_date timestamptz NOT NULL,
    end_date timestamptz,
    location text,
    capacity integer,
    is_public boolean DEFAULT true,
    registration_deadline timestamptz,
    created_by uuid REFERENCES profiles(id),
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

ALTER TABLE events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view public events"
    ON events FOR SELECT
    USING (is_public = true OR EXISTS (SELECT 1 FROM profiles WHERE user_id = auth.uid()));

CREATE POLICY "Admins can manage events"
    ON events FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE user_id = auth.uid()
            AND role IN ('admin', 'super_admin')
        )
    );

CREATE INDEX IF NOT EXISTS idx_events_org ON events(organization_id);
CREATE INDEX IF NOT EXISTS idx_events_start_date ON events(start_date);

-- ============================================================================
-- EVENT REGISTRATIONS
-- ============================================================================

CREATE TABLE IF NOT EXISTS event_registrations (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id uuid REFERENCES events(id) ON DELETE CASCADE,
    member_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    status text DEFAULT 'confirmed' CHECK (status IN ('confirmed', 'cancelled', 'waitlist')),
    registration_data jsonb DEFAULT '{}',
    registered_at timestamptz DEFAULT now(),
    UNIQUE(event_id, member_id)
);

ALTER TABLE event_registrations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members can view their own registrations"
    ON event_registrations FOR SELECT
    USING (
        member_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())
        OR EXISTS (
            SELECT 1 FROM profiles
            WHERE user_id = auth.uid()
            AND role IN ('admin', 'super_admin')
        )
    );

CREATE POLICY "Members can register for events"
    ON event_registrations FOR INSERT
    WITH CHECK (member_id IN (SELECT id FROM profiles WHERE user_id = auth.uid()));

CREATE POLICY "Members can cancel their registrations"
    ON event_registrations FOR UPDATE
    USING (member_id IN (SELECT id FROM profiles WHERE user_id = auth.uid()));

CREATE POLICY "Admins can manage all registrations"
    ON event_registrations FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE user_id = auth.uid()
            AND role IN ('admin', 'super_admin')
        )
    );

CREATE INDEX IF NOT EXISTS idx_event_registrations_event ON event_registrations(event_id);
CREATE INDEX IF NOT EXISTS idx_event_registrations_member ON event_registrations(member_id);

-- ============================================================================
-- COMMITTEES
-- ============================================================================

CREATE TABLE IF NOT EXISTS committees (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id text DEFAULT 'single-org',
    name text NOT NULL,
    description text,
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

ALTER TABLE committees ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view active committees"
    ON committees FOR SELECT
    USING (is_active = true OR EXISTS (SELECT 1 FROM profiles WHERE user_id = auth.uid()));

CREATE POLICY "Admins can manage committees"
    ON committees FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE user_id = auth.uid()
            AND role IN ('admin', 'super_admin')
        )
    );

CREATE INDEX IF NOT EXISTS idx_committees_org ON committees(organization_id);

-- ============================================================================
-- COMMITTEE POSITIONS
-- ============================================================================

CREATE TABLE IF NOT EXISTS committee_positions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    committee_id uuid REFERENCES committees(id) ON DELETE CASCADE,
    title text NOT NULL,
    description text,
    responsibilities text,
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

ALTER TABLE committee_positions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view committee positions"
    ON committee_positions FOR SELECT
    USING (EXISTS (SELECT 1 FROM profiles WHERE user_id = auth.uid()));

CREATE POLICY "Admins can manage committee positions"
    ON committee_positions FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE user_id = auth.uid()
            AND role IN ('admin', 'super_admin')
        )
    );

CREATE INDEX IF NOT EXISTS idx_committee_positions_committee ON committee_positions(committee_id);

-- ============================================================================
-- COMMITTEE MEMBERS
-- ============================================================================

CREATE TABLE IF NOT EXISTS committee_members (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    committee_id uuid REFERENCES committees(id) ON DELETE CASCADE,
    position_id uuid REFERENCES committee_positions(id),
    member_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    start_date date DEFAULT CURRENT_DATE,
    end_date date,
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

ALTER TABLE committee_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view committee members"
    ON committee_members FOR SELECT
    USING (EXISTS (SELECT 1 FROM profiles WHERE user_id = auth.uid()));

CREATE POLICY "Admins can manage committee members"
    ON committee_members FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE user_id = auth.uid()
            AND role IN ('admin', 'super_admin')
        )
    );

CREATE INDEX IF NOT EXISTS idx_committee_members_committee ON committee_members(committee_id);
CREATE INDEX IF NOT EXISTS idx_committee_members_member ON committee_members(member_id);

-- ============================================================================
-- MAILING LIST SUBSCRIPTIONS
-- ============================================================================

CREATE TABLE IF NOT EXISTS mailing_list_subscriptions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id text DEFAULT 'single-org',
    email text NOT NULL,
    first_name text,
    last_name text,
    status text DEFAULT 'subscribed' CHECK (status IN ('subscribed', 'unsubscribed')),
    subscription_token text UNIQUE DEFAULT gen_random_uuid()::text,
    subscribed_at timestamptz DEFAULT now(),
    unsubscribed_at timestamptz,
    metadata jsonb DEFAULT '{}',
    UNIQUE(organization_id, email)
);

ALTER TABLE mailing_list_subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can subscribe"
    ON mailing_list_subscriptions FOR INSERT
    WITH CHECK (true);

CREATE POLICY "Users can unsubscribe with token"
    ON mailing_list_subscriptions FOR UPDATE
    USING (true);

CREATE POLICY "Admins can view subscriptions"
    ON mailing_list_subscriptions FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE user_id = auth.uid()
            AND role IN ('admin', 'super_admin')
        )
    );

CREATE INDEX IF NOT EXISTS idx_mailing_list_org ON mailing_list_subscriptions(organization_id);
CREATE INDEX IF NOT EXISTS idx_mailing_list_token ON mailing_list_subscriptions(subscription_token);

-- ============================================================================
-- NOTIFICATIONS
-- ============================================================================

CREATE TABLE IF NOT EXISTS notifications (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    member_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    title text NOT NULL,
    message text NOT NULL,
    type text DEFAULT 'info' CHECK (type IN ('info', 'success', 'warning', 'error')),
    is_read boolean DEFAULT false,
    action_url text,
    created_at timestamptz DEFAULT now()
);

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members can view their own notifications"
    ON notifications FOR SELECT
    USING (member_id IN (SELECT id FROM profiles WHERE user_id = auth.uid()));

CREATE POLICY "Members can mark notifications as read"
    ON notifications FOR UPDATE
    USING (member_id IN (SELECT id FROM profiles WHERE user_id = auth.uid()));

CREATE POLICY "System can create notifications"
    ON notifications FOR INSERT
    WITH CHECK (true);

CREATE INDEX IF NOT EXISTS idx_notifications_member ON notifications(member_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON notifications(is_read);

-- ============================================================================
-- TRIGGERS
-- ============================================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_org_membership_types_updated_at
    BEFORE UPDATE ON organization_membership_types
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_org_form_schemas_updated_at
    BEFORE UPDATE ON organization_form_schemas
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_memberships_updated_at
    BEFORE UPDATE ON memberships
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_documents_updated_at
    BEFORE UPDATE ON documents
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_events_updated_at
    BEFORE UPDATE ON events
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_committees_updated_at
    BEFORE UPDATE ON committees
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_committee_positions_updated_at
    BEFORE UPDATE ON committee_positions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_committee_members_updated_at
    BEFORE UPDATE ON committee_members
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Insert default form schema
INSERT INTO organization_form_schemas (organization_id, form_type, schema_version, schema_data, is_active)
VALUES (
    'single-org',
    'signup',
    1,
    '{"fields": [{"name": "first_name", "type": "text", "label": "First Name", "required": true}, {"name": "last_name", "type": "text", "label": "Last Name", "required": true}, {"name": "email", "type": "email", "label": "Email", "required": true}, {"name": "phone", "type": "tel", "label": "Phone Number", "required": false}]}'::jsonb,
    true
)
ON CONFLICT DO NOTHING;

-- Insert default membership type
INSERT INTO organization_membership_types (organization_id, name, description, price, duration_months, is_active, display_order)
VALUES (
    'single-org',
    'Standard Membership',
    'Annual membership with full access',
    50.00,
    12,
    true,
    1
)
ON CONFLICT DO NOTHING;
