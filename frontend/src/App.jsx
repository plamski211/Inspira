import { BrowserRouter as Router, Routes, Route } from "react-router-dom";
import { useState, useEffect } from "react";
import { AppProvider } from "./contexts/AppContext";
import { ThemeProvider } from "./contexts/ThemeContext";
import { ToastProvider } from "./components/ui/Toast";
import Navbar from "./components/Navbar";
import Home from "./pages/Home";
import Explore from "./pages/Explore";
import Detail from "./pages/Detail";
import Upload from "./pages/Upload";
import Profile from "./pages/Profile";
import { DebugCSS } from "./components/layout/DebugCSS";
import { Toaster } from "./components/ui/Toast";
import { SkipToContent } from "./components/SkipToContent";
import { Auth0Provider, useAuth0 } from "@auth0/auth0-react";
import axios from "axios";

function AppContent() {
  const [scrolled, setScrolled] = useState(false);
  const [authError, setAuthError] = useState(null);
  const { getAccessTokenSilently, isAuthenticated, isLoading, user } = useAuth0();

  useEffect(() => {
    const handleScroll = () => {
      setScrolled(window.scrollY > 10);
    };
    window.addEventListener("scroll", handleScroll, { passive: true });
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  useEffect(() => {
    const getToken = async () => {
      if (!isAuthenticated || isLoading) {
        console.log('Not authenticated or still loading');
        return;
      }

      try {
        console.log('Getting token for user:', user?.sub);
        const token = await getAccessTokenSilently({
          authorizationParams: {
            audience: "https://api.inspira.com",
          },
        });
        
        console.log('Got new token:', token.substring(0, 20) + '...');
        const tokenData = { access_token: token };
        localStorage.setItem('auth0.is.authenticated', JSON.stringify(tokenData));
        console.log('Token stored in localStorage');
      } catch (error) {
        console.error('Error getting token:', error);
        setAuthError(error.message);
      }
    };

    getToken();
  }, [getAccessTokenSilently, isAuthenticated, isLoading, user]);

  const testAuth = async () => {
    if (!isAuthenticated) {
      console.log('Not authenticated, cannot test');
      alert('Please login first');
      return;
    }

    try {
      console.log('Testing authentication...');
      
      // Get current token from localStorage
      const authData = localStorage.getItem('auth0.is.authenticated');
      let token = null;
      if (authData) {
        try {
          const parsed = JSON.parse(authData);
          token = parsed.access_token;
          console.log('Found token in storage:', token ? `${token.substring(0, 15)}...` : 'null');
        } catch (e) {
          console.error('Error parsing auth data:', e);
        }
      }

      // Test the auth endpoint
      const response = await axios.get('/api/users/profiles/test/auth', {
        headers: {
          Authorization: token ? `Bearer ${token}` : ''
        }
      });
      
      console.log('Auth test response:', response.data);
      alert('Auth test successful! Check console for details.');
      
      // Also test the /me endpoint
      try {
        const profileResponse = await axios.get('/api/users/profiles/me', {
          headers: {
            Authorization: token ? `Bearer ${token}` : ''
          }
        });
        console.log('Profile response:', profileResponse.data);
      } catch (profileError) {
        console.error('Error fetching profile:', profileError);
      }
      
    } catch (error) {
      console.error('Auth test failed:', error);
      alert('Auth test failed! Check console for details.');
    }
  };

  const testHealth = async () => {
    try {
      console.log('Testing health check endpoint...');
      const response = await axios.get('/api/users/profiles/health');
      console.log('Health check response:', response.data);
      alert('Health check successful! Check console for details.');
    } catch (error) {
      console.error('Health check failed:', error);
      alert('Health check failed! Check console for details.');
    }
  };

  const testCreateProfile = async () => {
    try {
      console.log('Testing profile creation...');
      const response = await axios.post('/api/users/profiles/test/create');
      console.log('Profile creation response:', response.data);
      
      if (response.data && response.data.id) {
        localStorage.setItem('user_id', response.data.id);
        console.log('Test profile created and ID stored:', response.data.id);
        alert(`Test profile created with ID: ${response.data.id}`);
      } else {
        console.error('Failed to create test profile');
        alert('Failed to create test profile');
      }
    } catch (error) {
      console.error('Profile creation failed:', error);
      alert('Profile creation failed! Check console for details.');
    }
  };

  if (isLoading) {
    return <div>Loading...</div>;
  }

  // Show a fallback UI if there's an Auth0 error
  if (authError && authError.includes("secure origin")) {
    return (
      <div className="min-h-screen bg-background flex flex-col items-center justify-center p-4">
        <div className="max-w-md w-full bg-white rounded-lg shadow-lg p-6">
          <h1 className="text-2xl font-bold text-center mb-4">Inspira</h1>
          <div className="bg-yellow-50 border-l-4 border-yellow-400 p-4 mb-4">
            <p className="text-yellow-700">
              <strong>Note:</strong> Auth0 requires a secure HTTPS connection.
            </p>
            <p className="text-sm text-yellow-600 mt-1">
              You're currently viewing this site over HTTP.
            </p>
          </div>
          <div className="space-y-4">
            <h2 className="text-xl font-semibold">Welcome to Inspira</h2>
            <p>
              Inspira is a platform for creative inspiration. Browse through collections
              of artwork, photography, and design to spark your creativity.
            </p>
            <div className="grid grid-cols-2 gap-2 mt-4">
              {[1, 2, 3, 4].map((i) => (
                <div
                  key={i}
                  className="bg-gray-200 rounded-md aspect-square animate-pulse"
                />
              ))}
            </div>
            <p className="text-sm text-gray-500 mt-4">
              Some features are limited without authentication.
            </p>
          </div>
        </div>
      </div>
    );
  }

  return (
    <AppProvider>
      <ThemeProvider>
        <ToastProvider>
          <Router>
            <div className="min-h-screen bg-background">
              <SkipToContent />
              <Navbar scrolled={scrolled} />
              <main id="main-content" className="pt-16">
                {/* Debug buttons */}
                {import.meta.env.MODE === "development" && (
                  <div className="fixed bottom-4 right-4 z-50 flex flex-col space-y-2">
                    <button 
                      onClick={testAuth}
                      className="bg-red-500 text-white px-4 py-2 rounded-md shadow-md"
                    >
                      Test Auth
                    </button>
                    <button 
                      onClick={testHealth}
                      className="bg-green-500 text-white px-4 py-2 rounded-md shadow-md"
                    >
                      Test Health
                    </button>
                    <button 
                      onClick={testCreateProfile}
                      className="bg-blue-500 text-white px-4 py-2 rounded-md shadow-md"
                    >
                      Create Test Profile
                    </button>
                  </div>
                )}
                <Routes>
                  <Route path="/" element={<Home />} />
                  <Route path="/explore" element={<Explore />} />
                  <Route path="/pin/:id" element={<Detail />} />
                  <Route path="/upload" element={<Upload />} />
                  <Route path="/profile" element={<Profile />} />
                </Routes>
              </main>
              {import.meta.env.MODE === "development" && <DebugCSS />}
              <Toaster />
            </div>
          </Router>
        </ToastProvider>
      </ThemeProvider>
    </AppProvider>
  );
}

export default function App() {
  return (
    <Auth0Provider
      domain="dev-1ixkzn1oh8o82jto.us.auth0.com"
      clientId="p1G09sjsFo9UDtwio3V7gzsOg3cUPo24"
      cacheLocation="localstorage"
      useRefreshTokens={true}
      skipRedirectCallback={window.location.pathname === '/callback'}
      authorizationParams={{
        audience: "https://api.inspira.com",
        redirect_uri: import.meta.env.VITE_AUTH0_REDIRECT_URI || window.location.origin,
      }}
    >
      <AppContent />
    </Auth0Provider>
  );
}
