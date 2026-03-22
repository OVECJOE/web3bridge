/**
 * Confirmation Dialog Component
 * 
 * Reusable modal dialog for confirming sensitive actions like:
 * - Adding/removing signers
 * - Changing thresholds
 * - Updating security policies
 */

import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogHeader,
  AlertDialogTitle,
} from './ui/alert-dialog'
import { AlertCircle } from 'lucide-react'

interface ConfirmDialogProps {
  /**
   * Whether the dialog is open
   */
  open: boolean;

  /**
   * Callback when dialog is closed
   */
  onOpenChange: (open: boolean) => void;

  /**
   * Dialog title
   */
  title: string;

  /**
   * Dialog description/message
   */
  description: string | React.ReactNode;

  /**
   * Label for confirm button
   * @default "Confirm"
   */
  confirmLabel?: string;

  /**
   * Label for cancel button
   * @default "Cancel"
   */
  cancelLabel?: string;

  /**
   * Whether action is being processed
   * @default false
   */
  loading?: boolean;

  /**
   * Callback when user confirms
   */
  onConfirm: () => void | Promise<void>;

  /**
   * Whether this is a destructive action
   * @default false
   */
  isDestructive?: boolean;
}

/**
 * Reusable confirmation dialog for sensitive actions
 */
export default function ConfirmDialog({
  open,
  onOpenChange,
  title,
  description,
  confirmLabel = 'Confirm',
  cancelLabel = 'Cancel',
  loading = false,
  onConfirm,
  isDestructive = false,
}: ConfirmDialogProps) {
  return (
    <AlertDialog open={open} onOpenChange={onOpenChange}>
      <AlertDialogContent className="max-w-md">
        <AlertDialogHeader>
          <div className="flex items-start gap-3">
            {isDestructive && (
              <div className="flex-shrink-0">
                <AlertCircle className="w-5 h-5 text-red-600 mt-0.5" />
              </div>
            )}
            <div className="flex-1">
              <AlertDialogTitle>{title}</AlertDialogTitle>
              <AlertDialogDescription>{description}</AlertDialogDescription>
            </div>
          </div>
        </AlertDialogHeader>
        <div className="flex gap-3 justify-end mt-6">
          <AlertDialogCancel disabled={loading}>
            {cancelLabel}
          </AlertDialogCancel>
          <AlertDialogAction
            onClick={onConfirm}
            disabled={loading}
            className={isDestructive ? 'bg-red-600 hover:bg-red-700' : ''}
          >
            {loading ? 'Processing...' : confirmLabel}
          </AlertDialogAction>
        </div>
      </AlertDialogContent>
    </AlertDialog>
  );
}