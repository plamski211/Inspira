"use client"

export function Button({ children, onClick, variant = "default", size = "md", className = "" }) {
  const base = "rounded-full font-medium transition focus:outline-none"
  const variants = {
    default: "bg-orange-500 text-white hover:bg-orange-600",
    outline: "border border-gray-300 text-gray-700 hover:bg-gray-100",
  }
  const sizes = {
    sm: "px-3 py-1 text-xs",
    md: "px-4 py-2 text-sm",
  }

  return (
    <button onClick={onClick} className={`${base} ${variants[variant]} ${sizes[size]} ${className}`}>
      {children}
    </button>
  )
}
