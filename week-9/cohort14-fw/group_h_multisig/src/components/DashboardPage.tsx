/**
 * Dashboard Page Component
 * 
 * Main dashboard displaying:
 * - Total consolidated balance
 * - Signer status
 * - Pending approvals
 * - Asset breakdown
 * - Recent activity
 */

import { useVaultBalance } from '../hooks/useVaultBalance'
import { useEffect } from 'react'
import { Card } from './ui/card'
import { ArrowUpRight, ArrowDownLeft, TrendingUp, Shield } from 'lucide-react'
import { mockActivityItems } from '../lib/mockData'

/**
 * Dashboard page component
 * Displays vault overview and recent activity
 */
export default function DashboardPage() {
  const { balance, refetch } = useVaultBalance();

  useEffect(() => {
    refetch();
  }, [refetch]);

  return (
    <div className="p-8">
      {/* Balance Card */}
      <Card className="mb-8 p-8 bg-gradient-to-br from-gray-50 to-white border border-gray-200">
        <p className="text-xs font-semibold text-gray-500 uppercase tracking-wide mb-2">
          Total Consolidated Balance
        </p>
        <div className="flex items-baseline gap-4 mb-4">
          <h1 className="text-4xl font-bold text-gray-900">
            {balance?.total || '$0.00'}
          </h1>
          <div className="flex items-center gap-1 text-green-600">
            <TrendingUp className="w-4 h-4" />
            <span className="text-sm font-semibold">
              {balance ? `↑${balance.percentageChange.toFixed(1)}%` : '0%'}
            </span>
          </div>
        </div>
        <p className="text-sm text-gray-600">
          vs last month: {balance?.previousMonth || '$0.00'}
        </p>
      </Card>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-8">
        {/* Pending Approvals */}
        <Card className="p-6 bg-white">
          <div className="flex items-center justify-between mb-4">
            <div className="w-12 h-12 rounded-lg flex items-center justify-center" style={{ backgroundColor: '#f0e0e6' }}>
              <Shield className="w-6 h-6" style={{ color: '#8B3A62' }} />
            </div>
          </div>
          <p className="text-3xl font-bold text-gray-900 mb-1">04</p>
          <p className="text-sm text-gray-600 font-medium">Pending Approvals</p>
          <p className="text-xs text-gray-500 mt-2">REQUIRES YOUR ACTION</p>
        </Card>

        {/* Signer Status */}
        <Card className="p-6 bg-white">
          <p className="text-xs font-semibold text-gray-500 uppercase tracking-wide mb-4">
            Signer Status
          </p>
          <div className="flex items-baseline gap-2 mb-4">
            <span className="text-3xl font-bold text-gray-900">2</span>
            <span className="text-gray-500">of</span>
            <span className="text-3xl font-bold text-gray-400">5</span>
          </div>
          <p className="text-sm text-gray-600">
            Signatures required for execution
          </p>
          <div className="mt-3 flex gap-1">
            <div className="h-1 flex-1 rounded-full" style={{ backgroundColor: '#8B3A62' }}></div>
            <div className="h-1 flex-1 rounded-full" style={{ backgroundColor: '#8B3A62' }}></div>
            <div className="h-1 flex-1 rounded-full bg-gray-200"></div>
            <div className="h-1 flex-1 rounded-full bg-gray-200"></div>
            <div className="h-1 flex-1 rounded-full bg-gray-200"></div>
          </div>
        </Card>

        {/* Network Status */}
        <Card className="p-6 bg-white">
          <p className="text-xs font-semibold text-gray-500 uppercase tracking-wide mb-4">
            Ethereum Mainnet
          </p>
          <div className="flex items-center gap-2">
            <div className="w-2 h-2 bg-green-500 rounded-full animate-pulse"></div>
            <span className="text-sm font-medium text-gray-700">Institutional Node Active</span>
          </div>
          <p className="text-xs text-gray-500 mt-3">
            Secure Connection • ETH Mainnet
          </p>
        </Card>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Assets */}
        <Card className="p-6">
          <h2 className="text-lg font-semibold text-gray-900 mb-6">Holdings</h2>
          <div className="space-y-4">
            {balance?.assets.map((asset) => (
              <div key={asset.symbol} className="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
                <div>
                  <p className="text-sm font-semibold text-gray-900">{asset.symbol}</p>
                  <p className="text-xs text-gray-500">{asset.name}</p>
                </div>
                <p className="text-sm font-medium text-gray-900">{asset.balance}</p>
              </div>
            ))}
          </div>
        </Card>

        {/* Recent Activity */}
        <Card className="p-6">
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-lg font-semibold text-gray-900">Recent activity</h2>
            <a href="/queue" className="text-sm text-maroon-600 hover:text-maroon-700 font-medium">
              View All
            </a>
          </div>
          <div className="space-y-4">
            {mockActivityItems.slice(0, 3).map((item) => (
              <div key={item.id} className="flex items-center gap-4 pb-4 border-b border-gray-200 last:border-0">
                <div className="w-10 h-10 bg-gray-100 rounded-lg flex items-center justify-center flex-shrink-0">
                  {item.type === 'send' ? (
                    <ArrowUpRight className="w-5 h-5 text-maroon-600" />
                  ) : (
                    <ArrowDownLeft className="w-5 h-5 text-green-600" />
                  )}
                </div>
                <div className="flex-1">
                  <p className="text-sm font-medium text-gray-900">{item.title}</p>
                  <p className="text-xs text-gray-500">{item.description}</p>
                </div>
                <div className="text-right">
                  <p className={`text-sm font-medium ${item.type === 'send' ? 'text-red-600' : 'text-green-600'}`}>
                    {item.value}
                  </p>
                  <p className="text-xs text-gray-500">
                    {item.timestamp.toLocaleDateString()}
                  </p>
                </div>
              </div>
            ))}
          </div>
        </Card>
      </div>
    </div>
  );
}