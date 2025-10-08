import { useState, useEffect } from 'react'

export interface Organization {
  id: string
  slug: string
  name: string
  domain: string | null
  logo_url: string | null
  primary_color: string
  secondary_color: string
  contact_email: string
  contact_phone: string | null
  settings: any
  membership_year_start_month: number
  membership_year_end_month: number
  renewal_enabled: boolean
  renewal_form_schema_id: string | null
  is_active: boolean
  created_at: string
  updated_at: string
}

export function useTenant() {
  const [organization, setOrganization] = useState<Organization | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    // For single organization mode, use static configuration
    const staticOrg: Organization = {
      id: 'single-org',
      slug: 'choo',
      name: 'Choo Organization',
      domain: null,
      logo_url: null,
      primary_color: '#3b82f6',
      secondary_color: '#60a5fa',
      contact_email: 'contact@choo.org',
      contact_phone: null,
      settings: {},
      membership_year_start_month: 1,
      membership_year_end_month: 12,
      renewal_enabled: true,
      renewal_form_schema_id: null,
      is_active: true,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    }

    setOrganization(staticOrg)
    setLoading(false)
  }, [])

  return {
    organization,
    loading,
    error: null
  }
}