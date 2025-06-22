import { expect, afterEach, vi } from "vitest"
import { cleanup } from "@testing-library/react"
import * as matchers from "@testing-library/jest-dom/matchers"

// Mock IntersectionObserver
class IntersectionObserver {
  constructor(callback) {
    this.callback = callback;
  }

  observe() {
    return null;
  }

  unobserve() {
    return null;
  }

  disconnect() {
    return null;
  }
}

// Use globalThis instead of global to be compatible with ESLint
globalThis.IntersectionObserver = IntersectionObserver;

// Mock Auth0
vi.mock('@auth0/auth0-react', () => ({
  Auth0Provider: ({ children }) => children,
  useAuth0: () => ({
    isAuthenticated: false,
    user: null,
    isLoading: false,
    loginWithRedirect: vi.fn(),
    logout: vi.fn(),
    getAccessTokenSilently: vi.fn(),
  }),
}))

// Extend Vitest's expect method with methods from react-testing-library
expect.extend(matchers)

// Clean up after each test case (e.g. clearing jsdom)
afterEach(() => {
  cleanup()
})
