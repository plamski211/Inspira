"use client"

import { useState, useEffect, memo } from "react"
import { cn } from "@/utils"

const LazyImage = ({ src, alt, className, placeholderClassName, width, height, onLoad: onLoadProp, ...props }) => {
  const [isLoaded, setIsLoaded] = useState(false)
  const [error, setError] = useState(false)
  const [imageSrc, setImageSrc] = useState(null)

  useEffect(() => {
    // Reset states when src changes
    setIsLoaded(false)
    setError(false)

    // Create new image object to preload
    const img = new Image()
    img.src = src

    img.onload = () => {
      setImageSrc(src)
      setIsLoaded(true)
      if (onLoadProp) onLoadProp()
    }

    img.onerror = () => {
      setError(true)
      // Set to placeholder or fallback image
      setImageSrc("/placeholder.svg")
    }

    return () => {
      img.onload = null
      img.onerror = null
    }
  }, [src, onLoadProp])

  return (
    <div className="relative overflow-hidden" style={{ width, height }}>
      {/* Placeholder/skeleton */}
      <div
        className={cn(
          "absolute inset-0 bg-gray-200 animate-pulse",
          isLoaded && !error ? "opacity-0" : "opacity-100",
          placeholderClassName,
        )}
        aria-hidden="true"
      />

      {/* Actual image */}
      {imageSrc && (
        <img
          src={imageSrc || "/placeholder.svg"}
          alt={alt || ""}
          className={cn("transition-opacity duration-300", isLoaded ? "opacity-100" : "opacity-0", className)}
          loading="lazy"
          {...props}
        />
      )}
    </div>
  )
}

export default memo(LazyImage)
