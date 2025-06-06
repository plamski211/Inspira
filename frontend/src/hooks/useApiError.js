"use client"

import { useState, useCallback } from "react"
import { useToast } from "@/components/ui/Toast"

/**
 * Hook for handling API errors
 * @returns {Object} - Error handling utilities
 */
export function useApiError() {
  const [error, setError] = useState(null)
  const [isLoading, setIsLoading] = useState(false)
  const { error: showErrorToast } = useToast()

  /**
   * Handles API errors
   * @param {Error} error - Error object
   * @param {Object} options - Error handling options
   * @param {boolean} options.showToast - Whether to show a toast notification
   * @param {string} options.fallbackMessage - Fallback error message
   */
  const handleError = useCallback(
    (error, { showToast = true, fallbackMessage = "An error occurred" } = {}) => {
      console.error("API Error:", error)

      setError(error)

      if (showToast) {
        const errorMessage = error?.message || fallbackMessage
        showErrorToast({
          title: "Error",
          description: errorMessage,
        })
      }
    },
    [showErrorToast],
  )

  /**
   * Wraps an async function with error handling
   * @param {Function} fn - Async function to wrap
   * @param {Object} options - Error handling options
   * @returns {Function} - Wrapped function
   */
  const withErrorHandling = useCallback(
    (fn, options = {}) => {
      return async (...args) => {
        try {
          setIsLoading(true)
          setError(null)
          return await fn(...args)
        } catch (err) {
          handleError(err, options)
          throw err
        } finally {
          setIsLoading(false)
        }
      }
    },
    [handleError],
  )

  return {
    error,
    isLoading,
    handleError,
    withErrorHandling,
    clearError: () => setError(null),
  }
}
