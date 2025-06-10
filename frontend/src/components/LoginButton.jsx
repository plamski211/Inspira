import { useAuth0 } from "@auth0/auth0-react";

export default function LoginButton() {
  const { loginWithRedirect, isAuthenticated, isLoading } = useAuth0();

  const handleLogin = () => {
    console.log("Login button clicked");
    loginWithRedirect({
      audience: 'https://api.inspira.com',
      scope: 'openid profile email'
    });
  };

  if (isLoading) {
    return (
      <button className="bg-gray-300 text-white px-4 py-2 rounded-full cursor-not-allowed">
        Loading...
      </button>
    );
  }

  if (isAuthenticated) {
    return null;
  }

  return (
    <button 
      onClick={handleLogin}
      className="bg-primary text-white px-4 py-2 rounded-full hover:bg-primary-dark transition-colors"
    >
      Login
    </button>
  );
} 