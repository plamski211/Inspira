"use client"

import { useState, useEffect } from "react"
import { useParams, Link } from "react-router-dom"
import { Heart, MessageCircle, Share2, Bookmark, Download, MoreHorizontal, ChevronLeft } from "lucide-react"
import { motion } from "framer-motion"

export default function Detail() {
  const { id } = useParams()
  const [pin, setPin] = useState(null)
  const [loading, setLoading] = useState(true)
  const [liked, setLiked] = useState(false)
  const [saved, setSaved] = useState(false)
  const [comment, setComment] = useState("")
  const [comments, setComments] = useState([])
  const [relatedPins, setRelatedPins] = useState([])

  useEffect(() => {
    // Scroll to top when component mounts
    window.scrollTo(0, 0)

    // Simulate fetching pin data
    setLoading(true)
    setTimeout(() => {
      // Mock pin data
      setPin({
        id,
        title: "Creative Artwork with Vibrant Colors and Modern Design Elements",
        description:
          "This stunning piece combines vibrant colors with modern design elements to create a visually captivating experience. The artist uses a unique technique to blend digital and traditional art forms.",
        image: `https://picsum.photos/seed/${id}/800/1000`,
        user: "creative_artist",
        userImage: `https://i.pravatar.cc/150?u=${id}`,
        likes: 1243,
        saves: 876,
        views: 12500,
        createdAt: "2023-05-15T10:30:00Z",
        tags: ["digital art", "modern", "vibrant", "design", "creative"],
      })

      // Mock comments
      setComments([
        {
          id: 1,
          user: "artlover22",
          userImage: "https://i.pravatar.cc/150?u=1",
          text: "This is absolutely stunning! Love the color palette you used.",
          createdAt: "2023-05-16T14:22:00Z",
          likes: 24,
        },
        {
          id: 2,
          user: "designpro",
          userImage: "https://i.pravatar.cc/150?u=2",
          text: "The composition is perfect. Would love to know more about your process!",
          createdAt: "2023-05-16T15:45:00Z",
          likes: 18,
        },
        {
          id: 3,
          user: "creative_mind",
          userImage: "https://i.pravatar.cc/150?u=3",
          text: "Incredible work! The details are amazing.",
          createdAt: "2023-05-17T09:12:00Z",
          likes: 12,
        },
      ])

      // Mock related pins
      setRelatedPins(
        Array.from({ length: 8 }).map((_, i) => ({
          id: `related-${i}`,
          title: `Related ${["Artwork", "Design", "Creation"][Math.floor(Math.random() * 3)]} #${i + 1}`,
          user: `creator${Math.floor(Math.random() * 100)}`,
          image: `https://picsum.photos/seed/${Number.parseInt(id) + 100 + i}/300/400`,
          likes: Math.floor(Math.random() * 1000),
          saves: Math.floor(Math.random() * 500),
        })),
      )

      setLoading(false)
    }, 1000)
  }, [id])

  const handleLike = () => {
    setLiked(!liked)
    if (!liked) {
      setPin((prev) => ({ ...prev, likes: prev.likes + 1 }))
    } else {
      setPin((prev) => ({ ...prev, likes: prev.likes - 1 }))
    }
  }

  const handleSave = () => {
    setSaved(!saved)
    if (!saved) {
      setPin((prev) => ({ ...prev, saves: prev.saves + 1 }))
    } else {
      setPin((prev) => ({ ...prev, saves: prev.saves - 1 }))
    }
  }

  const handleCommentSubmit = (e) => {
    e.preventDefault()
    if (!comment.trim()) return

    const newComment = {
      id: comments.length + 1,
      user: "current_user", // In a real app, this would be the logged-in user
      userImage: "https://i.pravatar.cc/150?u=current",
      text: comment,
      createdAt: new Date().toISOString(),
      likes: 0,
    }

    setComments([newComment, ...comments])
    setComment("")
  }

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="w-12 h-12 border-4 border-gray-200 border-t-inspira rounded-full animate-spin"></div>
      </div>
    )
  }

  if (!pin) {
    return (
      <div className="min-h-screen flex flex-col items-center justify-center p-4">
        <h1 className="text-2xl font-bold mb-4">Pin not found</h1>
        <p className="text-gray-600 mb-6">The pin you're looking for doesn't exist or has been removed.</p>
        <Link to="/explore" className="px-6 py-2 bg-inspira text-white rounded-full">
          Explore more pins
        </Link>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-white">
      {/* Back button for mobile */}
      <Link
        to="/explore"
        className="fixed top-20 left-4 z-40 md:hidden bg-white/80 backdrop-blur-sm p-2 rounded-full shadow-md"
      >
        <ChevronLeft className="h-5 w-5" />
      </Link>

      <div className="max-w-screen-xl mx-auto px-4 py-8">
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: 0.5 }}
          className="bg-white rounded-2xl overflow-hidden shadow-xl"
        >
          <div className="flex flex-col md:flex-row">
            {/* Pin Image */}
            <div className="md:w-3/5 bg-gray-100">
              <img src={pin.image || "/placeholder.svg"} alt={pin.title} className="w-full h-auto object-cover" />
            </div>

            {/* Pin Details */}
            <div className="md:w-2/5 p-6 flex flex-col">
              {/* Header with actions */}
              <div className="flex justify-between items-center mb-4">
                <div className="flex items-center space-x-2">
                  <button
                    onClick={handleSave}
                    className={`px-4 py-2 rounded-full font-medium text-sm transition-colors ${
                      saved ? "bg-inspira text-white" : "bg-inspira/10 text-inspira-dark hover:bg-inspira/20"
                    }`}
                  >
                    {saved ? "Saved" : "Save"}
                  </button>
                  <button className="p-2 rounded-full hover:bg-gray-100">
                    <MoreHorizontal className="h-5 w-5 text-gray-600" />
                  </button>
                </div>

                <div className="flex items-center space-x-2">
                  <button className="p-2 rounded-full hover:bg-gray-100">
                    <Share2 className="h-5 w-5 text-gray-600" />
                  </button>
                  <button className="p-2 rounded-full hover:bg-gray-100">
                    <Download className="h-5 w-5 text-gray-600" />
                  </button>
                </div>
              </div>

              {/* Title and description */}
              <h1 className="text-2xl font-bold mb-2">{pin.title}</h1>
              <p className="text-gray-600 mb-4">{pin.description}</p>

              {/* Creator info */}
              <div className="flex items-center mb-6">
                <img
                  src={pin.userImage || "/placeholder.svg"}
                  alt={pin.user}
                  className="w-10 h-10 rounded-full object-cover border border-gray-200"
                />
                <div className="ml-3">
                  <div className="font-medium">{pin.user}</div>
                  <div className="text-sm text-gray-500">{new Date(pin.createdAt).toLocaleDateString()}</div>
                </div>
                <button className="ml-auto px-4 py-1.5 rounded-full text-sm font-medium bg-gray-100 hover:bg-gray-200 transition-colors">
                  Follow
                </button>
              </div>

              {/* Stats */}
              <div className="flex items-center justify-between mb-6 text-sm text-gray-500">
                <div className="flex items-center">
                  <Heart className={`h-4 w-4 mr-1 ${liked ? "fill-red-500 text-red-500" : ""}`} />
                  <span>{pin.likes.toLocaleString()} likes</span>
                </div>
                <div className="flex items-center">
                  <MessageCircle className="h-4 w-4 mr-1" />
                  <span>{comments.length} comments</span>
                </div>
                <div className="flex items-center">
                  <Bookmark className="h-4 w-4 mr-1" />
                  <span>{pin.saves.toLocaleString()} saves</span>
                </div>
              </div>

              {/* Tags */}
              <div className="mb-6">
                <h3 className="text-sm font-medium mb-2">Tags</h3>
                <div className="flex flex-wrap gap-2">
                  {pin.tags.map((tag) => (
                    <Link
                      key={tag}
                      to={`/explore?tag=${tag}`}
                      className="px-3 py-1 bg-gray-100 rounded-full text-sm hover:bg-gray-200 transition-colors"
                    >
                      {tag}
                    </Link>
                  ))}
                </div>
              </div>

              {/* Comments section */}
              <div className="flex-1 overflow-hidden flex flex-col">
                <h3 className="text-lg font-medium mb-4">Comments</h3>

                {/* Comment form */}
                <form onSubmit={handleCommentSubmit} className="mb-4 flex">
                  <input
                    type="text"
                    placeholder="Add a comment..."
                    value={comment}
                    onChange={(e) => setComment(e.target.value)}
                    className="flex-1 px-4 py-2 border border-gray-200 rounded-l-full focus:outline-none focus:ring-1 focus:ring-inspira"
                  />
                  <button
                    type="submit"
                    className="px-4 py-2 bg-inspira text-white rounded-r-full hover:bg-inspira-dark transition-colors"
                  >
                    Post
                  </button>
                </form>

                {/* Comments list */}
                <div className="overflow-y-auto flex-1 -mr-3 pr-3">
                  {comments.length === 0 ? (
                    <p className="text-gray-500 text-center py-4">No comments yet. Be the first to comment!</p>
                  ) : (
                    <div className="space-y-4">
                      {comments.map((comment) => (
                        <div key={comment.id} className="flex">
                          <img
                            src={comment.userImage || "/placeholder.svg"}
                            alt={comment.user}
                            className="w-8 h-8 rounded-full object-cover border border-gray-200 mr-3 flex-shrink-0"
                          />
                          <div className="flex-1">
                            <div className="bg-gray-100 rounded-2xl p-3">
                              <div className="font-medium">{comment.user}</div>
                              <p>{comment.text}</p>
                            </div>
                            <div className="flex items-center mt-1 text-xs text-gray-500">
                              <button className="hover:text-gray-700">Like</button>
                              <span className="mx-2">•</span>
                              <button className="hover:text-gray-700">Reply</button>
                              <span className="mx-2">•</span>
                              <span>{new Date(comment.createdAt).toLocaleDateString()}</span>
                            </div>
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              </div>
            </div>
          </div>
        </motion.div>

        {/* Related Pins */}
        <div className="mt-16">
          <h2 className="text-2xl font-bold mb-6">More like this</h2>
          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4">
            {relatedPins.map((relatedPin) => (
              <Link key={relatedPin.id} to={`/pin/${relatedPin.id}`} className="block">
                <div className="rounded-xl overflow-hidden bg-gray-100 hover:shadow-md transition-shadow">
                  <img
                    src={relatedPin.image || "/placeholder.svg"}
                    alt={relatedPin.title}
                    className="w-full h-auto object-cover aspect-[3/4]"
                  />
                  <div className="p-2">
                    <h3 className="font-medium text-sm line-clamp-1">{relatedPin.title}</h3>
                    <div className="flex items-center mt-1">
                      <img
                        src={`https://i.pravatar.cc/150?u=${relatedPin.user}`}
                        alt={relatedPin.user}
                        className="w-5 h-5 rounded-full object-cover"
                      />
                      <span className="ml-1 text-xs text-gray-500">{relatedPin.user}</span>
                    </div>
                  </div>
                </div>
              </Link>
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}
