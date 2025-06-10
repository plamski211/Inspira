"use client"

import { useState } from "react"
import { useNavigate } from "react-router-dom"
import FileUpload from "../components/FileUpload"
import { useAuth0 } from "@auth0/auth0-react"

export default function Upload() {
  const [uploadedContent, setUploadedContent] = useState(null)
  const { isAuthenticated, loginWithRedirect } = useAuth0()
  const navigate = useNavigate()

  // Redirect to homepage after successful upload
  const handleUploadComplete = (content) => {
    setUploadedContent(content)
    setTimeout(() => {
      navigate('/')
    }, 2000)
  }

  // If not authenticated, prompt login
  if (!isAuthenticated) {
    return (
      <div className="container mx-auto px-4 py-8 max-w-2xl">
        <div className="bg-white p-8 rounded-lg shadow text-center">
          <h2 className="text-2xl font-bold mb-4">Authentication Required</h2>
          <p className="mb-4">You need to be logged in to upload content.</p>
          <button 
            onClick={() => loginWithRedirect()}
            className="px-4 py-2 bg-inspira text-white rounded-full hover:bg-inspira-dark transition"
          >
            Log In
          </button>
        </div>
      </div>
    )
  }

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="max-w-2xl mx-auto">
        <h1 className="text-3xl font-bold mb-8">Upload Content</h1>
        
        {uploadedContent ? (
          <div className="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded mb-4">
            <p className="font-bold">Upload successful!</p>
            <p>Your content has been uploaded and is being processed.</p>
            <p className="text-sm mt-2">Redirecting to home page...</p>
          </div>
        ) : (
          <FileUpload onUploadComplete={handleUploadComplete} />
        )}
      </div>
    </div>
  )
}
