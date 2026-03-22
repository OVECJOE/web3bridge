
import { Link, useLocation } from 'react-router-dom';
import { LayoutDashboard, Clock, Plus, Settings, Square } from 'lucide-react';
// import { cn } from '../lib/utils';

interface NavItem {
  label: string;
  href: string;
  icon: React.ReactNode;
}

const navItems: NavItem[] = [
  {
    label: 'Dashboard',
    href: '/dashboard',
    icon: <LayoutDashboard className="w-5 h-5" />,
  },
  {
    label: 'Queue',
    href: '/queue',
    icon: <Clock className="w-5 h-5" />,
  },
  {
    label: 'Create',
    href: '/create',
    icon: <Plus className="w-5 h-5" />,
  },
  {
    label: 'Settings',
    href: '/settings',
    icon: <Settings className="w-5 h-5" />,
  },
];

/**
 * Sidebar navigation component
 * Renders left-side navigation with active state tracking
 */
export default function Sidebar() {
  const location = useLocation();
  const pathname = location.pathname;

  return (
    <aside className="w-64 bg-white border-r border-gray-200 flex flex-col h-screen sticky top-0">
      {/* Header */}
      <div className="p-6 border-b border-gray-200">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 rounded flex items-center justify-center" style={{ backgroundColor: '#8B3A62' }}>
              <Square className="w-5 h-5" style={{ color: 'white', fill: 'white' }} />
            </div>
            <h1 className="text-xl font-bold" style={{ color: '#1a1a1a' }}>The Vault</h1>
          </div>
      </div>

      {/* Navigation */}
      <nav className="flex-1 p-4 space-y-2">
        {navItems.map((item) => {
          const isActive = pathname === item.href;
          return (
            <Link
              key={item.href}
              to={item.href}
              className="flex items-center gap-3 px-4 py-3 rounded-lg transition-colors"
              style={
                isActive
                  ? { backgroundColor: '#faf5f7', color: '#8B3A62', fontWeight: '500' }
                  : { color: '#666666' }
              }
              onMouseEnter={(e) => {
                if (!isActive) (e.currentTarget as HTMLElement).style.backgroundColor = '#f5f5f5';
              }}
              onMouseLeave={(e) => {
                if (!isActive) (e.currentTarget as HTMLElement).style.backgroundColor = 'transparent';
              }}
            >
              <span className="flex-shrink-0">{item.icon}</span>
              <span>{item.label}</span>
            </Link>
          );
        })}
      </nav>

      {/* Footer */}
      <div className="p-4 border-t border-gray-200">
        <div className="p-4 rounded-lg" style={{ backgroundColor: '#faf5f7', borderColor: '#c99eb8', borderWidth: '1px' }}>
          <p className="text-xs font-semibold uppercase tracking-wide" style={{ color: '#8B3A62' }}>
            Vault Profile
          </p>
          <p className="text-sm font-medium text-gray-900 mt-2">
            Multisig Institutional
          </p>
          <p className="text-xs text-gray-500 mt-1">
            2 of 5 signatures required
          </p>
        </div>
      </div>
    </aside>
  );
}
