/*
  # New Features - Phase 1: Quick Wins
  
  This migration adds database support for:
  1. Member Tags/Labels System
  2. Communication History Timeline
  3. Enhanced Document Management
  
  Tables:
  - member_tags
  - member_tag_assignments
  - communication_log
  - document_folders
  - document_versions
  - document_downloads
*/

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- MEMBER TAGS SYSTEM
-- ============================================================================

-- Member tags table
CREATE TABLE IF NOT EXISTS member_tags (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE,
    name text NOT NULL,
    color text DEFAULT '#3B82F6',
    description text,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    UNIQUE(organization_id, name)
);

-- Member tag assignments (junction table)
CREATE TABLE IF NOT EXISTS member_tag_assignments (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    member_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    tag_id uuid REFERENCES member_tags(id) ON DELETE CASCADE,
    assigned_at timestamptz DEFAULT now(),
    assigned_by uuid REFERENCES profiles(id),
    UNIQUE(member_id, tag_id)
);

-- Indexes for member tags
CREATE INDEX IF NOT EXISTS idx_member_tags_organization ON member_tags(organization_id);
CREATE INDEX IF NOT EXISTS idx_member_tag_assignments_member ON member_tag_assignments(member_id);
CREATE INDEX IF NOT EXISTS idx_member_tag_assignments_tag ON member_tag_assignments(tag_id);

-- RLS policies for member tags
ALTER TABLE member_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE member_tag_assignments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view tags in their organization"
    ON member_tags FOR SELECT
    USING (
        organization_id IN (
            SELECT organization_id FROM profiles WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Admins can manage tags"
    ON member_tags FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE user_id = auth.uid()
            AND organization_id = member_tags.organization_id
            AND role IN ('admin', 'super_admin')
        )
    );

CREATE POLICY "Users can view tag assignments in their organization"
    ON member_tag_assignments FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM profiles p
            JOIN member_tags t ON t.id = member_tag_assignments.tag_id
            WHERE p.user_id = auth.uid()
            AND p.organization_id = t.organization_id
        )
    );

CREATE POLICY "Admins can manage tag assignments"
    ON member_tag_assignments FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM profiles p
            JOIN member_tags t ON t.id = member_tag_assignments.tag_id
            WHERE p.user_id = auth.uid()
            AND p.organization_id = t.organization_id
            AND p.role IN ('admin', 'super_admin')
        )
    );

-- ============================================================================
-- COMMUNICATION HISTORY TIMELINE
-- ============================================================================

-- Communication log table
CREATE TABLE IF NOT EXISTS communication_log (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE,
    member_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    type text NOT NULL CHECK (type IN ('email', 'note', 'event', 'status_change', 'system')),
    subject text,
    content text,
    metadata jsonb DEFAULT '{}',
    created_by uuid REFERENCES profiles(id),
    created_at timestamptz DEFAULT now()
);

-- Indexes for communication log
CREATE INDEX IF NOT EXISTS idx_communication_log_organization ON communication_log(organization_id);
CREATE INDEX IF NOT EXISTS idx_communication_log_member ON communication_log(member_id);
CREATE INDEX IF NOT EXISTS idx_communication_log_type ON communication_log(type);
CREATE INDEX IF NOT EXISTS idx_communication_log_created_at ON communication_log(created_at DESC);

-- RLS policies for communication log
ALTER TABLE communication_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members can view their own communication history"
    ON communication_log FOR SELECT
    USING (
        member_id IN (
            SELECT id FROM profiles WHERE user_id = auth.uid()
        )
        OR
        EXISTS (
            SELECT 1 FROM profiles
            WHERE user_id = auth.uid()
            AND organization_id = communication_log.organization_id
            AND role IN ('admin', 'super_admin')
        )
    );

CREATE POLICY "Admins can create communication logs"
    ON communication_log FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE user_id = auth.uid()
            AND organization_id = communication_log.organization_id
            AND role IN ('admin', 'super_admin')
        )
    );

-- ============================================================================
-- ENHANCED DOCUMENT MANAGEMENT
-- ============================================================================

