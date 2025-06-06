"use client"

import { createContext, useContext, useState } from "react"

const TabsContext = createContext({})

export function Tabs({ defaultValue, value, onValueChange, children, ...props }) {
  const [selectedTab, setSelectedTab] = useState(value || defaultValue)

  const handleValueChange = (newValue) => {
    setSelectedTab(newValue)
    onValueChange?.(newValue)
  }

  return (
    <TabsContext.Provider value={{ value: value || selectedTab, onValueChange: handleValueChange }}>
      <div {...props}>{children}</div>
    </TabsContext.Provider>
  )
}

export function TabsList({ children, className = "", ...props }) {
  return (
    <div className={`flex items-center ${className}`} {...props}>
      {children}
    </div>
  )
}

export function TabsTrigger({ value, children, className = "", ...props }) {
  const { value: selectedValue, onValueChange } = useContext(TabsContext)
  const isActive = selectedValue === value

  return (
    <button
      className={`flex items-center justify-center transition-all focus:outline-none ${
        isActive ? "data-[state=active]" : ""
      } ${className}`}
      onClick={() => onValueChange(value)}
      data-state={isActive ? "active" : "inactive"}
      {...props}
    >
      {children}
    </button>
  )
}

export function TabsContent({ value, children, className = "", ...props }) {
  const { value: selectedValue } = useContext(TabsContext)
  const isActive = selectedValue === value

  if (!isActive) return null

  return (
    <div className={className} data-state={isActive ? "active" : "inactive"} {...props}>
      {children}
    </div>
  )
}
