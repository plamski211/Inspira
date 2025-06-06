"use client"

import { useState, useEffect, memo } from "react"
import { useInView } from "react-intersection-observer"
import { cn } from "@/utils"

/**
 * Responsive image component with lazy loading and srcset support
 * @param {Object} props - Component props
 * @param {string} props.src - Default image source
 * @param {Object} props.srcSet - Object mapping breakpoints to image sources
 * @param {string} props.alt - Image alt text
 * @param {string} props.sizes - Image sizes attribute
 * @param {string} props.className - Additional CSS classes
 * @param {Function} props.onLoad - Callback when image loads
 * @param {string} props.objectFit - Object-fit style
 * @param {string} props.objectPosition - Object-position style
 * @param {boolean} props.priority - Whether to load the image with priority
 * @returns {JSX.Element} - Responsive image component
 */
const ResponsiveImage = ({
  src,
  srcSet = {},
  alt = "",
  sizes = "100vw",
  className,
  onLoad,
  objectFit = "cover",
  objectPosition = "center",
  priority = false,
  ...props
}) => {
  const [isLoaded, setIsLoaded] = useState(false)
  const [error, setError] = useState(false)
  const { ref, inView } = useInView({
    triggerOnce: true,
    rootMargin: "200px 0px",
  })

  // Format srcset string from srcSet object
  const formatSrcSet = () => {
    if (!srcSet || Object.keys(srcSet).length === 0) return undefined

    return Object.entries(srcSet)
      .map(([width, url]) => `${url} ${width}w`)
      .join(", ")
  }

  const handleLoad = (e) => {
    setIsLoaded(true)
    if (onLoad) onLoad(e)
  }

  const handleError = () => {
    setError(true)
    console.error(`Failed to load image: ${src}`)
  }

  // Reset states when src changes
  useEffect(() => {
    setIsLoaded(false)
    setError(false)
  }, [src])

  return (
    <div
      ref={ref}
      className={cn("relative overflow-hidden", className)}
      style={{
        aspectRatio: props.width && props.height ? `${props.width} / ${props.height}` : undefined,
      }}
    >
      {/* Placeholder/skeleton */}
      {!isLoaded && !error && <div className="absolute inset-0 bg-gray-200 animate-pulse" aria-hidden="true" />}

      {/* Error fallback */}
      {error && (
        <div className="absolute inset-0 flex items-center justify-center bg-gray-100 text-gray-400">
          <span className="text-sm">Image not available</span>
        </div>
      )}

      {/* Actual image */}
      {(inView || priority) && (
        <img
          src={src || "/placeholder.svg"}
          srcSet={formatSrcSet()}
          sizes={sizes}
          alt={alt}
          onLoad={handleLoad}
          onError={handleError}
          loading={priority ? "eager" : "lazy"}
          className={cn("transition-opacity duration-300", isLoaded ? "opacity-100" : "opacity-0", "w-full h-full")}
          style={{
            objectFit,
            objectPosition,
          }}
          {...props}
        />
      )}
    </div>
  )
}

export default memo(ResponsiveImage)
