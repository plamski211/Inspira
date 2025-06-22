"use client"

import { useState } from "react"
import { Link } from "react-router-dom"

export default function FeaturedCategories({ categories }) {
  return (
    <section className="py-16 px-4">
      <div className="max-w-screen-xl mx-auto">
        <h2 className="text-3xl font-bold mb-8 text-center">Explore Popular Categories</h2>

        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4 md:gap-6">
          {categories.map((category, index) => (
            <CategoryCard key={category.id} category={category} index={index} />
          ))}
        </div>
      </div>
    </section>
  )
}

function CategoryCard({ category }) {
  const [isHovered, setIsHovered] = useState(false)

  return (
    <div className="animate-fadeIn">
      <Link
        to={`/explore?category=${category.id}`}
        className="block relative rounded-xl overflow-hidden aspect-square group"
        onMouseEnter={() => setIsHovered(true)}
        onMouseLeave={() => setIsHovered(false)}
      >
        {/* Image */}
        <div className="absolute inset-0 bg-gray-200">
          <img
            src={category.img || `https://source.unsplash.com/random/300x300?${category.name}`}
            alt={category.name}
            className={`w-full h-full object-cover transition-transform duration-700 ${isHovered ? "scale-110" : "scale-100"}`}
            onError={(e) => {
              e.target.src = "https://via.placeholder.com/300?text=Category"
            }}
          />
        </div>

        {/* Overlay */}
        <div
          className={`absolute inset-0 bg-gradient-to-t from-black/70 via-black/30 to-transparent transition-opacity duration-300 ${isHovered ? "opacity-100" : "opacity-80"}`}
        ></div>

        {/* Content */}
        <div className="absolute bottom-0 left-0 right-0 p-4 text-white">
          <h3 className="text-xl font-bold mb-1">{category.name}</h3>
          <p
            className={`text-sm text-white/80 transition-all duration-300 ${isHovered ? "opacity-100 translate-y-0" : "opacity-0 translate-y-2"}`}
          >
            Discover amazing content
          </p>
        </div>
      </Link>
    </div>
  )
}
