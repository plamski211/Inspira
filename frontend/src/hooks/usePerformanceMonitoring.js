"use client"

import { useEffect, useRef } from "react"
import { startMeasure, endMeasure } from "@/utils/performance"

/**
 * Hook for monitoring component performance
 * @param {string} componentName - Name of the component
 * @param {Object} options - Monitoring options
 * @param {boolean} options.renderTime - Whether to measure render time
 * @param {boolean} options.mountTime - Whether to measure mount time
 * @param {boolean} options.updateTime - Whether to measure update time
 * @param {boolean} options.unmountTime - Whether to measure unmount time
 * @returns {Object} - Performance monitoring utilities
 */
export function usePerformanceMonitoring(
  componentName,
  { renderTime = true, mountTime = true, updateTime = true, unmountTime = true } = {},
) {
  const renderCount = useRef(0)
  const isMounted = useRef(false)

  // Measure render time
  if (renderTime) {
    renderCount.current++
    const renderLabel = `${componentName}-render-${renderCount.current}`
    startMeasure(renderLabel)

    // Use setTimeout to ensure we measure after the render is complete
    setTimeout(() => {
      endMeasure(renderLabel)
    }, 0)
  }

  // Measure mount and update time
  useEffect(() => {
    if (!isMounted.current) {
      // First render - component mounted
      isMounted.current = true

      if (mountTime) {
        endMeasure(`${componentName}-mount`)
      }
    } else if (updateTime) {
      // Subsequent renders - component updated
      endMeasure(`${componentName}-update-${renderCount.current}`)
    }

    return () => {
      if (unmountTime && isMounted.current) {
        startMeasure(`${componentName}-unmount`)

        // Use setTimeout to ensure we measure after the unmount is complete
        setTimeout(() => {
          endMeasure(`${componentName}-unmount`)
        }, 0)
      }
    }
  })

  // Start measuring mount time
  if (mountTime && !isMounted.current) {
    startMeasure(`${componentName}-mount`)
  }

  // Start measuring update time
  if (updateTime && isMounted.current) {
    startMeasure(`${componentName}-update-${renderCount.current}`)
  }

  return {
    measureOperation: (name, fn) => {
      const operationLabel = `${componentName}-${name}`
      startMeasure(operationLabel)
      const result = fn()

      if (result instanceof Promise) {
        return result.finally(() => {
          endMeasure(operationLabel)
        })
      }

      endMeasure(operationLabel)
      return result
    },
  }
}
