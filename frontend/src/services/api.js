// src/services/api.js
import axios from 'axios';

// Base URL for your API gateway or individual services
const API_URL = import.meta.env.VITE_API_GATEWAY_URL || 'http://localhost:8080';

// Create axios instance
const api = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Add auth token to requests
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('auth_token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// API functions
export const userService = {
  getProfile: () => api.get('/users/profile'),
  updateProfile: (profileData) => api.put('/users/profile', profileData),
  getCurrentUserProfile: () => api.get('/users/profiles/me'),
};

export const contentService = {
  getAllContent: () => api.get('/content'),
  getContentById: (id) => api.get(`/content/${id}`),
  createContent: (contentData) => api.post('/content', contentData),
  getUserContent: (userId) => api.get(`/users/${userId}/content`),
};

export const mediaService = {
  uploadMedia: (file) => {
    const formData = new FormData();
    formData.append('file', file);
    return api.post('/media/upload', formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    });
  },
  getMediaById: (id) => api.get(`/media/${id}`),
};