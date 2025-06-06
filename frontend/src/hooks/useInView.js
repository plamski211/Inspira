"use client"

import { useState, useEffect, useRef } from "react"

/**
 * Custom hook to detect when an element is in the viewport
 * @param {Object} options - IntersectionObserver options
 * @param {number} options.threshold - Percentage of element visible to trigger (0-1)
 * @param {string} options.root - Element that is used as the viewport
 * @param {string} options.rootMargin - Margin around the root
 * @param {boolean} options.triggerOnce - Whether to trigger only once
 * @returns {Array} [ref, inView] - Ref to attach to element and boolean indicating if in view
 */
export function useInView({ threshold = 0, root = null, rootMargin = "0px", triggerOnce = false } = {}) {
  const [inView, setInView] = useState(false)
  const ref = useRef(null)
  const enteredView = useRef(false)

  useEffect(() => {
    const node = ref.current

    // If the element doesn't exist or we've already triggered once, return
    if (!node || (triggerOnce && enteredView.current)) return

    const observer = new IntersectionObserver(
      ([entry]) => {
        const isIntersecting = entry.isIntersecting

        if (isIntersecting && triggerOnce) {
          enteredView.current = true
        }

        setInView(isIntersecting)
      },
      {
        threshold,
        root: root ? document.querySelector(root) : null,
        rootMargin,
      },
    )

    observer.observe(node)

    return () => {
      observer.disconnect()
    }
  }, [threshold, root, rootMargin, triggerOnce])

  return [ref, inView]
}
