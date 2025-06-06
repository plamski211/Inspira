"use client"

import { motion } from "framer-motion"
import HeroSection from "../components/HeroSection"
import FeaturedCategories from "../components/FeaturedCategories"
import MasonryGrid from "../components/MasonryGrid"
import { useState, useEffect } from "react"
import { Link } from "react-router-dom"
import { ArrowRight } from "lucide-react"

// Sample categories
const categories = [
  {
    id: "digital-art",
    name: "Digital Art",
    img: "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?q=80&w=2064&auto=format&fit=crop",
  },
  {
    id: "photography",
    name: "Photography",
    img: "https://images.unsplash.com/photo-1554080353-a576cf803bda?q=80&w=2074&auto=format&fit=crop",
  },
  {
    id: "illustration",
    name: "Illustration",
    img: "https://images.unsplash.com/photo-1618761714954-0b8cd0026356?q=80&w=2070&auto=format&fit=crop",
  },
  {
    id: "ui-design",
    name: "UI Design",
    img: "https://images.unsplash.com/photo-1545235617-7a424c1a60cc?q=80&w=2080&auto=format&fit=crop",
  },
  {
    id: "3d-art",
    name: "3D Art",
    img: "https://images.unsplash.com/photo-1633356122544-f134324a6cee?q=80&w=2070&auto=format&fit=crop",
  },
  {
    id: "fashion",
    name: "Fashion",
    img: "https://images.unsplash.com/photo-1445205170230-053b83016050?q=80&w=2071&auto=format&fit=crop",
  },
  {
    id: "architecture",
    name: "Architecture",
    img: "https://images.unsplash.com/photo-1487958449943-2429e8be8625?q=80&w=2070&auto=format&fit=crop",
  },
  {
    id: "nature",
    name: "Nature",
    img: "https://images.unsplash.com/photo-1501854140801-50d01698950b?q=80&w=2075&auto=format&fit=crop",
  },
]

// Generate sample pins for the homepage
const generateSamplePins = (count) => {
  return Array.from({ length: count }).map((_, i) => ({
    id: `home-${i}`,
    title: `Creative ${["Artwork", "Photography", "Design", "Illustration"][Math.floor(Math.random() * 4)]} #${i + 1}`,
    user: `creator${Math.floor(Math.random() * 100)}`,
    image: `https://picsum.photos/seed/${i + 100}/${300 + Math.floor(Math.random() * 300)}/${400 + Math.floor(Math.random() * 300)}`,
    likes: Math.floor(Math.random() * 1000),
    saves: Math.floor(Math.random() * 500),
    aspectRatio: 0.8 + Math.random() * 0.8, // Random aspect ratio between 0.8 and 1.6
  }))
}

export default function Home() {
  const [trendingPins, setTrendingPins] = useState([])
  const [isLoading, setIsLoading] = useState(true)

  useEffect(() => {
    // Simulate loading trending pins
    setIsLoading(true)
    setTimeout(() => {
      setTrendingPins(generateSamplePins(12))
      setIsLoading(false)
    }, 1000)
  }, [])

  return (
    <div className="min-h-screen">
      {/* Hero Section */}
      <HeroSection />

      {/* Featured Categories */}
      <FeaturedCategories categories={categories} />

      {/* Trending Section */}
      <section className="py-16 px-4 bg-gray-50">
        <div className="max-w-screen-xl mx-auto">
          <div className="flex justify-between items-center mb-8">
            <h2 className="text-3xl font-bold">Trending Now</h2>
            <Link to="/explore" className="flex items-center text-inspira hover:text-inspira-dark font-medium">
              See all <ArrowRight className="ml-1 h-4 w-4" />
            </Link>
          </div>

          {isLoading ? (
            <div className="grid grid-cols-2 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-4">
              {Array.from({ length: 10 }).map((_, i) => (
                <div
                  key={i}
                  className="rounded-xl bg-gray-200 animate-pulse"
                  style={{ height: `${200 + Math.random() * 200}px` }}
                ></div>
              ))}
            </div>
          ) : (
            <MasonryGrid pins={trendingPins} />
          )}
        </div>
      </section>

      {/* Call to Action */}
      <section className="py-20 px-4 bg-gradient-to-r from-inspira to-inspira-dark text-white text-center">
        <div className="max-w-screen-xl mx-auto">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5 }}
            viewport={{ once: true }}
          >
            <h2 className="text-3xl md:text-4xl font-bold mb-4">Ready to share your creativity?</h2>
            <p className="text-lg md:text-xl mb-8 max-w-2xl mx-auto">
              Join our community of creators and inspire others with your unique perspective.
            </p>
            <Link
              to="/upload"
              className="px-8 py-3 bg-white text-inspira-dark hover:bg-gray-100 font-medium rounded-full transition-colors inline-block"
            >
              Upload Your First Pin
            </Link>
          </motion.div>
        </div>
      </section>
    </div>
  )
}
