import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import './index.css';

// Load environment variables from env-config.js
const loadEnvironment = () => {
  return new Promise((resolve) => {
    // Check if window.ENV already exists
    if (window.ENV) {
      console.log('Environment variables already loaded');
      resolve();
      return;
    }

    // Create script element to load env-config.js
    const script = document.createElement('script');
    script.src = '/env-config.js';
    script.onload = () => {
      console.log('Environment variables loaded');
      resolve();
    };
    script.onerror = () => {
      console.warn('Failed to load environment variables');
      // Set default values
      window.ENV = {
        API_URL: '/api',
        AUTH0_AUDIENCE: 'https://api.inspira.com',
        AUTH0_REDIRECT_URI: window.location.origin
      };
      resolve();
    };
    document.head.appendChild(script);
  });
};

// Wait for environment variables to load before rendering
loadEnvironment().then(() => {
  ReactDOM.createRoot(document.getElementById('root')).render(
    <React.StrictMode>
      <App />
    </React.StrictMode>
  );
}); 