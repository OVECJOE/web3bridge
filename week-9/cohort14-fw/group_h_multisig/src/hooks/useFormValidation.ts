/**
 * useFormValidation Hook
 * 
 * Provides form validation utilities for The Vault.
 * Includes validation for Ethereum addresses, numbers, and custom rules.
 */

import { useCallback, useState } from 'react';

interface ValidationRule {
  validate: (value: unknown) => boolean;
  message: string;
}

interface ValidationRules {
  [fieldName: string]: ValidationRule[];
}

interface ValidationErrors {
  [fieldName: string]: string;
}

interface UseFormValidationReturn {
  errors: ValidationErrors;
  validate: (formData: Record<string, unknown>) => boolean;
  setFieldError: (fieldName: string, error: string) => void;
  clearFieldError: (fieldName: string) => void;
  clearAllErrors: () => void;
}

/**
 * Hook for form validation with custom rules
 * 
 * @param rules - Validation rules for form fields
 * @returns Validation state and methods
 */
export function useFormValidation(rules: ValidationRules): UseFormValidationReturn {
  const [errors, setErrors] = useState<ValidationErrors>({});

  /**
   * Validate all fields or specific form data
   */
  const validate = useCallback(
    (formData: Record<string, unknown>): boolean => {
      const newErrors: ValidationErrors = {};

      Object.entries(rules).forEach(([fieldName, fieldRules]) => {
        const value = formData[fieldName];

        for (const rule of fieldRules) {
          if (!rule.validate(value)) {
            newErrors[fieldName] = rule.message;
            break; // Stop at first error for this field
          }
        }
      });

      setErrors(newErrors);
      return Object.keys(newErrors).length === 0;
    },
    [rules]
  );

  /**
   * Set error for a specific field
   */
  const setFieldError = useCallback((fieldName: string, error: string) => {
    setErrors((prev) => ({ ...prev, [fieldName]: error }));
  }, []);

  /**
   * Clear error for a specific field
   */
  const clearFieldError = useCallback((fieldName: string) => {
    setErrors((prev) => {
      const newErrors = { ...prev };
      delete newErrors[fieldName];
      return newErrors;
    });
  }, []);

  /**
   * Clear all errors
   */
  const clearAllErrors = useCallback(() => {
    setErrors({});
  }, []);

  return {
    errors,
    validate,
    setFieldError,
    clearFieldError,
    clearAllErrors,
  };
}

/**
 * Pre-defined validation rules for common fields
 */
export const VALIDATION_RULES = {
  /**
   * Validate Ethereum address format
   */
  ethereumAddress: {
    validate: (value: unknown): boolean => {
      if (typeof value !== 'string') return false;
      return /^0x[a-fA-F0-9]{40}$/.test(value);
    },
    message: 'Invalid Ethereum address format',
  },

  /**
   * Validate non-empty string
   */
  required: {
    validate: (value: unknown): boolean => {
      if (typeof value === 'string') return value.trim().length > 0;
      return !!value;
    },
    message: 'This field is required',
  },

  /**
   * Validate positive number
   */
  positiveNumber: {
    validate: (value: unknown): boolean => {
      const num = Number(value);
      return !isNaN(num) && num > 0;
    },
    message: 'Must be a positive number',
  },

  /**
   * Validate non-negative number
   */
  nonNegativeNumber: {
    validate: (value: unknown): boolean => {
      const num = Number(value);
      return !isNaN(num) && num >= 0;
    },
    message: 'Must be a non-negative number',
  },

  /**
   * Validate minimum value
   */
  minValue: (min: number) => ({
    validate: (value: unknown): boolean => {
      const num = Number(value);
      return !isNaN(num) && num >= min;
    },
    message: `Must be at least ${min}`,
  }),

  /**
   * Validate maximum value
   */
  maxValue: (max: number) => ({
    validate: (value: unknown): boolean => {
      const num = Number(value);
      return !isNaN(num) && num <= max;
    },
    message: `Must be at most ${max}`,
  }),
};
