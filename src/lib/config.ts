/**
 * Application Configuration
 * Single organization mode - no multi-tenancy
 */

export const APP_CONFIG = {
  name: import.meta.env.VITE_ORG_NAME || 'Choo',
  logoUrl: import.meta.env.VITE_ORG_LOGO_URL || '',
  primaryColor: import.meta.env.VITE_PRIMARY_COLOR || '#3B82F6',
  secondaryColor: import.meta.env.VITE_SECONDARY_COLOR || '#1E40AF',
  
  // Feature flags (can be overridden by database settings)
  features: {
    events: true,
    committees: true,
    documents: true,
    mailingLists: true,
    notifications: true,
    analytics: true,
    badges: true,
    tags: true,
    calendar: true,
    qrCheckin: true,
    certificates: true,
    surveys: true,
    volunteers: true,
    referrals: true,
    payments: false, // Disabled by default
    ticketing: false, // Disabled by default
    onboarding: true,
    twoFactor: true,
    customBranding: true,
    multiLanguage: false, // Disabled by default
  }
};

/**
 * Check if a feature is enabled
 * This will be enhanced to check database settings
 */
export function isFeatureEnabled(featureKey: string): boolean {
  return APP_CONFIG.features[featureKey as keyof typeof APP_CONFIG.features] ?? false;
}

/**
 * Get application configuration
 */
export function getAppConfig() {
  return APP_CONFIG;
}