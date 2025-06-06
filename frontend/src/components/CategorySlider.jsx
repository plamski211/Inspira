"use client"

import { useState, useRef, useEffect } from "react"
import { ChevronLeft, ChevronRight } from "lucide-react"

export default function CategorySlider({ categories, activeCategory, onCategoryChange }) {
  const sliderRef = useRef(null)
  const [showLeftArrow, setShowLeftArrow] = useState(false)
  const [showRightArrow, setShowRightArrow] = useState(true)

  const scrollLeft = () => {
    if (sliderRef.current) {
      sliderRef.current.scrollBy({ left: -200, behavior: "smooth" })
    }
  }

  const scrollRight = () => {
    if (sliderRef.current) {
      sliderRef.current.scrollBy({ left: 200, behavior: "smooth" })
    }
  }

  const handleScroll = () => {
    if (sliderRef.current) {
      const { scrollLeft, scrollWidth, clientWidth } = sliderRef.current
      setShowLeftArrow(scrollLeft > 0)
      setShowRightArrow(scrollLeft < scrollWidth - clientWidth - 10)
    }
  }

  useEffect(() => {
    const slider = sliderRef.current
    if (slider) {
      slider.addEventListener("scroll", handleScroll)
      // Check initial state
      handleScroll()
      return () => slider.removeEventListener("scroll", handleScroll)
    }
  }, [])

  return (
    <div className="relative w-full">
      {/* Left scroll button */}
      {showLeftArrow && (
        <button
          onClick={scrollLeft}
          className="absolute left-0 top-1/2 -translate-y-1/2 z-10 bg-white rounded-full shadow-md p-2 hover:bg-gray-50 transition-colors"
          aria-label="Scroll left"
        >
          <ChevronLeft className="h-5 w-5 text-gray-600" />
        </button>
      )}

      {/* Categories slider */}
      <div
        ref={sliderRef}
        className="flex overflow-x-auto scrollbar-hide py-2 px-2 -mx-2 scroll-smooth"
        style={{ scrollbarWidth: "none", msOverflowStyle: "none" }}
      >
        {categories.map((category) => (
          <button
            key={category.id || category}
            onClick={() => onCategoryChange(category.id || category)}
            className={`whitespace-nowrap px-4 py-2 rounded-full mx-1 transition-colors ${
              activeCategory === (category.id || category)
                ? "bg-inspira text-white font-medium"
                : "bg-gray-100 text-gray-700 hover:bg-gray-200"
            }`}
          >
            {category.name || category}
          </button>
        ))}
      </div>

      {/* Right scroll button */}
      {showRightArrow && (
        <button
          onClick={scrollRight}
          className="absolute right-0 top-1/2 -translate-y-1/2 z-10 bg-white rounded-full shadow-md p-2 hover:bg-gray-50 transition-colors"
          aria-label="Scroll right"
        >
          <ChevronRight className="h-5 w-5 text-gray-600" />
        </button>
      )}
    </div>
  )
}
