"use client"

import { useRef, useEffect, forwardRef, createContext, useContext, useState } from "react"
import { createPortal } from "react-dom"
import { X } from "lucide-react"
import { cn } from "@/utils"

// Modal context
const ModalContext = createContext({
  isOpen: false,
  setIsOpen: () => {},
})

// Modal provider
export function ModalProvider({ children }) {
  const [isOpen, setIsOpen] = useState(false)

  return <ModalContext.Provider value={{ isOpen, setIsOpen }}>{children}</ModalContext.Provider>
}

// Hook to use modal
export function useModal() {
  const context = useContext(ModalContext)
  if (!context) {
    throw new Error("useModal must be used within a ModalProvider")
  }

  return context
}

// Modal component
export const Modal = forwardRef(
  ({ isOpen, onClose, children, className, overlayClassName, closeOnOverlayClick = true, ...props }, ref) => {
    const modalRef = useRef(null)
    const mergedRef = useMergeRefs(ref, modalRef)

    // Handle escape key press
    useEffect(() => {
      const handleEscape = (e) => {
        if (e.key === "Escape" && isOpen) {
          onClose()
        }
      }

      document.addEventListener("keydown", handleEscape)
      return () => document.removeEventListener("keydown", handleEscape)
    }, [isOpen, onClose])

    // Lock body scroll when modal is open
    useEffect(() => {
      if (isOpen) {
        document.body.style.overflow = "hidden"
      } else {
        document.body.style.overflow = ""
      }

      return () => {
        document.body.style.overflow = ""
      }
    }, [isOpen])

    // Focus trap
    useEffect(() => {
      if (!isOpen) return

      const modal = modalRef.current
      if (!modal) return

      const focusableElements = modal.querySelectorAll(
        'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])',
      )

      const firstElement = focusableElements[0]
      const lastElement = focusableElements[focusableElements.length - 1]

      const handleTabKey = (e) => {
        if (e.key === "Tab") {
          if (e.shiftKey) {
            if (document.activeElement === firstElement) {
              lastElement.focus()
              e.preventDefault()
            }
          } else {
            if (document.activeElement === lastElement) {
              firstElement.focus()
              e.preventDefault()
            }
          }
        }
      }

      modal.addEventListener("keydown", handleTabKey)
      firstElement?.focus()

      return () => {
        modal.removeEventListener("keydown", handleTabKey)
      }
    }, [isOpen])

    // Handle overlay click
    const handleOverlayClick = (e) => {
      if (closeOnOverlayClick && e.target === e.currentTarget) {
        onClose()
      }
    }

    if (!isOpen) return null

    return createPortal(
      <div
        className={cn(
          "fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm",
          overlayClassName,
        )}
        onClick={handleOverlayClick}
        aria-modal="true"
        role="dialog"
      >
        <div
          ref={mergedRef}
          className={cn("relative bg-white rounded-lg shadow-xl max-w-md w-full max-h-[90vh] overflow-auto", className)}
          {...props}
        >
          {children}
        </div>
      </div>,
      document.body,
    )
  },
)

Modal.displayName = "Modal"

// Modal parts
export const ModalHeader = forwardRef(({ className, children, ...props }, ref) => (
  <div ref={ref} className={cn("flex items-center justify-between p-4 border-b", className)} {...props}>
    <div className="text-lg font-semibold">{children}</div>
    <ModalCloseButton />
  </div>
))
ModalHeader.displayName = "ModalHeader"

export const ModalBody = forwardRef(({ className, ...props }, ref) => (
  <div ref={ref} className={cn("p-4", className)} {...props} />
))
ModalBody.displayName = "ModalBody"

export const ModalFooter = forwardRef(({ className, ...props }, ref) => (
  <div ref={ref} className={cn("flex justify-end gap-2 p-4 border-t", className)} {...props} />
))
ModalFooter.displayName = "ModalFooter"

export const ModalCloseButton = forwardRef(({ className, ...props }, ref) => {
  const { setIsOpen } = useModal()

  return (
    <button
      ref={ref}
      className={cn(
        "rounded-full p-1 text-gray-400 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-primary",
        className,
      )}
      onClick={() => setIsOpen(false)}
      aria-label="Close"
      {...props}
    >
      <X className="h-5 w-5" />
    </button>
  )
})
ModalCloseButton.displayName = "ModalCloseButton"

// Utility to merge refs
function useMergeRefs(...refs) {
  return (value) => {
    refs.forEach((ref) => {
      if (typeof ref === "function") {
        ref(value)
      } else if (ref != null) {
        ref.current = value
      }
    })
  }
}
