"use client"

import { useState, memo } from "react"
import { Link } from "react-router-dom"
import { Heart, Bookmark, Share2, MoreHorizontal } from "lucide-react"

const PinCard = ({ pin }) => {
  const [isHovered, setIsHovered] = useState(false)
  const [isLoaded, setIsLoaded] = useState(false)
  const [liked, setLiked] = useState(false)
  const [saved, setSaved] = useState(false)

  const handleLike = (e) => {
    e.preventDefault()
    e.stopPropagation()
    setLiked(!liked)
  }

  const handleSave = (e) => {
    e.preventDefault()
    e.stopPropagation()
    setSaved(!saved)
  }

  const handleShare = (e) => {
    e.preventDefault()
    e.stopPropagation()
    // Share functionality would go here
  }

  const handleMore = (e) => {
    e.preventDefault()
    e.stopPropagation()
    // More options functionality would go here
  }

  return (
    <Link to={`/pin/${pin.id}`}>
      <div
        className="relative mb-6 rounded-xl overflow-hidden group"
        onMouseEnter={() => setIsHovered(true)}
        onMouseLeave={() => setIsHovered(false)}
      >
        {/* Image container with aspect ratio */}
        <div className="relative w-full overflow-hidden bg-gray-200 rounded-xl">
          <div
            className={`absolute inset-0 bg-gray-200 animate-pulse ${isLoaded ? "hidden" : "block"}`}
            style={{ aspectRatio: "auto" }}
            aria-hidden="true"
          ></div>
          <img
            src={pin.image || "/placeholder.svg"}
            alt={pin.title || "Pin image"}
            className={`w-full object-cover transition-transform duration-500 ${
              isHovered ? "scale-105" : "scale-100"
            } ${isLoaded ? "opacity-100" : "opacity-0"}`}
            onLoad={() => setIsLoaded(true)}
            loading="lazy"
          />

          {/* Gradient overlay on hover */}
          <div
            className={`absolute inset-0 bg-gradient-to-b from-black/0 via-black/0 to-black/50 transition-opacity duration-300 ${
              isHovered ? "opacity-100" : "opacity-0"
            }`}
            aria-hidden="true"
          ></div>

          {/* Action buttons on hover */}
          <div
            className={`absolute top-2 right-2 flex flex-col gap-2 transition-all duration-300 ${
              isHovered ? "opacity-100 translate-y-0" : "opacity-0 -translate-y-2"
            }`}
          >
            <button
              onClick={handleSave}
              className={`p-2 rounded-full shadow-lg backdrop-blur-md transition-colors ${
                saved ? "bg-inspira text-white" : "bg-white/90 text-gray-700 hover:bg-white"
              }`}
              aria-label={saved ? "Unsave" : "Save"}
            >
              <Bookmark className="w-4 h-4" />
            </button>
            <button
              onClick={handleMore}
              className="p-2 rounded-full shadow-lg backdrop-blur-md bg-white/90 text-gray-700 hover:bg-white transition-colors"
              aria-label="More options"
            >
              <MoreHorizontal className="w-4 h-4" />
            </button>
          </div>

          {/* Bottom action bar on hover */}
          <div
            className={`absolute bottom-0 left-0 right-0 flex justify-between items-center p-3 transition-all duration-300 ${
              isHovered ? "opacity-100 translate-y-0" : "opacity-0 translate-y-2"
            }`}
          >
            <div className="flex gap-2">
              <button
                onClick={handleLike}
                className={`p-2 rounded-full shadow-lg backdrop-blur-md transition-colors ${
                  liked ? "bg-red-500 text-white" : "bg-white/90 text-gray-700 hover:bg-white"
                }`}
                aria-label={liked ? "Unlike" : "Like"}
              >
                <Heart className={`w-4 h-4 ${liked ? "fill-current" : ""}`} />
              </button>
              <button
                onClick={handleShare}
                className="p-2 rounded-full shadow-lg backdrop-blur-md bg-white/90 text-gray-700 hover:bg-white transition-colors"
                aria-label="Share"
              >
                <Share2 className="w-4 h-4" />
              </button>
            </div>
          </div>
        </div>

        {/* Card content */}
        <div className="p-2 mt-2">
          <h3 className="font-medium text-gray-900 line-clamp-1">{pin.title}</h3>
          <div className="flex items-center gap-2 mt-2">
            <img
              src={`https://i.pravatar.cc/150?u=${pin.user}`}
              alt={`${pin.user}'s avatar`}
              className="w-6 h-6 rounded-full object-cover border border-white"
            />
            <span className="text-sm text-gray-600">{pin.user}</span>
          </div>
        </div>
      </div>
    </Link>
  )
}

// Memoize the component to prevent unnecessary re-renders
export default memo(PinCard)
