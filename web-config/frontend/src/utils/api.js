import axios from 'axios'

const api = axios.create({
  baseURL: '/api',
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json',
  },
})

// Request interceptor
api.interceptors.request.use(
  (config) => {
    // You can add auth tokens here if needed
    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

// Response interceptor
api.interceptors.response.use(
  (response) => {
    return response
  },
  (error) => {
    // Handle common errors
    if (error.response?.status === 400) {
      console.error('Bad Request:', error.response.data)
    } else if (error.response?.status === 500) {
      console.error('Server Error:', error.response.data)
    } else if (error.code === 'ECONNABORTED') {
      console.error('Request Timeout')
    } else if (!error.response) {
      console.error('Network Error')
    }

    return Promise.reject(error)
  }
)

export default api