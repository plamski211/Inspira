"use client"

import { useState, useEffect } from "react"
import {
  breakpoints,
  isMinWidth,
  isMaxWidth,
  isBetweenWidths,
  getCurrentBreakpoint,
  isTouchDevice,
  isPortrait,
  isLandscape,
} from "@/utils/responsive"

/**
 * Hook for responsive design
 * @returns {Object} - Responsive utilities and state
 */
export function useResponsive() {
  const [state, setState] = useState({
    breakpoint: "xs",
    width: 0,
    height: 0,
    isMobile: false,
    isTablet: false,
    isDesktop: false,
    isPortrait: true,
    isLandscape: false,
    isTouchDevice: false,
  })

  useEffect(() => {
    const updateState = () => {
      const width = window.innerWidth
      const height = window.innerHeight
      const breakpoint = getCurrentBreakpoint()

      setState({
        breakpoint,
        width,
        height,
        isMobile: isMaxWidth("sm"),
        isTablet: isBetweenWidths("sm", "lg"),
        isDesktop: isMinWidth("lg"),
        isPortrait: isPortrait(),
        isLandscape: isLandscape(),
        isTouchDevice: isTouchDevice(),
      })
    }

    // Initial update
    updateState()

    // Update on resize
    window.addEventListener("resize", updateState)

    // Update on orientation change
    window.addEventListener("orientationchange", updateState)

    return () => {
      window.removeEventListener("resize", updateState)
      window.removeEventListener("orientationchange", updateState)
    }
  }, [])

  return {
    ...state,
    breakpoints,
    isMinWidth: (bp) => isMinWidth(bp),
    isMaxWidth: (bp) => isMaxWidth(bp),
    isBetweenWidths: (minBp, maxBp) => isBetweenWidths(minBp, maxBp),
  }
}
