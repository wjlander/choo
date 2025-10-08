import { useState, useEffect } from 'react'
import { supabase } from '@/lib/supabase/client'

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
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const loadOrganization = async () => {
      try {
        // For single organization mode, just load the first active organization
        const { data, error: fetchError } = await supabase
          .from('organizations')
          .select('*')
          .eq('is_active', true)
          .limit(1)
          .maybeSingle()

        if (fetchError) {
          console.error('Error loading organization:', fetchError)
          setError('Failed to load organization')
        } else if (data) {
          setOrganization(data)
        }
      } catch (err) {
        console.error('Error loading organization:', err)
        setError('Failed to load organization')
      } finally {
        setLoading(false)
      }
    }

    loadOrganization()
  }, [])

  return {
    organization,
    loading,
    error
  }
}