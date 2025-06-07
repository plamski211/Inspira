import { useEffect } from "react"
import { useState } from "react"
import { Link, useLocation } from "react-router-dom"
import { Search, Plus, Bell, MessageCircle, User } from "lucide-react"
import { useAuth0 } from "@auth0/auth0-react";
import { userService } from "../services/api";

export default function Navbar({ scrolled }) {
  const [searchFocused, setSearchFocused] = useState(false)
  const location = useLocation()
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false)
  const { loginWithRedirect, logout, isAuthenticated, user, getAccessTokenSilently } = useAuth0();

useEffect(() => {
  const fetchToken = async () => {
    if (isAuthenticated && getAccessTokenSilently) {
      try {
        const token = await getAccessTokenSilently();
        localStorage.setItem('auth_token', token);
        try {
          await userService.getCurrentUserProfile();
        } catch (profileErr) {
          console.error('❌ Error fetching profile:', profileErr.message);
        }
      } catch (error) {
        console.error("❌ Error fetching token:", error.message);
      }
    } else {
      localStorage.removeItem('auth_token');
    }
  };

  fetchToken();
}, [isAuthenticated, getAccessTokenSilently]);

  return (
    <header
      className={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${scrolled ? "bg-white shadow-md py-2" : "bg-white/95 py-3"
        }`}
    >
      <div className="max-w-screen-2xl mx-auto px-4 flex items-center justify-between">
        {/* Logo */}
        <Link to="/" className="flex items-center">
          <img src="/inspira-frontend/src/assets/logo.png" alt="Inspira" className="h-8 w-auto" />
          <span className="ml-2 text-inspira-dark font-bold text-xl hidden sm:inline-block">Inspira</span>
        </Link>

        {/* Navigation - Desktop */}
        <nav className="hidden md:flex items-center space-x-1">
          <NavLink to="/" active={location.pathname === "/"}>
            Home
          </NavLink>
          <NavLink to="/explore" active={location.pathname === "/explore"}>
            Explore
          </NavLink>
        </nav>

        {/* Search Bar */}
        <div
          className={`relative mx-4 flex-1 max-w-xl transition-all duration-300 ${searchFocused ? "scale-105" : "scale-100"
            }`}
        >
          <div className="relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 h-4 w-4" />
            <input
              type="text"
              placeholder="Search for inspiration..."
              className="w-full py-2.5 pl-10 pr-4 bg-gray-100 rounded-full focus:outline-none focus:ring-2 focus:ring-inspira transition-all"
              onFocus={() => setSearchFocused(true)}
              onBlur={() => setSearchFocused(false)}
            />
          </div>
        </div>

        {/* Action Buttons */}
        <div className="flex items-center space-x-1">
          <ActionButton icon={<Bell className="h-5 w-5" />} tooltip="Notifications" />
          <ActionButton icon={<MessageCircle className="h-5 w-5" />} tooltip="Messages" />
          <Link
            to="/upload"
            className="p-2.5 rounded-full text-white bg-inspira hover:bg-inspira-dark transition-colors flex items-center justify-center"
            title="Create"
          >
            <Plus className="h-5 w-5" />
          </Link>
          <Link
            to="/profile"
            className="p-2.5 rounded-full hover:bg-gray-100 transition-colors flex items-center justify-center"
            title="Profile"
          >
            <User className="h-5 w-5" />
          </Link>

          {/* Auth0 Login/Logout */}
          {!isAuthenticated ? (
            <button
              onClick={() => loginWithRedirect()}
              className="ml-2 px-4 py-2 bg-inspira text-white rounded-full hover:bg-inspira-dark transition"
            >
              Log In
            </button>
          ) : (
            <div className="flex items-center space-x-2">
              <span className="hidden sm:inline text-sm text-gray-600">Hi, {user.nickname}</span>
              <button
                onClick={() => logout({ returnTo: window.location.origin })}
                className="px-4 py-2 bg-gray-200 text-gray-800 rounded-full hover:bg-gray-300 transition"
              >
                Log Out
              </button>
            </div>
          )}
        </div>

        {/* Mobile Menu Button */}
        <button
          className="md:hidden p-2 rounded-full hover:bg-gray-100"
          onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
        >
          <div className="w-5 h-0.5 bg-gray-600 mb-1"></div>
          <div className="w-5 h-0.5 bg-gray-600 mb-1"></div>
          <div className="w-5 h-0.5 bg-gray-600"></div>
        </button>
      </div>

      {/* Mobile Menu */}
      {mobileMenuOpen && (
        <div className="md:hidden bg-white border-t border-gray-100 py-2 px-4 shadow-lg">
          <nav className="flex flex-col space-y-2">
            <MobileNavLink to="/" active={location.pathname === "/"}>
              Home
            </MobileNavLink>
            <MobileNavLink to="/explore" active={location.pathname === "/explore"}>
              Explore
            </MobileNavLink>
            <MobileNavLink to="/upload" active={location.pathname === "/upload"}>
              Create
            </MobileNavLink>
            <MobileNavLink to="/profile" active={location.pathname === "/profile"}>
              Profile
            </MobileNavLink>
          </nav>
        </div>
      )}
    </header>
  )
}

function NavLink({ to, active, children }) {
  return (
    <Link
      to={to}
      className={`px-3 py-2 rounded-full font-medium text-sm transition-colors ${active ? "bg-inspira/10 text-inspira-dark" : "text-gray-700 hover:bg-gray-100"
        }`}
    >
      {children}
    </Link>
  )
}

function MobileNavLink({ to, active, children }) {
  return (
    <Link
      to={to}
      className={`px-4 py-2 rounded-lg font-medium text-base transition-colors ${active ? "bg-inspira/10 text-inspira-dark" : "text-gray-700"
        }`}
    >
      {children}
    </Link>
  )
}

function ActionButton({ icon, tooltip }) {
  return (
    <button
      className="p-2.5 rounded-full hover:bg-gray-100 transition-colors flex items-center justify-center"
      title={tooltip}
    >
      {icon}
    </button>
  )
}
