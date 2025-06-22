"use client"

import { useRef, useEffect, useState, useCallback, memo } from "react"
import { useInView } from "react-intersection-observer"
import PinCard from "./PinCard"

const MasonryGrid = ({ pins, onPinVisible }) => {
  const gridRef = useRef(null)
  const [columns, setColumns] = useState([])
  const [visibleItems, setVisibleItems] = useState(new Set())

  // Use intersection observer for infinite scrolling
  const { ref: loadMoreRef, inView } = useInView({
    threshold: 0.1,
    triggerOnce: false,
  })

  // Notify parent when bottom is reached
  useEffect(() => {
    if (inView && onPinVisible) {
      onPinVisible("load-more")
    }
  }, [inView, onPinVisible])

  // Determine optimal column count based on screen width
  const calculateColumns = useCallback(() => {
    const width = window.innerWidth
    let cols = 2 // Default for mobile

    if (width >= 1536)
      cols = 6 // 2xl
    else if (width >= 1280)
      cols = 5 // xl
    else if (width >= 1024)
      cols = 4 // lg
    else if (width >= 768)
      cols = 3 // md
    else if (width >= 640) cols = 2 // sm

    // Distribute pins among columns
    const newColumns = Array.from({ length: cols }, () => [])

    pins.forEach((pin, index) => {
      // Add to the shortest column for balanced layout
      const shortestColumnIndex = newColumns
        .map((column, i) => ({
          height: column.reduce((sum, p) => sum + (p.aspectRatio || 1.5), 0),
          index: i,
        }))
        .sort((a, b) => a.height - b.height)[0].index

      newColumns[shortestColumnIndex].push(pin)
    })

    setColumns(newColumns)
  }, [pins])

  // Recalculate columns on window resize
  useEffect(() => {
    calculateColumns()

    const handleResize = () => {
      calculateColumns()
    }

    window.addEventListener("resize", handleResize)
    return () => window.removeEventListener("resize", handleResize)
  }, [calculateColumns])

  // Track which pins are visible
  const handlePinInView = useCallback(
    (pinId) => {
      if (!visibleItems.has(pinId)) {
        setVisibleItems((prev) => {
          const newSet = new Set(prev)
          newSet.add(pinId)
          return newSet
        })

        if (onPinVisible) {
          onPinVisible(pinId)
        }
      }
    },
    [visibleItems, onPinVisible],
  )

  return (
    <div
      ref={gridRef}
      className="w-full max-w-screen-2xl mx-auto px-4 grid grid-cols-2 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 2xl:grid-cols-6 gap-4"
    >
      {columns.map((column, colIndex) => (
        <div key={colIndex} className="flex flex-col gap-4">
          {column.map((pin) => (
            <PinObserver key={pin.id} pin={pin} onInView={handlePinInView} />
          ))}
        </div>
      ))}

      {/* Load more trigger element */}
      <div ref={loadMoreRef} className="col-span-full h-10" />
    </div>
  )
}

// Component to observe when a pin comes into view
const PinObserver = memo(({ pin, onInView }) => {
  const { ref, inView } = useInView({
    threshold: 0.1,
    triggerOnce: true,
  })

  useEffect(() => {
    if (inView) {
      onInView(pin.id)
    }
  }, [inView, pin.id, onInView])

  return (
    <div ref={ref} data-pin-id={pin.id}>
      <PinCard pin={pin} />
    </div>
  )
})

export default memo(MasonryGrid)
