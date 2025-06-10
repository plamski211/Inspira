import { useState } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { userApi } from '../services/api';

export default function DirectProfileCreation() {
  const { user, refreshProfile } = useAuth();
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState(null);
  const [error, setError] = useState(null);
  const [requestDetails, setRequestDetails] = useState(null);

  const createDirectProfile = async () => {
    setLoading(true);
    setError(null);
    setResult(null);
    setRequestDetails(null);
    
    try {
      // Create profile data using Auth0 user info
      const profileData = {
        auth0Id: user?.sub || `direct-debug-${Date.now()}`,
        displayName: user?.name || user?.email?.split('@')[0] || "Debug User",
        bio: "Created using direct debug endpoint",
        avatarUrl: user?.picture || "https://i.pravatar.cc/300",
        location: "Debug Location"
      };
      
      // Store request details for debugging
      setRequestDetails({
        url: 'http://localhost:8080/users/profiles/debug/direct-create',
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(profileData, null, 2)
      });
      
      console.log("Creating direct profile with data:", profileData);
      const response = await userApi.createProfileDirectly(profileData);
      console.log("Direct profile creation response:", response);
      
      setResult(response);
      
      // Refresh the profile in AuthContext
      if (refreshProfile) {
        await refreshProfile();
      }
    } catch (err) {
      console.error("Direct profile creation failed:", err);
      setError(err.message || "Profile creation failed");
    } finally {
      setLoading(false);
    }
  };

  const createTestProfile = async () => {
    setLoading(true);
    setError(null);
    setResult(null);
    setRequestDetails(null);
    
    try {
      // Store request details for debugging
      setRequestDetails({
        url: 'http://localhost:8080/users/profiles/test/create',
        method: 'GET',
        headers: { 'Content-Type': 'application/json' }
      });
      
      console.log("Creating test profile");
      const response = await userApi.testCreateProfile();
      console.log("Test profile creation response:", response);
      
      setResult(response);
      
      // Refresh the profile in AuthContext
      if (refreshProfile) {
        await refreshProfile();
      }
    } catch (err) {
      console.error("Test profile creation failed:", err);
      setError(err.message || "Test profile creation failed");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="p-4 bg-white rounded-lg border border-gray-200 shadow-sm">
      <h3 className="text-lg font-medium mb-4">Direct Profile Creation</h3>
      
      <div className="flex space-x-2 mb-4">
        <button
          onClick={createDirectProfile}
          disabled={loading}
          className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:bg-blue-300"
        >
          {loading ? "Creating..." : "Create Direct Profile"}
        </button>
        
        <button
          onClick={createTestProfile}
          disabled={loading}
          className="px-4 py-2 bg-purple-600 text-white rounded-md hover:bg-purple-700 disabled:bg-purple-300"
        >
          {loading ? "Creating..." : "Create Test Profile"}
        </button>
        
        <button
          onClick={refreshProfile}
          disabled={loading}
          className="px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700 disabled:bg-green-300"
        >
          {loading ? "Refreshing..." : "Refresh Profile"}
        </button>
      </div>
      
      {requestDetails && (
        <div className="p-3 bg-gray-50 border border-gray-200 rounded-md mb-4">
          <p className="font-medium">Request Details</p>
          <pre className="text-xs overflow-auto max-h-40 mt-2 p-2 bg-white rounded border">
            {`URL: ${requestDetails.url}\nMethod: ${requestDetails.method}\nHeaders: ${JSON.stringify(requestDetails.headers, null, 2)}${requestDetails.body ? `\nBody: ${requestDetails.body}` : ''}`}
          </pre>
        </div>
      )}
      
      {error && (
        <div className="p-3 bg-red-50 border border-red-200 rounded-md text-red-700 mb-4">
          <p className="font-medium">Error</p>
          <p>{error}</p>
          <div className="mt-2">
            <p className="text-sm text-red-600">Troubleshooting:</p>
            <ul className="list-disc list-inside text-sm text-red-600">
              <li>Check if user-service is running (docker-compose ps)</li>
              <li>Verify port 8080 is accessible</li>
              <li>Check CORS settings on the backend</li>
              <li>Verify network connectivity between containers</li>
            </ul>
          </div>
        </div>
      )}
      
      {result && (
        <div className="p-3 bg-green-50 border border-green-200 rounded-md text-green-700">
          <p className="font-medium">Profile Created</p>
          <pre className="text-xs overflow-auto max-h-40 mt-2 p-2 bg-white rounded border">
            {JSON.stringify(result, null, 2)}
          </pre>
        </div>
      )}
    </div>
  );
} 