"use client"

import { useState } from "react"
import { useNavigate } from "react-router-dom"
import { X, UploadIcon, Tag } from "lucide-react"
import { motion } from "framer-motion"
import { contentService, mediaService } from "../services/api"

export default function Upload() {
  const navigate = useNavigate()
  const [dragging, setDragging] = useState(false)
  const [file, setFile] = useState(null)
  const [preview, setPreview] = useState(null)
  const [title, setTitle] = useState("")
  const [description, setDescription] = useState("")
  const [tags, setTags] = useState([])
  const [currentTag, setCurrentTag] = useState("")
  const [loading, setLoading] = useState(false)

  const handleDragOver = (e) => {
    e.preventDefault()
    setDragging(true)
  }

  const handleDragLeave = () => {
    setDragging(false)
  }

  const handleDrop = (e) => {
    e.preventDefault()
    setDragging(false)

    if (e.dataTransfer.files && e.dataTransfer.files[0]) {
      handleFile(e.dataTransfer.files[0])
    }
  }

  const handleFileInput = (e) => {
    if (e.target.files && e.target.files[0]) {
      handleFile(e.target.files[0])
    }
  }

  const handleFile = (file) => {
    if (!file.type.match("image.*")) {
      alert("Please select an image file")
      return
    }

    setFile(file)

    const reader = new FileReader()
    reader.onload = (e) => {
      setPreview(e.target.result)
    }
    reader.readAsDataURL(file)
  }

  const removeFile = () => {
    setFile(null)
    setPreview(null)
  }

  const addTag = () => {
    if (currentTag.trim() && !tags.includes(currentTag.trim().toLowerCase())) {
      setTags([...tags, currentTag.trim().toLowerCase()])
      setCurrentTag("")
    }
  }

  const removeTag = (tagToRemove) => {
    setTags(tags.filter((tag) => tag !== tagToRemove))
  }

  const handleSubmit = async (e) => {
    e.preventDefault()

    if (!file) {
      alert("Please select an image")
      return
    }

    if (!title.trim()) {
      alert("Please add a title")
      return
    }

    setLoading(true)

    try {
      const uploadRes = await mediaService.uploadMedia(file)
      const mediaKey = uploadRes.data.key

      const userId = Number(localStorage.getItem('user_id'))
      const contentData = {
        userId,
        type: 'image',
        title,
        description,
        tags,
        mediaUrls: [mediaKey],
      }

      await contentService.createContent(contentData)
      navigate('/explore')
    } catch (err) {
      console.error('Upload failed', err)
      alert('Upload failed')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen bg-gray-50 py-8">
      <div className="max-w-4xl mx-auto px-4">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          className="bg-white rounded-2xl shadow-xl overflow-hidden"
        >
          <div className="p-6 border-b border-gray-100">
            <h1 className="text-2xl font-bold text-center">Create Pin</h1>
          </div>

          <form onSubmit={handleSubmit} className="p-6">
            <div className="flex flex-col md:flex-row gap-8">
              {/* Image Upload Section */}
              <div className="md:w-1/2">
                {!preview ? (
                  <div
                    className={`border-2 border-dashed rounded-xl h-80 flex flex-col items-center justify-center cursor-pointer transition-colors ${
                      dragging ? "border-inspira bg-inspira/5" : "border-gray-300 hover:border-inspira/50"
                    }`}
                    onDragOver={handleDragOver}
                    onDragLeave={handleDragLeave}
                    onDrop={handleDrop}
                    onClick={() => document.getElementById("file-input").click()}
                  >
                    <UploadIcon className="h-12 w-12 text-gray-400 mb-4" />
                    <p className="text-gray-600 mb-2">Drag and drop an image or click to browse</p>
                    <p className="text-gray-400 text-sm">Recommended: High quality .jpg files less than 20MB</p>
                    <input id="file-input" type="file" accept="image/*" className="hidden" onChange={handleFileInput} />
                  </div>
                ) : (
                  <div className="relative rounded-xl overflow-hidden h-80">
                    <img
                      src={preview || "/placeholder.svg"}
                      alt="Preview"
                      className="w-full h-full object-contain bg-gray-100"
                    />
                    <button
                      type="button"
                      onClick={removeFile}
                      className="absolute top-2 right-2 p-2 bg-white/80 backdrop-blur-sm rounded-full shadow-md hover:bg-white transition-colors"
                    >
                      <X className="h-5 w-5 text-gray-700" />
                    </button>
                  </div>
                )}
              </div>

              {/* Pin Details Section */}
              <div className="md:w-1/2 space-y-6">
                <div>
                  <label htmlFor="title" className="block text-sm font-medium text-gray-700 mb-1">
                    Title
                  </label>
                  <input
                    type="text"
                    id="title"
                    value={title}
                    onChange={(e) => setTitle(e.target.value)}
                    placeholder="Add a title"
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-inspira"
                    maxLength={100}
                  />
                  <div className="text-xs text-gray-500 mt-1 text-right">{title.length}/100</div>
                </div>

                <div>
                  <label htmlFor="description" className="block text-sm font-medium text-gray-700 mb-1">
                    Description
                  </label>
                  <textarea
                    id="description"
                    value={description}
                    onChange={(e) => setDescription(e.target.value)}
                    placeholder="Tell everyone what your Pin is about"
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-inspira resize-none"
                    rows={4}
                    maxLength={500}
                  ></textarea>
                  <div className="text-xs text-gray-500 mt-1 text-right">{description.length}/500</div>
                </div>

                <div>
                  <label htmlFor="tags" className="block text-sm font-medium text-gray-700 mb-1">
                    Tags
                  </label>
                  <div className="flex">
                    <input
                      type="text"
                      id="tags"
                      value={currentTag}
                      onChange={(e) => setCurrentTag(e.target.value)}
                      onKeyDown={(e) => e.key === "Enter" && (e.preventDefault(), addTag())}
                      placeholder="Add a tag"
                      className="flex-1 px-4 py-2 border border-gray-300 rounded-l-lg focus:outline-none focus:ring-2 focus:ring-inspira"
                    />
                    <button
                      type="button"
                      onClick={addTag}
                      className="px-4 py-2 bg-gray-100 border border-gray-300 border-l-0 rounded-r-lg hover:bg-gray-200 transition-colors"
                    >
                      Add
                    </button>
                  </div>

                  {tags.length > 0 && (
                    <div className="flex flex-wrap gap-2 mt-3">
                      {tags.map((tag) => (
                        <div key={tag} className="flex items-center bg-gray-100 rounded-full px-3 py-1 text-sm">
                          <Tag className="h-3 w-3 mr-1 text-gray-500" />
                          <span>{tag}</span>
                          <button
                            type="button"
                            onClick={() => removeTag(tag)}
                            className="ml-1 text-gray-500 hover:text-gray-700"
                          >
                            <X className="h-3 w-3" />
                          </button>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              </div>
            </div>

            <div className="mt-8 flex justify-end">
              <button
                type="button"
                onClick={() => navigate(-1)}
                className="px-6 py-2 mr-4 border border-gray-300 rounded-full text-gray-700 hover:bg-gray-50 transition-colors"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={loading || !file || !title.trim()}
                className={`px-6 py-2 rounded-full text-white transition-colors ${
                  loading || !file || !title.trim()
                    ? "bg-gray-400 cursor-not-allowed"
                    : "bg-inspira hover:bg-inspira-dark"
                }`}
              >
                {loading ? (
                  <span className="flex items-center">
                    <svg
                      className="animate-spin -ml-1 mr-2 h-4 w-4 text-white"
                      xmlns="http://www.w3.org/2000/svg"
                      fill="none"
                      viewBox="0 0 24 24"
                    >
                      <circle
                        className="opacity-25"
                        cx="12"
                        cy="12"
                        r="10"
                        stroke="currentColor"
                        strokeWidth="4"
                      ></circle>
                      <path
                        className="opacity-75"
                        fill="currentColor"
                        d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                      ></path>
                    </svg>
                    Uploading...
                  </span>
                ) : (
                  "Create Pin"
                )}
              </button>
            </div>
          </form>
        </motion.div>
      </div>
    </div>
  )
}
