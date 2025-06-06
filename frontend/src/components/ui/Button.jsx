import { forwardRef } from "react"
import { cn } from "@/utils"

/**
 * Button component with various styles and sizes
 *
 * @component
 * @example
 * // Default button
 * <Button>Click me</Button>
 *
 * // Outline variant
 * <Button variant="outline">Outline</Button>
 *
 * // Small size
 * <Button size="sm">Small</Button>
 *
 * @param {Object} props - Component props
 * @param {'default'|'outline'|'ghost'|'link'} [props.variant='default'] - Button style variant
 * @param {'sm'|'md'|'lg'} [props.size='md'] - Button size
 * @param {boolean} [props.disabled=false] - Whether the button is disabled
 * @param {React.ReactNode} props.children - Button content
 * @param {string} [props.className] - Additional CSS classes
 * @param {React.Ref} ref - Forwarded ref
 */
export const Button = forwardRef(
  ({ variant = "default", size = "md", disabled = false, className = "", children, ...props }, ref) => {
    // Base button styles
    const baseStyles =
      "inline-flex items-center justify-center rounded-full font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50"

    // Variant styles
    const variantStyles = {
      default: "bg-primary text-primary-foreground hover:bg-primary/90",
      outline: "border border-input bg-background hover:bg-accent hover:text-accent-foreground",
      ghost: "hover:bg-accent hover:text-accent-foreground",
      link: "text-primary underline-offset-4 hover:underline",
    }

    // Size styles
    const sizeStyles = {
      sm: "px-3 py-1 text-xs",
      md: "px-4 py-2 text-sm",
      lg: "px-6 py-3 text-base",
    }

    return (
      <button
        ref={ref}
        disabled={disabled}
        className={cn(baseStyles, variantStyles[variant], sizeStyles[size], className)}
        {...props}
      >
        {children}
      </button>
    )
  },
)

Button.displayName = "Button"
