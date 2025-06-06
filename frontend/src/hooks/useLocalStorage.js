"use client"

import { useState, useEffect } from "react"

/**
 * Hook to use localStorage with React state
 * @param {string} key - localStorage key
 * @param {any} initialValue - Initial value if key doesn't exist
 * @returns {[any, Function]} State and setter function
 */
export function useLocalStorage(key, initialValue) {
  // Get from localStorage on initial render
  const [storedValue, setStoredValue] = useState(() => {
    if (typeof window === "undefined") {
      return initialValue
    }

    try {
      const item = window.localStorage.getItem(key)
      return item ? JSON.parse(item) : initialValue
    } catch (error) {
      console.error(error)
      return initialValue
    }
  })

  // Update localStorage when state changes
  useEffect(() => {
    if (typeof window !== "undefined") {
      try {
        window.localStorage.setItem(key, JSON.stringify(storedValue))
      } catch (error) {
        console.error(error)
      }
    }
  }, [key, storedValue])

  return [storedValue, setStoredValue]
}