-- Document folders table
CREATE TABLE IF NOT EXISTS document_folders (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE,
    name text NOT NULL,
    parent_folder_id uuid REFERENCES document_folders(id) ON DELETE CASCADE,
    description text,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Document versions table
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

-- Document downloads tracking
CREATE TABLE IF NOT EXISTS document_downloads (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id uuid REFERENCES documents(id) ON DELETE CASCADE,
    member_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    downloaded_at timestamptz DEFAULT now(),
    ip_address inet,
    user_agent text
);

-- Add new columns to documents table
ALTER TABLE documents ADD COLUMN IF NOT EXISTS folder_id uuid REFERENCES document_folders(id);
ALTER TABLE documents ADD COLUMN IF NOT EXISTS approval_status text DEFAULT 'approved' CHECK (approval_status IN ('pending', 'approved', 'rejected'));
ALTER TABLE documents ADD COLUMN IF NOT EXISTS expires_at timestamptz;
ALTER TABLE documents ADD COLUMN IF NOT EXISTS access_roles text[] DEFAULT '{"member"}';
ALTER TABLE documents ADD COLUMN IF NOT EXISTS file_size bigint;
ALTER TABLE documents ADD COLUMN IF NOT EXISTS mime_type text;

-- Indexes for document management
CREATE INDEX IF NOT EXISTS idx_document_folders_organization ON document_folders(organization_id);
CREATE INDEX IF NOT EXISTS idx_document_folders_parent ON document_folders(parent_folder_id);
CREATE INDEX IF NOT EXISTS idx_document_versions_document ON document_versions(document_id);
CREATE INDEX IF NOT EXISTS idx_document_downloads_document ON document_downloads(document_id);
CREATE INDEX IF NOT EXISTS idx_document_downloads_member ON document_downloads(member_id);
CREATE INDEX IF NOT EXISTS idx_documents_folder ON documents(folder_id);

-- RLS policies for document folders
ALTER TABLE document_folders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view folders in their organization"
    ON document_folders FOR SELECT
    USING (
        organization_id IN (
            SELECT organization_id FROM profiles WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Admins can manage folders"
    ON document_folders FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE user_id = auth.uid()
            AND organization_id = document_folders.organization_id
            AND role IN ('admin', 'super_admin')
        )
    );

-- RLS policies for document versions
ALTER TABLE document_versions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view document versions"
    ON document_versions FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM documents d
            JOIN profiles p ON p.organization_id = d.organization_id
            WHERE d.id = document_versions.document_id
            AND p.user_id = auth.uid()
        )
    );

CREATE POLICY "Admins can manage document versions"
    ON document_versions FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM documents d
            JOIN profiles p ON p.organization_id = d.organization_id
            WHERE d.id = document_versions.document_id
            AND p.user_id = auth.uid()
            AND p.role IN ('admin', 'super_admin')
        )
    );

-- RLS policies for document downloads
ALTER TABLE document_downloads ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own downloads"
    ON document_downloads FOR SELECT
    USING (
        member_id IN (
            SELECT id FROM profiles WHERE user_id = auth.uid()
        )
        OR
        EXISTS (
            SELECT 1 FROM documents d
            JOIN profiles p ON p.organization_id = d.organization_id
            WHERE d.id = document_downloads.document_id
            AND p.user_id = auth.uid()
            AND p.role IN ('admin', 'super_admin')
        )
    );

CREATE POLICY "System can track downloads"
    ON document_downloads FOR INSERT
    WITH CHECK (true);

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Trigger for updated_at on member_tags
CREATE TRIGGER update_member_tags_updated_at
    BEFORE UPDATE ON member_tags
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger for updated_at on document_folders
CREATE TRIGGER update_document_folders_updated_at
    BEFORE UPDATE ON document_folders
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

-- Function to get member communication timeline
CREATE OR REPLACE FUNCTION get_member_communication_timeline(
    p_member_id uuid,
    p_limit integer DEFAULT 50,
    p_offset integer DEFAULT 0
)
RETURNS TABLE (
    id uuid,
    type text,
    subject text,
    content text,
    created_at timestamptz,
    created_by_name text
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        cl.id,
        cl.type,
        cl.subject,
        cl.content,
        cl.created_at,
        COALESCE(p.first_name || ' ' || p.last_name, 'System') as created_by_name
    FROM communication_log cl
    LEFT JOIN profiles p ON p.id = cl.created_by
    WHERE cl.member_id = p_member_id
    ORDER BY cl.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get document download statistics
CREATE OR REPLACE FUNCTION get_document_download_stats(p_document_id uuid)
RETURNS TABLE (
    total_downloads bigint,
    unique_downloaders bigint,
    last_download timestamptz
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*)::bigint as total_downloads,
        COUNT(DISTINCT member_id)::bigint as unique_downloaders,
        MAX(downloaded_at) as last_download
    FROM document_downloads
    WHERE document_id = p_document_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION get_member_communication_timeline TO authenticated;
GRANT EXECUTE ON FUNCTION get_document_download_stats TO authenticated;