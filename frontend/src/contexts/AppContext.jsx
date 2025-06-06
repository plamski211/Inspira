"use client"

import { createContext, useContext, useReducer, useMemo } from "react"

// Initial state
const initialState = {
  user: null,
  isAuthenticated: false,
  theme: "light",
  notifications: [],
  searchQuery: "",
  filters: {
    category: "All",
    sortBy: "recent",
    timeFrame: "all",
  },
}

// Action types
const ActionTypes = {
  SET_USER: "SET_USER",
  LOGOUT: "LOGOUT",
  SET_THEME: "SET_THEME",
  ADD_NOTIFICATION: "ADD_NOTIFICATION",
  REMOVE_NOTIFICATION: "REMOVE_NOTIFICATION",
  SET_SEARCH_QUERY: "SET_SEARCH_QUERY",
  SET_FILTERS: "SET_FILTERS",
}

// Reducer function
function appReducer(state, action) {
  switch (action.type) {
    case ActionTypes.SET_USER:
      return {
        ...state,
        user: action.payload,
        isAuthenticated: !!action.payload,
      }
    case ActionTypes.LOGOUT:
      return {
        ...state,
        user: null,
        isAuthenticated: false,
      }
    case ActionTypes.SET_THEME:
      return {
        ...state,
        theme: action.payload,
      }
    case ActionTypes.ADD_NOTIFICATION:
      return {
        ...state,
        notifications: [...state.notifications, action.payload],
      }
    case ActionTypes.REMOVE_NOTIFICATION:
      return {
        ...state,
        notifications: state.notifications.filter((notification) => notification.id !== action.payload),
      }
    case ActionTypes.SET_SEARCH_QUERY:
      return {
        ...state,
        searchQuery: action.payload,
      }
    case ActionTypes.SET_FILTERS:
      return {
        ...state,
        filters: {
          ...state.filters,
          ...action.payload,
        },
      }
    default:
      return state
  }
}

// Create context
const AppContext = createContext(undefined)

// Provider component
export function AppProvider({ children }) {
  const [state, dispatch] = useReducer(appReducer, initialState)

  // Memoized action creators
  const actions = useMemo(
    () => ({
      setUser: (user) => dispatch({ type: ActionTypes.SET_USER, payload: user }),
      logout: () => dispatch({ type: ActionTypes.LOGOUT }),
      setTheme: (theme) => dispatch({ type: ActionTypes.SET_THEME, payload: theme }),
      addNotification: (notification) =>
        dispatch({
          type: ActionTypes.ADD_NOTIFICATION,
          payload: {
            id: Date.now(),
            timestamp: new Date(),
            ...notification,
          },
        }),
      removeNotification: (id) => dispatch({ type: ActionTypes.REMOVE_NOTIFICATION, payload: id }),
      setSearchQuery: (query) => dispatch({ type: ActionTypes.SET_SEARCH_QUERY, payload: query }),
      setFilters: (filters) => dispatch({ type: ActionTypes.SET_FILTERS, payload: filters }),
    }),
    [],
  )

  // Memoize context value to prevent unnecessary re-renders
  const contextValue = useMemo(() => ({ state, actions }), [state, actions])

  return <AppContext.Provider value={contextValue}>{children}</AppContext.Provider>
}

// Custom hook for using the context
export function useAppContext() {
  const context = useContext(AppContext)
  if (context === undefined) {
    throw new Error("useAppContext must be used within an AppProvider")
  }
  return context
}

// Export action types for testing
export { ActionTypes }
