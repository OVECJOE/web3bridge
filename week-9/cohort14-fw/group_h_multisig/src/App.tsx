import { Routes, Route, Navigate } from 'react-router-dom'
import AppLayout from './components/AppLayout'
import DashboardPage from './components/DashboardPage'
import QueuePage from './components/QueuePage'
import CreatePage from './components/CreatePage'
import SettingsPage from './components/SettingsPage'

export default function App() {
  return (
    <Routes>
      {/* Redirect root path to dashboard */}
      <Route path="/" element={<Navigate to="/dashboard" replace />} />
      
      {/* Main application routes wrapped in AppLayout */}
      <Route element={<AppLayout />}>
        <Route path="/dashboard" element={<DashboardPage />} />
        <Route path="/queue" element={<QueuePage />} />
        <Route path="/create" element={<CreatePage />} />
        <Route path="/settings" element={<SettingsPage />} />
      </Route>
      
      {/* Catch-all redirect */}
      <Route path="*" element={<Navigate to="/dashboard" replace />} />
    </Routes>
  )
}
