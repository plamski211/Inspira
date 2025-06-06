/**
 * Responsive design utility functions
 */

// Breakpoint values (in pixels)
export const breakpoints = {
  xs: 0,
  sm: 640,
  md: 768,
  lg: 1024,
  xl: 1280,
  "2xl": 1536,
}

/**
 * Checks if the current viewport matches a media query
 * @param {string} query - Media query to check
 * @returns {boolean} - Whether the media query matches
 */
export function matchesMediaQuery(query) {
  if (typeof window === "undefined" || typeof window.matchMedia !== "function") {
    return false
  }

  return window.matchMedia(query).matches
}

/**
 * Checks if the current viewport is at least a certain width
 * @param {string|number} breakpoint - Breakpoint name or width in pixels
 * @returns {boolean} - Whether the viewport is at least the specified width
 */
export function isMinWidth(breakpoint) {
  const width = typeof breakpoint === "string" ? breakpoints[breakpoint] : breakpoint

  if (typeof width !== "number") {
    console.error(`Invalid breakpoint: ${breakpoint}`)
    return false
  }

  return matchesMediaQuery(`(min-width: ${width}px)`)
}

/**
 * Checks if the current viewport is at most a certain width
 * @param {string|number} breakpoint - Breakpoint name or width in pixels
 * @returns {boolean} - Whether the viewport is at most the specified width
 */
export function isMaxWidth(breakpoint) {
  const width = typeof breakpoint === "string" ? breakpoints[breakpoint] : breakpoint

  if (typeof width !== "number") {
    console.error(`Invalid breakpoint: ${breakpoint}`)
    return false
  }

  return matchesMediaQuery(`(max-width: ${width - 0.02}px)`)
}

/**
 * Checks if the current viewport is between two widths
 * @param {string|number} minBreakpoint - Minimum breakpoint name or width in pixels
 * @param {string|number} maxBreakpoint - Maximum breakpoint name or width in pixels
 * @returns {boolean} - Whether the viewport is between the specified widths
 */
export function isBetweenWidths(minBreakpoint, maxBreakpoint) {
  return isMinWidth(minBreakpoint) && isMaxWidth(maxBreakpoint)
}

/**
 * Gets the current breakpoint name
 * @returns {string} - Current breakpoint name
 */
export function getCurrentBreakpoint() {
  if (isMinWidth("2xl")) return "2xl"
  if (isMinWidth("xl")) return "xl"
  if (isMinWidth("lg")) return "lg"
  if (isMinWidth("md")) return "md"
  if (isMinWidth("sm")) return "sm"
  return "xs"
}

/**
 * Checks if the device is likely a touch device
 * @returns {boolean} - Whether the device is likely a touch device
 */
export function isTouchDevice() {
  if (typeof window === "undefined") return false

  return "ontouchstart" in window || navigator.maxTouchPoints > 0 || navigator.msMaxTouchPoints > 0
}

/**
 * Checks if the device is in portrait orientation
 * @returns {boolean} - Whether the device is in portrait orientation
 */
export function isPortrait() {
  return matchesMediaQuery("(orientation: portrait)")
}

/**
 * Checks if the device is in landscape orientation
 * @returns {boolean} - Whether the device is in landscape orientation
 */
export function isLandscape() {
  return matchesMediaQuery("(orientation: landscape)")
}
