import { Outlet } from 'react-router-dom'
import Sidebar from './Sidebar'
import Header from './Header'

/**
 * Main App Layout Component
 * 
 * Root layout component that provides:
 * - Sidebar navigation
 * - Header with wallet info
 * - Main content area with Outlet for React Router child pages
 * 
 * This component wraps all main application pages (Dashboard, Queue, Create, Settings)
 * and provides consistent layout structure and navigation.
 */
export default function AppLayout() {
  return (
    <div className="flex h-screen bg-gray-50">
      {/* Left sidebar with navigation */}
      <Sidebar />
      
      {/* Main content area */}
      <div className="flex-1 flex flex-col overflow-hidden">
        {/* Top header with wallet info and settings */}
        <Header />
        
        {/* Page content - rendered by React Router */}
        <main className="flex-1 overflow-auto">
          <Outlet />
        </main>
      </div>
    </div>
  )
}
