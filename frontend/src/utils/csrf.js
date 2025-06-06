/**
 * CSRF protection utility functions
 */

/**
 * Generates a CSRF token
 * @returns {string} - CSRF token
 */
export function generateCsrfToken() {
  const array = new Uint8Array(32)
  crypto.getRandomValues(array)
  return Array.from(array, (byte) => byte.toString(16).padStart(2, "0")).join("")
}

/**
 * Stores a CSRF token in localStorage
 * @param {string} token - CSRF token
 */
export function storeCsrfToken(token) {
  localStorage.setItem("csrf_token", token)
}

/**
 * Gets the stored CSRF token from localStorage
 * @returns {string|null} - CSRF token or null if not found
 */
export function getCsrfToken() {
  return localStorage.getItem("csrf_token")
}

/**
 * Validates a CSRF token
 * @param {string} token - CSRF token to validate
 * @returns {boolean} - Whether the token is valid
 */
export function validateCsrfToken(token) {
  const storedToken = getCsrfToken()
  return storedToken && token === storedToken
}

/**
 * Adds a CSRF token to a fetch request
 * @param {Object} options - Fetch options
 * @returns {Object} - Fetch options with CSRF token
 */
export function addCsrfToken(options = {}) {
  const token = getCsrfToken()

  if (!token) {
    console.error("CSRF token not found")
    return options
  }

  return {
    ...options,
    headers: {
      ...options.headers,
      "X-CSRF-Token": token,
    },
  }
}

/**
 * Initializes CSRF protection
 */
export function initCsrfProtection() {
  if (!getCsrfToken()) {
    const token = generateCsrfToken()
    storeCsrfToken(token)
  }
}
