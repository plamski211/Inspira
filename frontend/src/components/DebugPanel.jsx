import { useState, useEffect } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { userApi } from '../services/api';
import DirectProfileCreation from './DirectProfileCreation';
import NetworkTest from './NetworkTest';

export default function DebugPanel() {
  const [isOpen, setIsOpen] = useState(false);
  const [debugInfo, setDebugInfo] = useState({});
  const [loading, setLoading] = useState(false);
  const { isAuthenticated, user, profile, error, token, isLoading } = useAuth();
  const [jwtDebug, setJwtDebug] = useState({});
  const [dbDebug, setDbDebug] = useState({});
  const [testProfile, setTestProfile] = useState({});
  const [expandSection, setExpandSection] = useState("auth");

  const fetchDebugInfo = async () => {
    setLoading(true);
    try {
      const jwt = await userApi.debugJwt();
      setJwtDebug(jwt || {});
    } catch (err) {
      console.error("Failed to fetch JWT debug info:", err);
    }
    
    try {
      const db = await userApi.debugDatabase();
      setDbDebug(db || {});
    } catch (err) {
      console.error("Failed to fetch database debug info:", err);
    }
    
    try {
      const testP = await userApi.testCreateProfile();
      setTestProfile(testP || {});
    } catch (err) {
      console.error("Failed to create test profile:", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (isOpen && isAuthenticated) {
      fetchDebugInfo();
    }
  }, [isOpen, isAuthenticated]);

  if (!isOpen) {
    return (
      <button 
        className="fixed bottom-4 right-4 bg-blue-500 text-white p-2 rounded shadow-lg z-50"
        onClick={() => setIsOpen(true)}
      >
        Debug
      </button>
    );
  }

  const createTestProfile = async () => {
    try {
      const result = await userApi.testCreateProfile();
      alert(result ? 'Profile created!' : 'Failed to create profile');
      fetchDebugInfo();
    } catch (err) {
      alert('Error: ' + err.message);
    }
  };

  const createDirectProfile = async () => {
    try {
      const profileData = {
        auth0Id: user?.sub || "auth0|testuser" + Date.now(),
        displayName: user?.name || "Test User",
        bio: "Created using direct debug endpoint",
        avatarUrl: user?.picture || "https://via.placeholder.com/150",
        location: "Test Location"
      };
      
      const result = await userApi.createProfileDirectly(profileData);
      alert(result ? 'Profile created directly!' : 'Failed to create profile directly');
      fetchDebugInfo();
    } catch (err) {
      alert('Error: ' + err.message);
    }
  };

  const openApiDocs = () => {
    window.open("http://localhost:8080/swagger-ui.html", "_blank");
  };
  
  const openDbConsole = () => {
    window.open("http://localhost:8080/h2-console", "_blank");
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4 overflow-auto">
      <div className="bg-white rounded-lg shadow-xl p-6 max-w-4xl w-full max-h-[90vh] overflow-auto">
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-xl font-bold">Debug Panel</h2>
          <button 
            className="bg-gray-200 p-2 rounded hover:bg-gray-300"
            onClick={() => setIsOpen(false)}
          >
            Close
          </button>
        </div>
        
        <div className="mb-6">
          <div 
            className="flex justify-between items-center cursor-pointer p-2 bg-gray-100 rounded-md mb-2"
            onClick={() => setExpandSection(expandSection === "auth" ? "" : "auth")}
          >
            <h3 className="font-medium">Auth Status</h3>
            <span>{expandSection === "auth" ? "▼" : "▶"}</span>
          </div>
          
          {expandSection === "auth" && (
            <div className="p-3 bg-gray-50 rounded-md">
              <div className="grid grid-cols-2 gap-2 text-sm">
                <div className="font-semibold">Authenticated:</div>
                <div>{isAuthenticated ? "Yes" : "No"}</div>
                
                <div className="font-semibold">Loading:</div>
                <div>{isLoading ? "Yes" : "No"}</div>
                
                <div className="font-semibold">Has Token:</div>
                <div>{token ? "Yes" : "No"}</div>
                
                <div className="font-semibold">Token Length:</div>
                <div>{token ? token.length : 0}</div>
                
                <div className="font-semibold">Has Profile:</div>
                <div>{profile ? "Yes" : "No"}</div>
                
                <div className="font-semibold">Error:</div>
                <div className="text-red-600">{error ? error.message : ""}</div>
              </div>
            </div>
          )}
        </div>
        
        <div className="mb-6">
          <div 
            className="flex justify-between items-center cursor-pointer p-2 bg-gray-100 rounded-md mb-2"
            onClick={() => setExpandSection(expandSection === "user" ? "" : "user")}
          >
            <h3 className="font-medium">User Info</h3>
            <span>{expandSection === "user" ? "▼" : "▶"}</span>
          </div>
          
          {expandSection === "user" && (
            <div className="p-3 bg-gray-50 rounded-md">
              {user ? (
                <div className="grid grid-cols-2 gap-2 text-sm">
                  <div className="font-semibold">User ID:</div>
                  <div>{user.sub}</div>
                  
                  <div className="font-semibold">Name:</div>
                  <div>{user.name}</div>
                  
                  <div className="font-semibold">Email:</div>
                  <div>{user.email}</div>
                  
                  <div className="font-semibold">Email Verified:</div>
                  <div>{user.email_verified ? "Yes" : "No"}</div>
                </div>
              ) : (
                <p className="text-gray-500">No user information available</p>
              )}
            </div>
          )}
        </div>
        
        <div className="mb-6">
          <div 
            className="flex justify-between items-center cursor-pointer p-2 bg-gray-100 rounded-md mb-2"
            onClick={() => setExpandSection(expandSection === "profile" ? "" : "profile")}
          >
            <h3 className="font-medium">Profile Data</h3>
            <span>{expandSection === "profile" ? "▼" : "▶"}</span>
          </div>
          
          {expandSection === "profile" && (
            <div className="p-3 bg-gray-50 rounded-md">
              {profile ? (
                <pre className="text-xs overflow-auto max-h-40">
                  {JSON.stringify(profile, null, 2)}
                </pre>
              ) : (
                <div>
                  <p className="text-gray-500 mb-3">No profile data available</p>
                  <DirectProfileCreation />
                </div>
              )}
            </div>
          )}
        </div>
        
        <div className="mb-6">
          <div 
            className="flex justify-between items-center cursor-pointer p-2 bg-gray-100 rounded-md mb-2"
            onClick={() => setExpandSection(expandSection === "network" ? "" : "network")}
          >
            <h3 className="font-medium">Network Tests</h3>
            <span>{expandSection === "network" ? "▼" : "▶"}</span>
          </div>
          
          {expandSection === "network" && (
            <div className="p-3 bg-gray-50 rounded-md">
              <NetworkTest />
            </div>
          )}
        </div>
        
        <div className="mb-6">
          <div 
            className="flex justify-between items-center cursor-pointer p-2 bg-gray-100 rounded-md mb-2"
            onClick={() => setExpandSection(expandSection === "api" ? "" : "api")}
          >
            <h3 className="font-medium">API Debug Info</h3>
            <span>{expandSection === "api" ? "▼" : "▶"}</span>
          </div>
          
          {expandSection === "api" && (
            <div className="p-3 bg-gray-50 rounded-md">
              <h4 className="font-medium mb-2">JWT Debug:</h4>
              <pre className="text-xs overflow-auto max-h-40 mb-4 p-2 bg-white rounded border">
                {JSON.stringify(jwtDebug, null, 2)}
              </pre>
              
              <h4 className="font-medium mb-2">Database Debug:</h4>
              <pre className="text-xs overflow-auto max-h-40 mb-4 p-2 bg-white rounded border">
                {JSON.stringify(dbDebug, null, 2)}
              </pre>
              
              <h4 className="font-medium mb-2">Test Profile:</h4>
              <pre className="text-xs overflow-auto max-h-40 mb-4 p-2 bg-white rounded border">
                {JSON.stringify(testProfile, null, 2)}
              </pre>
              
              <div className="flex space-x-2 mt-4">
                <button 
                  onClick={openDbConsole}
                  className="px-4 py-2 bg-gray-700 text-white rounded hover:bg-gray-800 transition-colors"
                >
                  Open Database Console
                </button>
                <button 
                  onClick={openApiDocs}
                  className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 transition-colors"
                >
                  Open API Docs
                </button>
              </div>
            </div>
          )}
        </div>
        
        <div className="flex flex-wrap gap-2">
          <button
            className="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600"
            onClick={fetchDebugInfo}
          >
            Refresh Debug Info
          </button>
          <button
            className="bg-green-500 text-white px-4 py-2 rounded hover:bg-green-600"
            onClick={createTestProfile}
          >
            Create Test Profile
          </button>
          <button
            className="bg-purple-500 text-white px-4 py-2 rounded hover:bg-purple-600"
            onClick={createDirectProfile}
          >
            Create Direct Profile
          </button>
        </div>
      </div>
    </div>
  );
} 