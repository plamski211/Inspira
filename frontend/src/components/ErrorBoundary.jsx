"use client"

import { Component } from "react"
import { AlertTriangle } from "lucide-react"

class ErrorBoundary extends Component {
  constructor(props) {
    super(props)
    this.state = { hasError: false, error: null, errorInfo: null }
  }

  static getDerivedStateFromError(error) {
    // Update state so the next render will show the fallback UI
    return { hasError: true, error }
  }

  componentDidCatch(error, errorInfo) {
    // Log error to an error reporting service
    console.error("Error caught by ErrorBoundary:", error, errorInfo)
    this.setState({ errorInfo })

    // You could send to a reporting service here
    // reportError(error, errorInfo)
  }

  render() {
    const { hasError, error, errorInfo } = this.state
    const { fallback, children } = this.props

    if (hasError) {
      // Custom fallback UI
      if (fallback) {
        return fallback(error, errorInfo, this.resetError)
      }

      // Default fallback UI
      return (
        <div className="flex flex-col items-center justify-center min-h-[200px] p-6 bg-red-50 border border-red-100 rounded-lg text-center">
          <AlertTriangle className="h-12 w-12 text-red-500 mb-4" />
          <h2 className="text-xl font-bold text-red-800 mb-2">Something went wrong</h2>
          <p className="text-red-600 mb-4">We're sorry, but there was an error loading this content.</p>
          {process.env.NODE_ENV === "development" && error && (
            <div className="mt-4 p-4 bg-gray-800 text-white rounded text-left overflow-auto max-w-full">
              <p className="font-mono text-sm">{error.toString()}</p>
              {errorInfo && (
                <details className="mt-2">
                  <summary className="cursor-pointer text-sm">Stack trace</summary>
                  <pre className="mt-2 text-xs overflow-auto">{errorInfo.componentStack}</pre>
                </details>
              )}
            </div>
          )}
          <button
            onClick={this.resetError}
            className="mt-4 px-4 py-2 bg-red-600 text-white rounded-md hover:bg-red-700 transition-colors"
          >
            Try again
          </button>
        </div>
      )
    }

    return children
  }

  resetError = () => {
    this.setState({ hasError: false, error: null, errorInfo: null })
  }
}

export default ErrorBoundary
