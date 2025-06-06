import { render, screen } from "@testing-library/react"
import { describe, it, expect } from "vitest"

describe("Button Component", () => {
  it("renders correctly with default props", () => {
    render(<Button>Click me</Button>)
    expect(screen.getByRole("button", { name: /click me/i })).toBeInTheDocument()
  })

  it("applies variant classes correctly", () => {
    render(<Button variant="outline">Outline Button</Button>)
    const button = screen.getByRole("button", { name: /outline button/i })
    expect(button).toHaveClass("border")
  })

  it("applies size classes correctly", () => {
    render(<Button size="sm">Small Button</Button>)
    const button = screen.getByRole("button", { name: /small button/i })
    expect(button).toHaveClass("px-3")
  })

  it("is disabled when disabled prop is true", () => {
    render(<Button disabled>Disabled Button</Button>)
    expect(screen.getByRole("button", { name: /disabled button/i })).toBeDisabled()
  })
})
