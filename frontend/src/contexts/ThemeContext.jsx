"use client"

import { createContext, useContext, useState, useEffect } from "react"

const ThemeContext = createContext({
  theme: "light",
  toggleTheme: () => {},
})

export function ThemeProvider({ children }) {
  const [theme, setTheme] = useState("light")

  useEffect(() => {
    // Check for user preference in localStorage
    const savedTheme = localStorage.getItem("inspira-theme")

    if (savedTheme) {
      setTheme(savedTheme)
    } else if (window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches) {
      // If no saved preference, check system preference
      setTheme("dark")
    }
  }, [])

  useEffect(() => {
    // Apply theme class to document
    document.documentElement.classList.toggle("dark", theme === "dark")

    // Save preference to localStorage
    localStorage.setItem("inspira-theme", theme)
  }, [theme])

  const toggleTheme = () => {
    setTheme(theme === "light" ? "dark" : "light")
  }

  return <ThemeContext.Provider value={{ theme, toggleTheme }}>{children}</ThemeContext.Provider>
}

export function useTheme() {
  const context = useContext(ThemeContext)
  if (context === undefined) {
    throw new Error("useTheme must be used within a ThemeProvider")
  }
  return context
}
