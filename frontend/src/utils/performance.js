/**
 * Utility functions for performance monitoring
 */

// Check if the Performance API is available
const isPerformanceSupported = () => {
  return (
    typeof window !== "undefined" &&
    typeof window.performance !== "undefined" &&
    typeof window.performance.mark === "function" &&
    typeof window.performance.measure === "function"
  )
}

/**
 * Marks the start of a performance measurement
 * @param {string} name - Name of the measurement
 */
export function startMeasure(name) {
  if (!isPerformanceSupported()) return

  try {
    performance.mark(`${name}-start`)
  } catch (error) {
    console.error("Error starting performance measurement:", error)
  }
}

/**
 * Ends a performance measurement and logs the result
 * @param {string} name - Name of the measurement
 * @param {boolean} log - Whether to log the result to console
 * @returns {number|null} - Duration in milliseconds or null if measurement failed
 */
export function endMeasure(name, log = true) {
  if (!isPerformanceSupported()) return null

  try {
    performance.mark(`${name}-end`)
    performance.measure(name, `${name}-start`, `${name}-end`)

    const entries = performance.getEntriesByName(name)
    const duration = entries[0]?.duration

    if (log) {
      console.log(`⏱️ ${name}: ${duration.toFixed(2)}ms`)
    }

    // Clean up
    performance.clearMarks(`${name}-start`)
    performance.clearMarks(`${name}-end`)
    performance.clearMeasures(name)

    return duration
  } catch (error) {
    console.error("Error ending performance measurement:", error)
    return null
  }
}

/**
 * Measures the execution time of a function
 * @param {Function} fn - Function to measure
 * @param {string} name - Name of the measurement
 * @param {boolean} log - Whether to log the result to console
 * @returns {any} - Result of the function
 */
export function measureFunction(fn, name, log = true) {
  startMeasure(name)
  const result = fn()
  endMeasure(name, log)
  return result
}

/**
 * Measures the execution time of an async function
 * @param {Function} fn - Async function to measure
 * @param {string} name - Name of the measurement
 * @param {boolean} log - Whether to log the result to console
 * @returns {Promise<any>} - Result of the async function
 */
export async function measureAsyncFunction(fn, name, log = true) {
  startMeasure(name)
  try {
    const result = await fn()
    endMeasure(name, log)
    return result
  } catch (error) {
    endMeasure(name, log)
    throw error
  }
}

/**
 * Creates a higher-order function that measures execution time
 * @param {Function} fn - Function to wrap
 * @param {string} name - Name of the measurement
 * @param {boolean} log - Whether to log the result to console
 * @returns {Function} - Wrapped function
 */
export function withPerformanceMeasurement(fn, name, log = true) {
  return (...args) => {
    startMeasure(name)
    try {
      const result = fn(...args)

      // Handle promises
      if (result instanceof Promise) {
        return result.finally(() => {
          endMeasure(name, log)
        })
      }

      endMeasure(name, log)
      return result
    } catch (error) {
      endMeasure(name, log)
      throw error
    }
  }
}

/**
 * Reports performance metrics to an analytics service
 * @param {Object} metrics - Performance metrics to report
 */
export function reportPerformanceMetrics(metrics) {
  // This would connect to your analytics service
  // Example: analytics.trackPerformance(metrics)
  console.log("📊 Performance metrics:", metrics)
}

/**
 * Collects web vitals metrics
 */
export function collectWebVitals() {
  if (typeof window === "undefined" || !("web-vitals" in window)) {
    return
  }

  try {
    const { getCLS, getFID, getLCP, getFCP, getTTFB } = window["web-vitals"]

    getCLS((metric) => reportPerformanceMetrics({ CLS: metric.value }))
    getFID((metric) => reportPerformanceMetrics({ FID: metric.value }))
    getLCP((metric) => reportPerformanceMetrics({ LCP: metric.value }))
    getFCP((metric) => reportPerformanceMetrics({ FCP: metric.value }))
    getTTFB((metric) => reportPerformanceMetrics({ TTFB: metric.value }))
  } catch (error) {
    console.error("Error collecting web vitals:", error)
  }
}
