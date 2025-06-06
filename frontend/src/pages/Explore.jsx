"use client"

import { useState, useEffect, useCallback } from "react"
import { motion } from "framer-motion"
import MasonryGrid from "../components/MasonryGrid"
import CategorySlider from "../components/CategorySlider"
import { Search, Filter } from "lucide-react"

// Sample categories for the filter
const categories = [
  "All",
  "Digital Art",
  "Photography",
  "Illustration",
  "UI Design",
  "3D Art",
  "Fashion",
  "Architecture",
  "Nature",
  "Travel",
  "Food",
  "Technology",
  "Music",
  "Sports",
]

// Generate mock pins with different aspect ratios
const generateMockPins = (start, count) =>
  Array.from({ length: count }).map((_, i) => ({
    id: start + i,
    title: `Amazing ${["Art", "Photo", "Design", "Creative"][Math.floor(Math.random() * 4)]} #${start + i}`,
    user: `creator${start + i}`,
    image: `https://picsum.photos/seed/${start + i}/${300 + Math.floor(Math.random() * 300)}/${400 + Math.floor(Math.random() * 300)}`,
    likes: Math.floor(Math.random() * 1000),
    saves: Math.floor(Math.random() * 500),
    aspectRatio: 0.8 + Math.random() * 0.8, // Random aspect ratio between 0.8 and 1.6
  }))

