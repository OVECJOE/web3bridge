/**
 * useTransactionQueue Hook
 * 
 * Manages the queue of pending transactions awaiting approvals.
 * Handles fetching, filtering, and updating transaction states.
 */

import { useState, useCallback } from 'react';
import type { Transaction } from '../lib/types';
import { mockTransactionQueue } from '../lib/mockData';

interface UseTransactionQueueReturn {
  transactions: Transaction[];
  loading: boolean;
  error: string | null;
  approveTransaction: (transactionId: string, comment?: string) => Promise<void>;
  rejectTransaction: (transactionId: string, reason?: string) => Promise<void>;
  executeTransaction: (transactionId: string) => Promise<void>;
  getTransactionById: (id: string) => Transaction | undefined;
  refetch: () => Promise<void>;
}

/**
 * Hook for managing transaction queue
 * 
 * @returns Transaction queue state and action functions
 */
export function useTransactionQueue(): UseTransactionQueueReturn {
  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Fetch pending transactions
  const refetch = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);

      // Mock data - replace with actual smart contract call
      // const txs = await vault.getPendingTransactions();
      setTransactions(mockTransactionQueue);
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Failed to fetch transaction queue';
      setError(errorMessage);
      console.error('[useTransactionQueue] Error fetching transactions:', err);
    } finally {
      setLoading(false);
    }
  }, []);

  /**
   * Approve a transaction on behalf of current signer
   * Requires smart contract call: vault.approveTransaction(txId)
   */
  const approveTransaction = useCallback(
    async (transactionId: string, comment?: string) => {
      try {
        setError(null);

        if (!transactionId) {
          throw new Error('Transaction ID is required');
        }

        // Mock implementation - replace with smart contract call
        // await vault.approveTransaction(transactionId);

        setTransactions((prev) =>
          prev.map((tx) => {
            if (tx.id === transactionId) {
              return {
                ...tx,
                approvalsReceived: tx.approvalsReceived + 1,
                signers: tx.signers.map((s) =>
                  s.status === 'pending'
                    ? { ...s, status: 'approved' as const, timestamp: new Date() }
                    : s
                ),
              };
            }
            return tx;
          })
        );
      } catch (err) {
        const errorMessage = err instanceof Error ? err.message : 'Failed to approve transaction';
        setError(errorMessage);
        throw err;
      }
    },
    []
  );

  /**
   * Reject a transaction
   * Requires smart contract call: vault.rejectTransaction(txId)
   */
  const rejectTransaction = useCallback(
    async (transactionId: string, reason?: string) => {
      try {
        setError(null);

        if (!transactionId) {
          throw new Error('Transaction ID is required');
        }

        // Mock implementation - replace with smart contract call
        // await vault.rejectTransaction(transactionId);

        setTransactions((prev) =>
          prev.map((tx) => {
            if (tx.id === transactionId) {
              return {
                ...tx,
                status: 'rejected' as const,
              };
            }
            return tx;
          })
        );
      } catch (err) {
        const errorMessage = err instanceof Error ? err.message : 'Failed to reject transaction';
        setError(errorMessage);
        throw err;
      }
    },
    []
  );

  /**
   * Execute a transaction that has received sufficient approvals
   * Requires smart contract call: vault.executeTransaction(txId)
   */
  const executeTransaction = useCallback(async (transactionId: string) => {
    try {
      setError(null);

      if (!transactionId) {
        throw new Error('Transaction ID is required');
      }

      const tx = transactions.find((t) => t.id === transactionId);
      if (!tx) {
        throw new Error('Transaction not found');
      }

      if (tx.approvalsReceived < tx.approvalsRequired) {
        throw new Error(
          `Insufficient approvals. Need ${tx.approvalsRequired}, have ${tx.approvalsReceived}`
        );
      }

      // Mock implementation - replace with smart contract call
      // await vault.executeTransaction(transactionId);

      setTransactions((prev) =>
        prev.map((t) =>
          t.id === transactionId ? { ...t, status: 'executed' as const } : t
        )
      );
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Failed to execute transaction';
      setError(errorMessage);
      throw err;
    }
  }, [transactions]);

  /**
   * Get a specific transaction by ID
   */
  const getTransactionById = useCallback(
    (id: string): Transaction | undefined => {
      return transactions.find((tx) => tx.id === id);
    },
    [transactions]
  );

  return {
    transactions,
    loading,
    error,
    approveTransaction,
    rejectTransaction,
    executeTransaction,
    getTransactionById,
    refetch,
  };
}