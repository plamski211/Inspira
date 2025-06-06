"use client"

import { useState, useEffect } from "react"
import { Link } from "react-router-dom"
import { ArrowRight } from "lucide-react"

export default function HeroSection() {
  const [currentImageIndex, setCurrentImageIndex] = useState(0)
  const images = [
    "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?q=80&w=2064&auto=format&fit=crop",
    "https://images.unsplash.com/photo-1579547621113-e4bb2a19bdd6?q=80&w=2070&auto=format&fit=crop",
    "https://images.unsplash.com/photo-1518998053901-5348d3961a04?q=80&w=2069&auto=format&fit=crop",
    "https://images.unsplash.com/photo-1561214115-f2f134cc4912?q=80&w=2009&auto=format&fit=crop",
  ]

  useEffect(() => {
    const interval = setInterval(() => {
      setCurrentImageIndex((prevIndex) => (prevIndex + 1) % images.length)
    }, 5000)
    return () => clearInterval(interval)
  }, [images.length])

  return (
    <div className="relative overflow-hidden bg-gray-900 text-white">
      {/* Background image carousel */}
      <div className="absolute inset-0 z-0">
        {images.map((image, index) => (
          <div
            key={index}
            className={`absolute inset-0 transition-opacity duration-1000 ${
              index === currentImageIndex ? "opacity-100" : "opacity-0"
            }`}
          >
            <div className="absolute inset-0 bg-black/50 z-10"></div>
            <img src={image || "/placeholder.svg"} alt="Inspiration" className="w-full h-full object-cover" />
          </div>
        ))}
      </div>

      {/* Content */}
      <div className="relative z-10 max-w-screen-xl mx-auto px-4 py-24 md:py-32 flex flex-col items-center text-center">
        <h1 className="text-4xl md:text-6xl font-bold mb-6 leading-tight">
          Discover and Share <span className="text-inspira">Creative Inspiration</span>
        </h1>
        <p className="text-lg md:text-xl max-w-2xl mb-10 text-gray-200">
          Explore millions of inspiring ideas from creators around the world. Save what you love and build your own
          collection.
        </p>
        <div className="flex flex-col sm:flex-row gap-4">
          <Link
            to="/explore"
            className="px-8 py-3 bg-inspira hover:bg-inspira-dark text-white font-medium rounded-full transition-colors flex items-center justify-center"
          >
            Start Exploring <ArrowRight className="ml-2 h-5 w-5" />
          </Link>
          <Link
            to="/upload"
            className="px-8 py-3 bg-white/10 hover:bg-white/20 backdrop-blur-sm text-white font-medium rounded-full transition-colors"
          >
            Share Your Work
          </Link>
        </div>
      </div>

      {/* Scroll indicator */}
      <div className="absolute bottom-8 left-1/2 transform -translate-x-1/2 z-10 animate-bounce">
        <svg
          className="w-6 h-6 text-white"
          fill="none"
          strokeLinecap="round"
          strokeLinejoin="round"
          strokeWidth="2"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path d="M19 14l-7 7m0 0l-7-7m7 7V3"></path>
        </svg>
      </div>
    </div>
  )
}
