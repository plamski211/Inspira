"use client"

import { useState } from "react"
import { cn } from "@/utils"

export function SkipToContent() {
  const [isFocused, setIsFocused] = useState(false)

  return (
    <a
      href="#main-content"
      className={cn(
        "fixed top-4 left-4 z-50 bg-primary text-primary-foreground px-4 py-2 rounded-md transition-transform",
        isFocused ? "translate-y-0" : "-translate-y-full",
      )}
      onFocus={() => setIsFocused(true)}
      onBlur={() => setIsFocused(false)}
    >
      Skip to content
    </a>
  )
}
