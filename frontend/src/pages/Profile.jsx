import { useState, useEffect } from "react"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Settings, Grid, Bookmark, Heart, Edit3, MapPin, LinkIcon } from "lucide-react"
import MasonryGrid from "../components/MasonryGrid"

// Generate sample pins for the profile
const generateProfilePins = (count, prefix) => {
  return Array.from({ length: count }).map((_, i) => ({
    id: `${prefix}-${i}`,
    title: `${prefix === "created" ? "My Creation" : "Saved Pin"} #${i + 1}`,
    user: prefix === "created" ? "current_user" : `creator${Math.floor(Math.random() * 100)}`,
    image: `https://picsum.photos/seed/${prefix}-${i}/${300 + Math.floor(Math.random() * 300)}/${400 + Math.floor(Math.random() * 300)}`,
    likes: Math.floor(Math.random() * 1000),
    saves: Math.floor(Math.random() * 500),
    aspectRatio: 0.8 + Math.random() * 0.8,
  }))
}

export default function Profile() {
  const [activeTab, setActiveTab] = useState("created")
  const [createdPins, setCreatedPins] = useState([])
  const [savedPins, setSavedPins] = useState([])
  const [loading, setLoading] = useState(true)

  // Mock user data
  const user = {
    username: "creative_soul",
    displayName: "Alex Johnson",
    bio: "Digital artist and photographer passionate about capturing moments and creating unique visual experiences.",
    location: "San Francisco, CA",
    website: "alexjohnson.design",
    followers: 1243,
    following: 567,
    profileImage: "https://i.pravatar.cc/300?u=profile",
    coverImage: "https://images.unsplash.com/photo-1579546929518-9e396f3cc809?q=80&w=2070&auto=format&fit=crop",
  }

  useEffect(() => {
    // Simulate loading pins
    setLoading(true)

    setTimeout(() => {
      if (activeTab === "created") {
        setCreatedPins(generateProfilePins(15, "created"))
      } else if (activeTab === "saved") {
        setSavedPins(generateProfilePins(24, "saved"))
      }

      setLoading(false)
    }, 1000)
  }, [activeTab])

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Profile Header */}
      <div className="relative">
        {/* Cover Image */}
        <div className="h-64 overflow-hidden">
          <img src={user.coverImage || "/placeholder.svg"} alt="Cover" className="w-full h-full object-cover" />
        </div>

        {/* Profile Info */}
        <div className="max-w-screen-xl mx-auto px-4 relative -mt-20">
          <div className="bg-white rounded-2xl shadow-lg p-6 md:p-8">
            <div className="flex flex-col md:flex-row items-center md:items-start gap-6">
              {/* Profile Image */}
              <div className="relative">
                <img
                  src={user.profileImage || "/placeholder.svg"}
                  alt={user.displayName}
                  className="w-32 h-32 rounded-full border-4 border-white object-cover"
                />
                <button className="absolute bottom-0 right-0 p-2 bg-white rounded-full shadow-md hover:bg-gray-50 transition-colors">
                  <Edit3 className="h-4 w-4 text-gray-600" />
                </button>
              </div>

              {/* Profile Details */}
              <div className="flex-1 text-center md:text-left">
                <h1 className="text-2xl font-bold">{user.displayName}</h1>
                <p className="text-gray-500 mb-2">@{user.username}</p>
                <p className="text-gray-700 mb-4 max-w-2xl">{user.bio}</p>

                <div className="flex flex-wrap justify-center md:justify-start gap-4 mb-4">
                  {user.location && (
                    <div className="flex items-center text-gray-600 text-sm">
                      <MapPin className="h-4 w-4 mr-1" />
                      <span>{user.location}</span>
                    </div>
                  )}

                  {user.website && (
                    <div className="flex items-center text-gray-600 text-sm">
                      <LinkIcon className="h-4 w-4 mr-1" />
                      <a
                        href={`https://${user.website}`}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="text-inspira hover:underline"
                      >
                        {user.website}
                      </a>
                    </div>
                  )}
                </div>

                <div className="flex justify-center md:justify-start gap-6 text-sm">
                  <div>
                    <span className="font-bold">{user.followers.toLocaleString()}</span> followers
                  </div>
                  <div>
                    <span className="font-bold">{user.following.toLocaleString()}</span> following
                  </div>
                </div>
              </div>

              {/* Action Buttons */}
              <div className="flex gap-2">
                <button className="px-4 py-2 bg-inspira text-white rounded-full hover:bg-inspira-dark transition-colors">
                  Share
                </button>
                <button className="p-2 rounded-full hover:bg-gray-100 transition-colors">
                  <Settings className="h-5 w-5 text-gray-600" />
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Content Tabs */}
      <div className="max-w-screen-xl mx-auto px-4 py-8">
        <Tabs defaultValue="created" value={activeTab} onValueChange={setActiveTab}>
          <div className="flex justify-center mb-8">
            <TabsList className="bg-gray-100 p-1 rounded-full">
              <TabsTrigger
                value="created"
                className="rounded-full px-6 py-2 data-[state=active]:bg-white data-[state=active]:shadow-sm"
              >
                <Grid className="h-4 w-4 mr-2" />
                Created
              </TabsTrigger>
              <TabsTrigger
                value="saved"
                className="rounded-full px-6 py-2 data-[state=active]:bg-white data-[state=active]:shadow-sm"
              >
                <Bookmark className="h-4 w-4 mr-2" />
                Saved
              </TabsTrigger>
              <TabsTrigger
                value="liked"
                className="rounded-full px-6 py-2 data-[state=active]:bg-white data-[state=active]:shadow-sm"
              >
                <Heart className="h-4 w-4 mr-2" />
                Liked
              </TabsTrigger>
            </TabsList>
          </div>

          <TabsContent value="created">
            {loading ? (
              <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4">
                {Array.from({ length: 15 }).map((_, i) => (
                  <div
                    key={i}
                    className="bg-gray-200 rounded-xl animate-pulse"
                    style={{ height: `${200 + Math.random() * 200}px` }}
                  ></div>
                ))}
              </div>
            ) : createdPins.length > 0 ? (
              <MasonryGrid pins={createdPins} />
            ) : (
              <div className="text-center py-16">
                <h3 className="text-xl font-bold mb-2">You haven't created any pins yet</h3>
                <p className="text-gray-600 mb-6">Share your ideas with the world!</p>
                <button className="px-6 py-2 bg-inspira text-white rounded-full hover:bg-inspira-dark transition-colors">
                  Create a Pin
                </button>
              </div>
            )}
          </TabsContent>

          <TabsContent value="saved">
            {loading ? (
              <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4">
                {Array.from({ length: 15 }).map((_, i) => (
                  <div
                    key={i}
                    className="bg-gray-200 rounded-xl animate-pulse"
                    style={{ height: `${200 + Math.random() * 200}px` }}
                  ></div>
                ))}
              </div>
            ) : savedPins.length > 0 ? (
              <MasonryGrid pins={savedPins} />
            ) : (
              <div className="text-center py-16">
                <h3 className="text-xl font-bold mb-2">You haven't saved any pins yet</h3>
                <p className="text-gray-600 mb-6">Discover and save ideas that inspire you!</p>
                <button className="px-6 py-2 bg-inspira text-white rounded-full hover:bg-inspira-dark transition-colors">
                  Explore Pins
                </button>
              </div>
            )}
          </TabsContent>

          <TabsContent value="liked">
            <div className="text-center py-16">
              <h3 className="text-xl font-bold mb-2">You haven't liked any pins yet</h3>
              <p className="text-gray-600 mb-6">Show some love to pins that inspire you!</p>
              <button className="px-6 py-2 bg-inspira text-white rounded-full hover:bg-inspira-dark transition-colors">
                Explore Pins
              </button>
            </div>
          </TabsContent>
        </Tabs>
      </div>
    </div>
  )
}
