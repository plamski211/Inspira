"use client"

import { useState, useEffect, forwardRef, createContext, useContext } from "react"
import { X } from "lucide-react"
import { cn } from "@/utils"

// Toast context
const ToastContext = createContext({
  toasts: [],
  addToast: () => {},
  removeToast: () => {},
})

// Toast types
const TOAST_TYPES = {
  DEFAULT: "default",
  SUCCESS: "success",
  ERROR: "error",
  WARNING: "warning",
  INFO: "info",
}

// Toast provider
export function ToastProvider({ children }) {
  const [toasts, setToasts] = useState([])

  const addToast = (toast) => {
    const id = Date.now()
    setToasts((prev) => [...prev, { id, ...toast }])
    return id
  }

  const removeToast = (id) => {
    setToasts((prev) => prev.filter((toast) => toast.id !== id))
  }

  // Auto-remove toasts after duration
  useEffect(() => {
    const timers = toasts.map((toast) => {
      if (toast.duration !== Number.POSITIVE_INFINITY) {
        return setTimeout(() => {
          removeToast(toast.id)
        }, toast.duration || 5000)
      }
      return null
    })

    return () => {
      timers.forEach((timer) => timer && clearTimeout(timer))
    }
  }, [toasts])

  return <ToastContext.Provider value={{ toasts, addToast, removeToast }}>{children}</ToastContext.Provider>
}

// Hook to use toast
export function useToast() {
  const context = useContext(ToastContext)
  if (!context) {
    throw new Error("useToast must be used within a ToastProvider")
  }

  const { addToast, removeToast } = context

  return {
    toast: (props) => addToast({ type: TOAST_TYPES.DEFAULT, ...props }),
    success: (props) => addToast({ type: TOAST_TYPES.SUCCESS, ...props }),
    error: (props) => addToast({ type: TOAST_TYPES.ERROR, ...props }),
    warning: (props) => addToast({ type: TOAST_TYPES.WARNING, ...props }),
    info: (props) => addToast({ type: TOAST_TYPES.INFO, ...props }),
    dismiss: removeToast,
  }
}

// Toast component
export const Toast = forwardRef(
  ({ type = TOAST_TYPES.DEFAULT, title, description, onDismiss, className, ...props }, ref) => {
    const typeStyles = {
      [TOAST_TYPES.DEFAULT]: "bg-white border-gray-200",
      [TOAST_TYPES.SUCCESS]: "bg-green-50 border-green-200",
      [TOAST_TYPES.ERROR]: "bg-red-50 border-red-200",
      [TOAST_TYPES.WARNING]: "bg-yellow-50 border-yellow-200",
      [TOAST_TYPES.INFO]: "bg-blue-50 border-blue-200",
    }

    const titleColors = {
      [TOAST_TYPES.DEFAULT]: "text-gray-900",
      [TOAST_TYPES.SUCCESS]: "text-green-800",
      [TOAST_TYPES.ERROR]: "text-red-800",
      [TOAST_TYPES.WARNING]: "text-yellow-800",
      [TOAST_TYPES.INFO]: "text-blue-800",
    }

    return (
      <div
        ref={ref}
        className={cn("relative rounded-lg border p-4 shadow-md", typeStyles[type], className)}
        role="alert"
        aria-live="assertive"
        {...props}
      >
        <div className="flex items-start gap-3">
          <div className="flex-1">
            {title && <h3 className={cn("font-medium text-sm", titleColors[type])}>{title}</h3>}
            {description && <div className="mt-1 text-sm text-gray-700">{description}</div>}
          </div>
          <button
            onClick={onDismiss}
            className="text-gray-400 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary rounded-full"
            aria-label="Close"
          >
            <X className="h-4 w-4" />
          </button>
        </div>
      </div>
    )
  },
)

Toast.displayName = "Toast"

// Toaster component to display multiple toasts
export function Toaster() {
  const { toasts, removeToast } = useContext(ToastContext)

  return (
    <div className="fixed bottom-0 right-0 z-50 p-4 space-y-4 max-w-md w-full">
      {toasts.map((toast) => (
        <Toast
          key={toast.id}
          type={toast.type}
          title={toast.title}
          description={toast.description}
          onDismiss={() => removeToast(toast.id)}
          className="animate-in slide-in-from-right"
        />
      ))}
    </div>
  )
}
