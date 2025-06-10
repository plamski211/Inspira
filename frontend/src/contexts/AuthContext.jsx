import { createContext, useState, useEffect, useContext } from 'react';
import { useAuth0 } from '@auth0/auth0-react';
import { userApi } from '../services/api';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const { isAuthenticated, user, isLoading: auth0Loading, getAccessTokenSilently } = useAuth0();
  const [profile, setProfile] = useState(null);
  const [token, setToken] = useState(null);
  const [profileLoading, setProfileLoading] = useState(false);
  const [error, setError] = useState(null);

  // For debugging
  useEffect(() => {
    console.log("Auth0 state:", { isAuthenticated, user, auth0Loading });
  }, [isAuthenticated, user, auth0Loading]);

  // Get and store access token when auth state changes
  useEffect(() => {
    const getToken = async () => {
      if (isAuthenticated && user) {
        try {
          console.log("Getting access token for user:", user.sub);
          const accessToken = await getAccessTokenSilently({
            audience: 'https://api.inspira.com',
          });
          console.log("Access token received, length:", accessToken.length);
          setToken(accessToken);
          localStorage.setItem('auth_token', accessToken); // For debugging
        } catch (err) {
          console.error('Error getting access token:', err);
          setError(err);
        }
      }
    };

    getToken();
  }, [isAuthenticated, user, getAccessTokenSilently]);

  // Fetch user profile when authenticated
  useEffect(() => {
    const fetchUserProfile = async () => {
      if (isAuthenticated && user) {
        setProfileLoading(true);
        try {
          console.log('Fetching user profile from API for user:', user.sub);
          
          // Try to get existing profile first
          try {
            const userProfile = await userApi.getCurrentProfile();
            console.log('User profile fetched:', userProfile);
            setProfile(userProfile);
            return;
          } catch (fetchErr) {
            console.log('Profile not found, will try to create one:', fetchErr);
          }
          
          // If profile doesn't exist or error occurred, create one directly
          console.log('Creating profile directly for:', user.sub);
          const profileData = {
            auth0Id: user.sub,
            displayName: user.nickname || user.name || user.email?.split('@')[0] || "New User",
            bio: "Created automatically",
            avatarUrl: user.picture,
            location: ''
          };
          
          // Try direct creation first
          try {
            console.log('Attempting direct profile creation with:', profileData);
            const directProfile = await userApi.createProfileDirectly(profileData);
            console.log('Direct profile creation result:', directProfile);
            setProfile(directProfile);
            return;
          } catch (directErr) {
            console.log('Direct profile creation failed, trying test endpoint:', directErr);
          }
          
          // Try test endpoint as fallback
          const testProfile = await userApi.testCreateProfile();
          console.log('Test profile created:', testProfile);
          setProfile(testProfile);
          
        } catch (err) {
          console.error('All profile creation attempts failed:', err);
          setError(err);
        } finally {
          setProfileLoading(false);
        }
      }
    };

    if (isAuthenticated && user) {
      fetchUserProfile();
    }
  }, [isAuthenticated, user]);

  const value = {
    isAuthenticated,
    isLoading: auth0Loading || profileLoading,
    user,
    profile,
    token,
    error,
    refreshProfile: async () => {
      setProfileLoading(true);
      try {
        // Try all profile fetch/create methods
        try {
          const userProfile = await userApi.getCurrentProfile();
          setProfile(userProfile);
          return userProfile;
        } catch (fetchErr) {
          console.log('Profile refresh failed, trying creation:', fetchErr);
          
          if (user) {
            const profileData = {
              auth0Id: user.sub,
              displayName: user.nickname || user.name || user.email?.split('@')[0] || "New User",
              bio: "Created during refresh",
              avatarUrl: user.picture,
              location: ''
            };
            
            const directProfile = await userApi.createProfileDirectly(profileData);
            setProfile(directProfile);
            return directProfile;
          }
          throw new Error('No user available for profile creation');
        }
      } catch (err) {
        console.error('Error refreshing user profile:', err);
        setError(err);
        return null;
      } finally {
        setProfileLoading(false);
      }
    }
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export const useAuth = () => useContext(AuthContext); 