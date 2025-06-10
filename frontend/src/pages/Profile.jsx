import { useState, useEffect } from "react"
import { useParams, useNavigate } from "react-router-dom"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Settings, Grid, Bookmark, Heart, Edit3, MapPin, LinkIcon, AlertCircle } from "lucide-react"
import MasonryGrid from "../components/MasonryGrid"
import { useAuth } from "../contexts/AuthContext"
import { userApi } from "../services/api"

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
  const { id } = useParams()
  const navigate = useNavigate()
  const { isAuthenticated, isLoading: authLoading, profile: authProfile, user, refreshProfile, error: authError } = useAuth()
  
  const [activeTab, setActiveTab] = useState("created")
  const [createdPins, setCreatedPins] = useState([])
  const [savedPins, setSavedPins] = useState([])
  const [loading, setLoading] = useState(true)
  const [profile, setProfile] = useState(null)
  const [loadingProfile, setLoadingProfile] = useState(true)
  const [error, setError] = useState(null)
  const [debugInfo, setDebugInfo] = useState(null)
  
  const isOwnProfile = !id || (authProfile && id === authProfile.auth0Id)

  // For debugging
  useEffect(() => {
    const getDebugInfo = async () => {
      try {
        const jwt = await userApi.debugJwt()
        const db = await userApi.debugDatabase()
        setDebugInfo({ jwt, db })
      } catch (err) {
        console.error("Error getting debug info:", err)
      }
    }

    if (isAuthenticated && !authLoading) {
      getDebugInfo()
    }
  }, [isAuthenticated, authLoading])

  // Load profile data
  useEffect(() => {
    const fetchProfile = async () => {
      setLoadingProfile(true)
      
      try {
        // If no ID is provided, or it's the current user's ID, use the auth profile
        if (isOwnProfile && authProfile) {
          console.log("Using auth profile:", authProfile)
          setProfile(authProfile)
        } else if (id) {
          // Otherwise, fetch the profile by ID
          console.log("Fetching profile by ID:", id)
          const profileData = await userApi.getProfileByAuth0Id(id)
          setProfile(profileData)
        } else if (isAuthenticated && user) {
          // Try to create a profile if needed
          console.log("No profile found, creating test profile")
          try {
            const testProfile = await userApi.testCreateProfile()
            console.log("Created test profile:", testProfile)
            setProfile(testProfile)
          } catch (err) {
            console.error("Failed to create test profile:", err)
            setError("Failed to create user profile. Please try again later.")
          }
        }
      } catch (err) {
        console.error("Error fetching profile:", err)
        setError("Failed to load profile. Please try again later.")
      } finally {
        setLoadingProfile(false)
      }
    }

    if (!authLoading) {
      fetchProfile()
    }
  }, [id, authProfile, authLoading, isOwnProfile, isAuthenticated, user])

  // Load pins for selected tab
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

  const handleCreateTestProfile = async () => {
    setLoadingProfile(true)
    try {
      const testProfile = await userApi.testCreateProfile()
      console.log("Created test profile:", testProfile)
      setProfile(testProfile)
      setError(null)
    } catch (err) {
      console.error("Failed to create test profile:", err)
      setError("Failed to create test profile. Please try again.")
    } finally {
      setLoadingProfile(false)
    }
  }

  const handleDirectProfileCreation = async () => {
    setLoadingProfile(true)
    try {
      const profileData = {
        auth0Id: user?.sub || "auth0|testuser" + Date.now(),
        displayName: user?.name || "Test User",
        bio: "Created using direct debug endpoint",
        avatarUrl: user?.picture || "https://i.pravatar.cc/300",
        location: "Test Location"
      }
      
      const directProfile = await userApi.createProfileDirectly(profileData)
      console.log("Created direct profile:", directProfile)
      setProfile(directProfile)
      setError(null)
      
      // Refresh auth profile
      if (refreshProfile) {
        await refreshProfile()
      }
    } catch (err) {
      console.error("Failed to create direct profile:", err)
      setError("Failed to create profile directly. Please try again.")
    } finally {
      setLoadingProfile(false)
    }
  }

  // Show loading state if profile is still loading
  if (loadingProfile) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="w-16 h-16 border-4 border-gray-200 border-t-inspira rounded-full animate-spin mx-auto mb-4"></div>
          <p className="text-gray-600">Loading profile...</p>
        </div>
      </div>
    )
  }

  // Handle errors
  if (error || authError) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center p-8 bg-white rounded-lg shadow-md max-w-lg">
          <AlertCircle className="w-16 h-16 text-red-500 mx-auto mb-4" />
          <h2 className="text-2xl font-bold text-gray-800 mb-2">Error Loading Profile</h2>
          <p className="text-gray-600 mb-6">{error || authError?.message || "An unknown error occurred"}</p>
          
          <div className="space-y-4">
            <button 
              onClick={() => navigate("/")}
              className="px-6 py-2 bg-gray-200 text-gray-800 rounded-full hover:bg-gray-300 transition-colors"
            >
              Go to Home
            </button>
            
            <div className="pt-4 border-t border-gray-200">
              <p className="text-sm text-gray-500 mb-2">Debug Options:</p>
              <div className="flex flex-wrap gap-2 justify-center">
                <button 
                  onClick={handleCreateTestProfile}
                  className="px-4 py-1 bg-blue-100 text-blue-700 rounded-full text-sm hover:bg-blue-200 transition-colors"
                >
                  Create Test Profile
                </button>
                <button 
                  onClick={handleDirectProfileCreation}
                  className="px-4 py-1 bg-blue-100 text-blue-700 rounded-full text-sm hover:bg-blue-200 transition-colors"
                >
                  Create Direct Profile
                </button>
                <button 
                  onClick={() => refreshProfile && refreshProfile()}
                  className="px-4 py-1 bg-blue-100 text-blue-700 rounded-full text-sm hover:bg-blue-200 transition-colors"
                >
                  Refresh Profile
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    )
  }

  // Handle case when profile is not found
  if (!profile) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center p-8 bg-white rounded-lg shadow-md">
          <h2 className="text-2xl font-bold text-gray-800 mb-2">Profile Not Found</h2>
          <p className="text-gray-600 mb-6">The profile you're looking for doesn't exist or is not available.</p>
          
          <div className="space-y-4">
            <button 
              onClick={() => navigate("/")}
              className="px-6 py-2 bg-inspira text-white rounded-full hover:bg-inspira-dark transition-colors"
            >
              Go to Home
            </button>
            
            {isAuthenticated && (
              <div className="pt-4 border-t border-gray-200">
                <p className="text-sm text-gray-500 mb-2">Debug Options:</p>
                <div className="flex flex-wrap gap-2 justify-center">
                  <button 
                    onClick={handleCreateTestProfile}
                    className="px-4 py-1 bg-blue-100 text-blue-700 rounded-full text-sm hover:bg-blue-200 transition-colors"
                  >
                    Create Test Profile
                  </button>
                  <button 
                    onClick={handleDirectProfileCreation}
                    className="px-4 py-1 bg-blue-100 text-blue-700 rounded-full text-sm hover:bg-blue-200 transition-colors"
                  >
                    Create Direct Profile
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Profile Header */}
      <div className="relative">
        {/* Cover Image - default to a gradient if none exists */}
        <div className="h-64 overflow-hidden bg-gradient-to-r from-blue-400 to-purple-500">
          {profile.coverImage && (
            <img src={profile.coverImage} alt="Cover" className="w-full h-full object-cover" />
          )}
        </div>

        {/* Profile Info */}
        <div className="max-w-screen-xl mx-auto px-4 relative -mt-20">
          <div className="bg-white rounded-2xl shadow-lg p-6 md:p-8">
            <div className="flex flex-col md:flex-row items-center md:items-start gap-6">
              {/* Profile Image */}
              <div className="relative">
                <img
                  src={profile.avatarUrl || "https://via.placeholder.com/150"}
                  alt={profile.displayName}
                  className="w-32 h-32 rounded-full border-4 border-white object-cover"
                />
                {isOwnProfile && (
                  <button className="absolute bottom-0 right-0 p-2 bg-white rounded-full shadow-md hover:bg-gray-50 transition-colors">
                    <Edit3 className="h-4 w-4 text-gray-600" />
                  </button>
                )}
              </div>

              {/* Profile Details */}
              <div className="flex-1 text-center md:text-left">
                <h1 className="text-2xl font-bold">{profile.displayName}</h1>
                <p className="text-gray-500 mb-2">@{profile.auth0Id?.split('|')[1] || "user"}</p>
                <p className="text-gray-700 mb-4 max-w-2xl">{profile.bio || "No bio yet"}</p>

                <div className="flex flex-wrap justify-center md:justify-start gap-4 mb-4">
                  {profile.location && (
                    <div className="flex items-center text-gray-600 text-sm">
                      <MapPin className="h-4 w-4 mr-1" />
                      <span>{profile.location}</span>
                    </div>
                  )}

                  {profile.website && (
                    <div className="flex items-center text-gray-600 text-sm">
                      <LinkIcon className="h-4 w-4 mr-1" />
                      <a
                        href={`https://${profile.website}`}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="text-inspira hover:underline"
                      >
                        {profile.website}
                      </a>
                    </div>
                  )}
                </div>

                <div className="flex justify-center md:justify-start gap-6 text-sm">
                  <div>
                    <span className="font-bold">{profile.followers || 0}</span> followers
                  </div>
                  <div>
                    <span className="font-bold">{profile.following || 0}</span> following
                  </div>
                </div>
              </div>

              {/* Action Buttons */}
              <div className="flex gap-2">
                {isOwnProfile ? (
                  <button className="px-4 py-2 bg-inspira text-white rounded-full hover:bg-inspira-dark transition-colors">
                    Edit Profile
                  </button>
                ) : (
                  <button className="px-4 py-2 bg-inspira text-white rounded-full hover:bg-inspira-dark transition-colors">
                    Follow
                  </button>
                )}
                <button className="p-2 rounded-full hover:bg-gray-100 transition-colors">
                  <Settings className="h-5 w-5 text-gray-600" />
                </button>
              </div>
            </div>
            
            {/* Debug Info Section */}
            {isOwnProfile && debugInfo && (
              <div className="mt-6 p-4 bg-gray-100 rounded-lg text-xs overflow-auto">
                <details>
                  <summary className="cursor-pointer font-medium text-gray-700">Debug Information</summary>
                  <div className="mt-2 space-y-2">
                    <div>
                      <p className="font-semibold">Auth0 ID:</p>
                      <p className="text-gray-600">{profile.auth0Id || "Not available"}</p>
                    </div>
                    <div>
                      <p className="font-semibold">Database ID:</p>
                      <p className="text-gray-600">{profile.id || "Not available"}</p>
                    </div>
                    <div className="flex gap-2">
                      <button 
                        onClick={handleCreateTestProfile}
                        className="px-2 py-1 bg-blue-100 text-blue-700 rounded text-xs hover:bg-blue-200 transition-colors"
                      >
                        Create Test Profile
                      </button>
                      <button 
                        onClick={handleDirectProfileCreation}
                        className="px-2 py-1 bg-blue-100 text-blue-700 rounded text-xs hover:bg-blue-200 transition-colors"
                      >
                        Create Direct Profile
                      </button>
                    </div>
                  </div>
                </details>
              </div>
            )}
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
                <h3 className="text-xl font-bold mb-2">No pins created yet</h3>
                <p className="text-gray-600 mb-6">{isOwnProfile ? "Share your ideas with the world!" : "This user hasn't created any pins yet."}</p>
                {isOwnProfile && (
                  <button className="px-6 py-2 bg-inspira text-white rounded-full hover:bg-inspira-dark transition-colors">
                    Create a Pin
                  </button>
                )}
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
                <h3 className="text-xl font-bold mb-2">No saved pins yet</h3>
                <p className="text-gray-600 mb-6">{isOwnProfile ? "Discover and save ideas that inspire you!" : "This user hasn't saved any pins yet."}</p>
                {isOwnProfile && (
                  <button className="px-6 py-2 bg-inspira text-white rounded-full hover:bg-inspira-dark transition-colors">
                    Explore Pins
                  </button>
                )}
              </div>
            )}
          </TabsContent>

          <TabsContent value="liked">
            <div className="text-center py-16">
              <h3 className="text-xl font-bold mb-2">No liked pins yet</h3>
              <p className="text-gray-600 mb-6">{isOwnProfile ? "Show some love to pins that inspire you!" : "This user hasn't liked any pins yet."}</p>
              {isOwnProfile && (
                <button className="px-6 py-2 bg-inspira text-white rounded-full hover:bg-inspira-dark transition-colors">
                  Explore Pins
                </button>
              )}
            </div>
          </TabsContent>
        </Tabs>
      </div>
    </div>
  )
}
