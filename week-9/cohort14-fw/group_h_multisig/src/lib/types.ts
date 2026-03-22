

/** Represents a signer in the multisig vault */
export interface Signer {
  address: string;
  name: string;
  status: 'active' | 'pending_removal' | 'inactive';
}

/** Represents a transaction in the queue */
export interface Transaction {
  id: string;
  txId: string;
  type: 'transfer' | 'contract_call' | 'policy_update' | 'signer_management';
  description: string;
  value?: string;
  recipient?: string;
  status: 'pending' | 'approved' | 'rejected' | 'executed' | 'failed';
  createdAt: Date;
  expiresAt?: Date;
  approvalsRequired: number;
  approvalsReceived: number;
  signers: SignerApproval[];
  details?: Record<string, unknown>;
}

/** Represents a signer's approval status for a transaction */
export interface SignerApproval {
  signerAddress: string;
  signerName: string;
  status: 'pending' | 'approved' | 'rejected';
  timestamp?: Date;
  comment?: string;
}

/** Vault configuration and state */
export interface VaultConfig {
  name: string;
  owner: string;
  threshold: number;
  totalSigners: number;
  signers: Signer[];
  transactionLimit?: string;
  dailyLimit?: string;
  securityLevel: 'standard' | 'enhanced' | 'institutional';
  createdAt: Date;
  lastUpdated: Date;
}

/** Vault balance information */
export interface VaultBalance {
  total: string;
  previousMonth: string;
  percentageChange: number;
  assets: AssetBalance[];
}

/** Individual asset balance */
export interface AssetBalance {
  symbol: string;
  name: string;
  balance: string;
  decimals: number;
  address?: string;
}

/** Vault activity/transaction history item */
export interface ActivityItem {
  id: string;
  type: 'send' | 'receive' | 'contract_call' | 'policy_update';
  title: string;
  description: string;
  value?: string;
  status: 'pending' | 'completed' | 'failed';
  timestamp: Date;
  details?: Record<string, unknown>;
}

/** Settings change request */
export interface SettingChange {
  id: string;
  type: 'signer_add' | 'signer_remove' | 'threshold_change' | 'owner_change' | 'limit_change';
  currentValue: string;
  proposedValue: string;
  proposedBy: string;
  status: 'pending' | 'approved' | 'rejected';
  createdAt: Date;
}

/** Vault health/status information */
export interface VaultHealth {
  status: 'healthy' | 'warning' | 'critical';
  signingPower: number;
  backupStatus: 'good' | 'needs_attention';
  lastAudit?: Date;
  securityPolicies: SecurityPolicy[];
}

/** Security policy configuration */
export interface SecurityPolicy {
  id: string;
  name: string;
  description: string;
  enabled: boolean;
  config?: Record<string, unknown>;
}
