import { Header } from './components/layout/Header'
import { LoginForm } from './components/auth/LoginForm'
import { MemberDashboard } from './components/dashboard/MemberDashboard'
import { Toaster } from './components/ui/sonner'
import { useAuth } from './hooks/useAuth'

function App() {
  const { user, loading: authLoading } = useAuth()

  // For single organization mode, skip tenant loading
  // Show loading state while checking auth only
  if (authLoading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
          <p className="text-gray-600">Loading...</p>
        </div>
      </div>
    )
  }

  // Show login form if not authenticated
  if (!user) {
    return <LoginForm />
  }

  // Check if user is pending approval
  if (user.profile?.status === 'pending') {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center max-w-md mx-auto p-6 bg-white rounded-lg shadow-md">
          <div className="text-yellow-500 mb-4">
            <svg className="h-16 w-16 mx-auto" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
          <h1 className="text-2xl font-bold text-gray-900 mb-2">Awaiting Approval</h1>
          <p className="text-gray-600 mb-4">
            Your account has been successfully created! An administrator will review and approve your account shortly.
          </p>
          <p className="text-sm text-gray-500 mb-6">
            You'll receive access to your dashboard once your account is approved. Please check back later.
          </p>
          <div className="bg-blue-50 border border-blue-200 rounded-lg p-4 text-left">
            <p className="text-sm font-medium text-blue-900 mb-1">Account Details:</p>
            <p className="text-sm text-blue-800">Name: {user.profile?.first_name} {user.profile?.last_name}</p>
            <p className="text-sm text-blue-800">Email: {user.email}</p>
          </div>
        </div>
      </div>
    )
  }

  // Show main application
  return (
    <>
      <div className="min-h-screen bg-gray-50">
        <Header />
        <main>
          <MemberDashboard />
        </main>
      </div>
      <Toaster />
    </>
  )
}

export default App