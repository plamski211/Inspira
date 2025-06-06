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
import { Auth0Provider } from "@auth0/auth0-react";

export default function App() {
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    const handleScroll = () => {
      setScrolled(window.scrollY > 10);
    };
    window.addEventListener("scroll", handleScroll, { passive: true });
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  return (
    <Auth0Provider
    domain="dev-1ixkzn1oh8o82jto.us.auth0.com"
    clientId="p1G09sjsFo9UDtwio3V7gzsOg3cUPo24"
    cacheLocation="localstorage"
    authorizationParams={{
      audience: "https://api.inspira.com",
      redirect_uri: window.location.origin,
    }}
    >
      <AppProvider>
        <ThemeProvider>
          <ToastProvider>
            <Router>
              <div className="min-h-screen bg-background">
                <SkipToContent />
                <Navbar scrolled={scrolled} />
                <main id="main-content" className="pt-16">
                  <Routes>
                    <Route path="/" element={<Home />} />
                    <Route path="/explore" element={<Explore />} />
                    <Route path="/pin/:id" element={<Detail />} />
                    <Route path="/upload" element={<Upload />} />
                    <Route path="/profile" element={<Profile />} />
                  </Routes>
                </main>
                {process.env.NODE_ENV === "development" && <DebugCSS />}
                <Toaster />
              </div>
            </Router>
          </ToastProvider>
        </ThemeProvider>
      </AppProvider>
    </Auth0Provider>
  );
}
