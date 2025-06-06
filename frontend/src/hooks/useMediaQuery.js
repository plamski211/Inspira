"use client"

import { useState, useEffect } from "react"

/**
 * Hook to check if a media query matches
 * @param {string} query - Media query to check
 * @returns {boolean} Whether the media query matches
 */
export function useMediaQuery(query) {
  const [matches, setMatches] = useState(false)

  useEffect(() => {
    const media = window.matchMedia(query)

    // Update matches state initially
    setMatches(media.matches)

    // Define listener function
    const listener = (event) => {
      setMatches(event.matches)
    }

    // Add listener
    media.addEventListener("change", listener)

    // Clean up
    return () => {
      media.removeEventListener("change", listener)
    }
  }, [query])

  return matches
}

// Predefined media query hooks
export function useIsMobile() {
  return useMediaQuery("(max-width: 639px)")
}

export function useIsTablet() {
  return useMediaQuery("(min-width: 640px) and (max-width: 1023px)")
}

export function useIsDesktop() {
  return useMediaQuery("(min-width: 1024px)")
}
