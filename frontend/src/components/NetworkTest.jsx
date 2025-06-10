import { useState } from 'react';

export default function NetworkTest() {
  const [loading, setLoading] = useState(false);
  const [results, setResults] = useState({});
  
  const testEndpoints = async () => {
    setLoading(true);
    setResults({});
    
    const endpoints = [
      { name: 'API Gateway', url: 'http://localhost:8000/api/health' },
      { name: 'User Service', url: 'http://localhost:8080/users/profiles/health' },
      { name: 'User Service Debug', url: 'http://localhost:8080/users/profiles/debug/public' },
      { name: 'Test Create Profile', url: 'http://localhost:8080/users/profiles/test/create' },
      { name: 'API Gateway User Service', url: 'http://localhost:8000/api/users/profiles/health' }
    ];
    
    const newResults = {};
    
    for (const endpoint of endpoints) {
      try {
        console.log(`Testing endpoint: ${endpoint.name} (${endpoint.url})`);
        const startTime = Date.now();
        const response = await fetch(endpoint.url, { 
          method: 'GET',
          headers: { 'Content-Type': 'application/json' },
          cache: 'no-store'
        });
        const endTime = Date.now();
        
        let data = null;
        try {
          data = await response.json();
        } catch (e) {
          // Ignore JSON parsing errors
        }
        
        newResults[endpoint.name] = {
          status: response.status,
          ok: response.ok,
          time: endTime - startTime,
          data
        };
      } catch (error) {
        newResults[endpoint.name] = {
          error: error.message,
          ok: false
        };
      }
    }
    
    setResults(newResults);
    setLoading(false);
  };
  
  return (
    <div className="p-4 bg-white rounded-lg border border-gray-200 shadow-sm">
      <h3 className="text-lg font-medium mb-4">Network Connectivity Test</h3>
      
      <button
        onClick={testEndpoints}
        disabled={loading}
        className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:bg-blue-300 mb-4"
      >
        {loading ? "Testing..." : "Test API Connectivity"}
      </button>
      
      {Object.keys(results).length > 0 && (
        <div className="mt-4">
          <h4 className="text-md font-medium mb-2">Results:</h4>
          <div className="space-y-2">
            {Object.entries(results).map(([name, result]) => (
              <div 
                key={name} 
                className={`p-3 rounded-md ${result.ok 
                  ? 'bg-green-50 border border-green-200 text-green-700' 
                  : 'bg-red-50 border border-red-200 text-red-700'}`}
              >
                <div className="flex justify-between">
                  <span className="font-medium">{name}</span>
                  <span>{result.ok ? `✅ ${result.status} (${result.time}ms)` : `❌ ${result.error || result.status}`}</span>
                </div>
                {result.data && (
                  <pre className="text-xs overflow-auto max-h-32 mt-2 p-2 bg-white rounded border">
                    {JSON.stringify(result.data, null, 2)}
                  </pre>
                )}
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
} 