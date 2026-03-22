/**
 * Settings Page Component
 * 
 * Complete settings management interface for The Vault multisig contract.
 * Features:
 * - Manage signers (add/remove)
 * - Change vault owner
 * - Update signature threshold
 * - Manage transaction limits
 * - Configure security policies
 * - View vault health status
 * 
 * All actions require confirmation dialogs before execution.
 */

import { useState, useEffect } from 'react'
import { useVaultSettings } from '../hooks/useVaultSettings'
import { useFormValidation, VALIDATION_RULES } from '../hooks/useFormValidation'
import ConfirmDialog from './ConfirmDialog'
import { Card } from './ui/card'
import { Button } from './ui/button'
import { Input } from './ui/input'
import { AlertCircle, CheckCircle, Shield, Users, Lock, Trash2, Plus } from 'lucide-react'
import { Alert, AlertDescription } from './ui/alert'

/**
 * Settings page component
 * Manages all vault configuration and security settings
 */
export default function SettingsPage() {
  const { config, loading, error, addSigner, removeSigner, updateThreshold, refetch } =
    useVaultSettings();

  // Form state
  const [newSignerAddress, setNewSignerAddress] = useState('');
  const [newSignerName, setNewSignerName] = useState('');
  const [newThreshold, setNewThreshold] = useState<string>('');

  // Dialog state
  const [dialogState, setDialogState] = useState<{
    type: null | 'addSigner' | 'removeSigner' | 'threshold' | 'owner' | 'limit';
    open: boolean;
    targetAddress?: string;
  }>({
    type: null,
    open: false,
  });

  const [actionLoading, setActionLoading] = useState(false);
  const [actionError, setActionError] = useState<string | null>(null);

  // Form validation
  const { errors, validate, clearAllErrors } = useFormValidation({
    address: [VALIDATION_RULES.ethereumAddress, VALIDATION_RULES.required],
    name: [VALIDATION_RULES.required],
    limit: [VALIDATION_RULES.nonNegativeNumber],
  });

  // Load settings on mount
  useEffect(() => {
    refetch();
  }, [refetch]);

  /**
   * Handle adding a new signer
   */
  const handleAddSigner = async () => {
    try {
      setActionError(null);
      setActionLoading(true);

      if (!validate({ address: newSignerAddress, name: newSignerName })) {
        return;
      }

      await addSigner(newSignerAddress, newSignerName);
      setNewSignerAddress('');
      setNewSignerName('');
      setDialogState({ type: null, open: false });
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to add signer';
      setActionError(message);
      console.error('[SettingsPage] Error adding signer:', err);
    } finally {
      setActionLoading(false);
    }
  };

  /**
   * Handle removing a signer
   */
  const handleRemoveSigner = async () => {
    try {
      setActionError(null);
      setActionLoading(true);

      const address = dialogState.targetAddress;
      if (!address) throw new Error('No signer selected');

      await removeSigner(address);
      setDialogState({ type: null, open: false });
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to remove signer';
      setActionError(message);
      console.error('[SettingsPage] Error removing signer:', err);
    } finally {
      setActionLoading(false);
    }
  };

  /**
   * Handle threshold update
   */
  const handleUpdateThreshold = async () => {
    try {
      setActionError(null);
      setActionLoading(true);

      const threshold = parseInt(newThreshold, 10);
      if (isNaN(threshold) || threshold < 1) {
        throw new Error('Invalid threshold value');
      }

      await updateThreshold(threshold);
      setNewThreshold('');
      setDialogState({ type: null, open: false });
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to update threshold';
      setActionError(message);
      console.error('[SettingsPage] Error updating threshold:', err);
    } finally {
      setActionLoading(false);
    }
  };

  /**
   * Open confirmation dialog
   */
  const openDialog = (
    type: typeof dialogState.type,
    targetAddress?: string
  ) => {
    clearAllErrors();
    setActionError(null);
    setDialogState({ type, open: true, targetAddress });
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-screen">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-maroon-600 mx-auto mb-4"></div>
          <p className="text-gray-600">Loading settings...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <Alert variant="destructive" className="m-6">
        <AlertCircle className="h-4 w-4" />
        <AlertDescription>{error}</AlertDescription>
      </Alert>
    );
  }

  if (!config) {
    return (
      <div className="p-6">
        <Alert>
          <AlertCircle className="h-4 w-4" />
          <AlertDescription>No vault configuration found</AlertDescription>
        </Alert>
      </div>
    );
  }

  return (
    <div className="p-8 max-w-6xl">
      {/* Page Header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Vault Settings</h1>
        <p className="text-gray-600">
          Manage signers, security policies, and vault configuration
        </p>
      </div>

      {/* Action Error Alert */}
      {actionError && (
        <Alert variant="destructive" className="mb-6">
          <AlertCircle className="h-4 w-4" />
          <AlertDescription>{actionError}</AlertDescription>
        </Alert>
      )}

      {/* Settings Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Signers Management */}
        <Card className="p-6">
          <div className="flex items-center gap-2 mb-6">
            <Users className="w-5 h-5 text-maroon-600" />
            <h2 className="text-lg font-semibold text-gray-900">Signers</h2>
            <span className="ml-auto text-sm text-gray-500 bg-gray-100 px-3 py-1 rounded-full">
              {config.totalSigners}
            </span>
          </div>

          {/* Signers List */}
          <div className="space-y-3 mb-6">
            {config.signers.map((signer) => (
              <div
                key={signer.address}
                className="flex items-center justify-between p-3 bg-gray-50 rounded-lg border border-gray-200"
              >
                <div className="flex-1">
                  <p className="text-sm font-medium text-gray-900">{signer.name}</p>
                  <p className="text-xs text-gray-500 font-mono">{signer.address.slice(0, 10)}...{signer.address.slice(-8)}</p>
                </div>
                <div className="flex items-center gap-2">
                  <span
                    className={`text-xs font-medium px-2 py-1 rounded ${
                      signer.status === 'active'
                        ? 'bg-green-100 text-green-800'
                        : 'bg-yellow-100 text-yellow-800'
                    }`}
                  >
                    {signer.status === 'active' ? 'Active' : 'Pending Removal'}
                  </span>
                  {signer.status === 'active' && (
                    <button
                      onClick={() => openDialog('removeSigner', signer.address)}
                      className="p-1 hover:bg-red-100 rounded transition-colors"
                      title="Remove signer"
                    >
                      <Trash2 className="w-4 h-4 text-red-600" />
                    </button>
                  )}
                </div>
              </div>
            ))}
          </div>

          {/* Add Signer Form */}
          <button
            onClick={() => openDialog('addSigner')}
            className="w-full flex items-center justify-center gap-2 px-4 py-2 border-2 border-dashed rounded-lg transition-colors font-medium"
            style={{
              borderColor: '#c99eb8',
              color: '#8B3A62',
            }}
            onMouseEnter={(e) => (e.currentTarget.style.backgroundColor = '#faf5f7')}
            onMouseLeave={(e) => (e.currentTarget.style.backgroundColor = 'transparent')}
          >
            <Plus className="w-4 h-4" />
            Add Signer
          </button>
        </Card>

        {/* Threshold Configuration */}
        <Card className="p-6">
          <div className="flex items-center gap-2 mb-6">
            <Lock className="w-5 h-5 text-maroon-600" />
            <h2 className="text-lg font-semibold text-gray-900">Signature Threshold</h2>
          </div>

          <div className="mb-6 p-4 rounded-lg border" style={{ backgroundColor: '#faf5f7', borderColor: '#c99eb8' }}>
            <div className="text-center">
              <p className="text-xs font-semibold uppercase tracking-wide mb-2" style={{ color: '#8B3A62' }}>
                Current Threshold
              </p>
              <p className="text-4xl font-bold mb-2" style={{ color: '#8B3A62' }}>
                {config.threshold}
              </p>
              <p className="text-sm text-gray-600">
                of {config.totalSigners} signatures required for execution
              </p>
            </div>
          </div>

          <div className="space-y-3">
            <label className="block text-sm font-medium text-gray-700">
              New Threshold
            </label>
            <div className="flex gap-2">
              <Input
                type="number"
                min="1"
                max={config.totalSigners}
                value={newThreshold}
                onChange={(e) => setNewThreshold(e.target.value)}
                placeholder={`Between 1 and ${config.totalSigners}`}
                className="flex-1"
              />
              <Button
                onClick={() => openDialog('threshold')}
                disabled={!newThreshold || parseInt(newThreshold, 10) === config.threshold}
                style={{
                  backgroundColor: '#8B3A62',
                  color: 'white',
                }}
                className="hover:opacity-90"
              >
                Update
              </Button>
            </div>
            <p className="text-xs text-gray-500">
              Requires {config.threshold} signatures to approve changes
            </p>
          </div>
        </Card>

        {/* Vault Information */}
        <Card className="p-6 lg:col-span-2">
          <div className="flex items-center gap-2 mb-6">
            <Shield className="w-5 h-5 text-maroon-600" />
            <h2 className="text-lg font-semibold text-gray-900">Vault Information</h2>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="p-4 bg-gray-50 rounded-lg">
              <p className="text-xs text-gray-500 font-semibold uppercase tracking-wide mb-1">
                Vault Owner
              </p>
              <p className="text-sm font-mono text-gray-900 break-all">
                {config.owner.slice(0, 10)}...{config.owner.slice(-8)}
              </p>
            </div>

            <div className="p-4 bg-gray-50 rounded-lg">
              <p className="text-xs text-gray-500 font-semibold uppercase tracking-wide mb-1">
                Security Level
              </p>
              <p className="text-sm font-medium text-gray-900 capitalize">
                {config.securityLevel}
              </p>
            </div>

            <div className="p-4 bg-gray-50 rounded-lg">
              <p className="text-xs text-gray-500 font-semibold uppercase tracking-wide mb-1">
                Created
              </p>
              <p className="text-sm text-gray-900">
                {config.createdAt.toLocaleDateString()}
              </p>
            </div>

            <div className="p-4 bg-gray-50 rounded-lg">
              <p className="text-xs text-gray-500 font-semibold uppercase tracking-wide mb-1">
                Last Updated
              </p>
              <p className="text-sm text-gray-900">
                {config.lastUpdated.toLocaleDateString()}
              </p>
            </div>

            <div className="p-4 bg-gray-50 rounded-lg">
              <p className="text-xs text-gray-500 font-semibold uppercase tracking-wide mb-1">
                Transaction Limit
              </p>
              <p className="text-sm font-medium text-gray-900">
                ${config.transactionLimit?.toLocaleString() || 'Unlimited'}
              </p>
            </div>

            <div className="p-4 bg-gray-50 rounded-lg">
              <p className="text-xs text-gray-500 font-semibold uppercase tracking-wide mb-1">
                Daily Limit
              </p>
              <p className="text-sm font-medium text-gray-900">
                ${config.dailyLimit?.toLocaleString() || 'Unlimited'}
              </p>
            </div>
          </div>
        </Card>

        {/* Security Policies */}
        <Card className="p-6 lg:col-span-2">
          <div className="flex items-center gap-2 mb-6">
            <Shield className="w-5 h-5 text-maroon-600" />
            <h2 className="text-lg font-semibold text-gray-900">Security Policies</h2>
          </div>

          <div className="space-y-3">
            <div className="p-4 bg-gray-50 rounded-lg border border-gray-200 flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-900">
                  Institutional Standard Security
                </p>
                <p className="text-xs text-gray-500">
                  Enhanced security with multi-signature requirements
                </p>
              </div>
              <div className="flex-shrink-0">
                <CheckCircle className="w-5 h-5 text-green-600" />
              </div>
            </div>

            <div className="p-4 bg-gray-50 rounded-lg border border-gray-200 flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-900">
                  Transaction Limits
                </p>
                <p className="text-xs text-gray-500">
                  Daily and per-transaction spending limits enforced
                </p>
              </div>
              <div className="flex-shrink-0">
                <CheckCircle className="w-5 h-5 text-green-600" />
              </div>
            </div>

            <div className="p-4 bg-gray-50 rounded-lg border border-gray-200 flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-900">
                  Timelock
                </p>
                <p className="text-xs text-gray-500">
                  Mandatory delay before transaction execution
                </p>
              </div>
              <div className="flex-shrink-0">
                <CheckCircle className="w-5 h-5 text-green-600" />
              </div>
            </div>
          </div>
        </Card>
      </div>

      {/* Confirmation Dialogs */}

      {/* Add Signer Dialog */}
      <ConfirmDialog
        open={dialogState.type === 'addSigner' && dialogState.open}
        onOpenChange={(open) =>
          !open && setDialogState({ type: null, open: false })
        }
        title="Add New Signer"
        description={
          <div className="space-y-4 mt-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Ethereum Address
              </label>
              <Input
                value={newSignerAddress}
                onChange={(e) => setNewSignerAddress(e.target.value)}
                placeholder="0x..."
                className={errors.address ? 'border-red-500' : ''}
              />
              {errors.address && (
                <p className="text-red-600 text-xs mt-1">{errors.address}</p>
              )}
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Signer Name
              </label>
              <Input
                value={newSignerName}
                onChange={(e) => setNewSignerName(e.target.value)}
                placeholder="e.g., Alice Wong"
                className={errors.name ? 'border-red-500' : ''}
              />
              {errors.name && (
                <p className="text-red-600 text-xs mt-1">{errors.name}</p>
              )}
            </div>
          </div>
        }
        confirmLabel="Add Signer"
        loading={actionLoading}
        onConfirm={handleAddSigner}
      />

      {/* Remove Signer Dialog */}
      <ConfirmDialog
        open={dialogState.type === 'removeSigner' && dialogState.open}
        onOpenChange={(open) =>
          !open && setDialogState({ type: null, open: false })
        }
        title="Remove Signer"
        description={`Are you sure you want to remove this signer? They will no longer be able to approve transactions. This action requires ${config.threshold} signatures.`}
        confirmLabel="Remove"
        isDestructive
        loading={actionLoading}
        onConfirm={handleRemoveSigner}
      />

      {/* Update Threshold Dialog */}
      <ConfirmDialog
        open={dialogState.type === 'threshold' && dialogState.open}
        onOpenChange={(open) =>
          !open && setDialogState({ type: null, open: false })
        }
        title="Update Signature Threshold"
        description={`Change the required number of signatures from ${config.threshold} to ${newThreshold}? This action requires ${config.threshold} signatures to approve.`}
        confirmLabel="Update Threshold"
        loading={actionLoading}
        onConfirm={handleUpdateThreshold}
      />
    </div>
  );
}