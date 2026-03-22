

import type {
  VaultConfig,
  VaultBalance,
  Transaction,
  ActivityItem,
  VaultHealth,
  Signer,
} from './types';

/** Mock vault configuration */
export const mockVaultConfig: VaultConfig = {
  name: 'Multisig Institutional',
  owner: '0x742d35Cc6634C0532925a3b844Bc9e7595f4832',
  threshold: 2,
  totalSigners: 5,
  signers: [
    {
      address: '0x742d35Cc6634C0532925a3b844Bc9e7595f4832',
      name: 'Alice Wong',
      status: 'active',
    },
    {
      address: '0x8ba1f109551bD432803012645Ac136ddd64DBA72',
      name: 'Bob Smith',
      status: 'active',
    },
    {
      address: '0x9f2df0fed2c77648de5860a4cc508cd0818c85b8',
      name: 'Charlie Brown',
      status: 'active',
    },
    {
      address: '0xa0ee7a142d267c1f36714e4a8f75612e633cc5b8',
      name: 'Diana Prince',
      status: 'active',
    },
    {
      address: '0xc5a63a0c1f2d5f9e8c3b1a4f7d9e2c5b1a8f3e6d',
      name: 'Eve Johnson',
      status: 'pending_removal',
    },
  ],
  transactionLimit: '100000',
  dailyLimit: '500000',
  securityLevel: 'institutional',
  createdAt: new Date('2023-10-12'),
  lastUpdated: new Date('2024-03-15'),
};

/** Mock vault balance */
export const mockVaultBalance: VaultBalance = {
  total: '$2,482,190.42',
  previousMonth: '$2,207,210.18',
  percentageChange: 12.4,
  assets: [
    {
      symbol: 'ETH',
      name: 'Ethereum',
      balance: '412.80',
      decimals: 18,
      address: '0x0000000000000000000000000000000000000000',
    },
    {
      symbol: 'USDC',
      name: 'USD Coin',
      balance: '1,204,500',
      decimals: 6,
      address: '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48',
    },
    {
      symbol: 'WBTC',
      name: 'Wrapped Bitcoin',
      balance: '12.05',
      decimals: 8,
      address: '0x2260FAC5E5542a773Aa44fBCfeDd86a3D015fC31',
    },
  ],
};

/** Mock pending transactions in queue */
export const mockTransactionQueue: Transaction[] = [
  {
    id: '1',
    txId: '#1234',
    type: 'transfer',
    description: 'Send ETH',
    value: '12.50',
    recipient: 'LIQUIDITY POOL (0x4F...91)',
    status: 'pending',
    createdAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000),
    approvalsRequired: 3,
    approvalsReceived: 1,
    signers: [
      {
        signerAddress: '0x742d35Cc6634C0532925a3b844Bc9e7595f4832',
        signerName: 'Alice Wong',
        status: 'approved',
        timestamp: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000),
      },
      {
        signerAddress: '0x8ba1f109551bD432803012645Ac136ddd64DBA72',
        signerName: 'Bob Smith',
        status: 'pending',
      },
      {
        signerAddress: '0x9f2df0fed2c77648de5860a4cc508cd0818c85b8',
        signerName: 'Charlie Brown',
        status: 'pending',
      },
    ],
  },
  {
    id: '2',
    txId: '#1235',
    type: 'contract_call',
    description: 'Contract Interaction',
    status: 'pending',
    createdAt: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000),
    approvalsRequired: 2,
    approvalsReceived: 2,
    signers: [
      {
        signerAddress: '0x742d35Cc6634C0532925a3b844Bc9e7595f4832',
        signerName: 'Alice Wong',
        status: 'approved',
      },
      {
        signerAddress: '0x8ba1f109551bD432803012645Ac136ddd64DBA72',
        signerName: 'Bob Smith',
        status: 'approved',
      },
    ],
    details: {
      protocol: 'LIDO FINANCE',
      action: 'Stake()',
    },
  },
  {
    id: '3',
    txId: '#1236',
    type: 'policy_update',
    description: 'Update Policy',
    status: 'pending',
    createdAt: new Date(),
    approvalsRequired: 2,
    approvalsReceived: 0,
    signers: [
      {
        signerAddress: '0x742d35Cc6634C0532925a3b844Bc9e7595f4832',
        signerName: 'Alice Wong',
        status: 'pending',
      },
      {
        signerAddress: '0x8ba1f109551bD432803012645Ac136ddd64DBA72',
        signerName: 'Bob Smith',
        status: 'pending',
      },
    ],
    details: {
      protocol: 'Internal Protocol',
      change: 'Fee structure update',
    },
  },
];

/** Mock recent activity */
export const mockActivityItems: ActivityItem[] = [
  {
    id: '1',
    type: 'send',
    title: 'Send 12.50 ETH',
    description: 'TO: LIQUIDITY POOL (0x4F...91)',
    value: '- $28,125.00',
    status: 'completed',
    timestamp: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000),
  },
  {
    id: '2',
    type: 'receive',
    title: 'Receive 50,000 USDC',
    description: 'FROM: TREASURY RESERVE (0x1A...F2)',
    value: '+ $50,000.00',
    status: 'completed',
    timestamp: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000),
  },
  {
    id: '3',
    type: 'contract_call',
    title: 'Contract Call: Stake()',
    description: 'PROTOCOL: LIDO FINANCE',
    status: 'completed',
    timestamp: new Date(Date.now() - 9 * 24 * 60 * 60 * 1000),
  },
];

/** Mock vault health status */
export const mockVaultHealth: VaultHealth = {
  status: 'healthy',
  signingPower: 85,
  backupStatus: 'good',
  lastAudit: new Date('2024-03-10'),
  securityPolicies: [
    {
      id: '1',
      name: 'Institutional Standard Security',
      description: 'Enhanced security with multi-signature requirements',
      enabled: true,
    },
    {
      id: '2',
      name: 'Transaction Limits',
      description: 'Daily and per-transaction spending limits enforced',
      enabled: true,
    },
    {
      id: '3',
      name: 'Timelock',
      description: 'Mandatory delay before transaction execution',
      enabled: true,
    },
    {
      id: '4',
      name: 'Whitelist Enforcement',
      description: 'Transactions only to whitelisted addresses',
      enabled: false,
    },
  ],
};
