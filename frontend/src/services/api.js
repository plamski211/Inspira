// src/services/api.js
import axios from 'axios';

// Create a base axios instance
const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL || import.meta.env.VITE_API_BASE_URL || "http://localhost:8080/api",
  headers: {
    'Content-Type': 'application/json',
  },
});

// Add request interceptor to add auth token
api.interceptors.request.use(
  (config) => {
    // Get token from local storage
    const token = localStorage.getItem("auth_token");
    if (token) {
      config.headers["Authorization"] = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    console.error("Request interceptor error:", error);
    return Promise.reject(error);
  }
);

// Add response interceptor for error handling
api.interceptors.response.use(
  (response) => response,
  (error) => {
    console.error("API Error:", error.response || error);
    
    // Check if the error is due to authentication
    if (error.response?.status === 401) {
      // Redirect to login or refresh token
      console.log("Authentication required, redirecting to login...");
      localStorage.removeItem("auth_token");
      window.location.href = "/login";
    }
    
    return Promise.reject(error);
  }
);

// User profile API endpoints
export const userApi = {
  create: async (userData) => {
    console.log("Creating user profile with data:", userData);
    try {
      const response = await api.post("/users/profiles", userData);
      console.log("User profile created:", response.data);
      return response.data;
    } catch (error) {
      console.error("Failed to create user profile:", error);
      throw error;
    }
  },

  getById: async (id) => {
    try {
      const response = await api.get(`/users/profiles/${id}`);
      return response.data;
    } catch (error) {
      console.error(`Failed to get user profile with ID ${id}:`, error);
      throw error;
    }
  },

  getMe: async () => {
    try {
      const response = await api.get("/users/profiles/me");
      return response.data;
    } catch (error) {
      console.error("Failed to get current user profile:", error);
      throw error;
    }
  },
  
  update: async (id, userData) => {
    try {
      const response = await api.put(`/users/profiles/${id}`, userData);
      return response.data;
    } catch (error) {
      console.error(`Failed to update user profile with ID ${id}:`, error);
      throw error;
    }
  },
};

// Content service API endpoints
export const contentApi = {
  upload: async (file, title, description) => {
    try {
      // Create form data
      const formData = new FormData();
      formData.append('file', file);
      formData.append('title', title);
      if (description) {
        formData.append('description', description);
      }
      
      // Use multipart/form-data for file upload
      const response = await api.post("/content/upload", formData, {
        headers: {
          'Content-Type': 'multipart/form-data'
        }
      });
      
      return response.data;
    } catch (error) {
      console.error("Failed to upload content:", error);
      throw error;
    }
  },
  
  getMyContent: async () => {
    try {
      const response = await api.get("/content/my-content");
      return response.data;
    } catch (error) {
      console.error("Failed to get user content:", error);
      throw error;
    }
  },
  
  getById: async (id) => {
    try {
      const response = await api.get(`/content/${id}`);
      return response.data;
    } catch (error) {
      console.error(`Failed to get content with ID ${id}:`, error);
      throw error;
    }
  },
  
  getContentUrl: async (id, useProcessed = true) => {
    try {
      const response = await api.get(`/content/${id}/url`, {
        params: { useProcessed }
      });
      return response.data.url;
    } catch (error) {
      console.error(`Failed to get content URL for ID ${id}:`, error);
      throw error;
    }
  },
  
  deleteContent: async (id) => {
    try {
      const response = await api.delete(`/content/${id}`);
      return response.data;
    } catch (error) {
      console.error(`Failed to delete content with ID ${id}:`, error);
      throw error;
    }
  },
  
  updateContent: async (id, title, description) => {
    try {
      const response = await api.put(`/content/${id}`, null, {
        params: { 
          title, 
          description 
        }
      });
      return response.data;
    } catch (error) {
      console.error(`Failed to update content with ID ${id}:`, error);
      throw error;
    }
  }
};

export default api;