export default function Explore() {
  const [pins, setPins] = useState([])
  const [loading, setLoading] = useState(false)
  const [hasMore, setHasMore] = useState(true)
  const [activeCategory, setActiveCategory] = useState("All")
  const [searchQuery, setSearchQuery] = useState("")
  const [showFilters, setShowFilters] = useState(false)
  const [page, setPage] = useState(0)

  // Load initial pins
  useEffect(() => {
    loadMorePins()
  }, [])

  // Handle category change
  useEffect(() => {
    // Reset and load new pins when category changes
    setPins([])
    setPage(0)
    setHasMore(true)
    loadMorePins(true)
  }, [activeCategory])

  // Load more pins function
  const loadMorePins = useCallback(
    (reset = false) => {
      if (loading || (!hasMore && !reset)) return

      setLoading(true)

      // Simulate API call with timeout
      setTimeout(() => {
        const newPage = reset ? 0 : page + 1
        const newPins = generateMockPins(newPage * 20, 20)

        setPins((prev) => (reset ? newPins : [...prev, ...newPins]))
        setPage(newPage)
        setHasMore(newPage < 5) // Limit to 5 pages for demo
        setLoading(false)
      }, 800)
    },
    [loading, hasMore, page],
  )

  // Handle pin visibility for infinite scrolling
  const handlePinVisible = useCallback(
    (pinId) => {
      // If we're seeing the last few pins, load more
      const pinIndex = pins.findIndex((p) => p.id === Number.parseInt(pinId))
      if (pinIndex > pins.length - 5 && hasMore && !loading) {
        loadMorePins()
      }
    },
    [pins, hasMore, loading, loadMorePins],
  )

  // Handle search input
  const handleSearchChange = (e) => {
    setSearchQuery(e.target.value)
  }

  // Handle search submit
  const handleSearchSubmit = (e) => {
    e.preventDefault()
    // Would typically trigger a search API call here
    console.log("Searching for:", searchQuery)

    // For demo, just reset and show loading state
    setPins([])
    setPage(0)
    setHasMore(true)
    loadMorePins(true)
  }

  return (
    <div className="min-h-screen bg-gray-50 pt-6">
      {/* Search and Filters Header */}
      <div className="sticky top-16 z-40 bg-white shadow-sm py-4">
        <div className="max-w-screen-2xl mx-auto px-4">
          <div className="flex flex-col gap-4">
            {/* Search Bar */}
            <form onSubmit={handleSearchSubmit} className="relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 h-5 w-5" />
              <input
                type="search"
                placeholder="Search for inspiration..."
                value={searchQuery}
                onChange={handleSearchChange}
                className="w-full pl-10 pr-4 py-3 bg-gray-100 rounded-full focus:outline-none focus:ring-2 focus:ring-inspira transition-all"
              />
              <button
                type="button"
                onClick={() => setShowFilters(!showFilters)}
                className="absolute right-3 top-1/2 transform -translate-y-1/2 p-1.5 rounded-full hover:bg-gray-200 transition-colors"
                aria-label="Toggle filters"
              >
                <Filter className="h-5 w-5 text-gray-500" />
              </button>
            </form>

            {/* Category Slider */}
            <CategorySlider
              categories={categories}
              activeCategory={activeCategory}
              onCategoryChange={setActiveCategory}
            />
          </div>
        </div>
      </div>

      {/* Advanced Filters (hidden by default) */}
      {showFilters && (
        <motion.div
          initial={{ height: 0, opacity: 0 }}
          animate={{ height: "auto", opacity: 1 }}
          exit={{ height: 0, opacity: 0 }}
          transition={{ duration: 0.3 }}
          className="bg-white border-t border-gray-100 shadow-sm overflow-hidden"
        >
          <div className="max-w-screen-2xl mx-auto px-4 py-4">
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              {/* Filter options would go here */}
              <div className="space-y-2">
                <h3 className="font-medium text-gray-700">Sort By</h3>
                <div className="flex flex-wrap gap-2">
                  <button className="px-3 py-1.5 bg-gray-100 rounded-full text-sm hover:bg-gray-200 transition-colors">
                    Most Recent
                  </button>
                  <button className="px-3 py-1.5 bg-gray-100 rounded-full text-sm hover:bg-gray-200 transition-colors">
                    Most Popular
                  </button>
                </div>
              </div>

              <div className="space-y-2">
                <h3 className="font-medium text-gray-700">Time Period</h3>
                <div className="flex flex-wrap gap-2">
                  <button className="px-3 py-1.5 bg-gray-100 rounded-full text-sm hover:bg-gray-200 transition-colors">
                    All Time
                  </button>
                  <button className="px-3 py-1.5 bg-gray-100 rounded-full text-sm hover:bg-gray-200 transition-colors">
                    This Month
                  </button>
                  <button className="px-3 py-1.5 bg-gray-100 rounded-full text-sm hover:bg-gray-200 transition-colors">
                    This Week
                  </button>
                </div>
              </div>

              <div className="space-y-2">
                <h3 className="font-medium text-gray-700">Color</h3>
                <div className="flex flex-wrap gap-2">
                  {["red", "blue", "green", "yellow", "purple", "pink"].map((color) => (
                    <button
                      key={color}
                      className="w-8 h-8 rounded-full border border-gray-200"
                      style={{ backgroundColor: color }}
                      aria-label={`Filter by ${color}`}
                    ></button>
                  ))}
                </div>
              </div>
            </div>
          </div>
        </motion.div>
      )}

      {/* Main Content */}
      <main className="py-6">
        {pins.length === 0 && loading ? (
          <div className="max-w-screen-2xl mx-auto px-4 grid grid-cols-2 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 2xl:grid-cols-6 gap-4">
            {Array.from({ length: 20 }).map((_, i) => (
              <div key={i} className="mb-6">
                <div
                  className="bg-gray-200 rounded-xl animate-pulse"
                  style={{ height: `${200 + Math.random() * 200}px` }}
                ></div>
                <div className="h-4 bg-gray-200 rounded animate-pulse mt-2 w-3/4"></div>
                <div className="h-4 bg-gray-200 rounded animate-pulse mt-2 w-1/2"></div>
              </div>
            ))}
          </div>
        ) : (
          <MasonryGrid pins={pins} onPinVisible={handlePinVisible} />
        )}

        {/* Loading indicator */}
        {loading && pins.length > 0 && (
          <div className="flex justify-center py-8">
            <div className="w-10 h-10 border-4 border-gray-200 border-t-inspira rounded-full animate-spin"></div>
          </div>
        )}

        {/* End of results */}
        {!hasMore && pins.length > 0 && !loading && (
          <div className="text-center py-10 text-gray-500">
            <p>You've reached the end of the results</p>
          </div>
        )}
      </main>
    </div>
  )
}
