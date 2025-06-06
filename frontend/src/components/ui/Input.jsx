import { forwardRef } from "react"
import { cn } from "@/utils"

/**
 * Input component for text entry
 *
 * @component
 * @example
 * // Basic usage
 * <Input placeholder="Enter your name" />
 *
 * // With label and error
 * <div>
 *   <Label htmlFor="email">Email</Label>
 *   <Input id="email" type="email" placeholder="Enter your email" error="Please enter a valid email" />
 * </div>
 *
 * @param {Object} props - Component props
 * @param {string} [props.type='text'] - Input type
 * @param {string} [props.error] - Error message
 * @param {string} [props.className] - Additional CSS classes
 * @param {React.Ref} ref - Forwarded ref
 */
export const Input = forwardRef(({ type = "text", error, className, ...props }, ref) => {
  return (
    <>
      <input
        type={type}
        className={cn(
          "flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background",
          "file:border-0 file:bg-transparent file:text-sm file:font-medium",
          "placeholder:text-muted-foreground",
          "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2",
          "disabled:cursor-not-allowed disabled:opacity-50",
          error && "border-destructive focus-visible:ring-destructive",
          className,
        )}
        ref={ref}
        {...props}
      />
      {error && <p className="mt-1 text-sm text-destructive">{error}</p>}
    </>
  )
})
Input.displayName = "Input"
