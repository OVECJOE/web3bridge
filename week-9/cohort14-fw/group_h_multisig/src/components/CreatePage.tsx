/**
 * Create Page Component
 * 
 * Form for creating new transactions.
 * Allows users to:
 * - Initiate transfers
 * - Make contract calls
 * - Update policies
 * 
 * All transactions are submitted to the multisig contract
 * and require approvals before execution.
 */

import { useState } from 'react'
import { Card } from './ui/card'
import { Button } from './ui/button'
import { Input } from './ui/input'
import { Lock } from 'lucide-react'

/**
 * Create page component
 * Form for initiating new vault transactions
 */
export default function CreatePage() {
  const [txType, setTxType] = useState<'transfer' | 'contract_call' | 'policy'>('transfer');
  const [recipient, setRecipient] = useState('');
  const [amount, setAmount] = useState('');
  const [asset, setAsset] = useState('ETH');
  const [loading, setLoading] = useState(false);

  /**
   * Handle transaction submission
   * In actual implementation, this would call the smart contract
   */
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    try {
      // Mock submission - replace with actual smart contract call
      // await vault.createTransaction({ type: txType, recipient, amount, asset });
      
      // For now, just show success message
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      // Reset form
      setRecipient('');
      setAmount('');
      
      alert('Transaction created successfully! Awaiting approvals...');
    } catch (err) {
      console.error('[CreatePage] Error creating transaction:', err);
      alert('Failed to create transaction');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="p-8 max-w-2xl">
      {/* Page Header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Initiate Transaction</h1>
        <p className="text-gray-600">
          Create a new transaction. It will be submitted to signers for approval.
        </p>
      </div>

      <Card className="p-8">
        <form onSubmit={handleSubmit} className="space-y-8">
          {/* Transaction Type Selection */}
          <div>
            <label className="block text-sm font-semibold text-gray-900 mb-4">
              Transaction Protocol
            </label>
            <div className="space-y-3">
              {[
                { value: 'transfer' as const, label: 'Initiate.', icon: '→' },
                { value: 'contract_call' as const, label: 'Execute Contract Call', icon: '⚙' },
                { value: 'policy' as const, label: 'Update Policy', icon: '📋' },
              ].map((option) => (
                <label key={option.value} className="flex items-center p-4 border-2 rounded-lg cursor-pointer transition-all"
                  style={{
                    borderColor: txType === option.value ? '#8B3A62' : '#e0e0e0',
                    backgroundColor: txType === option.value ? '#faf5f7' : '#ffffff',
                  }}
                  onMouseEnter={(e) => {
                    if (txType !== option.value) e.currentTarget.style.backgroundColor = '#f9f9f9';
                  }}
                  onMouseLeave={(e) => {
                    if (txType !== option.value) e.currentTarget.style.backgroundColor = '#ffffff';
                  }}
                >
                  <input
                    type="radio"
                    name="txType"
                    value={option.value}
                    checked={txType === option.value}
                    onChange={(e) => setTxType(e.target.value as typeof txType)}
                    className="w-4 h-4"
                  />
                  <span className="ml-3 text-sm font-medium text-gray-900">{option.label}</span>
                </label>
              ))}
            </div>
          </div>

          {/* Transfer Form */}
          {txType === 'transfer' && (
            <div className="space-y-6 p-6 bg-gray-50 rounded-lg border border-gray-200">
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-2">
                  01. DESTINATION PORTFOLIO
                </label>
                <Input
                  type="text"
                  placeholder="Recipient Ethereum Address (0x...)"
                  value={recipient}
                  onChange={(e) => setRecipient(e.target.value)}
                  required
                  className="bg-white"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-semibold text-gray-700 mb-2">
                    02. ASSET
                  </label>
                  <select
                    value={asset}
                    onChange={(e) => setAsset(e.target.value)}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg bg-white"
                  >
                    <option value="ETH">ETH</option>
                    <option value="USDC">USDC</option>
                    <option value="WBTC">WBTC</option>
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-semibold text-gray-700 mb-2">
                    03. AMOUNT
                  </label>
                  <Input
                    type="number"
                    placeholder="0.00"
                    value={amount}
                    onChange={(e) => setAmount(e.target.value)}
                    required
                    step="0.01"
                    min="0"
                    className="bg-white"
                  />
                </div>
              </div>

              {/* Vault Projection */}
              <div className="p-4 bg-white rounded-lg border border-gray-200">
                <p className="text-xs font-semibold text-gray-600 uppercase tracking-wide mb-3">
                  VAULT PROJECTION
                </p>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <p className="text-xs text-gray-500 font-medium">Balance Post-Transfer</p>
                    <p className="text-lg font-bold text-gray-900 font-mono">1,244.18 ETe</p>
                  </div>
                  <div>
                    <p className="text-xs text-gray-500 font-medium">Estimated Network Fee</p>
                    <p className="text-lg font-bold text-green-700">~ 0.0024 ETH</p>
                  </div>
                </div>
              </div>

              {/* Approvals Required */}
              <div className="p-4 rounded-lg border" style={{ backgroundColor: '#faf5f7', borderColor: '#c99eb8' }}>
                <div className="flex items-center gap-2">
                  <div className="flex -space-x-2">
                    <div className="w-6 h-6 rounded-full flex items-center justify-center text-white text-xs font-bold" style={{ backgroundColor: '#8B3A62' }}>
                      A
                    </div>
                    <div className="w-6 h-6 bg-green-600 rounded-full flex items-center justify-center text-white text-xs font-bold">
                      B
                    </div>
                  </div>
                  <p className="text-sm font-medium" style={{ color: '#3d1d2c' }}>
                    Requires 3 of 5 institutional signers to execute.
                  </p>
                </div>
              </div>
            </div>
          )}

          {/* Contract Call Form */}
          {txType === 'contract_call' && (
            <div className="p-6 bg-gray-50 rounded-lg border border-gray-200">
              <p className="text-gray-600 mb-4">Contract call creation form</p>
              <Input
                type="text"
                placeholder="Contract address and function details"
                className="bg-white"
              />
            </div>
          )}

          {/* Policy Update Form */}
          {txType === 'policy' && (
            <div className="p-6 bg-gray-50 rounded-lg border border-gray-200">
              <p className="text-gray-600 mb-4">Policy update form</p>
              <Input
                type="text"
                placeholder="Policy details and parameters"
                className="bg-white"
              />
            </div>
          )}

          {/* Submit Button */}
          <div className="flex gap-4">
            <Button
              type="submit"
              disabled={loading || !recipient || !amount}
              className="flex-1 h-12 text-white font-semibold text-base"
              style={{ backgroundColor: '#8B3A62' }}
            >
              {loading ? (
                <span className="flex items-center gap-2">
                  <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
                  Processing...
                </span>
              ) : (
                <span className="flex items-center justify-center gap-2">
                  <Lock className="w-5 h-5" />
                  Propose Transaction
                </span>
              )}
            </Button>
          </div>

          {/* Info Text */}
          <p className="text-xs text-gray-500 text-center">
            SIGNEM Wired: CURRENT SESSION: 0X71C...4F32
          </p>
        </form>
      </Card>
    </div>
  );
}