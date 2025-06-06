/**
 * Combines multiple class names into a single string
 * @param {...string} classes - Class names to combine
 * @returns {string} Combined class names
 */
export function cn(...classes) {
  return classes.filter(Boolean).join(" ")
}

/**
 * Formats a number for display (e.g., 1000 -> 1k)
 * @param {number} num - Number to format
 * @returns {string} Formatted number
 */
export function formatNumber(num) {
  if (num >= 1000000) {
    return (num / 1000000).toFixed(1) + "M"
  }
  if (num >= 1000) {
    return (num / 1000).toFixed(1) + "k"
  }
  return num.toString()
}

/**
 * Formats a date for display
 * @param {string|Date} date - Date to format
 * @returns {string} Formatted date
 */
export function formatDate(date) {
  const d = new Date(date)
  return d.toLocaleDateString("en-US", {
    year: "numeric",
    month: "short",
    day: "numeric",
  })
}

/**
 * Debounces a function call
 * @param {Function} func - Function to debounce
 * @param {number} wait - Wait time in milliseconds
 * @returns {Function} Debounced function
 */
export function debounce(func, wait) {
  let timeout
  return function executedFunction(...args) {
    const later = () => {
      clearTimeout(timeout)
      func(...args)
    }
    clearTimeout(timeout)
    timeout = setTimeout(later, wait)
  }
}
