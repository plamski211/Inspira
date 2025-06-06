import { api } from "./api"

/**
 * Service for pin-related API calls
 */
export const pinService = {
  /**
   * Get trending pins
   * @param {number} limit - Number of pins to fetch
   * @returns {Promise<Array>} - Array of pin objects
   */
  getTrendingPins: (limit = 20) => {
    return api.get(`/pins/trending?limit=${limit}`)
  },

  /**
   * Get pins by category
   * @param {string} category - Category ID or name
   * @param {number} page - Page number for pagination
   * @param {number} limit - Number of pins per page
   * @returns {Promise<Array>} - Array of pin objects
   */
  getPinsByCategory: (category, page = 1, limit = 20) => {
    return api.get(`/pins/category/${category}?page=${page}&limit=${limit}`)
  },

  /**
   * Get pin details by ID
   * @param {string|number} id - Pin ID
   * @returns {Promise<Object>} - Pin object with details
   */
  getPinById: (id) => {
    return api.get(`/pins/${id}`)
  },

  /**
   * Get related pins
   * @param {string|number} pinId - Pin ID to find related pins for
   * @param {number} limit - Number of related pins to fetch
   * @returns {Promise<Array>} - Array of related pin objects
   */
  getRelatedPins: (pinId, limit = 8) => {
    return api.get(`/pins/${pinId}/related?limit=${limit}`)
  },

  /**
   * Create a new pin
   * @param {Object} pinData - Pin data
   * @returns {Promise<Object>} - Created pin object
   */
  createPin: (pinData) => {
    return api.post("/pins", pinData)
  },

  /**
   * Update a pin
   * @param {string|number} id - Pin ID
   * @param {Object} pinData - Updated pin data
   * @returns {Promise<Object>} - Updated pin object
   */
  updatePin: (id, pinData) => {
    return api.put(`/pins/${id}`, pinData)
  },

  /**
   * Delete a pin
   * @param {string|number} id - Pin ID
   * @returns {Promise<Object>} - Response data
   */
  deletePin: (id) => {
    return api.delete(`/pins/${id}`)
  },

  /**
   * Like a pin
   * @param {string|number} id - Pin ID
   * @returns {Promise<Object>} - Response data
   */
  likePin: (id) => {
    return api.post(`/pins/${id}/like`)
  },

  /**
   * Unlike a pin
   * @param {string|number} id - Pin ID
   * @returns {Promise<Object>} - Response data
   */
  unlikePin: (id) => {
    return api.delete(`/pins/${id}/like`)
  },

  /**
   * Save a pin
   * @param {string|number} id - Pin ID
   * @param {string|number} collectionId - Collection ID (optional)
   * @returns {Promise<Object>} - Response data
   */
  savePin: (id, collectionId) => {
    return api.post(`/pins/${id}/save`, { collectionId })
  },

  /**
   * Unsave a pin
   * @param {string|number} id - Pin ID
   * @returns {Promise<Object>} - Response data
   */
  unsavePin: (id) => {
    return api.delete(`/pins/${id}/save`)
  },
}
