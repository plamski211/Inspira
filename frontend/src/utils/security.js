/**
 * Security utility functions
 */

/**
 * Sanitizes a string to prevent XSS attacks
 * @param {string} input - String to sanitize
 * @returns {string} - Sanitized string
 */
export function sanitizeString(input) {
  if (!input || typeof input !== "string") return ""

  const div = document.createElement("div")
  div.textContent = input
  return div.innerHTML
}

/**
 * Sanitizes an object's string properties to prevent XSS attacks
 * @param {Object} obj - Object to sanitize
 * @returns {Object} - Sanitized object
 */
export function sanitizeObject(obj) {
  if (!obj || typeof obj !== "object") return {}

  const sanitized = {}

  for (const [key, value] of Object.entries(obj)) {
    if (typeof value === "string") {
      sanitized[key] = sanitizeString(value)
    } else if (typeof value === "object" && value !== null) {
      sanitized[key] = sanitizeObject(value)
    } else {
      sanitized[key] = value
    }
  }

  return sanitized
}

/**
 * Validates a URL to prevent open redirect vulnerabilities
 * @param {string} url - URL to validate
 * @param {Array<string>} allowedDomains - Allowed domains
 * @returns {boolean} - Whether the URL is valid
 */
export function isValidUrl(url, allowedDomains = []) {
  if (!url || typeof url !== "string") return false

  try {
    const parsedUrl = new URL(url)

    // Check if URL is relative
    if (url.startsWith("/") && !url.startsWith("//")) {
      return true
    }

    // Check if URL is from an allowed domain
    if (allowedDomains.length > 0) {
      return allowedDomains.some((domain) => parsedUrl.hostname === domain || parsedUrl.hostname.endsWith(`.${domain}`))
    }

    // Check if URL is from the same origin
    if (typeof window !== "undefined") {
      return parsedUrl.origin === window.location.origin
    }

    return false
  } catch (error) {
    return false
  }
}

/**
 * Creates a Content Security Policy nonce
 * @returns {string} - CSP nonce
 */
export function generateCspNonce() {
  const array = new Uint8Array(16)
  crypto.getRandomValues(array)
  return Array.from(array, (byte) => byte.toString(16).padStart(2, "0")).join("")
}

/**
 * Validates and sanitizes user input
 * @param {Object} input - User input
 * @param {Object} schema - Validation schema
 * @returns {Object} - Validated and sanitized input
 */
export function validateAndSanitizeInput(input, schema) {
  if (!input || !schema) return {}

  const validated = {}

  for (const [key, validator] of Object.entries(schema)) {
    if (key in input) {
      const value = input[key]

      if (validator.type === "string" && typeof value === "string") {
        // Validate string
        if (validator.pattern && !validator.pattern.test(value)) {
          continue
        }

        // Sanitize string
        validated[key] = sanitizeString(value)
      } else if (validator.type === "number" && typeof value === "number") {
        // Validate number
        if (validator.min !== undefined && value < validator.min) {
          continue
        }
        if (validator.max !== undefined && value > validator.max) {
          continue
        }

        validated[key] = value
      } else if (validator.type === "boolean" && typeof value === "boolean") {
        validated[key] = value
      } else if (validator.type === "array" && Array.isArray(value)) {
        // Validate array
        if (validator.itemType === "string") {
          validated[key] = value.filter((item) => typeof item === "string").map((item) => sanitizeString(item))
        } else {
          validated[key] = value
        }
      }
    }
  }

  return validated
}
